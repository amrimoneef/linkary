import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:linkary/core/widgets/custom_snackbar.dart';
import '../../domain/entities/data_usage_entity.dart';
import '../../domain/usecases/data_usage_usecases.dart'; // افترض أنك أنشأت ملف الـ UseCases
import '../../../../core/utils/session_helper.dart';
class DataUsageController extends GetxController {
  final GetDataUsageUseCase getUseCase;
  final SaveDataUsageUseCase saveUseCase;
  final CalibrateDataUsageUseCase calibrateUseCase;

  DataUsageController({required this.getUseCase, required this.saveUseCase, required this.calibrateUseCase,});

  var isLoading = true.obs;
  var isSaving = false.obs;
  var errorMessage = ''.obs;

  var selectedPackageType = 'not_set'.obs; // 'not_set' = غير محدود, 'unlimited' = محدد (بناءً على راوتر ASR)
  var selectedGB = 2.obs; // القيمة الافتراضية للجيجا
  var usedDataFormatted = '0.00'.obs;

  // ثوابت التحويل
  final int bytesInGB = 1073741824;
  final int bytesInMB = 1048576;

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    isLoading.value = true;
    try {
      final result = await getUseCase.execute();

      selectedPackageType.value = result.packageType;
      // تحويل البايتات إلى جيجا لاختيارها في القائمة المنسدلة
      if (result.packageDataBytes > 0) {
        selectedGB.value = (result.packageDataBytes / bytesInGB).round();
      }

      // تنسيق البيانات المستخدمة (مثلاً 2.45 جيجابايت)
      double usedGB = result.usedDataBytes / bytesInGB;
      usedDataFormatted.value = usedGB.toStringAsFixed(2);

    } catch (e) {
      if (SessionHelper.handleSessionError(e)) return;
      errorMessage.value = e.toString().replaceAll('Exception:', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveSettings() async {
    isSaving.value = true;
    try {
      String typeToSend = selectedPackageType.value == 'unlimited' ? 'unlimited' : 'not_set';
      int bytesToSend = selectedPackageType.value == 'unlimited' ? (selectedGB.value * bytesInGB) : 0;

      final success = await saveUseCase.execute(typeToSend, bytesToSend);
      
      if (success) {
        // 🔄 تصفير البيانات تلقائياً
        try {
          await calibrateUseCase.execute(0);
        } catch (e) {
          if (kDebugMode) print("⚠️ فشل تصفير العداد: $e");
        }
        
        // 🚀 الخروج من الشاشة أولاً لتجنب تداخل الـ Snackbar مع مسار الصفحة
        Get.back(); 

        // إظهار النجاح على الشاشة السابقة (الرئيسية)
        CustomSnackbar.showSuccess('تم بنجاح', 'تم تطبيق إعدادات الباقة وتصفير العداد.');
      } else {
        CustomSnackbar.showError('خطأ', 'المودم رفض حفظ الإعدادات.');
      }
    } catch (e) {
      if (SessionHelper.handleSessionError(e)) return;
      CustomSnackbar.showError('فشل الاتصال', 'تعذر حفظ الإعدادات، تأكد من اتصالك بالمودم.');
      if (kDebugMode) print("❌ Error in saveSettings: $e");
    } finally {
      isSaving.value = false;
    }
  }

  // 🚀 دالة المعايرة الجديدة
  Future<void> calibrateData(double amount, String unit) async {
    isSaving.value = true;
    try {
      int bytesToSend = 0;
      if (unit == 'جيجا بايت') {
        bytesToSend = (amount * bytesInGB).round();
      } else if (unit == 'ميجا بايت') {
        bytesToSend = (amount * bytesInMB).round();
      }

      final success = await calibrateUseCase.execute(bytesToSend);
      if (success) {
        Get.back(); // إغلاق النافذة المنبثقة
        CustomSnackbar.showSuccess('تمت المعايرة', 'تم تصفير/تعديل العداد بنجاح!');
        fetchData();
      } else {
        CustomSnackbar.showError('خطأ', 'فشلت عملية المعايرة');
      }
    } catch (e) {
      if (SessionHelper.handleSessionError(e)) return;
      CustomSnackbar.showError('خطأ', 'فشلت عملية المعايرة');
    } finally {
      isSaving.value = false;
    }
  }
}