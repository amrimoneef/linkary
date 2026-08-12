import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:linkary/core/widgets/custom_snackbar.dart';
import '../../domain/usecases/speed_limit_usecases.dart';
import '../../domain/entities/speed_limit_entity.dart';
import '../../../../core/utils/session_helper.dart';

class SpeedLimitController extends GetxController {
  final GetSpeedLimitUseCase getUseCase;
  final SaveSpeedLimitUseCase saveUseCase;

  SpeedLimitController({required this.getUseCase, required this.saveUseCase});

  var isLoading = true.obs;
  var isSaving = false.obs;
  var errorMessage = ''.obs;

  var isEnabled = false.obs;
  var selectedMode = 1.obs;
  final uploadController = TextEditingController();
  final downloadController = TextEditingController();

  // ⚡ Reactive text values to trigger UI updates
  var rxUploadSpeed = ''.obs;
  var rxDownloadSpeed = ''.obs;

  // 🚀 قائمة الأجهزة المراقبة
  var deviceItems = <SpeedLimitItem>[].obs;
  var selectedSmartIp = ''.obs;
  var selectedSmartName = ''.obs;

  void selectSmartDevice(String ip, String name) {
    selectedSmartIp.value = ip;
    selectedSmartName.value = name;
  }

  /// 🚀 تطبيق سرعة جاهزة
  void applyPreset(int valueKb) {
    uploadController.text = valueKb.toString();
    downloadController.text = valueKb.toString();
  }

  @override
  void onInit() {
    super.onInit();

    // Bind listeners to update reactive values
    uploadController.addListener(() => rxUploadSpeed.value = uploadController.text);
    downloadController.addListener(() => rxDownloadSpeed.value = downloadController.text);

    fetchData();
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    try {
      final result = await getUseCase.execute();
      isEnabled.value = result.isEnabled;
      selectedMode.value = result.mode;
      uploadController.text = result.uploadSpeed.toString();
      downloadController.text = result.downloadSpeed.toString();
      deviceItems.value = result.items; // تحميل الأجهزة
    } catch (e) {
      if (SessionHelper.handleSessionError(e)) return;
      errorMessage.value = e.toString().replaceAll('Exception:', '');
    } finally {
      isLoading.value = false;
    }
  }

  // 🚀 دالة إضافة جهاز جديد للقائمة محلياً
  void addDeviceRule(String ip, int up, int dl, String comment) {
    int newIndex = deviceItems.isEmpty ? 0 : deviceItems.map((e) => e.index).reduce((a, b) => a > b ? a : b) + 1;
    deviceItems.add(SpeedLimitItem(index: newIndex, ip: ip, upSpeed: up, dlSpeed: dl, comment: comment));
  }

  // 🚀 دالة تحديث بيانات جهاز موجود
  void updateDeviceRule(int index, int up, int dl) {
    final idx = deviceItems.indexWhere((element) => element.index == index);
    if (idx != -1) {
      final item = deviceItems[idx];
      deviceItems[idx] = SpeedLimitItem(
        index: item.index,
        ip: item.ip,
        upSpeed: up,
        dlSpeed: dl,
        comment: item.comment,
      );
      deviceItems.refresh();
    }
  }

  // 🚀 دالة حذف جهاز
  void removeDeviceRule(int index) {
    deviceItems.removeWhere((element) => element.index == index);
  }

  Future<void> saveData({bool closeOnSuccess = true}) async {
    isSaving.value = true;
    try {
      final upSpeed = int.tryParse(uploadController.text) ?? 248;
      final dlSpeed = int.tryParse(downloadController.text) ?? 248;

      final success = await saveUseCase.execute(isEnabled.value, selectedMode.value, upSpeed, dlSpeed, deviceItems);
      if (success) {
        if (closeOnSuccess) Get.back();
        CustomSnackbar.showSuccess('تم', 'تم تطبيق الإعدادات بنجاح');
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

  @override
  void onClose() {
    uploadController.dispose();
    downloadController.dispose();
    super.onClose();
  }
}