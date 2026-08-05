import 'package:get/get.dart';
import '../../domain/entities/device_data_limit.dart';
import '../../domain/usecases/add_device_data_limit_usecase.dart';
import '../../domain/usecases/delete_device_data_limit_usecase.dart';
import '../../domain/usecases/get_device_data_limit_enable_usecase.dart';
import '../../domain/usecases/get_device_data_limit_list_usecase.dart';
import '../../domain/usecases/set_device_data_limit_enable_usecase.dart';
import '../../../../core/widgets/custom_snackbar.dart';

class DeviceDataLimitController extends GetxController {
  final GetDeviceDataLimitEnableUseCase _getEnableUseCase;
  final SetDeviceDataLimitEnableUseCase _setEnableUseCase;
  final GetDeviceDataLimitListUseCase _getListUseCase;
  final AddDeviceDataLimitUseCase _addLimitUseCase;
  final DeleteDeviceDataLimitUseCase _deleteLimitUseCase;

  DeviceDataLimitController(
    this._getEnableUseCase,
    this._setEnableUseCase,
    this._getListUseCase,
    this._addLimitUseCase,
    this._deleteLimitUseCase,
  );

  var isLoading = false.obs;
  var isEnabled = false.obs;
  var deviceLimits = <DeviceDataLimit>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    try {
      isEnabled.value = await _getEnableUseCase();
      deviceLimits.value = await _getListUseCase();
    } catch (e) {
      CustomSnackbar.showError('خطأ', 'فشل في جلب البيانات: ${e.toString()}');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleEnable(bool value) async {
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
      CustomSnackbar.showError('خطأ', 'فشل في تحديث الحالة: ${e.toString()}');
    }
  }

  Future<void> addLimitItem(String mac, int quotaBytes, String comment) async {
    try {
      final success = await _addLimitUseCase(mac, quotaBytes, comment);
      if (success) {
        CustomSnackbar.showSuccess('نجاح', 'تمت إضافة القيد بنجاح');
        await fetchData();
      } else {
        CustomSnackbar.showError('خطأ', 'فشل في إضافة القيد');
      }
    } catch (e) {
      CustomSnackbar.showError('خطأ', 'حدث خطأ: ${e.toString()}');
    }
  }

  Future<void> deleteLimitItem(String mac) async {
    try {
      final success = await _deleteLimitUseCase(mac);
      if (success) {
        CustomSnackbar.showSuccess('نجاح', 'تم حذف القيد بنجاح');
        await fetchData();
      } else {
        CustomSnackbar.showError('خطأ', 'فشل في حذف القيد');
      }
    } catch (e) {
      CustomSnackbar.showError('خطأ', 'حدث خطأ: ${e.toString()}');
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
