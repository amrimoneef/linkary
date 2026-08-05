import 'package:get/get.dart';
import '../../../../core/utils/whats_new_helper.dart';
import '../../../../core/widgets/permissions_dialog.dart';

class MainLayoutController extends GetxController {
  // 🚀 المتغير التفاعلي الذي يراقب الشاشة الحالية (يبدأ بـ 1 = الرئيسية)
  var currentIndex = 1.obs;

  @override
  void onReady() async {
    super.onReady();
    // عرض "ما الجديد" إذا كان هناك تحديث جديد ولم يتم عرضه بعد
    WhatsNewHelper.checkAndShowWhatsNew();
    
    // طلب الصلاحيات إذا لم يتم طلبها من قبل
    await PermissionsDialog.showIfNeeded();
  }

  void changePage(int index) {
    currentIndex.value = index;
  }
}