import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/services/tutorial_service.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../modem_auth/presentation/controllers/auth_controller.dart';

// استيراد كافة شاشات الإعدادات الفرعية
import '../../../parental_control/presentation/controllers/parental_control_controller.dart';
import '../../../settings/presentation/pages/wifi_settings_page.dart';
import '../../../speed_limit/presentation/pages/speed_limit_page.dart';
import '../../../data_usage/presentation/pages/data_usage_page.dart';
import '../../../mac_filter/presentation/pages/mac_filter_page.dart';
import '../../../device_data_limit/presentation/pages/device_data_limit_page.dart';
import '../../../device_data_limit/presentation/controllers/device_data_limit_controller.dart';
import '../../../parental_control/presentation/pages/parental_control_page.dart';
import '../../../about/presentation/pages/about_page.dart';
import '../../../settings/presentation/pages/admin_settings_page.dart';
import '../../../settings/presentation/pages/lcd_settings_page.dart';
import '../../../connected_devices/presentation/pages/connected_devices_page.dart';
import '../../../modem_finder/presentation/pages/modem_finder_settings_page.dart';
import '../../../../core/widgets/expandable_power_menu.dart';
import 'battery_settings_page.dart';

class AllSettingsPage extends StatelessWidget {
  const AllSettingsPage({super.key});

