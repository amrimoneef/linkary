import 'dart:async';
import 'dart:ui'; // 👈 ضروري لتأثير الزجاج (Glassmorphism)
import 'dart:math' as math; // ضروري لعمليات الرادار المتقدمة

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:linkary/core/widgets/custom_snackbar.dart';
import '../../../../core/services/tutorial_service.dart';
import '../../../dashboard/domain/entities/engineering_info_entity.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../mifi_app_monitor/presentation/pages/app_monitor_screen.dart';
import '../../../settings/presentation/controllers/wifi_settings_controller.dart';
import '../../../signal_finder/presentation/pages/signal_finder_page.dart';
import '../../../speed_test/presentation/pages/speed_test_page.dart';
import '../../../modem_finder/presentation/pages/modem_finder_page.dart';

class NetworkInfoPage extends StatelessWidget {
  NetworkInfoPage({super.key}) {
    dashboardController.fetchEngineeringInfo();
  }

  final DashboardController dashboardController =
      Get.find<DashboardController>();
  final WifiSettingsController wifiSettingsController =
      Get.find<WifiSettingsController>();
  
  final ScrollController _scrollController = ScrollController();

  // 🎨 ألوان الفضاء السحيق
  Color get bgColor =>
      Get.isDarkMode ? const Color(0xFF070B19) : const Color(0xFFFFFFFF);
  Color get cardColor =>
      Get.isDarkMode ? const Color(0xFF111827) : Colors.white;
  Color get textColor =>
      Get.isDarkMode ? Colors.white : const Color(0xFF1E293B);
  Color get subTextColor =>
      Get.isDarkMode ? Colors.white70 : const Color(0xFF8E9AAA);

