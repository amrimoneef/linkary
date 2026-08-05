import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/network/session_manager.dart';
import 'package:linkary/features/settings/domain/usecases/get_admin_settings_usecase.dart';
import 'package:linkary/features/settings/domain/usecases/update_admin_settings_usecase.dart';
import 'package:linkary/features/settings/infrastructure/models/admin_settings_model.dart';

import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/utils/session_helper.dart';
import '../../../modem_auth/presentation/controllers/auth_controller.dart';

class AdminSettingsController extends GetxController {
  final GetAdminSettingsUseCase getAdminSettingsUseCase;
  final UpdateAdminSettingsUseCase updateAdminSettingsUseCase;

  AdminSettingsController({
    required this.getAdminSettingsUseCase,
    required this.updateAdminSettingsUseCase,
  });

  final isLoading = false.obs;
  final isAdminInfoLoading = false.obs;
  final adminSettings = Rxn<AdminSettingsModel>();

  // التعديلات المقررة
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final lcdPwController = TextEditingController();
  
  // خاصية تفعيل/تعطيل كلمة مرور LCD
  final isLcdPwEnabled = false.obs;
  
  // خاصية رؤية كلمة المرور
  final isPasswordVisible = false.obs;
  
  // الخيارات الزمنية الجديدة (بالدقائق)
  final sessionTimeoutMin = 5.obs; 
  final isSleepTimeoutEnabled = false.obs; // التحكم في تفعيل وضع النوم
  final sleepTimeoutMin = 10.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAdminSettings();
  }

  Future<void> fetchAdminSettings() async {
    isAdminInfoLoading.value = true;
    try {
      final settings = await getAdminSettingsUseCase.execute();
      adminSettings.value = settings;
      
      // تعبئة الحقول
      usernameController.text = settings.username;
      passwordController.text = settings.password;
      lcdPwController.text = settings.lcdPassword;
      
      // تحديد ما إذا كانت كلمة مرور الشاشة مفعلة
      isLcdPwEnabled.value = settings.lcdPassword.isNotEmpty;
      
      // تحويل وقت الجلسة من ثواني لمحاكاة الخيارات (1, 5, 10, 15)
      final totalSec = int.tryParse(settings.totalTime) ?? 300;
      sessionTimeoutMin.value = (totalSec / 60).round();
      if (![1, 5, 10, 15].contains(sessionTimeoutMin.value)) {
        sessionTimeoutMin.value = 5; // Default if unknown
      }

      // وقت السكون (كما يأتي من المودم)
      final fetchedSleepTime = settings.sleepTime;
      isSleepTimeoutEnabled.value = fetchedSleepTime > 0;
      
      sleepTimeoutMin.value = fetchedSleepTime;
      if (![0, 10, 20, 30, 40].contains(sleepTimeoutMin.value)) {
        sleepTimeoutMin.value = 10; // Default if unknown
      }

    } catch (e) {
      if (SessionHelper.handleSessionError(e)) return;
      CustomSnackbar.showError('خطأ', 'فشل في جلب إعدادات المسؤول: $e');
    } finally {
      isAdminInfoLoading.value = false;
    }
  }

  Future<void> updateSettings() async {
    if (passwordController.text.isEmpty) {
      CustomSnackbar.showError('خطأ', 'يرجى إدخال كلمة المرور');
      return;
    }

    // التحقق مما إذا كانت كلمة المرور قد تغيرت
    final isPasswordChanged = passwordController.text != adminSettings.value?.password;

    // إظهار حوار تأكيد مفصل
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('تأكيد الإعدادات', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          isPasswordChanged 
              ? 'أنت على وشك تغيير كلمة مرور المسؤول إلى "${passwordController.text}".\n\nحفظ الإعدادات سيؤدي إلى تطبيق التغييرات وتسجيل خروجك من التطبيق تلقائياً.\nهل أنت متأكد من المتابعة؟'
              : 'حفظ إعدادات المسؤول سيؤدي إلى تطبيق التغييرات وتسجيل خروجك من التطبيق تلقائياً لمنع أي تعارض.\n\nهل أنت متأكد من المتابعة؟', 
          textAlign: TextAlign.right,
          style: const TextStyle(height: 1.5)
        ),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('تراجع')),
          TextButton(
            onPressed: () => Get.back(result: true), 
            child: const Text('تأكيد وحفظ', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    isLoading.value = true;
    try {
      await updateAdminSettingsUseCase.execute(
        username: usernameController.text, // اسم المستخدم ثابت
        password: passwordController.text,
        totalTime: (sessionTimeoutMin.value * 60).toString(), // تحويل للثواني للمودم
        lcdPw: isLcdPwEnabled.value ? lcdPwController.text : "", // إرسال فارغ إذا تم التعطيل
        sleepTime: sleepTimeoutMin.value,
      );
      
      // مزامنة كلمة المرور مع البصمة إذا كانت مفعله
      if (isPasswordChanged) {
        final biometricEnabled = await SessionManager.isBiometricEnabled();
        if (biometricEnabled) {
          final sn = Get.find<AuthController>().currentSN.value;
          await SessionManager.savePassword(passwordController.text, sn);
        }
      }

      Get.find<AuthController>().forceLogout(
        'إعدادات المسؤول', 
        'تم تأكيد إعدادات المسؤول بنجاح. يرجى تسجيل الدخول العودة للإعدادات.'
      );
    } catch (e) {
      if (SessionHelper.handleSessionError(e)) return;
      CustomSnackbar.showError('خطأ', 'فشل في تحديث الإعدادات: $e');
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    lcdPwController.dispose();
    super.onClose();
  }
}
