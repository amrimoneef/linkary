import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:linkary/core/widgets/custom_snackbar.dart';
// استيراد الـ UseCases
import '../../../../core/utils/session_helper.dart';
import '../../domain/usecases/mac_filter_usecases.dart';
import '../../../modem_auth/presentation/controllers/auth_controller.dart';

class MacFilterController extends GetxController {
  final GetMacFilterUseCase getUseCase;
  final SaveMacFilterUseCase saveUseCase;

  MacFilterController({required this.getUseCase, required this.saveUseCase});

  var isLoading = true.obs;
  var isSaving = false.obs;
  var errorMessage = ''.obs;

  var selectedMode = 'disable'.obs; // disable, deny, allow
  var allowList = <String>[].obs;
  var denyList = <String>[].obs;
  var routerMacAddress = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    try {
      final result = await getUseCase.execute();
      selectedMode.value = result.filterMode;
      allowList.value = result.allowList;
      denyList.value = result.denyList;
      routerMacAddress.value = result.routerMac;
    } catch (e) {
      if (SessionHelper.handleSessionError(e)) return;
      errorMessage.value = e.toString().replaceAll('Exception:', '');
    } finally {
      isLoading.value = false;
    }
  }

  void addMac(String mac) {
    if (selectedMode.value == 'deny' && !denyList.contains(mac)) denyList.add(mac);
    if (selectedMode.value == 'allow' && !allowList.contains(mac)) allowList.add(mac);
  }

  void removeMac(String mac) {
    if (selectedMode.value == 'deny') denyList.remove(mac);
    if (selectedMode.value == 'allow') allowList.remove(mac);
  }

  Future<void> saveSettings() async {
    // 🛡️ حماية من الانتحار (Self-Lockout Protection)
    if (selectedMode.value == 'deny' && denyList.contains(routerMacAddress.value)) {
      CustomSnackbar.showError('تحذير أمني ⚠️', 'لا يمكنك وضع عنوان المودم في القائمة السوداء!');
      return;
    }
    if (selectedMode.value == 'allow' && allowList.isEmpty) {
      CustomSnackbar.showWarning('تحذير أمني ⚠️', 'القائمة البيضاء فارغة! تفعيلها سيطرد الجميع.');
      return;
    }

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('تأكيد الإعدادات', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('حفظ الإعدادات الخاصة بقائمة الحظر سيؤدي إلى الخروج من التطبيق تلقائياً وتطبيق القواعد فوراً.\n\nهل أنت متأكد من المتابعة؟', textAlign: TextAlign.right, style: TextStyle(height: 1.5)),
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
      final success = await saveUseCase.execute(selectedMode.value, allowList, denyList);
      if (success) {
        Get.find<AuthController>().forceLogout(
          'تحديثات الحظر',
          'تم تطبيق إعدادات الحظر على الأجهزة. يرجى تسجيل الدخول مجدداً لاستكمال التصفح.'
        );
      } else {
        CustomSnackbar.showError('خطأ', 'فشل حفظ الإعدادات');
      }
    } catch (e) {
      if (SessionHelper.handleSessionError(e)) return;
      CustomSnackbar.showError('خطأ', 'فشل حفظ الإعدادات');
    } finally {
      isSaving.value = false;
    }
  }
}