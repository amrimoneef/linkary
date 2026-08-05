import 'package:flutter/material.dart';
import '../../domain/services/usage_pattern_analyzer.dart';
import 'package:iconsax/iconsax.dart';

class InsightCard extends StatelessWidget {
  final UsageInsight insight;

  const InsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Select colors based on usage context
    Color boxColor;
    Color iconColor;
    Color textColor;
    IconData iconData;

    if (insight.differencePercentage == 0) {
      boxColor = isDark ? const Color(0xFF16213E).withValues(alpha: 0.5) : const Color(0xFFF3F4F6);
      iconColor = const Color(0xFF4A90E2);
      textColor = isDark ? Colors.white70 : const Color(0xFF4B5563);
      iconData = Iconsax.info_circle;
    } else if (insight.isHigherThanAverage) {
      boxColor = const Color(0xFFEF4444).withValues(alpha: 0.1); // Reddish
      iconColor = const Color(0xFFEF4444);
      textColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C);
      iconData = Iconsax.trend_up;
    } else {
      boxColor = const Color(0xFF10B981).withValues(alpha: 0.1); // Greenish
      iconColor = const Color(0xFF10B981);
      textColor = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857);
      iconData = Iconsax.trend_down;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight.formattedMessage,
              style: TextStyle(
                color: textColor,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
