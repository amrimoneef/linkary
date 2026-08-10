import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:math' as math;
import 'dart:ui';
import '../../domain/entities/proximity_level.dart';
import 'package:iconsax/iconsax.dart';

class ProximityRadarWidget extends StatefulWidget {
  final double percentage;
  final ProximityLevel level;
  final double distanceInMeters;
  final double distanceMin;
  final double distanceMax;
  final bool isScanning;

  const ProximityRadarWidget({
    Key? key,
    required this.percentage,
    required this.level,
    required this.distanceInMeters,
    required this.distanceMin,
    required this.distanceMax,
    required this.isScanning,
  }) : super(key: key);

  @override
  State<ProximityRadarWidget> createState() => _ProximityRadarWidgetState();
}

class _ProximityRadarWidgetState extends State<ProximityRadarWidget> with TickerProviderStateMixin {
  late AnimationController _sweepController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: _getPulseDuration(widget.level),
    );

    if (widget.isScanning) {
      _sweepController.repeat();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(ProximityRadarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isScanning != oldWidget.isScanning) {
      if (widget.isScanning) {
        _sweepController.repeat();
        _pulseController.repeat(reverse: true);
      } else {
        _sweepController.stop();
        _pulseController.stop();
        _pulseController.value = 0;
      }
    }

    if (oldWidget.level != widget.level && widget.isScanning) {
      _pulseController.duration = _getPulseDuration(widget.level);
      _pulseController.repeat(reverse: true);
    }
  }

  Duration _getPulseDuration(ProximityLevel level) {
    switch (level) {
      case ProximityLevel.freezing: return const Duration(milliseconds: 2000);
      case ProximityLevel.cold: return const Duration(milliseconds: 1500);
      case ProximityLevel.warm: return const Duration(milliseconds: 800);
      case ProximityLevel.hot: return const Duration(milliseconds: 400);
      case ProximityLevel.burning: return const Duration(milliseconds: 150);
    }
  }

  Color _getColor(ProximityLevel level) {
    switch (level) {
      case ProximityLevel.freezing: return const Color(0xFFEF4444); // أحمر (بعيد جداً)
      case ProximityLevel.cold:     return const Color(0xFFFF9800); // برتقالي (بعيد)
      case ProximityLevel.warm:     return const Color(0xFFFFC107); // أصفر (متوسط)
      case ProximityLevel.hot:      return const Color(0xFF2ECC71); // أخضر فاتح (قريب)
      case ProximityLevel.burning:  return const Color(0xFF00E676); // أخضر زاهي (قريب جداً)
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor(widget.level);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: Listenable.merge([_sweepController, _pulseController]),
      builder: (context, child) {
        return SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer Glowing Rings
              if (widget.isScanning) ...[
                Container(
                  width: 250 + (50 * _pulseController.value),
                  height: 250 + (50 * _pulseController.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.1 * (1 - _pulseController.value)),
                      width: 2,
                    ),
                  ),
                ),
                Container(
                  width: 200 + (100 * _pulseController.value),
                  height: 200 + (100 * _pulseController.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.05 * (1 - _pulseController.value)),
                      width: 1,
                    ),
                  ),
                ),
              ],
              
              // Custom Painter for Radar Sweep and Progress Arc
              CustomPaint(
                size: const Size(260, 260),
                painter: PremiumRadarPainter(
                  sweepAngle: _sweepController.value * 2 * math.pi,
                  percentage: widget.percentage,
                  color: color,
                  isDark: isDark,
                  isScanning: widget.isScanning,
                ),
              ),
              
              // Center Glass Orb
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.3),
                      border: Border.all(
                        color: color.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: widget.isScanning ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.2 + (0.2 * _pulseController.value)),
                          blurRadius: 30,
                          spreadRadius: 5,
                        )
                      ] : [],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isScanning ? Iconsax.radar5 : Iconsax.radar_14,
                            color: widget.isScanning ? color : Colors.grey,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${widget.percentage.toInt()}%',
                            style: TextStyle(
                              fontSize: 56,
                              height: 1.0,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black87,
                              shadows: [
                                if (widget.isScanning)
                                  Shadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 15,
                                  )
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.routing, size: 14, color: widget.isScanning ? color : Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDistanceText(widget.distanceInMeters, widget.isScanning),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: widget.isScanning ? color : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDistanceText(double distance, bool isScanning) {
    if (!isScanning) return 'غير نشط';
    if (distance <= 0.0) return 'جاري القياس...';
    if (distance < 1.0) {
      final cm = (distance * 100).round();
      return '$cm سم';
    }
    return '${distance.toStringAsFixed(1)} متر';
  }
}

class PremiumRadarPainter extends CustomPainter {
  final double sweepAngle;
  final double percentage;
  final Color color;
  final bool isDark;
  final bool isScanning;

  PremiumRadarPainter({
    required this.sweepAngle,
    required this.percentage,
    required this.color,
    required this.isDark,
    required this.isScanning,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Track Ring
    final trackPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi,
      2 * math.pi,
      false,
      trackPaint,
    );

    if (isScanning) {
      // Progress Arc
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);
      
      final sweep = (percentage / 100) * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi / 2, // Start at bottom
        sweep,
        false,
        progressPaint,
      );

      // Radar Sweep inside the arc
      final innerRadius = radius - 15;
      final sweepPaint = Paint()
        ..shader = SweepGradient(
          center: FractionalOffset.center,
          colors: [
            color.withValues(alpha: 0.0),
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.6),
          ],
          stops: const [0.0, 0.9, 1.0],
          transform: GradientRotation(sweepAngle - math.pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: innerRadius))
        ..style = PaintingStyle.fill;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        sweepAngle - math.pi / 2,
        math.pi / 2,
        true,
        sweepPaint,
      );
      
      // Grid lines inside radar
      final gridPaint = Paint()
        ..color = color.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
        
      canvas.drawCircle(center, innerRadius * 0.5, gridPaint);
      canvas.drawLine(Offset(center.dx, center.dy - innerRadius), Offset(center.dx, center.dy + innerRadius), gridPaint);
      canvas.drawLine(Offset(center.dx - innerRadius, center.dy), Offset(center.dx + innerRadius, center.dy), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PremiumRadarPainter oldDelegate) {
    return sweepAngle != oldDelegate.sweepAngle || 
           percentage != oldDelegate.percentage ||
           color != oldDelegate.color ||
           isScanning != oldDelegate.isScanning;
  }
}
