import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../controllers/app_monitor_controller.dart';
import '../../domain/entities/app_category.dart';

class CategoryBreakdownCard extends StatelessWidget {
  final AppMonitorController controller;

  const CategoryBreakdownCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF111827);
    final subText = Theme.of(context).brightness == Brightness.dark ? Colors.white54 : const Color(0xFF6B7280);
    final cardBg = Theme.of(context).brightness == Brightness.dark ? const Color(0xFF16213E) : const Color(0xFFE5E7EB);

    return Obx(() {
      if (controller.categoryTotals.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(bottom: 25),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: cardBg.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'توزيع الاستهلاك حسب الصنف',
              style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                // Pie Chart
                SizedBox(
                  width: 130,
                  height: 130,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 35,
                      sections: _buildSections(controller.categoryTotals),
                    ),
                  ),
                ),
                const SizedBox(width: 25),
                // Legend
                Expanded(
                  child: Column(
                    children: _buildLegendItems(controller.categoryTotals, context),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  List<PieChartSectionData> _buildSections(Map<AppCategory, int> totals) {
    final totalBytes = totals.values.fold<int>(0, (sum, val) => sum + val);
    if (totalBytes == 0) return [];

    return totals.entries.map((e) {
      final percentage = (e.value / totalBytes);
      return PieChartSectionData(
        color: e.key.color,
        value: e.value.toDouble(),
        title: '${(percentage * 100).toStringAsFixed(0)}%',
        radius: 25,
        titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  List<Widget> _buildLegendItems(Map<AppCategory, int> totals, BuildContext context) {
    final text = Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF111827);
    final subText = Theme.of(context).brightness == Brightness.dark ? Colors.white54 : const Color(0xFF6B7280);
    
    // Sort by consumption
    final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    // Take top 4 or all if less
    return sorted.take(4).map((e) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: e.key.color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                e.key.displayName, 
                style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              controller.formatBytes(e.value),
              style: TextStyle(color: subText, fontSize: 11, fontFamily: 'monospace'),
            ),
          ],
        ),
      );
    }).toList();
  }
}
