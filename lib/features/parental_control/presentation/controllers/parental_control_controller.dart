import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:linkary/core/widgets/custom_snackbar.dart';
import '../../../../core/utils/session_helper.dart';
import '../../../../core/services/device_names_service.dart';
import '../../domain/entities/parental_control_entity.dart';
import '../../domain/usecases/parental_control_usecases.dart';

class ParentalControlController extends GetxController {
  final GetParentalControlStatusUseCase getStatusUseCase;
  final SetParentalControlStatusUseCase setStatusUseCase;
  final GetParentalDevicesUseCase getListUseCase;
  final SaveParentalRuleUseCase saveRuleUseCase;
  final DeleteParentalRuleUseCase deleteRuleUseCase;

  ParentalControlController({
    required this.getStatusUseCase,
    required this.setStatusUseCase,
    required this.getListUseCase,
    required this.saveRuleUseCase,
    required this.deleteRuleUseCase,
  });

  var isLoading = true.obs;
  var isEnabled = false.obs;
  var devicesList = <ParentalDevice>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    try {
      isEnabled.value = await getStatusUseCase.execute();
      final results = await getListUseCase.execute();
      
      // جلب الأسماء المخصصة ودمجها
      final customNames = await DeviceNamesService.getAllNames();
      
      devicesList.value = (results as List<ParentalDevice>).map((d) {
        final savedName = customNames[d.mac.toUpperCase()];
        if (savedName != null && savedName.isNotEmpty) {
          return ParentalDevice(
            mac: d.mac,
            name: savedName,
            timeSlots: d.timeSlots,
          );
        }
        return d;
      }).toList();
    } catch (e) {
      if (SessionHelper.handleSessionError(e)) return;
      CustomSnackbar.showError('خطأ', 'فشل جلب البيانات: $e');
      debugPrint('Error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleParentalControl(bool value) async {
    isEnabled.value = value;
    await setStatusUseCase.execute(value);
  }

  int timeOfDayToMinutes(TimeOfDay time) {
    return (time.hour * 60) + time.minute;
  }

  int calculateRepeatMode(List<int> selectedDays) {
    int mask = 0;
    for (int day in selectedDays) {
      mask += (1 << day);
    }
    return mask == 0 ? 127 : mask;
  }

  Future<void> saveRule(String mac, TimeOfDay start, TimeOfDay end, List<int> days) async {
    Get.back();
    isLoading.value = true;
    try {
      int sTime = timeOfDayToMinutes(start);
      int eTime = timeOfDayToMinutes(end);
      int mode = calculateRepeatMode(days);

      final success = await saveRuleUseCase.execute(mac, sTime, eTime, mode, 0);
      if (success) {
        CustomSnackbar.showSuccess('تم', 'تم تقييد الجهاز بنجاح!');
        fetchData();
      }
    } catch (e) {
      if (SessionHelper.handleSessionError(e)) return;
      CustomSnackbar.showError('خطأ', 'فشل حفظ القاعدة: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteDevice(String mac) async {
    isLoading.value = true;
    try {
      final success = await deleteRuleUseCase.execute(mac);
      if (success) {
        CustomSnackbar.showSuccess('تم', 'تم حذف الجهاز بنجاح!');
        fetchData();
      }
    } catch (e) {
      if (SessionHelper.handleSessionError(e)) return;
      CustomSnackbar.showError('خطأ', 'فشل حذف الجهاز: $e');
    } finally {
      isLoading.value = false;
    }
  }
}