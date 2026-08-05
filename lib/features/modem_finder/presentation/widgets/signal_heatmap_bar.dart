import 'package:flutter/material.dart';

class SignalHeatmapBar extends StatelessWidget {
  final double percentage; // 0.0 to 100.0

  const SignalHeatmapBar({
    Key? key,
    required this.percentage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text('❄️', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final barWidth = constraints.maxWidth;
                const indicatorSize = 24.0;
                final leftPosition = (percentage / 100) * (barWidth - indicatorSize);

                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // Gradient bar
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFEF4444), // أحمر (بعيد جداً)
                            Color(0xFFFF9800), // برتقالي
                            Color(0xFFFFC107), // أصفر
                            Color(0xFF2ECC71), // أخضر فاتح
                            Color(0xFF00E676), // أخضر زاهي (قريب جداً)
                          ],
                        ),
                      ),
                    ),
                    // Indicator
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      left: leftPosition.clamp(0.0, barWidth - indicatorSize),
                      child: Container(
                        width: indicatorSize,
                        height: indicatorSize,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                          border: Border.all(color: Colors.grey.shade300, width: 2),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          const Text('🔥', style: TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}
