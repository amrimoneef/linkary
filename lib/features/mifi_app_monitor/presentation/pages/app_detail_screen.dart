import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/app_category.dart';
import '../../domain/entities/app_usage_entity.dart';
import '../controllers/app_monitor_controller.dart';
import '../../../../core/services/tutorial_service.dart';

class AppDetailScreen extends StatefulWidget {
  final AppUsageEntity app;

  const AppDetailScreen({super.key, required this.app});

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen> {
  final AppMonitorController controller = Get.find<AppMonitorController>();
  String _selectedChartTab = 'الإجمالي';

  @override
  void initState() {
    super.initState();
    controller.fetchAppHistory(widget.app.packageName);
  }

  @override
  Widget build(BuildContext context) {
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Get.find<TutorialService>().showAppDetailTutorial(context);
    // });

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F111A) : const Color(0xFFF4F6FB);
    final text = isDark ? Colors.white : const Color(0xFF1E2432);
    final subText = isDark ? Colors.white54 : const Color(0xFF8A94A6);
    final cardBg = isDark ? const Color(0xFF1C1F2E) : Colors.white;
    final primaryColor = const Color(0xFF2A64D9);

    return Scaffold(
      backgroundColor: bg,
      body: Obx(() {
        final liveApp = controller.allInstalledApps.firstWhereOrNull((a) => a.packageName == widget.app.packageName) ??
            controller.appsUsage.firstWhereOrNull((a) => a.packageName == widget.app.packageName) ??
            widget.app;

        final usageApp = controller.appsUsage.firstWhereOrNull((a) => a.packageName == widget.app.packageName) ??
            AppUsageEntity(packageName: widget.app.packageName, appName: widget.app.appName, totalBytes: 0, rxBytes: 0, txBytes: 0);

        return SingleChildScrollView(
          physics: const ScrollPhysics(),
          child: Column(
            children: [
              // Top Blue Background Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 10,
                    bottom: 60,
                    left: 20,
                    right: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF154093), Color(0xFF2A64D9)],
                  ),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
                ),
                child: Column(
                  children: [
                    // App Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white), // RTL back arrow
                          onPressed: () => Get.back(),
                        ),
                        Row(
                          children: [
                            IconButton(
                              key: Get.find<TutorialService>().appDetailHelpKey,
                              icon: const Icon(Icons.help_outline, color: Colors.white),
                              onPressed: () => Get.find<TutorialService>().showAppDetailTutorial(context, force: true),
                            ),
                            IconButton(
                              key: Get.find<TutorialService>().adShareButtonKey,
                              icon: const Icon(Icons.share, color: Colors.white),
                              onPressed: () => controller.shareAppDetail(context, liveApp.packageName),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // App Icon and Info
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                        ],
                      ),
                      padding: const EdgeInsets.all(5),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: liveApp.iconData != null
                            ? Image.memory(liveApp.iconData!, fit: BoxFit.cover)
                            : const Icon(Iconsax.global, size: 40, color: Colors.blue),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      liveApp.appName,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      liveApp.packageName,
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Text(liveApp.isSystemApp ? 'أساسي (نظام)' : 'تطبيق مستخدم', style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        const SizedBox(width: 10),
                        Obx(() {
                          final isBlocked = controller.isAppBlocked(liveApp.packageName);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isBlocked ? Colors.redAccent.withValues(alpha: 0.2) : Colors.greenAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: isBlocked ? Colors.redAccent.withValues(alpha: 0.5) : Colors.greenAccent.withValues(alpha: 0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(isBlocked ? Iconsax.lock : Iconsax.unlock, color: Colors.white, size: 14),
                                const SizedBox(width: 6),
                                Text(isBlocked ? 'محظور' : 'نشط', style: const TextStyle(color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              // Stats Card Overlapping
              Transform.translate(
                offset: const Offset(0, -40),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    key: Get.find<TutorialService>().adMainStatsKey,
                    child: _buildMainStatsCard(usageApp, cardBg, text, primaryColor),
                  ),
                ),
              ),

              // Rest of the screen
              Transform.translate(
                offset: const Offset(0, -20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Grid Cards
                      Container(
                        key: Get.find<TutorialService>().adGridDetailsKey,
                        child: _buildGridDetails(liveApp, cardBg, text, subText),
                      ),

                      const SizedBox(height: 20),

                      Container(
                        key: Get.find<TutorialService>().adGoalButtonKey,
                        child: _buildOpenDialogButton(cardBg, primaryColor, usageApp),
                      ),

                      const SizedBox(height: 20),

                      // Chart Section
                      Container(
                        key: Get.find<TutorialService>().adChartKey,
                        child: _buildChartSection(cardBg, text, subText, primaryColor),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildMainStatsCard(AppUsageEntity usageApp, Color cardBg, Color text, Color primaryColor) {
    final goalBytes = controller.appGoals[usageApp.packageName] ?? 0;
    final maxBytes = goalBytes > 0 ? goalBytes : (usageApp.totalBytes > 100 * 1024 * 1024 ? usageApp.totalBytes * 2 : 100 * 1024 * 1024);
    final progress = usageApp.totalBytes / maxBytes;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 25,
      child: Column(
        children: [
          Row(
            children: [
              _buildStatItem('التحميل', controller.formatBytes(usageApp.rxBytes), Icons.download_rounded, const Color(0xFF2A64D9)),
              Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.2)),
              _buildStatItem('الرفع', controller.formatBytes(usageApp.txBytes), Icons.upload_rounded, const Color(0xFFFF8A65)),
              Container(width: 1, height: 40, color: Colors.grey.withOpacity(0.2)),
              _buildStatItem('الإجمالي', controller.formatBytes(usageApp.totalBytes), Icons.pie_chart_rounded, text),
            ],
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(controller.formatBytes(usageApp.totalBytes), style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
              Text(controller.formatBytes(maxBytes), style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    // Split value and unit
    final parts = value.split(' ');
    final val = parts.isNotEmpty ? parts[0] : '0';
    final unit = parts.length > 1 ? parts[1] : 'MB';

    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color == const Color(0xFF1E2432) || color == Colors.white ? color : color)),
              const SizedBox(width: 2),
              Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGridDetails(AppUsageEntity app, Color cardBg, Color text, Color subText) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildSmallCard('التصنيف', app.category.displayName, Iconsax.category, cardBg, text, subText)),
            const SizedBox(width: 15),
            Expanded(child: _buildSmallCard('آخر نشاط', app.lastActiveTime != null 
                ? DateFormat('hh:mm a', 'ar_AG').format(app.lastActiveTime!) 
                : 'الجلسة الحالية', Iconsax.clock, cardBg, text, subText)),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: _buildSmallCard('وقت الاستخدام', _formatDuration(app.usageTime), Iconsax.timer, cardBg, text, subText),
        ),
      ],
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null || duration.inSeconds == 0) return '0 دقيقة';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '$hours ساعة و $minutes دقيقة';
    } else {
      return '$minutes دقيقة';
    }
  }

  Widget _buildSmallCard(String title, String value, IconData icon, Color cardBg, Color text, Color subText) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2A64D9).withOpacity(0.8), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(color: subText, fontSize: 11, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChartSection(Color cardBg, Color text, Color subText, Color primaryColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('نشاط الاستهلاك', style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: ['حركة البيانات', 'الإجمالي'].map((tab) => GestureDetector(
                    onTap: () => setState(() => _selectedChartTab = tab),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedChartTab == tab ? (isDark ? Colors.white.withOpacity(0.1) : Colors.white) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _selectedChartTab == tab ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)] : [],
                      ),
                      child: Text(tab, style: TextStyle(color: _selectedChartTab == tab ? (isDark ? Colors.white : text) : subText, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  )).toList(),
                ),
              )
            ],
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 150,
            child: controller.appHistoryData.isEmpty
                ? Center(child: Text('لا توجد بيانات سجل كافية', style: TextStyle(color: subText, fontSize: 13)))
                : LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (spot) => isDark ? const Color(0xFF1C1F2E) : Colors.white,
                          tooltipBorder: BorderSide(color: primaryColor.withOpacity(0.2)),
                          tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          tooltipBorderRadius: BorderRadius.circular(12),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              String label = 'الإجمالي';
                              if (_selectedChartTab == 'حركة البيانات') {
                                label = spot.barIndex == 0 ? 'تحميل' : 'رفع';
                              }
                              return LineTooltipItem(
                                '$label: ${spot.y.toStringAsFixed(2)} MB',
                                TextStyle(
                                  color: spot.bar.color ?? text,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 22, getTitlesWidget: (val, meta) {
                          final i = val.toInt();
                          if (i < 0 || i >= controller.appHistoryData.length) return const SizedBox.shrink();
                          return Padding(padding: const EdgeInsets.only(top: 8), child: Text(_getArabicDayShort(controller.appHistoryData[i]['dayName']), style: TextStyle(color: subText, fontSize: 11)));
                        })),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: _selectedChartTab == 'الإجمالي'
                        ? [
                            LineChartBarData(
                              spots: controller.appHistoryData.asMap().entries.map((e) {
                                final total = (e.value['rx'] + e.value['tx']) / 1048576;
                                return FlSpot(e.key.toDouble(), total);
                              }).toList(),
                              isCurved: true,
                              color: primaryColor,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [primaryColor.withOpacity(0.3), primaryColor.withOpacity(0.0)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ]
                        : [
                            // Download Line
                            LineChartBarData(
                              spots: controller.appHistoryData.asMap().entries.map((e) {
                                return FlSpot(e.key.toDouble(), e.value['rx'] / 1048576);
                              }).toList(),
                              isCurved: true,
                              color: const Color(0xFF2A64D9),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(show: false),
                            ),
                            // Upload Line
                            LineChartBarData(
                              spots: controller.appHistoryData.asMap().entries.map((e) {
                                return FlSpot(e.key.toDouble(), e.value['tx'] / 1048576);
                              }).toList(),
                              isCurved: true,
                              color: const Color(0xFFFF8A65),
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(show: false),
                              belowBarData: BarAreaData(show: false),
                            ),
                          ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _getArabicDayShort(String e) {
    const m = {'Saturday': 'سبت', 'Sunday': 'أحد', 'Monday': 'إثن', 'Tuesday': 'ثلا', 'Wednesday': 'أرب', 'Thursday': 'خمي', 'Friday': 'جمع'};
    return m[e] ?? e.substring(0, 3);
  }

  Widget _buildOpenDialogButton(Color cardBg, Color primaryColor, AppUsageEntity app) {
    return Obx(() {
      final goalBytes = controller.appGoals[app.packageName];
      final hasGoal = goalBytes != null && goalBytes > 0;

      return GestureDetector(
        onTap: () => _showGlassyGoalDialog(context, app),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(color: primaryColor.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, 5))
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Iconsax.setting_2, color: primaryColor),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('تخصيص السقف وحظر التطبيق', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(hasGoal ? 'الحد الحالي: ${controller.formatBytes(goalBytes)}' : 'انقر لضبط الحد الأقصى للاستهلاك', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              if (hasGoal)
                IconButton(
                  onPressed: () {
                    _showActionConfirmDialog(
                      context,
                      title: 'حذف سقف الاستهلاك',
                      message: 'هل أنت متأكد من رغبتك في إزالة سقف الاستهلاك لهذا التطبيق؟',
                      onConfirm: () {
                        controller.removeAppGoal(app.packageName);
                        if (controller.isAppBlocked(app.packageName)) {
                          controller.unblockApp(app.packageName);
                        }
                        CustomSnackbar.showInfo('تم الحذف', 'تم إزالة سقف الاستهلاك ورفع الحظر إن وجد');
                      },
                    );
                  },
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 24),
                  tooltip: 'إزالة السقف',
                )
              else
                Icon(Icons.arrow_forward_ios, size: 16, color: primaryColor),
            ],
          ),
        ),
      );
    });
  }

  void _showGlassyGoalDialog(BuildContext context, AppUsageEntity app) {
    final TextEditingController manualController = TextEditingController();
    final RxBool autoBlock = (controller.appAutoBlockPrefs[app.packageName] ?? false).obs;
    final List<int> presets = [100, 250, 500, 1000, 2000, 5000];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final goalBytes = controller.appGoals[app.packageName];
    final hasGoal = goalBytes != null && goalBytes > 0;
    final currentGoalMb = hasGoal ? goalBytes ~/ (1024 * 1024) : 0;
    final RxInt selectedVal = currentGoalMb.obs;
    
    manualController.text = currentGoalMb > 0 ? currentGoalMb.toString() : '';

    Get.dialog(
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16213E).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 30)
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Center(
                    child: Text('إعدادات سقف الاستهلاك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                  ),
                  const SizedBox(height: 25),

                  Text('الحد الأقصى للتنبيه', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: manualController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'مثال: 500',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Iconsax.edit, color: Colors.grey),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Obx(() => Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: presets.map((p) {
                      final isSelected = selectedVal.value == p;
                      return InkWell(
                        onTap: () {
                          selectedVal.value = p;
                          manualController.text = p.toString();
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: (Get.width - 120) / 3,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF2A64D9) : (isDark ? Colors.black.withOpacity(0.2) : Colors.white),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? const Color(0xFF2A64D9) : const Color(0xFF2A64D9).withOpacity(0.2)),
                            boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF2A64D9).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            p >= 1000 ? '${p/1000} GB' : '$p MB', 
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF2A64D9), 
                              fontWeight: FontWeight.bold, 
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('إيقاف الإنترنت تلقائياً', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : Colors.black)),
                          const SizedBox(height: 4),
                          const Text('سيتم منع الاتصال بالانترنت فور الوصول للحد', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      Obx(() => Switch(
                        value: autoBlock.value,
                        onChanged: (v) => autoBlock.value = v,
                        activeColor: const Color(0xFF2A64D9),
                      )),
                    ],
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final val = int.tryParse(manualController.text);
                        
                        // Show reset confirmation dialog
                        final RxBool blockApp = controller.isAppBlocked(app.packageName).obs;
                        
                        Get.dialog(
                          AlertDialog(
                            backgroundColor: isDark ? const Color(0xFF16213E) : Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: Row(
                              children: [
                                const Icon(Iconsax.refresh, color: Color(0xFF2A64D9)),
                                const SizedBox(width: 10),
                                const Text('تصفير البيانات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                              ],
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('هل تريد تصفير استهلاك البيانات لهذا التطبيق؟', style: TextStyle(fontSize: 14)),
                                const SizedBox(height: 15),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Obx(() => CheckboxListTile(
                                    value: blockApp.value,
                                    onChanged: (v) => blockApp.value = v ?? false,
                                    title: Text('حظر التطبيق من الإنترنت', style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                                    contentPadding: EdgeInsets.zero,
                                    activeColor: const Color(0xFF2A64D9),
                                    dense: true,
                                    controlAffinity: ListTileControlAffinity.leading,
                                  )),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () async {
                                  Get.back(); // Close reset dialog
                                  Get.back(); // Close goal dialog
                                  
                                  // Apply blocking status
                                  if (blockApp.value) {
                                    controller.blockApp(app.packageName, app.appName);
                                  } else {
                                    controller.unblockApp(app.packageName);
                                  }
                                  
                                  if (val == null || val <= 0) {
                                    await controller.removeAppGoal(app.packageName);
                                    CustomSnackbar.showInfo('تم التحديث', 'تم إزالة سقف الاستهلاك');
                                  } else {
                                    await controller.setAppGoal(app.packageName, val, autoBlock: autoBlock.value);
                                    CustomSnackbar.showSuccess('تم بنجاح', 'تم حفظ إعدادات سقف الاستهلاك');
                                  }
                                },
                                child: Text('حفظ فقط', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  Get.back(); // Close reset dialog
                                  Get.back(); // Close goal dialog
                                  
                                  // Apply blocking status
                                  if (blockApp.value) {
                                    controller.blockApp(app.packageName, app.appName);
                                  } else {
                                    controller.unblockApp(app.packageName);
                                  }
                                  
                                  // Reset usage first
                                  await controller.resetAppUsage(app.packageName);
                                  
                                  if (val == null || val <= 0) {
                                    await controller.removeAppGoal(app.packageName);
                                    CustomSnackbar.showInfo('تم التحديث', 'تم إزالة وتصفير البيانات');
                                  } else {
                                    await controller.setAppGoal(app.packageName, val, autoBlock: autoBlock.value);
                                    CustomSnackbar.showSuccess('تم بنجاح', 'تم تصفير البيانات وحفظ الإعدادات');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2A64D9),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Text('حفظ وتصفير', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          barrierDismissible: true,
                        );
                      },
                      icon: const Icon(Iconsax.save_2, size: 20),
                      label: const Text('حفظ الإعدادات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2A64D9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 0,
                      ),
                    ),
                  ),


                ],
              ),
            ),
          ),
        ),
      ),
      barrierColor: Colors.black.withOpacity(0.5),
    );
  }
  void _showActionConfirmDialog(BuildContext context, {required String title, required String message, required VoidCallback onConfirm, bool isDanger = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    Get.dialog(
      AlertDialog(
        backgroundColor: isDark ? const Color(0xFF16213E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(isDanger ? Iconsax.warning_2 : Iconsax.info_circle, color: isDanger ? Colors.redAccent : const Color(0xFF2A64D9)),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('تراجع', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? Colors.redAccent : const Color(0xFF2A64D9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('تأكيد'),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }
}