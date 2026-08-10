import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/network/session_manager.dart';
import '../../../modem_auth/presentation/controllers/auth_controller.dart';
import '../../../modem_auth/presentation/pages/login_page.dart';
import '../../../modem_auth/domain/repositories/auth_repository.dart';
import '../../../modem_auth/domain/entities/auth_entity.dart';
import '../../../main_layout/presentation/pages/main_layout_page.dart';
import '../../../onboarding/presentation/pages/onboarding_page.dart';
import '../../../quick_setup/presentation/pages/quick_setup_page.dart';
import '../../../../core/services/app_update_service.dart';
import '../pages/modem_connection_error_page.dart';

class SplashController extends GetxController {
  final NetworkInfo networkInfo;
  final AuthController authController;

  SplashController({
    required this.networkInfo,
    required this.authController,
  });

  var loadingText = 'جاري تهيئة بيئة النظام...'.obs;
  var loadingProgress = 0.1.obs;

  @override
  void onInit() {
    super.onInit();
    _initApp();
  }

  Future<void> _initApp() async {
    // 0. التحقق الإجباري من التحديثات قبل الدخول للتطبيق
    loadingText.value = 'التحقق من التحديثات...';
    await AppUpdateService.checkForUpdate();

    // 1. Check onboarding status
    final onboardingVisited = await SessionManager.isOnboardingVisited();
    if (!onboardingVisited) {
      Get.offAll(() => OnboardingPage());
      return;
    }

    loadingText.value = 'التحقق من حالة المودم وتوفر الشبكة...';
    loadingProgress.value = 0.50;
    await Future.delayed(const Duration(milliseconds: 100)); // Minimal delay for UI to paint

    // 2. Run all heavy checks in parallel!
    final authRepo = Get.find<AuthRepository>();
    final results = await Future.wait([
      networkInfo.isConnectedToModem(),
      authRepo.checkIfSetupRequired(),
      authController.authInitFuture ?? Future.value(),
    ]);

    final isConnected = results[0] as bool;
    final isSetupRequired = results[1] as bool;
    
    // AuthController now has the SN
    final currentSN = authController.currentSN.value;

    final sessionId = await SessionManager.getSessionId(currentSN);
    final hasSession = sessionId != null && sessionId.isNotEmpty;

    if (!isConnected) {
      loadingText.value = 'الشبكة غير متوفرة';
      loadingProgress.value = 1.0;
      await Future.delayed(const Duration(milliseconds: 300));
      Get.offAll(() => const ModemConnectionErrorPage());
      return;
    }

    // 3. Check if modem needs factory setup
    if (isSetupRequired) {
      loadingText.value = 'تم اكتشاف مودم جديد! جاري تجهيز معالج الإعداد...';
      loadingProgress.value = 0.65;
      await Future.delayed(const Duration(milliseconds: 300));
      
      final needsSetup = await authController.silentLogin('admin');
      if (needsSetup) {
        loadingProgress.value = 1.0;
        await Future.delayed(const Duration(milliseconds: 100));
        Get.offAll(() => QuickSetupPage());
        return;
      }
    }

    // 4. Check session — التحقق الفعلي من صلاحية الجلسة على المودم
    if (hasSession) {
      loadingText.value = 'التحقق من صلاحية الجلسة...';
      loadingProgress.value = 0.75;

      final isValid = await authController.checkSession();

      if (isValid) {
        // الجلسة صالحة — نستعيد بيانات المستخدم ونبدأ Heartbeat
        authController.currentUser = AuthEntity(
          isAuthenticated: true,
          sessionId: sessionId,
        );
        authController.startHeartbeat();

        loadingText.value = 'جاهز للبدء!';
        loadingProgress.value = 1.0;
        await Future.delayed(const Duration(milliseconds: 400));
        Get.offAll(() => MainLayoutPage());
        return;
      } else {
        // الجلسة منتهية على المودم — محاولة تجديد الجلسة بالمصادقة/كلمة المرور
        loadingText.value = 'تجديد الجلسة...';
        loadingProgress.value = 0.85;

        final renewed = await authController.renewSessionWithBiometricsOrPassword();
        if (renewed) {
          authController.startHeartbeat();

          loadingText.value = 'جاهز للبدء!';
          loadingProgress.value = 1.0;
          await Future.delayed(const Duration(milliseconds: 100));
          Get.offAll(() => MainLayoutPage());
          return;
        }
        // إذا فشل التجديد، نتابع لصفحة الدخول
        debugPrint('⚠️ Session renewal failed in Splash — falling through to login');
      }
    }

    // 5. If no session, check if biometric is enabled for auto-login
    loadingText.value = 'تجهيز واجهة الدخول...';
    loadingProgress.value = 0.90;

    if (authController.isBiometricEnabled.value && authController.isBiometricAvailable.value) {
      loadingText.value = 'مصادقة البصمة...';
      loadingProgress.value = 1.0;
      await authController.loginWithBiometric();
      
      if (authController.currentUser == null) {
        Get.offAll(() => LoginPage());
      }
    } else {
      loadingProgress.value = 1.0;
      Get.offAll(() => LoginPage());
    }
  }
}

