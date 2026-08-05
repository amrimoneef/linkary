import 'dart:math';
import 'package:flutter/material.dart';

class SpeedometerGauge extends StatefulWidget {
  final double speed;
  final String phaseText;
  final Color glowColor;

  const SpeedometerGauge({
    Key? key,
    required this.speed,
    required this.phaseText,
    required this.glowColor,
  }) : super(key: key);

  @override
  State<SpeedometerGauge> createState() => _SpeedometerGaugeState();
}

class _SpeedometerGaugeState extends State<SpeedometerGauge> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _animation;
  double _oldSpeed = 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 300),
    );
    _animation = Tween<double>(begin: _oldSpeed, end: widget.speed).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void didUpdateWidget(SpeedometerGauge oldWidget) {
    if (oldWidget.speed != widget.speed) {
      _oldSpeed = oldWidget.speed;
      _animation = Tween<double>(begin: _oldSpeed, end: widget.speed).animate(CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ));
      _animController.forward(from: 0.0);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _SpeedometerPainter(
            speed: _animation.value,
            glowColor: widget.glowColor,
          ),
          child: SizedBox(
            width: 250,
            height: 250,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.phaseText,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    _animation.value.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  const Text(
                    'Mbps',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpeedometerPainter extends CustomPainter {
  final double speed;
  final Color glowColor;

  _SpeedometerPainter({required this.speed, required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - 15; // padding for glow

    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    final startAngle = pi * 0.8;
    final sweepAngle = pi * 1.4;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      backgroundPaint,
    );

    // Dynamic speed cap
    final maxSpeed = 100.0; 
    final value = min(speed, maxSpeed) / maxSpeed;
    final valueAngle = sweepAngle * value;

    if (valueAngle > 0) {
      final glowPaint = Paint()
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: [glowColor.withValues(alpha: 0.2), glowColor],
          stops: [0.0, 1.0],
          transform: GradientRotation(startAngle - pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        valueAngle,
        false,
        glowPaint,
      );

      final outerGlowPaint = Paint()
        ..color = glowColor.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        valueAngle,
        false,
        outerGlowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter oldDelegate) {
    return oldDelegate.speed != speed || oldDelegate.glowColor != glowColor;
  }
}
