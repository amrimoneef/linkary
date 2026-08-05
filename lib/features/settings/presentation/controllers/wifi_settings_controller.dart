import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:linkary/core/widgets/custom_snackbar.dart';
import '../../domain/usecases/get_wifi_settings_usecase.dart';
import '../../domain/usecases/save_wifi_settings_usecase.dart';
import '../../../../core/utils/session_helper.dart';
import '../../../../core/network/session_manager.dart';
import '../../../modem_auth/presentation/controllers/auth_controller.dart';
import '../../domain/repositories/settings_repository.dart';

class WifiSettingsController extends GetxController {
  final GetWifiSettingsUseCase getWifiSettingsUseCase;
  final SaveWifiSettingsUseCase saveWifiSettingsUseCase;

  WifiSettingsController({
    required this.getWifiSettingsUseCase,
    required this.saveWifiSettingsUseCase,
  });

  var isLoading = true.obs;
  var isSaving = false.obs;
  var errorMessage = ''.obs;
  var isPasswordVisible = false.obs;

  final formKey = GlobalKey<FormState>();

  // الحقول النصية
  final ssidController = TextEditingController();
  final passwordController = TextEditingController();

  // الخيارات التفاعلية
  var isWifiEnabled = true.obs;
  var isBroadcastEnabled = true.obs;
  var selectedMaxClients = 2.obs;
  var maxClientsLimit = 10.obs;
  var selectedChannel = '0'.obs;
  var selectedEncryption = 'psk-mixed+tkip+ccmp'.obs;

  String _initialPassword = '';

  @override
  void onInit() {
    super.onInit();
    fetchSettings();
  }

  Future<void> fetchSettings() async {
    isLoading.value = true;
    try {
      final result = await getWifiSettingsUseCase.execute();

      ssidController.text = result.ssid;
      passwordController.text = result.password;
      _initialPassword = result.password; // Store initial password to track changes
      isWifiEnabled.value = result.isWifiEnabled;
      isBroadcastEnabled.value = result.isBroadcastEnabled;
      selectedMaxClients.value = result.maxClients;
      maxClientsLimit.value = result.maxClientsLimit;
      selectedChannel.value = result.channel;
      selectedEncryption.value = result.encryption;

    } catch (e) {
      if (SessionHelper.handleSessionError(e)) return;
      errorMessage.value = e.toString().replaceAll('Exception:', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveSettings() async {
    if (!formKey.currentState!.validate()) return;

    final newWifiPassword = passwordController.text.trim();
    bool shouldSyncAdminPassword = false;

    // Check if the user changed the Wi-Fi password
    if (newWifiPassword != _initialPassword) {
      final syncConfirm = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('توحيد كلمات المرور', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text(
            'لقد قمت بتغيير كلمة مرور شبكة الواي فاي.\n\nهل ترغب أيضاً في جعل كلمة مرور الدخول للتطبيق (Admin) مطابقة لكلمة مرور الواي فاي الجديدة لتسهيل تذكرها ومنع النسيان؟', 
            textAlign: TextAlign.right, 
            style: TextStyle(height: 1.5)
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false), 
              child: const Text('لا، للواي فاي فقط', style: TextStyle(color: Colors.grey))
            ),
            TextButton(
              onPressed: () => Get.back(result: true), 
              child: const Text('نعم، قم بذلك!', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      shouldSyncAdminPassword = syncConfirm == true;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('تأكيد الإعدادات', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('حفظ إعدادات الواي فاي سيؤدي إلى تطبيق التغييرات وتسجيل خروجك من التطبيق تلقائياً لمنع أي تعارض.\n\nهل أنت متأكد من المتابعة؟', textAlign: TextAlign.right, style: TextStyle(height: 1.5)),
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

    isSaving.value = true;
    try {
      // 1. تغيير كلمة مرور المسؤول أولاً (إن تم طلب ذلك)
      // لأن تغيير الواي فاي سيؤدي لانقطاع الاتصال فوراً
      if (shouldSyncAdminPassword) {
        try {
          final settingsRepo = Get.find<SettingsRepository>();
          await settingsRepo.changeAdminPassword(newWifiPassword);
          final sn = Get.find<AuthController>().currentSN.value;
          await SessionManager.savePassword(newWifiPassword, sn); // تحديث الجلسة مع الرقم التسلسلي للبصمة
          debugPrint('✅ Admin password synchronized successfully.');
        } catch (e) {
          debugPrint('Failed to sync admin password: $e');
          // لا نوقف العملية إذا فشل تغيير باسورد الإدمن، نستمر لتغيير الواي فاي
        }
      }

      // 2. تغيير إعدادات الواي فاي
      bool wifiSuccess = false;
      try {
        wifiSuccess = await saveWifiSettingsUseCase.execute(
          ssidController.text.trim(),
          newWifiPassword,
          isWifiEnabled.value,
          isBroadcastEnabled.value,
          selectedMaxClients.value,
          selectedChannel.value,
          selectedEncryption.value,
        );
      } catch (e) {
        // إذا انقطع الاتصال، فهذا متوقع لأن المودم يعيد تشغيل شبكة الواي فاي
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('software caused connection abort') || 
            errorString.contains('connection reset') || 
            errorString.contains('connection refused') ||
            errorString.contains('host is down') ||
            errorString.contains('failed host lookup')) {
          debugPrint('✅ Expected Wi-Fi drop after changing settings: $e');
          wifiSuccess = true; // نعتبره نجاحاً لأن المودم استقبل الأمر وقطع الشبكة
        } else {
          rethrow;
        }
      }

      // 3. الخروج من التطبيق لأن الإعدادات تغيرت
      if (wifiSuccess) {
        Get.find<AuthController>().forceLogout(
          'إعدادات الواي فاي', 
          'تم تأكيد إعدادات الواي فاي وقطع الاتصال. يرجى الاتصال بالشبكة وتسجيل الدخول مجدداً.'
        );
      } else {
        CustomSnackbar.showError('خطأ', 'فشل حفظ الإعدادات');
      }
    } catch (e) {
      if (SessionHelper.handleSessionError(e)) return;
      CustomSnackbar.showError('خطأ', 'حدث خطأ غير متوقع');
    } finally {
      isSaving.value = false;
    }
  }

  void togglePasswordVisibility() => isPasswordVisible.value = !isPasswordVisible.value;

  @override
  void onClose() {
    ssidController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}