import 'dart:math' as math;
import 'package:flutter/material.dart';

class CompositeScoreGauge extends StatelessWidget {
  final double score;
  final Color baseColor;

  const CompositeScoreGauge({
    Key? key,
    required this.score,
    required this.baseColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: score),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Ambient glow
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.15),
                    blurRadius: 60,
                    spreadRadius: 20,
                  )
                ],
              ),
            ),
            
            // The Gauge CustomPaint
            SizedBox(
              width: 240,
              height: 240,
              child: CustomPaint(
                painter: _GaugePainter(
                  score: value,
                  color: baseColor,
                ),
              ),
            ),

            // Number in the middle
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${value.toInt()}%',
                  style: TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: baseColor.withValues(alpha: 0.8),
                        blurRadius: 20,
                      )
                    ],
                  ),
                ),
                const Text(
                  'رادار سام المتقدم',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                Image.asset(
                  'assets/images/الشعار ابيض.png',
                  height: 30,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double score;
  final Color color;

  _GaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 18.0;

    // Background track
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // We draw an arc from 135 degrees to 45 degrees (270 degrees total)
    const startAngle = math.pi * 0.75;
    const sweepAngle = math.pi * 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Foreground track (The score)
    final progress = (score / 100).clamp(0.0, 1.0);
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth * 2
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final actualSweep = sweepAngle * progress;

    if (actualSweep > 0) {
      // Glow
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        actualSweep,
        false,
        glowPaint,
      );
      // Main track
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        actualSweep,
        false,
        fgPaint,
      );
    }
    
    // Draw tick marks
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 2;
      
    for (int i = 0; i <= 10; i++) {
      final angle = startAngle + (sweepAngle * (i / 10));
      final innerRadius = radius - strokeWidth + 5;
      final outerRadius = radius - strokeWidth - 5;
      
      final p1 = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );
      
      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}
