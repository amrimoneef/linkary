import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/network/session_manager.dart';
import '../../../../core/widgets/permissions_dialog.dart';
import '../../../modem_auth/presentation/pages/login_page.dart';

class OnboardingController extends GetxController with GetTickerProviderStateMixin {
  final pageController = PageController();
  var currentPage = 0.obs;
  var pageScrollPosition = 0.0.obs; // To track exact scroll for Parallax
  var touchPosition = Offset.zero.obs; // لتتبع لمسة المستخدم وتفاعل الخلفية

  // للتحكم في الحركات المستمرة (Breathing/Floating)
  late AnimationController breathingController;
  late AnimationController blobController;

  final List<OnboardingModel> slides = [
    OnboardingModel(
      title: 'تحكم ذكي ومتكامل',
      description: 'أهلاً بك في Sam4g! استمتع بإدارة مودمك بالكامل من جيبك بكل سهولة وأمان.',
      icon: Icons.auto_awesome,
      color: const Color(0xFF4A90E2),
    ),
    OnboardingModel(
      title: 'أمان وحماية قصوى',
      description: 'فعل الدخول بالبصمة، تحكم في الأجهزة المتصلة، وأمنع المتطفلين من الإتصال بالشبكة بضغطة زر.',
      icon: Icons.shield,
      color: const Color(0xFF50E3C2),
    ),
    OnboardingModel(
      title: 'إدارة السرعة والبيانات',
      description: 'حدد سرعات المتصلين، راقب استهلاك البيانات، وابقَ على اطلاع دائم بحالة شبكتك.',
      icon: Icons.speed,
      color: const Color(0xFFF5A623),
    ),
    OnboardingModel(
      title: 'رادار توجيه الإشارة',
      description: 'اعثر على أفضل تغطية للبرج بسهولة تامة من خلال رادار توجيه ذكي مدعوم بتنبيهات اهتزازية دقيقة.',
      icon: Iconsax.radar5,
      color: const Color(0xFF9B51E0),
    ),
    OnboardingModel(
      title: 'جدار ناري ومراقبة التطبيقات',
      description: 'راقب استهلاك كل تطبيق على حدة، وامنع التطبيقات غير المرغوب بها من استهلاك بياناتك بنقرة واحدة.',
      icon: Iconsax.security_safe,
      color: const Color(0xFFF6E2A0),
    ),
    OnboardingModel(
      title: 'مساعد صوتي ذكي',
      description: 'تحكم بالمودم بالكامل باستخدام الأوامر الصوتية باللغة العربية، المساعد الذكي في خدمتك دائماً.',
      icon: Iconsax.microphone_2,
      color: const Color(0xFF00B4D8),
    ),
    OnboardingModel(
      title: 'متابعة الرصيد والباقات',
      description: 'استعلم عن رصيدك المتبقي وحالة باقتك مباشرة من التطبيق دون الحاجة لفتح المتصفح.',
      icon: Iconsax.wallet_2,
      color: const Color(0xFF4CAF50),
    ),
    OnboardingModel(
      title: 'إشعارات ذكية وفورية',
      description: 'تلقى تنبيهات فورية عند انخفاض شحن البطارية أو انتهاء الباقة، أو حتى اتصل جهاز جديد بالشبكة، لتبقى دائماً على اطلاع.',
      icon: Iconsax.notification,
      color: const Color(0xFFFF5722),
    ),
    OnboardingModel(
      title: 'اين المودم؟',
      description: 'ميزة ذكية تساعدك على تحديد مكان المودم في حال نسيت أين وضعته، لتوفير الوقت والجهد.',
      icon: Iconsax.mobile,
      color: const Color(0xFF3F51B5),
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    
    // استماع لحركة التمرير من أجل تأثير Parallax
    pageController.addListener(() {
      if (pageController.page != null) {
        pageScrollPosition.value = pageController.page!;
      }
    });

    // إعداد حركة التنفس/الطفو المستمرة للبطاقات
    breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // إعداد حركة الأشكال الخلفية
    blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  void onPageChanged(int index) {
    if (currentPage.value != index) {
      HapticFeedback.lightImpact(); // تأثير حسي عند كل تمريرة
    }
    currentPage.value = index;
  }

  void next() {
    if (currentPage.value < slides.length - 1) {
      HapticFeedback.mediumImpact(); // تأثير أقوى قليلاً عند النقر على الأزرار
      pageController.nextPage(
        duration: const Duration(milliseconds: 700),
        curve: Curves.fastOutSlowIn,
      );
    } else {
      HapticFeedback.heavyImpact();
      completeOnboarding();
    }
  }

  void updateTouchPosition(Offset offset) {
    touchPosition.value = offset;
  }

  Future<void> completeOnboarding() async {
    await SessionManager.setOnboardingVisited();
    await PermissionsDialog.showIfNeeded();
    Get.offAll(() => LoginPage(), transition: Transition.fadeIn, duration: const Duration(milliseconds: 600));
  }

  @override
  void onClose() {
    pageController.dispose();
    breathingController.dispose();
    blobController.dispose();
    super.onClose();
  }
}

class OnboardingModel {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingModel({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
