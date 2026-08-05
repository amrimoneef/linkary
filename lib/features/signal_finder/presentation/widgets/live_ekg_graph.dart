import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/entities/signal_point.dart';

class LiveEkgGraph extends StatelessWidget {
  final List<SignalPoint> points; // last 15 points
  final double currentScore;

  const LiveEkgGraph({
    Key? key,
    required this.points,
    required this.currentScore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          size: Size.infinite,
          painter: _EkgPainter(points: points),
        ),
      ),
    );
  }
}

class _EkgPainter extends CustomPainter {
  final List<SignalPoint> points;
  static const int maxPoints = 15;

  _EkgPainter({required this.points});

  Color _getColor(double score) {
    if (score == 0) return Colors.grey;
    if (score <= 25) return Colors.redAccent;
    if (score <= 50) return Colors.orangeAccent;
    if (score <= 79) return Colors.blueAccent;
    return Colors.greenAccent;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final double width = size.width;
    final double height = size.height;
    final double dx = width / (maxPoints - 1);

    // 1. Draw Reference Lines
    _drawReferenceLine(canvas, width, height, 0.8, Colors.greenAccent.withValues(alpha: 0.3));
    _drawReferenceLine(canvas, width, height, 0.5, Colors.blueAccent.withValues(alpha: 0.3));
    _drawReferenceLine(canvas, width, height, 0.25, Colors.redAccent.withValues(alpha: 0.3));

    // 2. Prepare points
    final Path path = Path();
    List<Offset> scaledPoints = [];
    
    // Calculate starting X so newer points appear on the right and it 'scrolls'
    double startX = width - ((points.length - 1) * dx);
    if (startX < 0) startX = 0;

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      // Y is inverted (0 is top, height is bottom in canvas)
      final y = height - (point.compositeScore / 100 * height);
      final x = startX + (i * dx);
      scaledPoints.add(Offset(x, y));
    }

    // Move to first point
    path.moveTo(scaledPoints.first.dx, scaledPoints.first.dy);

    // Draw lines to other points
    for (int i = 1; i < scaledPoints.length; i++) {
        // smooth curve
        final p0 = scaledPoints[i - 1];
        final p1 = scaledPoints[i];
        final midX = (p0.dx + p1.dx) / 2;
        path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    // Get current line color from the last point
    final currentColor = _getColor(points.last.compositeScore);

    // 3. Draw gradient fill under the line
    final fillPath = Path.from(path);
    fillPath.lineTo(scaledPoints.last.dx, height);
    fillPath.lineTo(scaledPoints.first.dx, height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          currentColor.withValues(alpha: 0.3),
          currentColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height))
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(fillPath, fillPaint);

    // 4. Draw Glow Line (Blurred)
    final glowPaint = Paint()
      ..color = currentColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawPath(path, glowPaint);

    // 5. Draw Sharp Line
    final linePaint = Paint()
      ..color = currentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // 6. Draw glowing dot at the end
    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
      
    canvas.drawCircle(scaledPoints.last, 5, dotPaint);
  }

  void _drawReferenceLine(Canvas canvas, double width, double height, double percent, Color color) {
    final y = height - (height * percent);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
      
    // Draw dashed line
    const dashWidth = 5.0;
    const dashSpace = 5.0;
    double startX = 0;
    while (startX < width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _EkgPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}
