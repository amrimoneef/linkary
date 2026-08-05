import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:ui'; // تأثيرات الزجاج

import '../../../../core/services/tutorial_service.dart';
import '../../../dashboard/presentation/pages/dashboard_page.dart';
import '../../../network_info/presentation/pages/network_info_page.dart';
import '../../../settings/presentation/pages/all_settings_page.dart';
import '../../../bill/presentation/pages/bill_page.dart';
import '../../../voice_assistant/presentation/widgets/voice_fab.dart';
import '../controllers/main_layout_controller.dart';

class MainLayoutPage extends StatelessWidget {
  MainLayoutPage({super.key});

  final MainLayoutController controller = Get.put(MainLayoutController());
  final TutorialService tutorialService = Get.put(TutorialService(), permanent: true);

  // 🎨 قائمة الشاشات
  final List<Widget> pages = [
    AllSettingsPage(),
    DashboardPage(),
    NetworkInfoPage(),
    BillPage(),
  ];

  // 🎨 الألوان التكيفية للوضعين (الليلي والنهاري)
  Color get bgColor => Get.isDarkMode ? const Color(0xFF0A0E21) : const Color(0xFFF4F7FC);
  Color get bottomBarColor => Get.isDarkMode ? const Color(0xFF16213E).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9);
  Color get inactiveIconColor => Get.isDarkMode ? Colors.white54 : const Color(0xFF94A3B8);
  Color get activeColor => const Color(0xFF4A90E2); // اللون الأزرق للأيقونة النشطة

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;

          if (controller.currentIndex.value != 1) {
            // التوجيه للرئيسية (Dashboard) بدلاً من الخروج
            controller.changePage(1);
          } else {
            // إظهار حوار التأكيد عند محاولة الخروج من الرئيسية
            final shouldExit = await Get.dialog<bool>(
              AlertDialog(
                title: const Text('تأكيد الخروج', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold)),
                content: const Text('هل أنت متأكد أنك تريد الخروج من التطبيق؟', textAlign: TextAlign.right, style: TextStyle(height: 1.5)),
                actions: [
                  TextButton(onPressed: () => Get.back(result: false), child: const Text('لا')),
                  TextButton(
                    onPressed: () => Get.back(result: true), 
                    child: const Text('نعم', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );

            if (shouldExit == true) {
              SystemNavigator.pop();
            }
          }
        },
        child: Scaffold(
          extendBody: true, // يضمن امتداد الشاشة خلف البار الشفاف
          backgroundColor: bgColor,
        body: Stack(
          children: [
            // 📺 عرض الشاشات
            IndexedStack(
              index: controller.currentIndex.value,
              children: pages,
            ),

            // 🌟 البار السفلي الديناميكي المتحرك
            Positioned(
              bottom: 25, // ارتفاع البار عن أسفل الشاشة
              left: 20,
              right: 20,
              child: Container(
                key: tutorialService.bottomNavKey,
                child: _buildDynamicBottomBar(),
              ),
            ),

            // ✨ الزر العائم للمساعد الصوتي
            Positioned(
              bottom: 110,
              right: 20,
              child: Container(
                key: tutorialService.voiceAssistantKey,
                child: const VoiceFAB(),
              ),
            ),
          ],
        ),
      ));
    });
  }

  // ==========================================
  // 🧩 دوال بناء البار الديناميكي
  // ==========================================

  Widget _buildDynamicBottomBar() {
    return Stack(
      clipBehavior: Clip.none, // مهم جداً: يسمح للأيقونة بالطفو خارج حدود البار بدون أن تنقص
      children: [
        // 1. خلفية البار مع تأثير الزجاج (Glassmorphism)
        ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 75,
              decoration: BoxDecoration(
                color: bottomBarColor,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 5),
                ],
              ),
            ),
          ),
        ),

        // 2. صف الأيقونات المتفاعلة (تطفو فوق الخلفية)
        Positioned.fill(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Iconsax.setting_2, 'الإعدادات'),
              _buildNavItem(1, Iconsax.home_15, 'الرئيسية'),
              _buildNavItem(2, Iconsax.global_search, 'الشبكة'),
              _buildNavItem(3, Iconsax.receipt_item, 'الرصيد'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isActive = controller.currentIndex.value == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => controller.changePage(index),
      child: SizedBox(
        width: 80, // مساحة الضغط الثابتة لمنع اهتزاز الأيقونات المجاورة
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350), // سرعة الحركة
          curve: Curves.easeOutBack, // تأثير ارتداد جميل (Spring)
          // 🚀 السحر هنا: إذا كانت نشطة، ترتفع للأعلى بمقدار 25 بكسل
          transform: Matrix4.translationValues(0, isActive ? -25 : 0, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔵 الدائرة الملونة حول الأيقونة النشطة
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                padding: EdgeInsets.all(isActive ? 16 : 10),
                decoration: BoxDecoration(
                  color: isActive ? activeColor : Colors.transparent,
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [BoxShadow(color: activeColor.withValues(alpha: 0.4), blurRadius: 15, offset: const Offset(0, 5))]
                      : [],
                ),
                child: Icon(
                  icon,
                  color: isActive ? Colors.white : inactiveIconColor,
                  size: isActive ? 28 : 26,
                ),
              ),

              // 📝 النص (يختفي بنعومة عندما ترتفع الأيقونة)
              AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: isActive ? 0.0 : 1.0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: isActive ? 0 : 20, // تقليص المساحة عند الاختفاء لضمان التوسيط
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      label,
                      style: TextStyle(color: inactiveIconColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}