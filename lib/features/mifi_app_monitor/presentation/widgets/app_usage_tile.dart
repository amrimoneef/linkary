import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../domain/entities/app_usage_entity.dart';
import '../../domain/entities/app_category.dart';
import '../controllers/app_monitor_controller.dart';
import '../pages/app_detail_screen.dart';
import 'pulse_icon_wrapper.dart';

class AppUsageTile extends StatelessWidget {
  final AppUsageEntity app;
  final AppMonitorController controller;
  final int maxBytesInList;

  const AppUsageTile({
    super.key, 
    required this.app, 
    required this.controller,
    required this.maxBytesInList,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).brightness == Brightness.dark 
        ? Colors.white 
        : const Color(0xFF111827);
    final subText = Theme.of(context).brightness == Brightness.dark 
        ? Colors.white54 
        : const Color(0xFF6B7280);
    final cardBg = Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF16213E) 
        : const Color(0xFFE5E7EB);

    return InkWell(
      onTap: () => Get.to(
        () => AppDetailScreen(app: app),
        transition: Transition.rightToLeftWithFade,
        duration: const Duration(milliseconds: 400),
      ),
      borderRadius: BorderRadius.circular(15),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            // App Icon with Activity Radar (Pulse) and Category Marker
            PulseIconWrapper(
              isActive: (app.rxSpeed + app.txSpeed) > 0,
              pulseColor: app.category.color,
              child: Stack(
                children: [
                  Hero(
                    tag: 'app_icon_${app.packageName}',
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: cardBg.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: cardBg.withValues(alpha: 0.05)),
                      ),
                      child: app.iconData != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15), 
                              child: Image.memory(app.iconData!, fit: BoxFit.cover),
                            )
                          : Icon(Iconsax.global, color: subText.withValues(alpha: 0.5), size: 24),
                    ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        app.category.icon,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(width: 15),
            
            // Name and Progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          app.appName, 
                          style: TextStyle(
                            color: text, 
                            fontSize: 15, 
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        controller.formatBytes(app.totalBytes), 
                        style: TextStyle(
                          color: subText, 
                          fontSize: 13, 
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Multi-segment usage bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double rxRatio = maxBytesInList > 0 
                            ? (app.rxBytes / maxBytesInList).clamp(0.0, 1.0) 
                            : 0.0;
                        final double txRatio = maxBytesInList > 0 
                            ? (app.txBytes / maxBytesInList).clamp(0.0, 1.0) 
                            : 0.0;
                            
                        return Container(
                          height: 5,
                          width: constraints.maxWidth,
                          color: text.withValues(alpha: 0.05),
                          child: Row(
                            children: [
                              if (rxRatio > 0)
                                Container(
                                  width: constraints.maxWidth * rxRatio,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00D2FF), // Download color
                                  ),
                                ),
                              if (txRatio > 0)
                                Container(
                                  width: constraints.maxWidth * txRatio,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF00FF87), // Upload color
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Status indicators (System app / Real-time speed / Goal)
                  Obx(() {
                    final goalBytes = controller.appGoals[app.packageName];
                    final hasGoal = goalBytes != null && goalBytes > 0;
                    final double goalPercentage = hasGoal ? (app.totalBytes / goalBytes).clamp(0.0, 1.0) : 0.0;
                    final bool isGoalExceeded = goalPercentage >= 1.0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasGoal)
                          Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'سقف الاستهلاك: ${(goalPercentage * 100).toInt()}%',
                                      style: TextStyle(
                                        color: isGoalExceeded ? Colors.redAccent : subText,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      controller.formatBytes(goalBytes),
                                      style: TextStyle(color: subText, fontSize: 10),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: goalPercentage,
                                    minHeight: 3,
                                    backgroundColor: text.withValues(alpha: 0.05),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isGoalExceeded ? Colors.redAccent : const Color(0xFFF1C40F),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (app.isSystemApp || app.isCurrentlyActive)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                if (app.isSystemApp)
                                  _buildTag('النظام', Colors.orangeAccent),
                                if (app.isCurrentlyActive) ...[
                                  if (app.isSystemApp) const SizedBox(width: 8),
                                  _buildTag('نشط الآن', Colors.blueAccent),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${controller.formatSpeed(app.rxSpeed + app.txSpeed)}',
                                    style: TextStyle(color: Colors.blueAccent.withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label, 
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }
}
