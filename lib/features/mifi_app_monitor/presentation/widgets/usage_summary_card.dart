import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import '../controllers/app_monitor_controller.dart';

class UsageSummaryCard extends StatelessWidget {
  final AppMonitorController controller;

  const UsageSummaryCard({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final cardBg = Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF16213E) 
        : const Color(0xFFE5E7EB);
    final glow = Theme.of(context).brightness == Brightness.dark 
        ? const Color(0xFF4A90E2) 
        : const Color(0xFF60A5FA);
    final text = Theme.of(context).brightness == Brightness.dark 
        ? Colors.white 
        : const Color(0xFF111827);
    final subText = Theme.of(context).brightness == Brightness.dark 
        ? Colors.white54 
        : const Color(0xFF6B7280);

    return Obx(() {
      // Calculate dynamic ratio for the progress bar
      double progressRatio = 0.0;
      if (controller.totalUsage.value > 0) {
        progressRatio = (controller.rxBytes.value / controller.totalUsage.value).clamp(0.0, 1.0);
      }

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
        decoration: BoxDecoration(
          color: cardBg.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: cardBg.withValues(alpha: 0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: _buildMiniStat(
                context, 
                Iconsax.arrow_down_2, 
                const Color(0xFF00D2FF), 
                'تحميل', 
                controller.formatBytes(controller.rxBytes.value),
                text,
                subText,
              ),
            ),
            
            // Central Progress Circle
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cardBg.withValues(alpha: 0.05),
                boxShadow: [
                  BoxShadow(
                    color: glow.withValues(alpha: 0.1),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                   SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: progressRatio,
                      strokeWidth: 10,
                      backgroundColor: cardBg.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(glow),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        child: Text(
                          controller.formatBytes(controller.totalUsage.value).split(' ')[0],
                          style: TextStyle(
                            color: text, 
                            fontSize: 26, 
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          )
                        ),
                      ),
                      Text(
                        controller.formatBytes(controller.totalUsage.value).split(' ')[1],
                        style: TextStyle(
                          color: subText, 
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        )
                      ),
                    ],
                  )
                ],
              ),
            ),
            
            Expanded(
              child: _buildMiniStat(
                context, 
                Iconsax.arrow_up_1, 
                const Color(0xFF00FF87), 
                'رفع', 
                controller.formatBytes(controller.txBytes.value),
                text,
                subText,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMiniStat(
    BuildContext context, 
    IconData icon, 
    Color color, 
    String title, 
    String value,
    Color text,
    Color subText,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value, 
            style: TextStyle(
              color: text, 
              fontSize: 14, // Slightly reduced font to fit better
              fontWeight: FontWeight.bold, 
              fontFamily: 'monospace'
            )
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title, 
          style: TextStyle(
            color: subText, 
            fontSize: 12
          )
        ),
      ],
    );
  }
}
