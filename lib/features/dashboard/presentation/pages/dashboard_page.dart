import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import 'package:linkary/core/widgets/glass_card.dart';
import 'package:iconsax/iconsax.dart';
import 'package:linkary/features/mifi_app_monitor/presentation/pages/app_monitor_screen.dart';
import 'package:linkary/features/mifi_app_monitor/presentation/pages/firewall_management_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/services/tutorial_service.dart';
import '../../../banners/presentation/widgets/banners_carousel_widget.dart';
import '../../../banners/presentation/controllers/banners_controller.dart';
import '../../../connected_devices/presentation/pages/connected_devices_page.dart';
import '../../../data_usage/presentation/pages/data_usage_page.dart';
import '../../../device_management/presentation/pages/device_management_page.dart';
import '../../../mac_filter/presentation/pages/mac_filter_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../../notifications/presentation/controllers/notifications_controller.dart';
import '../../../settings/presentation/controllers/wifi_settings_controller.dart';
import '../../../settings/presentation/pages/wifi_settings_page.dart';
import '../../../modem_finder/presentation/pages/modem_finder_page.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/signal_bars_widget.dart';

class DashboardPage extends StatelessWidget {
  DashboardPage({super.key});

  final DashboardController controller = Get.find<DashboardController>();
  final WifiSettingsController wifiSettingsController = Get.find<WifiSettingsController>();
  final TutorialService tutorialService = Get.put(TutorialService(), permanent: true);

