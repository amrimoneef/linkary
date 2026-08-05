import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../domain/entities/app_category.dart';
import '../../domain/entities/app_usage_entity.dart';

class AppDetailInfographicWidget extends StatelessWidget {
  final AppUsageEntity app;
  final List<Map<String, dynamic>> historyData;
  final String dateStr;

  const AppDetailInfographicWidget({
    super.key,
    required this.app,
    required this.historyData,
    required this.dateStr,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate total from history if current is zero
    int totalBytesToShow = app.totalBytes;
    int rxBytesToShow = app.rxBytes;
    int txBytesToShow = app.txBytes;
    String periodLabel = 'استهلاك اليوم';

    if (totalBytesToShow == 0 && historyData.isNotEmpty) {
      totalBytesToShow = historyData.fold(0, (sum, day) => sum + (day['rx'] as int) + (day['tx'] as int));
      rxBytesToShow = historyData.fold(0, (sum, day) => sum + (day['rx'] as int));
      txBytesToShow = historyData.fold(0, (sum, day) => sum + (day['tx'] as int));
      periodLabel = 'إجمالي آخر 7 أيام';
    }

    return Material(
      color: Colors.transparent,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          width: 420,
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'اعدادات مودم Sam4G',
                        style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        'تقرير استهلاك التطبيق التفصيلي',
                        style: TextStyle(color: Colors.blueAccent.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Icon(Iconsax.radar5, color: Colors.blueAccent, size: 32),
                ],
              ),
              const SizedBox(height: 25),
              
              // App Info Card
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: app.iconData != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.memory(app.iconData!, fit: BoxFit.cover),
                            )
                          : const Icon(Iconsax.mobile, color: Colors.blueAccent, size: 35),
                    ),
                    const SizedBox(width: 22),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app.appName,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(app.category.icon, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                app.category.displayName,
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Total Usage (BIG)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    periodLabel,
                    style: TextStyle(color: Colors.blueAccent.withValues(alpha: 0.8), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatBytes(totalBytesToShow),
                    style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Breakdown (Download / Upload)
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem('تنزيل', _formatBytes(rxBytesToShow), const Color(0xFF2A64D9)),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: _buildStatItem('رفع', _formatBytes(txBytesToShow), const Color(0xFFFF8A65)),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Chart Section
              if (historyData.isNotEmpty) ...[
                 const Text(
                  'نشاط الاستهلاك',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 110,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: historyData.asMap().entries.map((e) {
                            final total = (e.value['rx'] + e.value['tx']) / 1048576;
                            return FlSpot(e.key.toDouble(), total);
                          }).toList(),
                          isCurved: true,
                          color: const Color(0xFF2A64D9),
                          barWidth: 5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [const Color(0xFF2A64D9).withValues(alpha: 0.35), const Color(0xFF2A64D9).withValues(alpha: 0.0)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              
              const SizedBox(height: 15),
              
              // Date & Time
              Row(
                children: [
                  const Icon(Iconsax.calendar_1, color: Colors.white24, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    dateStr,
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              
              const SizedBox(height: 25),
              
              // Footer
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFF2A64D9), borderRadius: BorderRadius.circular(12)),
                      child: const Text(
                        'حمّل تطبيق اعدادات مودم Sam4G الان',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'تم توليد التقرير بواسطة تطبيق اعدادات مودم Sam4G',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'monospace'), textDirection: TextDirection.ltr),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1073741824) return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
    if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(2)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '$bytes B';
  }
}
