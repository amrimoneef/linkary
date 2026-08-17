import 'package:get/get.dart';
import '../../domain/entities/device_data_limit.dart';
import '../../domain/usecases/add_device_data_limit_usecase.dart';
import '../../domain/usecases/update_device_data_limit_usecase.dart';
import '../../domain/usecases/delete_device_data_limit_usecase.dart';
import '../../domain/usecases/get_device_data_limit_enable_usecase.dart';
import '../../domain/usecases/get_device_data_limit_list_usecase.dart';
import '../../domain/usecases/set_device_data_limit_enable_usecase.dart';
import '../../../../core/utils/session_helper.dart';
import '../../../../core/widgets/custom_snackbar.dart';

class DeviceDataLimitController extends GetxController {
  final GetDeviceDataLimitEnableUseCase _getEnableUseCase;
  final SetDeviceDataLimitEnableUseCase _setEnableUseCase;
  final GetDeviceDataLimitListUseCase _getListUseCase;
  final AddDeviceDataLimitUseCase _addLimitUseCase;
  final UpdateDeviceDataLimitUseCase _updateLimitUseCase;
  final DeleteDeviceDataLimitUseCase _deleteLimitUseCase;

  DeviceDataLimitController(
    this._getEnableUseCase,
    this._setEnableUseCase,
    this._getListUseCase,
    this._addLimitUseCase,
    this._updateLimitUseCase,
    this._deleteLimitUseCase,
  );

  var isLoading = false.obs;
  var isEnabled = false.obs;
  var isFeatureSupported = true.obs;
  var deviceLimits = <DeviceDataLimit>[].obs;
  
  // For Smart Bottom Sheet
  var selectedSmartMac = ''.obs;
  var selectedSmartName = ''.obs;

  void selectSmartDevice(String mac, String name) {
    selectedSmartMac.value = mac;
    selectedSmartName.value = name;
  }

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData({bool silent = false}) async {
    isLoading.value = true;
    try {
      isEnabled.value = await _getEnableUseCase();
      deviceLimits.value = await _getListUseCase();
      isFeatureSupported.value = true;
    } catch (e) {
      if (SessionHelper.handleSessionError(e)) return;
      final errorStr = e.toString();
      if (errorStr.contains('100002') || 
          errorStr.contains('100003') || 
          errorStr.contains('SESSION_EXPIRED') ||
          errorStr.contains('Connection reset by peer') ||
          errorStr.contains('FormatException') ||
          errorStr.contains('FEATURE_NOT_SUPPORTED') ||
          errorStr.contains('404') ||
          errorStr.contains('500') ||
          errorStr.contains('ClientException')) {
        isFeatureSupported.value = false;
        isEnabled.value = false;
        deviceLimits.clear();
      } else {
        isFeatureSupported.value = true;
        if (!silent) {
          CustomSnackbar.showError('خطأ', 'فشل في جلب البيانات: $errorStr');
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleEnable(bool value) async {
    if (!isFeatureSupported.value) {
      CustomSnackbar.showInfo('ميزة جديدة في طريقها لمودمك!', 'يجري حالياً إطلاق التحديث الجديد للمودم تدريجياً من الشركة المصنعة لتفعيل التحكم في باقات واستهلاك الأجهزة. ستعمل الميزة تلقائياً فور وصول التحديث لجهازك.');
      return;
    }
    final prev = isEnabled.value;
    isEnabled.value = value;
    try {
      final success = await _setEnableUseCase(value);
      if (!success) {
        isEnabled.value = prev;
        CustomSnackbar.showError('خطأ', 'لم يتم تطبيق التغييرات');
      } else {
        CustomSnackbar.showSuccess('نجاح', 'تم تحديث الحالة بنجاح');
      }
    } catch (e) {
      isEnabled.value = prev;
      final errStr = e.toString();
      if (errStr.contains('FormatException') || errStr.contains('FEATURE_NOT_SUPPORTED') || errStr.contains('100002')) {
        isFeatureSupported.value = false;
        CustomSnackbar.showInfo('ميزة جديدة في طريقها لمودمك!', 'يجري حالياً إطلاق التحديث الجديد للمودم تدريجياً من الشركة المصنعة لتفعيل التحكم في باقات واستهلاك الأجهزة. ستعمل الميزة تلقائياً فور وصول التحديث لجهازك.');
      } else {
        CustomSnackbar.showError('خطأ', 'فشل في تحديث الحالة: $errStr');
      }
    }
  }

  Future<bool> addLimitItem(String mac, int quotaBytes, String comment, {bool showSnackbar = true}) async {
    try {
      final success = await _addLimitUseCase(mac, quotaBytes, comment);
      if (success) {
        if (showSnackbar) CustomSnackbar.showSuccess('نجاح', 'تمت إضافة القيد بنجاح');
        await fetchData();
        return true;
      } else {
        if (showSnackbar) CustomSnackbar.showError('خطأ', 'فشل في إضافة القيد');
        return false;
      }
    } catch (e) {
      if (showSnackbar) CustomSnackbar.showError('خطأ', 'حدث خطأ: ${e.toString()}');
      return false;
    }
  }

  Future<bool> updateLimitItem(int index, String mac, int quotaBytes, String comment, {bool showSnackbar = true}) async {
    try {
      final success = await _updateLimitUseCase(index, mac, quotaBytes, comment);
      if (success) {
        if (showSnackbar) CustomSnackbar.showSuccess('نجاح', 'تم تحديث القيد بنجاح');
        await fetchData();
        return true;
      } else {
        if (showSnackbar) CustomSnackbar.showError('خطأ', 'فشل في تحديث القيد');
        return false;
      }
    } catch (e) {
      if (showSnackbar) CustomSnackbar.showError('خطأ', 'حدث خطأ: ${e.toString()}');
      return false;
    }
  }

  Future<bool> deleteLimitItem(String mac, {bool showSnackbar = true}) async {
    try {
      final success = await _deleteLimitUseCase(mac);
      if (success) {
        if (showSnackbar) CustomSnackbar.showSuccess('نجاح', 'تم حذف القيد بنجاح');
        await fetchData();
        return true;
      } else {
        if (showSnackbar) CustomSnackbar.showError('خطأ', 'فشل في حذف القيد');
        return false;
      }
    } catch (e) {
      if (showSnackbar) CustomSnackbar.showError('خطأ', 'حدث خطأ: ${e.toString()}');
      return false;
    }
  }

  String formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    } else if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    } else if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '$bytes Bytes';
    }
  }
}
