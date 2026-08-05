import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:linkary/core/widgets/custom_snackbar.dart';
import 'package:linkary/features/settings/domain/usecases/get_wifi_settings_usecase.dart';
import 'package:linkary/features/settings/domain/usecases/save_wifi_settings_usecase.dart';
import 'package:linkary/features/settings/domain/usecases/update_admin_settings_usecase.dart';
import 'package:linkary/features/modem_auth/presentation/controllers/auth_controller.dart';
import 'package:linkary/features/modem_auth/presentation/pages/login_page.dart';
import 'package:linkary/features/modem_auth/domain/repositories/auth_repository.dart';
import 'package:linkary/core/network/session_manager.dart';
import 'package:linkary/core/utils/session_helper.dart';

class QuickSetupController extends GetxController {
  final GetWifiSettingsUseCase getWifiSettingsUseCase;
  final SaveWifiSettingsUseCase saveWifiSettingsUseCase;
  final UpdateAdminSettingsUseCase updateAdminSettingsUseCase;

  QuickSetupController({
    required this.getWifiSettingsUseCase,
    required this.saveWifiSettingsUseCase,
    required this.updateAdminSettingsUseCase,
  });

  final formKey = GlobalKey<FormState>();

  final ssidController = TextEditingController();
  final wifiPasswordController = TextEditingController();
  final adminPasswordController = TextEditingController();

  var isSaving = false.obs;
  var isLoading = true.obs;
  var useWifiPasswordForAdmin = false.obs;
  var isWifiPasswordVisible = false.obs;
  var isAdminPasswordVisible = false.obs;

  @override
  void onInit() {
    super.onInit();
    
    wifiPasswordController.addListener(() {
      if (useWifiPasswordForAdmin.value) {
        adminPasswordController.text = wifiPasswordController.text;
      }
    });

    fetchCurrentSettings();
  }

  Future<void> fetchCurrentSettings() async {
    isLoading.value = true;
    try {
      final result = await getWifiSettingsUseCase.execute();
      ssidController.text = result.ssid;
      wifiPasswordController.text = result.password;
    } catch (e) {
      debugPrint('Error fetching wifi settings: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void toggleWifiPasswordVisibility() => isWifiPasswordVisible.value = !isWifiPasswordVisible.value;
  void toggleAdminPasswordVisibility() => isAdminPasswordVisible.value = !isAdminPasswordVisible.value;

  Future<void> saveSettings() async {
    if (!formKey.currentState!.validate()) return;

    isSaving.value = true;
    try {
      final adminPassword = useWifiPasswordForAdmin.value 
          ? wifiPasswordController.text.trim()
          : adminPasswordController.text.trim();
      
      // حفظ القيم محلياً قبل أي dispose
      final ssid = ssidController.text.trim();
      final wifiPassword = wifiPasswordController.text.trim();

      final authController = Get.find<AuthController>();
      debugPrint('🔑 Session ID: ${authController.currentUser?.sessionId}');

      // ===== الخطوة 1: تغيير كلمة مرور المسؤول أولاً =====
      debugPrint('📝 Step 1: Changing admin password...');
      try {
        await updateAdminSettingsUseCase.execute(
          username: 'admin',
          password: adminPassword,
          totalTime: '5',
          lcdPw: '',
          sleepTime: 1,
        );
        debugPrint('✅ Step 1: Admin password changed!');
      } catch (e) {
        debugPrint('❌ Step 1 FAILED: $e');
        CustomSnackbar.showError('خطأ', 'فشل تغيير كلمة مرور المودم: $e');
        return;
      }

      // ===== الخطوة 2: إبلاغ المودم أن الإعداد اكتمل =====
      debugPrint('📝 Step 2: Marking setup as complete...');
      try {
        final authRepo = Get.find<AuthRepository>();
        await authRepo.markSetupComplete();
        debugPrint('✅ Step 2: Setup marked complete!');
      } catch (e) {
        debugPrint('⚠️ Step 2 failed (non-critical): $e');
      }

      // ===== الخطوة 3: تغيير الواي فاي (آخر API — قد يقطع الاتصال) =====
      debugPrint('📝 Step 3: Changing WiFi settings...');
      try {
        await saveWifiSettingsUseCase.execute(
          ssid,
          wifiPassword,
          true,
          true,
          10,
          '0',
          'psk-mixed+tkip+ccmp',
        ).timeout(const Duration(seconds: 3));
        debugPrint('✅ Step 3: WiFi changed!');
      } catch (e) {
        debugPrint('⚠️ Step 3: WiFi timeout/error (expected): $e');
      }

      // ===== الخطوة 4: مسح الجلسة والانتقال لتسجيل الدخول =====
      debugPrint('📝 Step 4: Navigating to LoginPage...');
      await SessionManager.clearSession();
      authController.currentUser = null;
      
      Get.offAll(() => LoginPage());
      CustomSnackbar.showSuccess(
        'اكتمل الإعداد ✅',
        'تم حفظ الإعدادات. اتصل بشبكة "$ssid" ثم سجّل الدخول بكلمة المرور الجديدة.',
      );
      debugPrint('✅ Step 4: Done!');
      
    } catch (e) {
      debugPrint('❌ UNEXPECTED ERROR: $e');
      if (SessionHelper.handleSessionError(e)) return;
      CustomSnackbar.showError('خطأ', 'حدث خطأ غير متوقع: $e');
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    ssidController.dispose();
    wifiPasswordController.dispose();
    adminPasswordController.dispose();
    super.onClose();
  }
}
