import 'package:flutter/material.dart';

class SignalBarsWidget extends StatelessWidget {
  final int level; // 0 to 5
  final double height;
  final double width;

  const SignalBarsWidget({
    super.key,
    required this.level,
    this.height = 24.0,
    this.width = 30.0,
  });

  @override
  Widget build(BuildContext context) {
    final int safeLevel = level.clamp(0, 5);
    final double barWidth = (width - 8) / 5; // 4 spaces * 2 = 8

    Color getActiveColor() {
      if (safeLevel >= 4) return Colors.greenAccent;
      if (safeLevel >= 2) return Colors.orangeAccent;
      return Colors.redAccent;
    }

    final activeColor = getActiveColor();

    return SizedBox(
      width: width,
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(5, (index) {
          final barIndex = index + 1;
          final isActive = barIndex <= safeLevel;
          final barHeight = height * (barIndex / 5);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: barWidth,
            height: barHeight,
            decoration: BoxDecoration(
              color: isActive ? activeColor : Colors.grey.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(2),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 0.5,
                      )
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }
}
