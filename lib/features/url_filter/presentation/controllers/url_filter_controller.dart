import 'package:get/get.dart';
import '../../domain/usecases/get_url_filter_usecase.dart';
import '../../domain/usecases/save_url_filter_usecase.dart';

class UrlFilterController extends GetxController {
  final GetUrlFilterUseCase getUseCase;
  final SaveUrlFilterUseCase saveUseCase;

  UrlFilterController({
    required this.getUseCase,
    required this.saveUseCase,
  });

  var isLoading = true.obs;
  var isSaving = false.obs;
  var filterMode = 'disable'.obs;
  var blackItems = <String>[].obs;
  var errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      isLoading(true);
      errorMessage('');
      final data = await getUseCase();
      filterMode.value = data.mode;
      blackItems.assignAll(data.blackItems);
    } catch (e) {
      errorMessage('حدث خطأ أثناء جلب البيانات: $e');
    } finally {
      isLoading(false);
    }
  }

  Future<void> toggleMode(bool isEnabled) async {
    final newMode = isEnabled ? 'blacklist' : 'disable';
    filterMode.value = newMode;
    await saveData();
  }

  Future<void> addUrl(String url) async {
    if (blackItems.length >= 10) {
      Get.snackbar('تنبيه', 'لا يمكن إضافة أكثر من 10 مواقع للقائمة السوداء.');
      return;
    }
    if (url.trim().isEmpty) return;
    
    // Simple URL validation if needed
    blackItems.add(url.trim());
    await saveData();
  }

  Future<void> removeUrl(int index) async {
    if (index >= 0 && index < blackItems.length) {
      blackItems.removeAt(index);
      await saveData();
    }
  }

  Future<void> editUrl(int index, String newUrl) async {
    if (index >= 0 && index < blackItems.length) {
      if (newUrl.trim().isEmpty) return;
      blackItems[index] = newUrl.trim();
      await saveData();
    }
  }

  Future<void> saveData() async {
    try {
      isSaving(true);
      final success = await saveUseCase(
        mode: filterMode.value,
        blackItems: blackItems,
      );
      if (!success) {
        Get.snackbar('خطأ', 'فشل في حفظ الإعدادات.');
        // Revert on fail
        await fetchData();
      }
    } catch (e) {
      Get.snackbar('خطأ', 'حدث خطأ: $e');
      await fetchData();
    } finally {
      isSaving(false);
    }
  }
}
