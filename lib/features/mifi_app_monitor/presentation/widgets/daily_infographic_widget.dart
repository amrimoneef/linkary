import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../domain/entities/app_usage_entity.dart';
import '../../domain/entities/app_category.dart';

class DailyInfographicWidget extends StatelessWidget {
  final List<AppUsageEntity> topApps;
  final Map<AppCategory, int> categoryTotals;
  final int totalBytes;
  final String dateStr;

  const DailyInfographicWidget({
    super.key,
    required this.topApps,
    required this.categoryTotals,
    required this.totalBytes,
    required this.dateStr,
  });

  @override
  Widget build(BuildContext context) {
    // 📐 Infographic dimensions (Standardized for sharing)
    return Material(
      color: Colors.transparent,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(30),
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
              // Header: Logo & Branding
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'اعدادات مودم Sam4G',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      Text(
                        'تقرير مراقب التطبيقات',
                        style: TextStyle(
                          color: Colors.blueAccent.withValues(alpha: 0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Iconsax.radar5, color: Colors.blueAccent, size: 32),
                ],
              ),
              
              const SizedBox(height: 30),
              
              // Highlights: Total Usage
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Iconsax.data, color: Colors.blueAccent.withValues(alpha: 0.6), size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'إجمالي الاستهلاك / اليوم',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _formatBytes(totalBytes),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.blueAccent.withValues(alpha: 0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Category Breakdown
              const Text(
                'توزيع حسب الفئات',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              ...categoryTotals.entries.take(4).map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                       Text(entry.key.icon, style: const TextStyle(fontSize: 14)),
                       const SizedBox(width: 10),
                       Text(entry.key.displayName, style: const TextStyle(color: Colors.white, fontSize: 13)),
                       const Spacer(),
                       Text(
                         _formatBytes(entry.value), 
                         style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                         textDirection: TextDirection.ltr,
                       ),
                    ],
                  ),
                );
              }),
      
              const SizedBox(height: 30),
              
              // Top Apps List
              const Text(
                'أكثر التطبيقات استهلاكاً',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              ...topApps.take(4).map((app) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                       // App Icon
                       Container(
                         width: 24,
                         height: 24,
                         decoration: BoxDecoration(
                           color: Colors.white.withValues(alpha: 0.05),
                           borderRadius: BorderRadius.circular(6),
                         ),
                         child: app.iconData != null
                             ? ClipRRect(
                                 borderRadius: BorderRadius.circular(6),
                                 child: Image.memory(app.iconData!, fit: BoxFit.cover),
                               )
                             : const Icon(Iconsax.mobile, color: Colors.blueAccent, size: 14),
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: Text(
                           app.appName,
                           style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                           overflow: TextOverflow.ellipsis,
                         ),
                       ),
                       Text(
                         _formatBytes(app.totalBytes),
                         style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                         textDirection: TextDirection.ltr,
                       ),
                    ],
                  ),
                );
              }),
              
              const SizedBox(height: 30),
              
              // Footer
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'حمّل تطبيق اعدادات مودم Sam4G الان',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'سهّل اتصالك.. وتحكّم في شبكتك',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 9),
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

  String _formatBytes(int bytes) {
    if (bytes >= 1073741824) return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
    if (bytes >= 1048576) return '${(bytes / 1048576).toStringAsFixed(2)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '$bytes B';
  }
}