  Color bgColor(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  Color textColor(BuildContext context) => Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white;
  Color subTextColor(BuildContext context) => Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white54;

  List<Color> get headerGradient => Get.isDarkMode
      ? [const Color(0xFF1E3C72), const Color(0xFF2A6E98)]
      : [const Color(0xFF4A90E2), const Color(0xFF50E3C2)];

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      tutorialService.showDashboardTutorial(context);
    });

    // 🚀 تم إزالة Obx الخارجي من هنا، لأن GetX يعيد بناء الواجهة تلقائياً عند تغيير الثيم
    return Scaffold(
      backgroundColor: bgColor(context),
      body: RefreshIndicator(
        onRefresh: () async {
          await controller.fetchData();
          if (Get.isRegistered<BannersController>()) {
            await Get.find<BannersController>().fetchBanners();
          }
        },
        color: const Color(0xFF4A90E2),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 70),
          physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🌌 القسم العلوي الملون (الخلفية المتدرجة + المؤشر الدائري)
              _buildHeaderSection(context),

              // 📊 البطاقات المتداخلة (سرعة التنزيل والرفع)
              Transform.translate(
                offset: const Offset(0, -40), // سحب البطاقات للأعلى لتتداخل مع الخلفية
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    key: tutorialService.speedsCardsKey,
                    child: _buildSpeedsCardsRow(context),
                  ),
                ),
              ),

              // عرض العروض والاعلانات
              const BannersCarouselWidget(),
              const SizedBox(height: 10),
            
              // 🛠️ أدوات التحكم
              Transform.translate(
                offset: const Offset(0, -20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('الوصول السريع', style: TextStyle(color: textColor(context), fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      key: tutorialService.quickActionsKey,
                      child: _buildQuickActionsRow(context),
                    ),
                    const SizedBox(height: 30),

                    // 🌐 تفاصيل الشبكة
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('تفاصيل الاستهلاك والمدة', style: TextStyle(color: textColor(context), fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        key: tutorialService.networkGridKey,
                        child: _buildNetworkGrid(context),
                      ),
                    ),
                  ],
                ),
              ),
                    const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 🧩 دوال بناء الواجهة (Widgets)
  // ==========================================

  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 40, bottom: 60, left: 10, right: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: headerGradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40)),
      ),
      child: Column(
        children: [
          // 1. شريط العنوان والتبديل
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: tutorialService.themeToggleKey,
                    icon: Icon(Get.isDarkMode ? Icons.light_mode : Icons.dark_mode, color: Colors.white, shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 3))]),
                    onPressed: () => Get.changeThemeMode(Get.isDarkMode ? ThemeMode.light : ThemeMode.dark),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(Iconsax.notification, color: Colors.white, shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 3))]),
                        onPressed: () => Get.to(() => NotificationsPage()),
                      ),
                      if (Get.isRegistered<NotificationsController>())
                        Obx(() {
                          final count = Get.find<NotificationsController>().unreadCount.value;
                          if (count == 0) return const SizedBox.shrink();
                          return Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: Text(
                                count > 9 ? '+9' : count.toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                  IconButton(
                    key: tutorialService.helpButtonKey,
                    icon: Icon(Icons.help_outline, color: Colors.white, shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 3))]),
                    onPressed: () => tutorialService.showDashboardTutorial(context, force: true),
                  ),
                ],
              ),

              Column(
                children: [
                  const SizedBox(height: 2),
                  Image.asset(
                    'assets/images/الشعار ابيض.png',
                    height: 25,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              Container(
                key: tutorialService.signalBarsKey,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                child: Obx(() {
                  final data = controller.dashboardData.value;
                  if (data == null) return const SizedBox.shrink();
                  
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Text(data.networkType.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      // const SizedBox(width: 8),
                      SignalBarsWidget(level: data.signalLevel, height: 14, width: 18),
                      const SizedBox(width: 4),
                      Icon(data.isCharging ? Icons.battery_charging_full : Icons.battery_full, color: Colors.greenAccent, size: 14),
                      const SizedBox(width: 2),
                      Text('${data.batteryCapacity}%', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // 2. المؤشر الدائري لاستهلاك البيانات (Hero)
          Obx(() {
            if (controller.isLoading.value) return const SizedBox(height: 180, child: Center(child: CircularProgressIndicator(color: Colors.white)));
            final data = controller.dashboardData.value;
            if (data == null) return const SizedBox.shrink();

            return Container(
              key: tutorialService.dataUsageCircleKey,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 190, height: 190,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 180, height: 180,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: controller.usagePercentage.value > 0 ? controller.usagePercentage.value : 1.0), // إذا كان 0 اجعله دائرة كاملة بشكل جمالي
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return CircularProgressIndicator(
                        value: controller.usagePercentage.value == 0.0 ? null : value, // إذا لم يكن هناك باقة يلف باستمرار
                        strokeWidth: 12,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          controller.usagePercentage.value > 0.9 ? Colors.redAccent : Colors.greenAccent,
                        ),
                      );
                    },
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!controller.isPlanSet.value) ...[
                      const Icon(Iconsax.info_circle, color: Colors.white70, size: 24),
                      const SizedBox(height: 8),
                      const Text('الباقة غير محددة', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () => Get.to(() => DataUsagePage()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          minimumSize: const Size(80, 30),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('ضبط الآن', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ] else ...[
                      Text('الباقة المحددة', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(controller.selectedPlanDisplay.value, style: const TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text('تم استهلاك', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text('${(controller.usagePercentage.value * 100).toInt()}%', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ],
              ),
            );
          }),
          const SizedBox(height: 10),
        Obx(() {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('وضع تقييد البيانات', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text(controller.isPlanSet.value ? 'مفعل' : 'غير مفعل', style: TextStyle(color: !controller.isPlanSet.value ? Colors.red : Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          );
        }),
          const SizedBox(height: 30),


          // 3. حالة البطارية ومدة التشغيل
          Obx(() {
            final data = controller.dashboardData.value;
            if (data == null) return const SizedBox.shrink();
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      key: tutorialService.qrCodeKey,
                      onTap: () => _showQrBottomSheet(context),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 5))]),
                        child: const Icon(Iconsax.scan_barcode, color: Color(0xFF4A90E2), size: 28),
                      ),
                    ),
                    ],
                ),
                Container(
                  key: tutorialService.connectedDevicesKey,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Icon(Icons.devices, color: Color(0xB2538EFA), size: 16),
                      const SizedBox(width: 5),
                      Obx(() => TextButton(
                        onPressed: () => Get.to(() => const DeviceManagementPage()),
                        child: Text('${controller.connectedDevicesCount.value} ${controller.connectedDevicesCount.value == 1 ? "جهاز" : "أجهزة"}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      ))
                    ],
                  ),
                )
              ],
            );
          })
        ],
      ),
    );
  }

  Widget _buildSpeedsCardsRow(BuildContext context) {
    return Obx(() {
      final data = controller.dashboardData.value;
      return Row(
        children: [
          Expanded(child: _buildMiniCard(context, 'سرعة التنزيل', controller.formatSpeed(data?.rxSpeed ?? 0), Icons.arrow_downward_rounded, const Color(0xFF4A90E2), data?.rxSpeed ?? 0, 20 * 1024 * 1024)),
          const SizedBox(width: 15),
          Expanded(child: _buildMiniCard(context, 'سرعة الرفع', controller.formatSpeed(data?.txSpeed ?? 0), Icons.arrow_upward_rounded, const Color(0xFF50E3C2), data?.txSpeed ?? 0, 10 * 1024 * 1024)),
        ],
      );
    });
  }

  Widget _buildMiniCard(BuildContext context, String title, String value, IconData icon, Color iconColor, int speedBytes, int maxSpeedBytes) {
    double percentage = (speedBytes / maxSpeedBytes).clamp(0.01, 1.0); // 0.01 كحد أدنى للشكل الجمالي
    
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const Spacer(),
              const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 15),
          Text(value, style: TextStyle(color: textColor(context), fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          const SizedBox(height: 5),
          Text(title, style: TextStyle(color: subTextColor(context), fontSize: 12)),
          const SizedBox(height: 15),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: percentage),
            duration: const Duration(milliseconds: 800),
            curve: Curves.fastOutSlowIn,
            builder: (context, val, child) {
              return LinearProgressIndicator(
                value: val,
                backgroundColor: iconColor.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                borderRadius: BorderRadius.circular(5),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildActionItem(context, Icons.devices, 'الأجهزة', const Color(0xFF4A90E2), () => Get.to(() => const DeviceManagementPage())),
          _buildActionItem(context, Icons.radar, 'أين المودم؟', const Color(0xFFFF073A), () => Get.to(() => const ModemFinderPage())),
          _buildActionItem(context, Icons.wifi_password, 'الواي فاي', const Color(0xFF9B51E0), () => Get.to(() => WifiSettingsPage())),
          _buildActionItem(context, Icons.data_usage, 'الباقة', Colors.orangeAccent, () => Get.to(() => DataUsagePage())),
          _buildActionItem(context, Icons.security, 'حظر الاستخدام', Colors.redAccent, () => Get.to(() => MacFilterPage())),
          _buildActionItem(context, Icons.app_settings_alt, 'مراقب التطبيقات', Color(
              0xFF8BEDD7), () => Get.to(() => AppMonitorScreen())),
          _buildActionItem(context, Icons.block, 'تقييد التطبيقات', const Color(
              0xFFEF8B8B), () => Get.to(() => FirewallManagementScreen())),
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 15),
        child: SizedBox(
          width: 130,
          child: GlassCard(
            borderRadius: 20,
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 12),
                  ],
                ),
                const SizedBox(height: 15),
                Text('الوصول إلى', style: TextStyle(color: subTextColor(context), fontSize: 10)),
                const SizedBox(height: 5),
                Text(title, style: TextStyle(color: textColor(context), fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNetworkGrid(BuildContext context) {
    return Obx(() {
      final data = controller.dashboardData.value;
      if (data == null) return const SizedBox.shrink();

      return GlassCard(
        padding: const EdgeInsets.all(20),
        borderRadius: 25,
        child: Column(
          children: [
            _buildListTile(context, Icons.data_saver_on, 'استهلاك الجلسة الحالية', '${controller.formatDataUsage(data.currentUsage)} خلال ${controller.formatDuration(data.currentDuration)}'),
            const Divider(height: 30, color: Colors.grey, thickness: 0.2),
            _buildListTile(context, Icons.data_saver_off_rounded, 'الاستهلاك المتراكم', '${controller.formatDataUsage(data.totalUsage ?? 0)} خلال ${controller.formatTotalDuration(data.totalDuration)}'),
            ],
        ),
      );
    });
  }

  Widget _buildListTile(BuildContext context, IconData icon, String title, String value, {Widget? trailingWidget}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF4A90E2).withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: const Color(0xFF4A90E2), size: 20),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: subTextColor(context), fontSize: 14)),
              Text(value, style: TextStyle(color: textColor(context), fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (trailingWidget != null) trailingWidget,
      ],
    );
  }

  // ==========================================
  // 🚀 النافذة السفلية الأنيقة لعرض الـ QR Code
  // ==========================================
  void _showQrBottomSheet(BuildContext context) {
    final ssid = controller.wifiSsid.value;
    final password = wifiSettingsController.passwordController.text;
    final String qrData = 'WIFI:T:WPA;S:$ssid;P:$password;;';

    Get.bottomSheet(
      Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(45),
        decoration: BoxDecoration(
          color: Get.isDarkMode ? const Color(0xFF070B19) : const Color(
              0xFFFFFFFF),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          boxShadow: [BoxShadow(color: const Color(0xFF8E2DE2).withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 25),
            Text('مشاركة الشبكة', style: TextStyle(color: Get.isDarkMode ? Colors.white : const Color(0xFF1E293B), fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text('دع الضيوف يمسحون الرمز للاتصال فوراً', style: TextStyle(color: Get.isDarkMode ? Colors.white70 : const Color(0xFF8E9AAA), fontSize: 14)),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 5))]),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0A0E21)),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.circle, color: Color(0xFF000000)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

class _SignalState {
  final String label;
  final Color color;
  final String? message;
  _SignalState(this.label, this.color, [this.message]);
}