  // 🎨 ألوان الهوية الديناميكية
  Color bgColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0A0E21) : const Color(0xFFF4F7FC);
  Color cardColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF16213E) : Colors.white;
  Color textColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B);
  Color subTextColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white70 : const Color(0xFF8E9AAA);

  // التدرج اللوني للرأس (أزرق سماوي يشبه الصورة المرفقة)
  List<Color> headerGradient(BuildContext context) => Theme.of(context).brightness == Brightness.dark
      ? [const Color(0xFF1E3C72), const Color(0xFF2A5298)]
      : [const Color(0xFF4A90E2), const Color(0xFF50E3C2)];

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<TutorialService>().showAllSettingsTutorial(context);
    });

    return Scaffold(
      backgroundColor: bgColor(context),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
        child: Column(
          children: [
            // 🌌 1. القسم العلوي المنحني (Header)
            _buildHeader(context),

            // 📊 2. شبكة البطاقات المتداخلة (Grid)
            Transform.translate(
              offset: const Offset(0, -40), // سحب البطاقات للأعلى لتتداخل مع الخلفية الزرقاء
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSettingsGrid(context),
              ),
            ),

            const SizedBox(height: 80), // مساحة أمان للبار السفلي
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 🧩 دوال بناء الواجهة
  // ==========================================

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, left: 25, right: 25, bottom: 70),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: headerGradient(context),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. الترحيب والشعار
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('إدارة المودم', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                  const Text('الإعدادات', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: Get.find<TutorialService>().allSettingsHelpKey,
                    icon: Icon(Icons.help_outline, color: Colors.white, shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 3))]),
                    onPressed: () => Get.find<TutorialService>().showAllSettingsTutorial(context, force: true),
                  ),
                  Image.asset(
                    'assets/images/الشعار ابيض.png',
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),

          // 2. السويتش المركزي
          Center(
            child: Column(
              children: [
                Text('حالة البث', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 14, letterSpacing: 3, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Container(
                  key: Get.find<TutorialService>().powerCoreSwitchKey,
                  child: PowerCoreSwitch(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // 3. زري إعادة التشغيل وتسجيل الخروج في الزوايا السفلى
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              GestureDetector(
                key: Get.find<TutorialService>().logoutButtonKey,
                onTap: () => Get.find<AuthController>().logout(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.logout, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('الخروج من التطبيق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                ),
              ),

              // درج طاقة المودم المنبثق التفاعلي (Expandable Power Drawer)
              Container(
                key: Get.find<TutorialService>().rebootButtonKey,
                child: const ExpandablePowerMenu(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGrid(BuildContext context) {
    return Container(
        key: Get.find<TutorialService>().settingsGridKey,
        child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 0.9, // زيادة المساحة الرأسية قليلاً لتجنب Overflow
      children: [
        // 1. الواي فاي
        _buildSettingCard(

          title: 'الواي فاي',
          subtitle: 'إعدادات الشبكة اللاسلكية',
          icon: Iconsax.wifi,
          gradientColors: const [Color(0xFF93AEFF), Color(0xFF4A90E2)],
          onTap: () => Get.to(() => WifiSettingsPage()),
        ),

        // 2. حد السرعة
        _buildSettingCard(

          title: 'حد السرعة',
          subtitle: 'تقييد سرعة الأجهزة',
          icon: Iconsax.chart_2,
          gradientColors: const [Color(0xFFF6E2A0), Color(0xFFD5B040)],
          onTap: () => Get.to(() => SpeedLimitPage()),
        ),

        // 3. تقييد الباقة
        _buildSettingCard(

          title: 'استهلاك الباقة',
          subtitle: 'تحديد حصة البيانات',
          icon: Iconsax.graph,
          gradientColors: const [Color(0xFF8BEDD7), Color(0xFF3EC3A5)],
          onTap: () => Get.to(() => DataUsagePage()),
        ),

        // 4. مرشح الماك
        _buildSettingCard(

          title: 'حظر الأجهزة',
          subtitle: 'إدارة الأجهزة المتصلة',
          icon: Iconsax.security_user,
          gradientColors: const [Color(0xFFEF8B8B), Color(0xFFCF4545)],
          onTap: () => Get.to(() => MacFilterPage()),
        ),

        // 4.2 إدارة باقة الأجهزة
        Obx(() {
          final isSupported = Get.find<DeviceDataLimitController>().isFeatureSupported.value;
          return _buildSettingCard(
            title: 'إدارة باقة الأجهزة',
            subtitle: isSupported ? 'تحديد باقة لكل جهاز متصل' : 'قريباً في التحديث القادم للمودم',
            icon: Icons.data_usage,
            gradientColors: isSupported ? const [Color(0xFFFFA07A), Color(0xFFFF4500)] : const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            onTap: () => Get.to(() => const DeviceDataLimitPage()),
          );
        }),

        // 4.5 الأجهزة المتصلة
        _buildSettingCard(
          title: 'الأجهزة المتصلة',
          subtitle: 'إدارة الأجهزة وتسميتها لسهولة التعرف عليها',
          icon: Iconsax.mobile,
          gradientColors: const [Color(0xFF8BCAEF), Color(0xFF45A2CF)],
          onTap: () => Get.to(() => ConnectedDevicesPage()),
        ),

        // 5. التحكم الأبوي
        Obx(() {
          final isSupported = Get.find<ParentalControlController>().isFeatureSupported.value;
          return _buildSettingCard(
            title: 'التحكم الأبوي',
            subtitle: isSupported ? 'إدارة أوقات استخدام الإنترنت' : 'قريباً في التحديث القادم للمودم 🚀',
            icon: Iconsax.lock,
            gradientColors: isSupported ? const [Color(0xFFC28BF6), Color(0xFF9B51E0)] : const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
            onTap: () => Get.to(() => ParentalControlPage()),
          );
        }),

        // 7. إعدادات المسؤول
        _buildSettingCard(
          title: 'إعدادات المسؤول',
          subtitle: 'تغيير كلمة مرور Admin والمزيد',
          icon: Iconsax.user_octagon,
          gradientColors: const [Color(0xFFA889FD), Color(0xFF7C4DFF)],
          onTap: () => Get.to(() => const AdminSettingsPage()),
        ),

        // 8. إدارة التنبيهات
        _buildSettingCard(
          title: 'إدارة التنبيهات',
          subtitle: 'تنبيهات البطارية ورصيد البيانات',
          icon: Iconsax.notification,
          gradientColors: const [Color(0xFF81C784), Color(0xFF388E3C)],
          onTap: () => Get.to(() => const BatterySettingsPage()),
        ),

        // 8. إعدادات البحث عن المودم
        _buildSettingCard(
          title: 'البحث عن المودم',
          subtitle: 'معايرة الإشارة وإنذار النسيان',
          icon: Iconsax.radar,
          gradientColors: const [Color(0xFFFF8B8B), Color(0xFFFF073A)],
          onTap: () => Get.to(() => const ModemFinderSettingsPage()),
        ),

        // 7.5 إعدادات الشاشة (LCD)
        _buildSettingCard(
          title: 'إعدادات الشاشة',
          subtitle: 'كلمة مرور LCD ووضع السكون',
          icon: Iconsax.mobile,
          gradientColors: const [Color(0xFFFFD194), Color(0xFFD1913C)],
          onTap: () => Get.to(() => const LcdSettingsPage()),
        ),

        // 8. حول التطبيق
        _buildSettingCard(

          title: 'حول التطبيق',
          subtitle: 'معلومات التطبيق',
          icon: Iconsax.info_circle,
          gradientColors: const [Color(0xFF40EFDF), Color(0xFF009688)],
          onTap: () => Get.to(() => const AboutPage()),
        ),
      ],
    )
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors, // 👈 1. غيرنا هذا إلى قائمة ألوان
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors, // 👈 2. وضعنا التدرج اللوني هنا مباشرة
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              // 👈 3. نأخذ اللون الأخير في التدرج لنصنع منه الظل
              color: gradientColors.last.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Stack(
          children: [
            // الدوائر الخلفية الشفافة
            Positioned(right: -30, bottom: -30, child: CircleAvatar(radius: 80, backgroundColor: Colors.white.withValues(alpha: 0.1))),
            Positioned(right: -10, bottom: -10, child: CircleAvatar(radius: 40, backgroundColor: Colors.white.withValues(alpha: 0.1))),

            // الأيقونة الكبيرة
            Positioned(
              right: 15,
              bottom: 15,
              child: Transform.rotate(
                angle: -0.1,
                child: Icon(icon, size: 55, color: Colors.white.withValues(alpha: 0.9)),
              ),
            ),

            // النصوص العلوية
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ☢️ مفاعل الاتصال (Power Core Switch)
// ==========================================
class PowerCoreSwitch extends StatelessWidget {
  final DashboardController controller = Get.find<DashboardController>();

  PowerCoreSwitch({super.key});

  void _confirmToggle(bool isConnected) {
    Get.defaultDialog(
      title: isConnected ? 'إيقاف بث الإنترنت' : 'تشغيل بث الإنترنت',
      titleStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: isConnected ? Colors.redAccent : Colors.greenAccent.shade700,
          fontSize: 18),
      middleText: isConnected
          ? 'سيؤدي هذا الإجراء إلى قطع اتصال البيانات الخلوية عن المودم .\n\nالواي فاي سيبقى يعمل، ولكن لن تتمكن الأجهزة المتصلة من تصفح الإنترنت حتى تقوم بإعادة تشغيله.'
          : 'سيؤدي هذا الإجراء إلى تفعيل اتصال البيانات الخلوية للمودم .\n\nتنبيه: سيبدأ استهلاك باقة الإنترنت للأجهزة المتصلة.',
      middleTextStyle: const TextStyle(fontSize: 14, height: 1.6),
      textConfirm: isConnected ? 'نعم، أوقف البث' : 'نعم، شغّل البث',
      textCancel: 'تراجع',
      confirmTextColor: Colors.white,
      buttonColor: isConnected ? Colors.redAccent : Colors.greenAccent.shade700,
      cancelTextColor: Get.isDarkMode ? Colors.white70 : Colors.black87,
      radius: 20,
      titlePadding: const EdgeInsets.only(top: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      onConfirm: () {
        Get.back(); // إغلاق النافذة المنبثقة
        controller.switchDataConnection();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isConnected = controller.isDataConnected.value;
      final isLoading = controller.isTogglingData.value;

      // ألوان النيون بناءً على الحالة (أخضر للمتصل، أحمر للمنقطع)
      final glowColor = isConnected ? Colors.greenAccent : Colors.redAccent;
      final iconColor = isConnected ? Colors.white : Colors.white70;

      return GestureDetector(
        onTap: () {
          if (!isLoading) {
            _confirmToggle(isConnected);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              // الوهج الخارجي
              BoxShadow(
                color: glowColor.withValues(alpha: isConnected ? 0.5 : 0.2),
                blurRadius: isConnected ? 50 : 20,
                spreadRadius: isConnected ? 15 : 5,
              )
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: glowColor.withValues(alpha: 0.8),
                    width: isConnected ? 3 : 1,
                  ),
                ),
                child: Center(
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isConnected ? Iconsax.wifi : Iconsax.wifi_square5,
                        color: iconColor,
                        size: 45,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isConnected ? 'متصل' : 'مقطوع',
                        style: TextStyle(
                          color: iconColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isConnected ? 'انقر للقطع' : 'انقر للاتصال',
                          style: TextStyle(
                            color: iconColor,
                            fontSize: 9,
                            fontWeight: FontWeight.normal,
                            letterSpacing: 1.5,
                          ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}