import 'package:flutter/material.dart';

class QualityProgressBar extends StatelessWidget {
  final double percentage; // 0 to 100

  const QualityProgressBar({Key? key, required this.percentage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Colors from Red (Weak) to Green (Excellent)
    final List<Color> colors = [
      Colors.redAccent,
      Colors.orangeAccent,
      Colors.yellowAccent,
      Colors.lightGreenAccent,
      Colors.green,
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        // Clamp percentage between 0 and 100
        final double safePercentage = percentage.clamp(0, 100);
        // Calculate thumb position
        final double thumbPosition = (safePercentage / 100) * width;

        return Column(
          children: [
            // The bar and thumb
            SizedBox(
              height: 20,
              width: width,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Gradient Bar
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: colors,
                        stops: const [0.1, 0.3, 0.5, 0.7, 0.9],
                      ),
                    ),
                  ),
                  // Thumb
                  Positioned(
                    left: thumbPosition - 10, // -10 to center the thumb (size 20)
                    child: Container(
                      width: 20,
                      height: 20,
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
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Labels
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildLabel('ضعيف', Colors.redAccent),
                  const SizedBox(width: 5),
                  _buildLabel('متوسط', Colors.orangeAccent),
                  const SizedBox(width: 5),
                  _buildLabel('جيد', Colors.yellow),
                  const SizedBox(width: 5),
                  _buildLabel('جيد جداً', Colors.lightGreenAccent),
                  const SizedBox(width: 5),
                  _buildLabel('ممتاز', Colors.green),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
