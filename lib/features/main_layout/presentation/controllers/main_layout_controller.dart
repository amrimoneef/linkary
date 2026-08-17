import 'package:get/get.dart';
import '../../../../core/services/tutorial_service.dart';
import '../../../../core/utils/whats_new_helper.dart';
import '../../../../core/widgets/permissions_dialog.dart';

class MainLayoutController extends GetxController {
  // 🚀 المتغير التفاعلي الذي يراقب الشاشة الحالية (يبدأ بـ 1 = الرئيسية)
  var currentIndex = 1.obs;

  @override
  void onReady() async {
    super.onReady();
    
    // 1️⃣ أولاً: عرض نافذة "ما الجديد" إذا كان هناك تحديث جديد والانتظار حتى يغلقها المستخدم
    await WhatsNewHelper.checkAndShowWhatsNew();
    
    // 2️⃣ ثانياً: عرض نافذة طلب صلاحيات الإشعارات بعد إغلاق التحديثات
    await PermissionsDialog.showIfNeeded();

    // 3️⃣ ثالثاً: بدء الدرس التفاعلي للشاشة الرئيسية بعد خلو الشاشة من أي حوارات منبثقة
    await Future.delayed(const Duration(milliseconds: 600));
    if (Get.isRegistered<TutorialService>() && Get.context != null) {
      Get.find<TutorialService>().showDashboardTutorial(Get.context!);
    }
  }

  void changePage(int index) {
    currentIndex.value = index;
  }
}