  List<Color> get headerGradient => Get.isDarkMode
      ? [const Color(0xFF1E3C72), const Color(0xFF2A5298)]
      : [const Color(0xFF4A90E2), const Color(0xFF50E3C2)];

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<TutorialService>().showNetworkInfoTutorial(context);
    });

    return Obx(() {
      return Scaffold(
        backgroundColor: bgColor,
        body: RefreshIndicator(
          onRefresh: () async {
            await dashboardController.fetchData();
            await dashboardController.fetchEngineeringInfo();
          },
          color: const Color(0xFF8E2DE2),
          // 🌌 إضافة وهج خلفي للشاشة لتعزيز الطابع الفضائي
          child: Stack(
            children: [
              // وهج أزرق/بنفسجي خفي في الخلفية (يظهر في الوضع الليلي)
              if (Get.isDarkMode) ...[
                Positioned(
                  top: 200,
                  left: -100,
                  child: _buildAmbientGlow(const Color(0xFF8E2DE2)),
                ),
                Positioned(
                  bottom: 100,
                  right: -100,
                  child: _buildAmbientGlow(const Color(0xFF4A90E2)),
                ),
              ],

              SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                child: Column(
                  children: [
                    _buildHeader(context), // 👈 بقي كما هو بناءً على طلبك

                    Transform.translate(
                      offset: const Offset(0, -30), // سحب أقوى للأعلى
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // _buildStaggeredCardsGrid(), // 👈 الشبكة المتناثرة الجديدة
                            const SizedBox(height: 50),
                            // عنوان قسم الرادار بتصميم مستقبلي
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Iconsax.radar5,
                                    color: Colors.blueAccent,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'الرادار وبيانات البرج',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),

                            Container(
                              key: Get.find<TutorialService>().engineeringGridKey,
                              child: _buildEngineeringGrid(context),
                            ),
                            
                            const SizedBox(height: 30),
                            // 🎛️ إعدادات البرج في الأسفل
                            Container(
                              key: Get.find<TutorialService>().bandLockCardKey,
                              child: BandLockCard(controller: dashboardController),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  // 🌟 وهج محيطي للخلفية
  Widget _buildAmbientGlow(Color color) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 100,
            spreadRadius: 50,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🧩 الهيدر (لم يتم تغييره)
  // ==========================================
  Widget _buildHeader(BuildContext context) {
    final data = dashboardController.dashboardData.value;
    final totalUsage = dashboardController.formatDataUsage(
      data?.totalUsage ?? 0,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 50, left: 25, right: 25, bottom: 60),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: headerGradient,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: const Icon(Iconsax.wifi, color: Colors.white),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الشبكة الحالية',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        dashboardController.wifiSsid.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: Get.find<TutorialService>().networkInfoHelpKey,
                    icon: Icon(Icons.help_outline, color: Colors.white, shadows: [Shadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 3))]),
                    onPressed: () => Get.find<TutorialService>().showNetworkInfoTutorial(context, force: true),
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
          const SizedBox(height: 30),
          // 🎯 الأزرار العلوية المتدرجة داخل الترويسة
          Obx(() => _buildHeaderActions(context)),
          
          const SizedBox(height: 30),
          // ⬇️ مؤشر النزول لإعدادات البرج
          GestureDetector(
            onTap: () {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
              );
            },
            child: Column(
              children: [
                Text(
                  'إعدادات البرج',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(Iconsax.arrow_down_1, color: Colors.white.withValues(alpha: 0.5), size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 📶 شريط إشارة احترافي ومتوهج
  Widget _buildProfessionalSignalBars(int level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(5, (index) {
          final isActive = index < level;
          
          // تحديد اللون بناءً على قوة الإشارة
          Color barColor;
          if (level <= 1) {
            barColor = const Color(0xFFFF4B4B); // أحمر للضعيف جداً
          } else if (level <= 3) {
            barColor = const Color(0xFFFFA500); // برتقالي للمتوسط
          } else {
            barColor = const Color(0xFF00FF87); // أخضر نيون للممتاز
          }

          return AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(left: 3), // مسافة بين الأعمدة
            width: 3.5,
            height: 6.0 + (index * 3.5), // أطوال تدريجية: 6, 9.5, 13, 16.5, 20
            decoration: BoxDecoration(
              color: isActive ? barColor : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
              boxShadow: isActive ? [
                BoxShadow(
                  color: barColor.withValues(alpha: 0.6),
                  blurRadius: 4,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                )
              ] : [],
            ),
          );
        }).toList(), // إزالة Reversed لعكس الاتجاه
      ),
    );
  }

  // ==========================================
  // 🚀 الشبكة المتناثرة الجديدة (Staggered Layout)
  // ==========================================
  Widget _buildStaggeredCardsGrid() {
    final data = dashboardController.dashboardData.value;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔲 العمود الأول
        Expanded(
          child: Column(
            children: [
              _buildNeoCard(
                height: 190,
                title: 'مزود الخدمة',
                value: data?.networkName ?? '-',
                subtitle: data?.networkType.toUpperCase() ?? '4G',
                icon: Iconsax.send_2,
                gradient: const [Color(0xFF6B8DF2), Color(0xFF4A90E2)],
              ),
              const SizedBox(height: 15),
              _buildNeoCard(
                height: 170,
                title: 'استهلاك الجلسة',
                value: dashboardController.formatDataUsage(
                  data?.currentUsage ?? 0,
                ),
                subtitle: 'معدل النقل الحالي',
                icon: Iconsax.data,
                gradient: const [Color(0xFF43E97B), Color(0xFF38F9D7)],
              ),
              const SizedBox(height: 15),
              _buildNeoCard(
                height: 190,
                title: 'مدة التشغيل',
                value: dashboardController.formatDuration(
                  data?.currentDuration ?? 0,
                ),
                subtitle: 'الوقت الفعلي',
                icon: Iconsax.timer_1,
                gradient: const [Color(0xFFFF7E79), Color(0xFFEB5757)],
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        // 🔲 العمود الثاني (مسحوب للأسفل ليعطي تأثير التبعثر)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 35),
            child: Column(
              children: [
                _buildNeoCard(
                  height: 170,
                  title: 'رقم خط الـ4G',
                  value: data?.phoneNumber.replaceAll('+967', '') ?? '-',
                  subtitle: data?.imei.isNotEmpty == true
                      ? 'IMEI: ${data!.imei}'
                      : 'إدارة الحساب',
                  icon: Iconsax.simcard_1,
                  gradient: const [Color(0xFFB185DB), Color(0xFF9B51E0)],
                  isCopyable: true,
                ),
                const SizedBox(height: 15),
                _buildNeoCard(
                  height: 190,
                  title: 'قوة الإشارة',
                  value: '${data?.rssi ?? 0} dBm',
                  subtitle: 'مستوى ${data?.signalLevel ?? 0} من 5',
                  icon: Iconsax.bank,
                  gradient: const [Color(0xFFFFB75E), Color(0xFFED8F03)],
                ),
                const SizedBox(height: 15),
                _buildNeoCard(
                  height: 170,
                  title: 'عنوان IP',
                  value: data?.ipv4Ip ?? '-',
                  subtitle: 'الداخلي للشبكة',
                  icon: Iconsax.link,
                  gradient: const [Color(0xFF89F7FE), Color(0xFF66A6FF)],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 🃏 بطاقة النيون الديناميكية (Neo Card)
  Widget _buildNeoCard({
    required double height,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    bool isCopyable = false,
  }) {
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: gradient.last.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 🌊 دوائر خلفية شفافة لتعطي عمق 3D
          Positioned(
            right: -30,
            bottom: -30,
            child: CircleAvatar(
              radius: 80,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            right: -10,
            bottom: -10,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),

          // 🎨 الأيقونة الكبيرة في الأسفل
          Positioned(
            right: 15,
            bottom: 15,
            child: Transform.rotate(
              angle: -0.1,
              child: Icon(
                icon,
                size: 55,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),

          // 📝 النصوص
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                ),
                const Spacer(),
                if (isCopyable)
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: value));
                      CustomSnackbar.showSuccess(
                        'تم النسخ',
                        'تم نسخ $title بنجاح',
                      );
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            value,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                            maxLines: 1,
                          ),
                        ),
                        const Icon(Iconsax.copy, size: 16, color: Colors.white),
                      ],
                    ),
                  )
                else
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                  ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🛰️ شبكة الرادار الفضائية (Glassmorphism Effect)
  // ==========================================
  Widget _buildEngineeringGrid(BuildContext context) {
    if (dashboardController.isEngLoading.value) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
      );
    }

    final engData = dashboardController.engInfoData.value;
    if (engData == null) return const SizedBox.shrink();

    final diagnosis = engData.getSmartDiagnosis();

    return Stack(
      alignment: Alignment.center,
      children: [
        // 📡 الرادار في الخلفية العميقة
        Positioned.fill(child: PulseRadar(color: diagnosis.color)),

        // 📊 الكروت الزجاجية (الرادار سيظهر من خلالها)
        Column(
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _buildGlassCard(
                  'RSRP (الإشارة)',
                  engData.rsrp,
                  engData.rsrpStatus,
                  Iconsax.box_1,
                ),
                _buildGlassCard(
                  'SINR (التشويش)',
                  engData.sinr,
                  engData.sinrStatus,
                  Iconsax.radar,
                ),
                _buildGlassCard(
                  'RSRQ (الجودة)',
                  engData.rsrq,
                  engData.rsrqStatus,
                  Iconsax.activity,
                ),
                _buildDetailedGlassCard(
                  'Band (التردد)',
                  'B${engData.band}',
                  'النطاق المستخدم',
                  Iconsax.wifi,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDetailedGlassCard(
                    'PCI',
                    engData.pci,
                    'رقم الخلية',
                    Iconsax.global,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDetailedGlassCard(
                    'Bandwidth',
                    engData.bandwidth,
                    'عرض النطاق',
                    Iconsax.hierarchy,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // 🎯 الأزرار مثلثية الترتيب داخل الترويسة
  Widget _buildHeaderActions(BuildContext context) {
    final engData = dashboardController.engInfoData.value;
    final diagnosis = engData?.getSmartDiagnosis();

    return SizedBox(
      height: 380, // Increased height to fit 3 rows of buttons (Pentagon)
      child: Stack(
        alignment: Alignment.center,
        children: [
          // خطوط التوصيل الخفية مع تأثير التيار الكهربائي
          const AnimatedPentagonLines(),
          
          // الرأس: زر الرادار — أعلى ومنتصف
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: _buildGlassCircleButton(
                key: Get.find<TutorialService>().radarButtonKey,
                icon: Iconsax.radar_2,
                label: 'تشغيل الرادار',
                accentColor: const Color(0xE2FF4A90),
                onTap: () => Get.to(() => const SignalFinderPage()),
              ),
            ),
          ),
          
          // قاعدة اليمين: قياس السرعة
          Positioned(
            bottom: 0,
            right: 50,
            child: _buildGlassCircleButton(
              key: Get.find<TutorialService>().speedTestButtonKey,
              icon: Icons.speed_rounded,
              label: 'قياس السرعة',
              accentColor: const Color(0xFF818CF8),
              onTap: () => Get.to(() => const SpeedTestPage()),
            ),
          ),
          
          // قاعدة اليسار: تحليل الشبكة
          Positioned(
            bottom: 0,
            left: 50,
            child: _buildGlassCircleButton(
              key: Get.find<TutorialService>().smartAnalysisButtonKey,
              icon: Icons.satellite_alt,
              label: 'تحليل الشبكة',
              accentColor: diagnosis?.color ?? const Color(0xFFFBBF24),
              onTap: () {
                if (engData != null && diagnosis != null) {
                  _showSmartAnalysisReport(context, engData, diagnosis);
                } else {
                  CustomSnackbar.showError('خطأ', 'بيانات البرج غير متوفرة بعد');
                }
              },
            ),
          ),

          // وسط اليسار: مراقب التطبيقات
          Positioned(
            top: 130,
            left: 20,
            child: _buildGlassCircleButton(
              key: Get.find<TutorialService>().appMonitorButtonKey,
              icon: Icons.adb_outlined,
              label: 'مراقب التطبيقات',
              accentColor: const Color(0xFFF6E2A0),
              onTap: () => _navigateToAppMonitor(),
            ),
          ),
          
          // وسط اليمين: أين المودم
          Positioned(
            top: 130,
            right: 20,
            child: _buildGlassCircleButton(
              key: Get.find<TutorialService>().modemFinderButtonKey,
              icon: Icons.security_update_warning,
              label: 'أين المودم',
              accentColor: const Color(0xFF00B4D8), // لون مميز للرادار
              onTap: () => Get.to(() => const ModemFinderPage()),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildGlassCircleButton({
    Key? key,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color accentColor = Colors.white,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // طبقة الوهج الخارجي (حلقة متوهجة)
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.35),
                  blurRadius: 22,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // تدرج لوني خفيف لإعطاء شخصية مميزة لكل زر
                    gradient: LinearGradient(
                      colors: [
                        accentColor.withValues(alpha: 0.22),
                        Colors.white.withValues(alpha: 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.5),
                      width: 1.8,
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // 🧊 دالة الكارت الزجاجي (Glassmorphism)
  Widget _buildGlassCard(
    String title,
    String value,
    SignalStatus status,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Get.isDarkMode ? 0.3 : 0.08),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 15,
            sigmaY: 15,
          ), // قوة التغبيش الزجاجي
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Get.isDarkMode
                    ? [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.02),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.9),
                        Colors.white.withValues(alpha: 0.5),
                      ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Get.isDarkMode
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.9),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: status.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: status.color, size: 18),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: status.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: status.color.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        status.label,
                        style: TextStyle(
                          color: status.color,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(color: subTextColor, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? 'N/A' : value,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: status.progress,
                    backgroundColor: status.color.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(status.color),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🧊 دالة الكارت الزجاجي المصغر
  Widget _buildDetailedGlassCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Get.isDarkMode ? 0.3 : 0.08),
            blurRadius: 20,
            spreadRadius: -5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Get.isDarkMode
                    ? [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.02),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.9),
                        Colors.white.withValues(alpha: 0.5),
                      ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Get.isDarkMode
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.9),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: subTextColor, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(color: subTextColor, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  value.isEmpty ? 'N/A' : value,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subTextColor.withValues(alpha: 0.5),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 🧠 تقرير الذكاء الاصطناعي (Terminal Effect)
  // ==========================================
  void _showSmartAnalysisReport(
    BuildContext context,
    EngineeringInfoEntity engData,
    SmartDiagnosis diagnosis,
  ) {
    Get.bottomSheet(
      Container(
        margin: const EdgeInsets.all(15),
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: diagnosis.color.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: diagnosis.color.withOpacity(0.15),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: diagnosis.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.cpu_charge,
                      color: diagnosis.color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'محرك الذكاء الاصطناعي | جاري التحليل...',
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w100,
                          ),
                        ),
                        Text(
                          'الحالة: ${diagnosis.overallQuality}',
                          style: TextStyle(
                            color: diagnosis.color,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 30, color: Colors.grey),

              Row(
                children: [
                  const Icon(Iconsax.danger, color: Colors.orange, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'التشخيص والمشكلة:',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TypewriterText(
                text: diagnosis.issue,
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w100,
                ),
                delay: const Duration(milliseconds: 300),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  const Icon(
                    Iconsax.search_status,
                    color: Colors.blueAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'الأسباب المحتملة:',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...diagnosis.causes.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '> ',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.w100,
                        ),
                      ),
                      Expanded(
                        child: TypewriterText(
                          text: entry.value,
                          style: TextStyle(
                            color: subTextColor,
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w100,
                          ),
                          delay: Duration(
                            milliseconds: 1500 + (entry.key * 800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  const Icon(
                    Iconsax.magic_star,
                    color: Colors.greenAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'خطوات الحل المقترحة:',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...diagnosis.solutions.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.greenAccent.withOpacity(0.1),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.tick_circle,
                          color: Colors.greenAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TypewriterText(
                            text: entry.value,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                            delay: Duration(
                              milliseconds: 3500 + (entry.key * 1000),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  // ==========================================
  // 🚀 النافذة السفلية الأنيقة لعرض الـ QR Code
  // ==========================================
  void _showQrBottomSheet(BuildContext context) {
    final ssid = dashboardController.wifiSsid.value;
    final password = wifiSettingsController.passwordController.text;
    final String qrData = 'WIFI:T:WPA;S:$ssid;P:$password;;';

    Get.bottomSheet(
      Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(45),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8E2DE2).withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 25),
            Text(
              'مشاركة الشبكة',
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'دع الضيوف يمسحون الرمز للاتصال فوراً',
              style: TextStyle(color: subTextColor, fontSize: 14),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: 200.0,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF0A0E21),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.circle,
                  color: Color(0xFF000000),
                ),
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

// ==========================================
// 📡 رادار النبض الذكي (Pulse Radar)
// ==========================================
class PulseRadar extends StatefulWidget {
  final Color color;
  const PulseRadar({super.key, required this.color});

  @override
  State<PulseRadar> createState() => _PulseRadarState();
}

class _PulseRadarState extends State<PulseRadar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // سرعة دوران الرادار (3 ثوانٍ لدورة كاملة)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _PremiumRadarPainter(_controller.value, widget.color),
          size: const Size(double.infinity, double.infinity),
        );
      },
    );
  }
}

class _PremiumRadarPainter extends CustomPainter {
  final double progress;
  final Color color;

  _PremiumRadarPainter(this.progress, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width > size.height
        ? size.width / 1.1
        : size.height / 1.1;

    // 1. رسم شبكة الرادار الخلفية (دوائر ثابتة)
    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final int ringCount = 3;
    for (int i = 1; i <= ringCount; i++) {
      canvas.drawCircle(center, maxRadius * (i / ringCount), gridPaint);
    }

    // خطوط التقاطع المتعامدة (Crosshairs)
    final crosshairPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // خط عمودي وأفقي
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius),
      Offset(center.dx, center.dy + maxRadius),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(center.dx - maxRadius, center.dy),
      Offset(center.dx + maxRadius, center.dy),
      crosshairPaint,
    );

    // 2. النبضات الإشعاعية (Sonar Pulses)
    for (int i = 0; i < 2; i++) {
      final currentProgress = (progress + (i * 0.5)) % 1.0;
      final radius = maxRadius * currentProgress;
      // تلاشي ناعم للخارج
      double opacity = math.pow((1.0 - currentProgress), 1.5).toDouble();

      final pulsePaint = Paint()
        ..color = color.withValues(alpha: opacity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth =
            2.0 +
            (opacity * 2.5) // يكون أسمك في المنتصف
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          4.0,
        ); // توهج خفيف

      canvas.drawCircle(center, radius, pulsePaint);
    }

    // 3. الماسح الدوار (Sweeping Scanner)
    final sweepAngle = progress * 2 * math.pi;

    final sweepGradient = SweepGradient(
      center: Alignment.center,
      startAngle: 0.0,
      endAngle: math.pi / 2, // ذيل الماسح يمتد لـ 90 درجة
      colors: [
        Colors.transparent,
        color.withValues(alpha: 0.1),
        color.withValues(alpha: 0.2),
      ],
      stops: const [0.0, 0.4, 1.0],
      transform: GradientRotation(sweepAngle - (math.pi / 2)),
    );

    final scannerPaint = Paint()
      ..shader = sweepGradient.createShader(
        Rect.fromCircle(center: center, radius: maxRadius),
      )
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxRadius),
      sweepAngle - (math.pi / 2),
      math.pi / 2,
      true,
      scannerPaint,
    );

    // 4. خط الليزر للماسح (Leading Edge)
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2.0);

    final lineEndX = center.dx + maxRadius * math.cos(sweepAngle);
    final lineEndY = center.dy + maxRadius * math.sin(sweepAngle);
    canvas.drawLine(center, Offset(lineEndX, lineEndY), linePaint);

    // 5. النقطة المركزية المشعة (Core Dot)
    final coreGlowPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
    canvas.drawCircle(center, 5.0, coreGlowPaint);

    final coreSolidPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 2.5, coreSolidPaint);
  }

  @override
  bool shouldRepaint(covariant _PremiumRadarPainter oldDelegate) => true;
}

// ==========================================
// ⌨️ محرك الآلة الكاتبة (Typewriter Effect)
// ==========================================
class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration speed;
  final Duration delay;
  final bool showCursor;

  const TypewriterText({
    super.key,
    required this.text,
    required this.style,
    this.speed = const Duration(milliseconds: 30),
    this.delay = Duration.zero,
    this.showCursor = true,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = '';
  late Timer _timer;
  int _currentIndex = 0;
  bool _isTyping = false;
  bool _cursorVisible = true;
  late Timer _cursorTimer;

  @override
  void initState() {
    super.initState();
    _cursorTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) setState(() => _cursorVisible = !_cursorVisible);
    });

    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() => _isTyping = true);
        _startTyping();
      }
    });
  }

  void _startTyping() {
    _timer = Timer.periodic(widget.speed, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayedText += widget.text[_currentIndex];
          _currentIndex++;
        });
      } else {
        timer.cancel();
        setState(() => _isTyping = false);
      }
    });
  }

  @override
  void dispose() {
    if (_isTyping) _timer.cancel();
    _cursorTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: _displayedText, style: widget.style),
          if (widget.showCursor && (_isTyping || _displayedText.isEmpty))
            TextSpan(
              text: _cursorVisible ? ' █' : '',
              style: widget.style.copyWith(
                color: widget.style.color?.withOpacity(0.5),
              ),
            ),
        ],
      ),
    );
  }
}

// ==========================================
// 🎛️ بطاقة التحكم بالتردد (Band Lock Card)
// ==========================================
class BandLockCard extends StatefulWidget {
  final DashboardController controller;
  const BandLockCard({super.key, required this.controller});

  @override
  State<BandLockCard> createState() => _BandLockCardState();
}

class _BandLockCardState extends State<BandLockCard> {
  bool isAuto = true;
  List<int> selectedBands = [];
  bool isInitialized = false;
  int? focusedBand; // تتبع النطاق الذي يرغب المستخدم في رؤية معلوماته

  // قاموس معلومات النطاقات (Bands Info Dictionary)
  final Map<int, Map<String, String>> bandsInfo = {
    1: {
      'work': 'تردد أساسي يدعم التغطية المتوازنة وسرعات جيدة.',
      'when': 'يُستخدم كتردد إضافي لتعزيز استقرار الاتصال في المدن.',
    },
    3: {
      'work': 'يوازن بين التغطية الواسعة والسرعة العالية.',
      'when': 'إذا كنت في مدينة أو قرية متوسطة، فغالباً أنت متصل بهذا النطاق.',
    },
    7: {
      'work': 'تردد عالٍ جداً يوفر سرعات إنترنت هائلة (Bandwidth واسع).',
      'when':
          'يُستخدم في المناطق المزدحمة جداً مثل الملاعب، المطارات، ومراكز المدن الكبرى. مداه قصير ولكنه يتحمل ضغط مستخدمين كبير.',
    },
    28: {
      'work':
          'يتميز بقدرة جبارة على اختراق الجدران والوصول لمسافات بعيدة جداً.',
      'when':
          'يُستخدم لتغطية المناطق الريفية والصحراوية، وفي داخل الأقبية (البدروم) والمباني الخرسانية السميكة.',
    },
    41: {
      'work':
          'يوفر سعة تحميل (Download) ضخمة جداً لأن الشبكة يمكنها تخصيص معظم الوقت للتحميل بدلاً من الرفع.',
      'when': 'يُستخدم لتعزيز السرعات في المناطق ذات الكثافة السكانية العالية.',
    },
  };

  void applyChanges() async {
    await widget.controller.saveBandConfig(isAuto, selectedBands);
    await widget.controller.fetchData();
    await widget.controller.fetchEngineeringInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final config = widget.controller.bandConfig.value;

      if (widget.controller.isBandLoading.value && config == null) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      }

      if (config == null) {
        return const SizedBox.shrink();
      }

      if (!isInitialized) {
        isAuto = config.isAuto;
        selectedBands = List.from(config.configuredBands);
        // تعيين أول باند كتركيز افتراضي لرؤية المعلومات
        if (selectedBands.isNotEmpty) focusedBand = selectedBands.first;
        isInitialized = true;
      }

      final bool hasChanges =
          (isAuto != config.isAuto) ||
          (!isAuto &&
              selectedBands.join(',') != config.configuredBands.join(','));

      // --- متغيرات الثيم (تعمل في الليل والنهار) ---
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final cardBg   = isDark ? const Color(0xFF0F1A2E) : Colors.white;
      final labelClr = isDark ? Colors.white : const Color(0xFF1E293B);
      final subClr   = isDark ? Colors.white70 : const Color(0xFF64748B);
      final borderClr = isDark
          ? const Color(0xFF38BDF8).withValues(alpha: 0.4)
          : const Color(0xFF3B82F6).withValues(alpha: 0.3);
      final glowClr = isDark
          ? const Color(0xFF38BDF8).withValues(alpha: 0.12)
          : const Color(0xFF3B82F6).withValues(alpha: 0.08);
      final iconBg  = isDark
          ? Colors.white.withValues(alpha: 0.1)
          : const Color(0xFF3B82F6).withValues(alpha: 0.12);
      final iconClr = isDark ? Colors.white : const Color(0xFF3B82F6);

      return Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderClr, width: 1.8),
          boxShadow: [
            BoxShadow(color: glowClr, blurRadius: 24, spreadRadius: 4),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان ومفتاح التبديل
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Iconsax.wifi_square, color: iconClr, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'إعدادات البرج',
                      style: TextStyle(
                        color: labelClr,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.3)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => isAuto = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: isAuto
                                ? (isDark ? Colors.white : const Color(0xFF3B82F6))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            'تلقائي',
                            style: TextStyle(
                              color: isAuto
                                  ? (isDark ? Colors.black : Colors.white)
                                  : subClr,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => isAuto = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: !isAuto
                                ? (isDark ? Colors.white : const Color(0xFF3B82F6))
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            'يدوي',
                            style: TextStyle(
                              color: !isAuto
                                  ? (isDark ? Colors.black : Colors.white)
                                  : subClr,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            if (isAuto)
              Text(
                'هذا الوضع سيقوم باختيار التردد الأفضل تلقائياً لضمان أفضل تغطية ممكنة.',
                style: TextStyle(color: subClr, fontSize: 11),
              )
            else ...[
              Text(
                'هذا الوضع يسمح لك باختيار التردد يدوياً لتثبيت الاتصال على برج محدد.',
                style: TextStyle(color: subClr, fontSize: 11),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Iconsax.info_circle,
                      color: Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تحذير: تثبيت التردد يمنع المودم من البحث عن شبكات أفضل. لا تستخدمه إذا كنت تتنقل كثيراً لتجنب فقدان التغطية.',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 10,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: isAuto
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: const SizedBox(height: 0, width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الترددات المدعومة (اضغط للتفاصيل):',
                      style: TextStyle(color: subClr, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: config.supportedBands.map((band) {
                        final isSelected = selectedBands.contains(band);
                        final isFocused = focusedBand == band;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              focusedBand = band; // تحديث معلومات النطاق
                              if (isSelected) {
                                if (selectedBands.length > 1) {
                                  selectedBands.remove(band);
                                }
                              } else {
                                selectedBands.add(band);
                              }
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF3B82F6)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.07)
                                      : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isFocused
                                    ? const Color(0xFF3B82F6)
                                    : (isSelected
                                        ? Colors.transparent
                                        : (isDark
                                            ? Colors.white.withValues(alpha: 0.15)
                                            : const Color(0xFFCBD5E1))),
                              ),
                            ),
                            child: Text(
                              'B$band',
                              style: TextStyle(
                                color: isSelected ? Colors.white : labelClr,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // قسم معلومات النطاق المختار (Band Info Section)
                    if (focusedBand != null &&
                        bandsInfo.containsKey(focusedBand)) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'معلومات النطاق B$focusedBand',
                                  style: TextStyle(
                                    color: const Color(0xFF3B82F6),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Iconsax.info_circle,
                                  size: 16,
                                  color: subClr,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildInfoRow(
                              'عمله:',
                              bandsInfo[focusedBand]!['work']!,
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow(
                              'متى يُستخدم:',
                              bandsInfo[focusedBand]!['when']!,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (hasChanges) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: widget.controller.isBandSaving.value
                      ? null
                      : applyChanges,
                  icon: widget.controller.isBandSaving.value
                      ? const SizedBox.shrink()
                      : const Icon(Iconsax.save_2, size: 20),
                  label: widget.controller.isBandSaving.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'تطبيق التغييرات',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildInfoRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelClr = isDark ? Colors.white70 : const Color(0xFF64748B);
    final valueClr = isDark ? Colors.white   : const Color(0xFF1E293B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelClr,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: valueClr,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 🛸 زر الرادار الذكي الدائري والنابض
// ==========================================
class GlowingRadarButton extends StatefulWidget {
  const GlowingRadarButton({super.key});

  @override
  State<GlowingRadarButton> createState() => _GlowingRadarButtonState();
}

class _GlowingRadarButtonState extends State<GlowingRadarButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(
      begin: 0.2,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Center(
          child: GestureDetector(
            onTap: () => Get.to(() => const SignalFinderPage()),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF4A90E2,
                    ).withValues(alpha: _glowAnimation.value * 0.4),
                    blurRadius: 30 + (20 * _glowAnimation.value),
                    spreadRadius: 5 + (10 * _glowAnimation.value),
                  ),
                  BoxShadow(
                    color: const Color(
                      0xFF50E3C2,
                    ).withValues(alpha: _glowAnimation.value * 0.2),
                    blurRadius: 60 + (40 * _glowAnimation.value),
                    spreadRadius: 10 + (15 * _glowAnimation.value),
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF4A90E2).withValues(alpha: 0.35),
                          const Color(0xFF50E3C2).withValues(alpha: 0.20),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: 0.3 + (_glowAnimation.value * 0.5),
                        ),
                        width: 2,
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.radar5, color: Colors.white, size: 45),
                        SizedBox(height: 5),
                        Text(
                          'تشغيل الرادار',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black45, blurRadius: 5),
                            ],
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
      },
    );
  }
}

// ⚡ تأثير التيار الكهربائي المتحرك للخطوط
class AnimatedPentagonLines extends StatefulWidget {
  const AnimatedPentagonLines({super.key});

  @override
  State<AnimatedPentagonLines> createState() => _AnimatedPentagonLinesState();
}

class _AnimatedPentagonLinesState extends State<AnimatedPentagonLines>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 380),
          painter: _PentagonLinePainter(progress: _controller.value),
        );
      },
    );
  }
}

// 🔺 رسام خطوط التوصيل الخماسية بين الأزرار
class _PentagonLinePainter extends CustomPainter {
  final double progress;
  _PentagonLinePainter({this.progress = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final glowPaint = Paint()
      ..color = const Color(0xFF00B4D8) // لون التيار الكهربائي
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0); // توهج

    // نقاط الخماسي
    const double btnRadius = 42.0;
    final top = Offset(size.width / 2, btnRadius);
    final midRight = Offset(size.width - 20 - btnRadius, 130 + btnRadius);
    final midLeft = Offset(20 + btnRadius, 130 + btnRadius);
    final botRight = Offset(size.width - 50 - btnRadius, size.height - btnRadius - 22);
    final botLeft = Offset(50 + btnRadius, size.height - btnRadius - 22);

    // رسم الخطوط كمسارات متقطعة (Dashed) لتكوين الشبكة مع التيار
    _drawDashedWithCurrent(canvas, basePaint, glowPaint, top, midRight, progress, 0.0);
    _drawDashedWithCurrent(canvas, basePaint, glowPaint, top, midLeft, progress, 0.2);
    _drawDashedWithCurrent(canvas, basePaint, glowPaint, midLeft, botLeft, progress, 0.4);
    _drawDashedWithCurrent(canvas, basePaint, glowPaint, midRight, botRight, progress, 0.6);
    _drawDashedWithCurrent(canvas, basePaint, glowPaint, botLeft, botRight, progress, 0.8);
    
    // خطوط داخلية لتعزيز الشكل الفضائي
    _drawDashedWithCurrent(canvas, basePaint, glowPaint, midLeft, midRight, progress, 0.5);
  }

  void _drawDashedWithCurrent(Canvas canvas, Paint basePaint, Paint glowPaint, Offset from, Offset to, double progress, double offsetTime) {
    const double dashLen = 12;
    const double gapLen  = 5;
    final total = (to - from).distance;
    final dir   = (to - from) / total;
    
    // رسم الخطوط الأساسية المتقطعة
    double dist = 0;
    while (dist < total) {
      final start = from + dir * dist;
      final end   = from + dir * math.min(dist + dashLen, total);
      canvas.drawLine(start, end, basePaint);
      dist += dashLen + gapLen;
    }

    // حساب موضع التيار الكهربائي بناءً على الوقت (progress) وإزاحة البداية (offsetTime)
    final double adjustedProgress = (progress + offsetTime) % 1.0;
    
    // التيار يتحرك على طول الخط
    final currentPos = total * adjustedProgress;
    final currentStart = math.max(0.0, currentPos - 30.0);
    final currentEnd = math.min(total, currentPos + 30.0);
    
    if (currentEnd > 0 && currentStart < total) {
      // إخفاء التيار بسلاسة عند البداية والنهاية
      final start = from + dir * currentStart;
      final end = from + dir * currentEnd;
      canvas.drawLine(start, end, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_PentagonLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

void _navigateToAppMonitor() {
  Get.to(
    () => AppMonitorScreen(),
    transition: Transition.cupertino,
    duration: const Duration(milliseconds: 400),
  );
}
