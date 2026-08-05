import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../core/services/tutorial_service.dart';
import '../controllers/app_monitor_controller.dart';
import '../widgets/usage_summary_card.dart';
import '../widgets/filter_chips_bar.dart';
import '../widgets/connection_status_banner.dart';
import '../widgets/app_usage_tile.dart';
import '../widgets/permission_gate_widget.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/live_speed_indicator.dart';
import '../widgets/category_breakdown_card.dart';
import '../widgets/insight_card.dart';
import 'firewall_management_screen.dart';

class AppMonitorScreen extends StatelessWidget {
  final AppMonitorController controller = Get.find<AppMonitorController>();

  AppMonitorScreen({super.key});

  Color textColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF111827);
  Color subTextColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? Colors.white54 : const Color(0xFF6B7280);
  Color glowColor(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? const Color(0xFF4A90E2) : const Color(0xFF60A5FA);

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0A0E21) : const Color(0xFFFAFAFC);
    final glow = glowColor(context);

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Get.find<TutorialService>().showAppMonitorTutorial(context);
    // });

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor(context)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'مراقب التطبيقات',
          style: TextStyle(
            fontSize: 12,
            color: textColor(context),
            fontWeight: FontWeight.bold,
          )
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: subTextColor(context)),
            onPressed: () => Get.find<TutorialService>().showAppMonitorTutorial(context, force: true),
            tooltip: 'مساعدة',
          ),
          // IconButton(
          //   icon: Icon(Iconsax.refresh, color: subTextColor(context)),
          //   onPressed: () => controller.refreshUsage(),
          // ),
          IconButton(
            key: Get.find<TutorialService>().amExportButtonKey,
            icon: Icon(Icons.share, color: subTextColor(context)),
            onPressed: () => controller.shareDailyReport(context),
            tooltip: 'مشاركة التقرير',
          ),
          IconButton(
            key: Get.find<TutorialService>().amFirewallButtonKey,
            icon: Icon(Iconsax.shield_tick, color: subTextColor(context)),
            onPressed: () => Get.to(() => const FirewallManagementScreen()),
            tooltip: 'جدار الحماية',
          ),
          IconButton(
            key: Get.find<TutorialService>().amResetButtonKey,
            icon: Icon(Iconsax.trash, color: subTextColor(context)),
            onPressed: () => _confirmReset(context),
            tooltip: 'تصفير الجلسة',
          )
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator(color: glow));
        }

        if (!controller.hasPermission.value) {
          return PermissionGateWidget(controller: controller);
        }

        return Stack(
          children: [
            // Ambient Glow Effects
            Positioned(top: -100, right: -50, child: _buildAmbientGlow(glow.withValues(alpha: 0.2))),
            Positioned(bottom: -50, left: -50, child: _buildAmbientGlow(glow.withValues(alpha: 0.1))),

            RefreshIndicator(
              color: glow,
              onRefresh: () => controller.refreshUsage(),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                children: [
                  // 🏁 Branding Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                      ),
                      Image.asset(
                        Get.isDarkMode ? 'assets/images/الشعار ابيض.png' : 'assets/images/الشعار اسود.png',
                        height: 35,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // 1. Chart Section
                  Container(
                    key: Get.find<TutorialService>().amChartKey,
                    child: _buildHistoryChart(context),
                  ),
                  const SizedBox(height: 25),
                  
                  // 2. Filter Section
                  Container(
                    key: Get.find<TutorialService>().amFilterBarKey,
                    child: FilterChipsBar(controller: controller),
                  ),
                  const SizedBox(height: 25),
                  
                  // 3. Status Section
                  ConnectionStatusBanner(controller: controller),
                  
                  // 3.5 Smart Alerts Section
                  _buildAlertsBanner(context),
                  
                  // 3.6 Insight Card (Usage Pattern)
                  Obx(() {
                    if (controller.currentInsight.value == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: InsightCard(insight: controller.currentInsight.value!),
                    );
                  }),
                  
                  // 4. Summary Card
                  Container(
                    key: Get.find<TutorialService>().amSummaryCardKey,
                    child: UsageSummaryCard(controller: controller),
                  ),
                  const SizedBox(height: 15),
                  
                  // 4.5 Live Speed Info
                  Container(
                    key: Get.find<TutorialService>().amLiveSpeedKey,
                    child: LiveSpeedIndicator(controller: controller),
                  ),
                  const SizedBox(height: 25),
                  
                  // 4.6 Category Breakdown
                  Container(
                    key: Get.find<TutorialService>().amCategoryBreakdownKey,
                    child: CategoryBreakdownCard(controller: controller),
                  ),
                  const SizedBox(height: 10),
                  
                  // 5. Apps List Section
                  _buildAppsListHeader(context),
                  const SizedBox(height: 15),
                  Container(
                    key: Get.find<TutorialService>().amSearchBarKey,
                    child: SearchBarWidget(controller: controller),
                  ),
                  const SizedBox(height: 20),
                  _buildAppsList(context),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildAlertsBanner(BuildContext context) {
    return Obx(() {
      if (controller.activeAlerts.isEmpty) return const SizedBox.shrink();
      
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: controller.activeAlerts.map((alert) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Iconsax.info_circle, color: Colors.orangeAccent, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(alert, style: TextStyle(color: textColor(context), fontSize: 12, fontWeight: FontWeight.w500))),
              ],
            ),
          )).toList(),
        ),
      );
    });
  }

  void _confirmReset(BuildContext context) {
    Get.dialog(
      AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF16213E) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('تصفير الجلسة؟', style: TextStyle(color: textColor(context), fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text('سيتم البدء بحساب الاستهلاك من اللحظة الحالية فقط لهذه الجلسة.', style: TextStyle(color: subTextColor(context), fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              controller.resetSession();
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryChart(BuildContext context) {
    final cardBg = Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF16213E) 
        : const Color(0xFFE5E7EB);
    final subText = subTextColor(context);

    return Container(
      height: 200,
      padding: const EdgeInsets.only(top: 25, bottom: 10, left: 10, right: 10),
      decoration: BoxDecoration(
        color: cardBg.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: cardBg.withValues(alpha: 0.05)),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: controller.maxYForChart.value,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => cardBg,
              tooltipBorderRadius: BorderRadius.all(Radius.circular(8)),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${rod.toY.toStringAsFixed(1)} MB',
                  const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (double value, TitleMeta meta) {
                  final style = TextStyle(color: subText, fontWeight: FontWeight.bold, fontSize: 10);
                  int index = value.toInt();
                  String dayText = '';
                  
                  if (index >= 0 && index < controller.historyStats.length) {
                    final stat = controller.historyStats[index];
                    String fullName = stat['dayName'];
                    String dateStr = stat['date'];
                    
                    if (controller.selectedFilter.value == MonitorFilter.month) {
                       if (index % 5 == 0) dayText = dateStr.substring(8);
                    } else {
                       dayText = _getArabicDayShort(fullName);
                    }
                  }
                  return SideTitleWidget(
                    meta: meta,
                    space: 10.0,
                    child: Text(dayText, style: style),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (controller.maxYForChart.value / 4).clamp(1.0, double.infinity),
            getDrawingHorizontalLine: (value) => FlLine(color: cardBg.withValues(alpha: 0.05), strokeWidth: 1, dashArray: [4, 4]),
          ),
          borderData: FlBorderData(show: false),
          barGroups: controller.historyStats.map((stat) {
            int index = stat['dayIndex'];
            double rxMB = stat['rx'] / 1048576;
            double txMB = stat['tx'] / 1048576;
            return _makeGroupData(context, index, rxMB, txMB);
          }).toList(),
        ),
      ),
    );
  }

  String _getArabicDayShort(String englishDay) {
    const map = {
      'Saturday': 'سبت', 'Sunday': 'أحد', 'Monday': 'إثن', 'Tuesday': 'ثلا',
      'Wednesday': 'أرب', 'Thursday': 'خمي', 'Friday': 'جمع'
    };
    return map[englishDay] ?? '';
  }

  BarChartGroupData _makeGroupData(BuildContext context, int x, double y1, double y2) {
    final cardBg = Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF16213E) 
        : const Color(0xFFE5E7EB);
        
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1, 
          gradient: const LinearGradient(
            colors: [Color(0xFF00D2FF), Color(0xFF3A7BD5)],
            begin: Alignment.bottomCenter, end: Alignment.topCenter,
          ),
          width: 8, 
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: controller.maxYForChart.value, color: cardBg.withValues(alpha: 0.1)),
        ),
        BarChartRodData(
          toY: y2, 
          gradient: const LinearGradient(
            colors: [Color(0xFF00FF87), Color(0xFF60EFFF)],
            begin: Alignment.bottomCenter, end: Alignment.topCenter,
          ),
          width: 8, 
          borderRadius: BorderRadius.circular(4),
          backDrawRodData: BackgroundBarChartRodData(show: true, toY: controller.maxYForChart.value, color: cardBg.withValues(alpha: 0.1)),
        ),
      ],
    );
  }

  Widget _buildAppsListHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'استهلاك التطبيقات', 
          style: TextStyle(
            color: textColor(context), 
            fontSize: 18, 
            fontWeight: FontWeight.bold
          )
        ),
        _buildActiveBadge(context),
      ],
    );
  }

  Widget _buildActiveBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: glowColor(context).withValues(alpha: 0.1), 
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: glowColor(context).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            'مراقبة نشطة', 
            style: TextStyle(color: glowColor(context), fontSize: 11, fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }

  Widget _buildAppsList(BuildContext context) {
    return Obx(() {
      if (controller.filteredAppsUsage.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(Iconsax.search_status, size: 40, color: subTextColor(context)),
                const SizedBox(height: 15),
                Text(
                  'لا توجد نتائج مطابقة لبحثك.', 
                  style: TextStyle(color: subTextColor(context), fontSize: 14)
                ),
              ],
            ),
          ),
        );
      }

      final maxBytes = controller.filteredAppsUsage.fold<int>(0, (max, app) => app.totalBytes > max ? app.totalBytes : max);

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.filteredAppsUsage.length,
        itemBuilder: (context, index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 400 + (index * 50).clamp(0, 400)),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: AppUsageTile(
                    app: controller.filteredAppsUsage[index],
                    controller: controller,
                    maxBytesInList: maxBytes,
                  ),
                ),
              );
            },
          );
        },
      );
    });
  }

  Widget _buildAmbientGlow(Color color) {
    return Container(
      width: 300, 
      height: 300, 
      decoration: BoxDecoration(
        shape: BoxShape.circle, 
        boxShadow: [
          BoxShadow(
            color: color, 
            blurRadius: 150, 
            spreadRadius: 50
          )
        ]
      )
    );
  }
}