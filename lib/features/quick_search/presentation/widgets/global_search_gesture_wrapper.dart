import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../modem_auth/presentation/controllers/auth_controller.dart';
import '../controllers/global_search_notch_controller.dart';
import '../pages/quick_search_page.dart';

class GlobalSearchGestureWrapper extends StatefulWidget {
  final Widget child;

  const GlobalSearchGestureWrapper({super.key, required this.child});

  @override
  State<GlobalSearchGestureWrapper> createState() => _GlobalSearchGestureWrapperState();
}

class _GlobalSearchGestureWrapperState extends State<GlobalSearchGestureWrapper>
    with SingleTickerProviderStateMixin {
  late final GlobalSearchNotchController controller;

  // Local listenables for ultra-smooth 120FPS rendering without Obx/Builder rebuild collisions
  final ValueNotifier<double> _dragDistance = ValueNotifier<double>(0.0);
  final ValueNotifier<double> _touchY = ValueNotifier<double>(350.0);
  final ValueNotifier<bool> _isReached = ValueNotifier<bool>(false);

  Offset _startPos = Offset.zero;
  int? _activePointerId;
  bool _isTrackingDrag = false;
  bool _hasVibrated = false;

  late final AnimationController _springController;
  Animation<double>? _springAnim;

  static const double _threshold = 75.0;
  static const double _maxDrag = 125.0;

  @override
  void initState() {
    super.initState();
    // Ensure controller is registered for DI
    if (!Get.isRegistered<GlobalSearchNotchController>()) {
      controller = Get.put(GlobalSearchNotchController(), permanent: true);
    } else {
      controller = Get.find<GlobalSearchNotchController>();
    }

    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _springController.addListener(() {
      if (_springAnim != null) {
        _dragDistance.value = _springAnim!.value;
      }
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    _dragDistance.dispose();
    _touchY.dispose();
    _isReached.dispose();
    super.dispose();
  }

  bool _isEligible(BuildContext context) {
    // Hide when keyboard is open
    if (MediaQuery.of(context).viewInsets.bottom > 50) return false;

    // Hide if Quick Search is already open
    if (QuickSearchPage.isOpen) return false;

    // Only allow when authenticated and ready
    if (!Get.isRegistered<AuthController>()) return false;
    final auth = Get.find<AuthController>();
    if (auth.currentSN.value == null || auth.currentSN.value!.isEmpty) return false;

    return true;
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!_isEligible(context)) return;
    if (event.position.dx > 70.0) return;

    _startPos = event.position;
    _activePointerId = event.pointer;
    _isTrackingDrag = false;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointerId || !_isEligible(context)) return;

    final dx = event.position.dx - _startPos.dx;
    final dy = event.position.dy - _startPos.dy;

    if (!_isTrackingDrag) {
      // Detect deliberate swipe from Left to Right:
      // dx > 18px and predominantly horizontal (dx > dy.abs() * 1.3)
      if (dx > 45.0 && dx > dy.abs() * 1.8) {
        _isTrackingDrag = true;
        _springController.stop();
        _hasVibrated = false;
        _isReached.value = false;
        _touchY.value = event.position.dy;
      } else if (dy.abs() > 22.0 || dx < -20.0) {
        _activePointerId = null;
        return;
      }
    }

    if (_isTrackingDrag) {
      _touchY.value = event.position.dy;

      final rawDelta = event.position.dx - _startPos.dx;
      if (rawDelta <= 0) {
        _dragDistance.value = 0.0;
        if (_isReached.value) {
          _isReached.value = false;
          _hasVibrated = false;
          HapticFeedback.selectionClick();
        }
        return;
      }

      double clamped = rawDelta;
      if (clamped > _maxDrag) {
        clamped = _maxDrag + (clamped - _maxDrag) * 0.2;
      }
      _dragDistance.value = clamped;

      if (_dragDistance.value >= _threshold) {
        if (!_hasVibrated) {
          HapticFeedback.mediumImpact();
          _hasVibrated = true;
          _isReached.value = true;
        }
      } else {
        if (_hasVibrated) {
          _hasVibrated = false;
          _isReached.value = false;
          HapticFeedback.selectionClick();
        }
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer == _activePointerId && _isTrackingDrag) {
      if (_dragDistance.value >= _threshold) {
        HapticFeedback.lightImpact();
        _resetSpring();
        QuickSearchPage.open(context);
      } else {
        _resetSpring();
      }
    }
    _isTrackingDrag = false;
    _activePointerId = null;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer == _activePointerId && _isTrackingDrag) {
      _resetSpring();
    }
    _isTrackingDrag = false;
    _activePointerId = null;
  }

  void _resetSpring() {
    _springAnim = Tween<double>(
      begin: _dragDistance.value,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _springController,
      curve: Curves.easeOutCubic,
    ));
    _springController.forward(from: 0.0);
    _isReached.value = false;
    _hasVibrated = false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: Stack(
        children: [
          // 1. App Navigation Route Content (Never re-rendered during drag gestures)
          widget.child,

          // 2. Black Liquid Swipe Overlay
          AnimatedBuilder(
            animation: Listenable.merge([_dragDistance, _touchY, _isReached]),
            builder: (context, _) {
              if (!_isEligible(context)) return const SizedBox.shrink();

              final dragDist = _dragDistance.value;
              final isReached = _isReached.value;
              if (dragDist <= 0.5) return const SizedBox.shrink();

              final progress = (dragDist / _threshold).clamp(0.0, 1.0);
              final touchY = _touchY.value;
              final screenSize = MediaQuery.of(context).size;
              final minY = 100.0;
              final maxY = (screenSize.height - 100.0) > minY ? (screenSize.height - 100.0) : minY;
              final clampedY = touchY.clamp(minY, maxY);

              final circleRadius = (18.0 + (progress * 4.0)).clamp(18.0, 22.0);
              final crestX = dragDist;
              final circleCenterX = (crestX - circleRadius * 0.85).clamp(0.0, crestX);

              return Stack(
                children: [
                  // Canvas Liquid Wave
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: LiquidWavePainter(
                          dragDistance: dragDist,
                          touchY: clampedY,
                          isReached: isReached,
                          progress: progress,
                        ),
                      ),
                    ),
                  ),

                  // Search Icon Badge at the Crest of the Liquid Wave
                  if (dragDist > 8.0)
                    Positioned(
                      left: circleCenterX - circleRadius,
                      top: clampedY - circleRadius,
                      width: circleRadius * 2,
                      height: circleRadius * 2,
                      child: IgnorePointer(
                        child: Center(
                          child: Icon(
                            Iconsax.search_normal_1,
                            size: 17.0 + (progress * 4.0),
                            color: isReached
                                ? const Color(0xFF4A90E2)
                                : Colors.white.withValues(alpha: 0.85 + (progress * 0.15)),
                          ),
                        ),
                      ),
                    ),

                  // Floating Interactive Label (Expands as the user pulls right)
                  if (progress > 0.3)
                    Positioned(
                      left: circleCenterX + circleRadius + 10.0,
                      top: clampedY - 18.0,
                      child: IgnorePointer(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: progress > 0.35 ? 1.0 : 0.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0C1019).withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isReached
                                    ? const Color(0xFF4A90E2)
                                    : Colors.white.withValues(alpha: 0.15 + (progress * 0.2)),
                                width: isReached ? 1.5 : 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isReached
                                      ? const Color(0xFF4A90E2).withValues(alpha: 0.4)
                                      : Colors.black.withValues(alpha: 0.4),
                                  blurRadius: isReached ? 16 : 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isReached ? 'أفلت للفتح' : 'البحث الشامل',
                                  style: TextStyle(
                                    color: isReached
                                        ? const Color(0xFF4A90E2)
                                        : Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  isReached ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                                  size: 13,
                                  color: isReached
                                      ? const Color(0xFF4A90E2)
                                      : Colors.white.withValues(alpha: 0.6),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// CustomPainter for rendering an organic, liquid wave (Liquid Swipe) in obsidian black
class LiquidWavePainter extends CustomPainter {
  final double dragDistance;
  final double touchY;
  final bool isReached;
  final double progress;

  LiquidWavePainter({
    required this.dragDistance,
    required this.touchY,
    required this.isReached,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dragDistance <= 0.5) return;

    final minY = 100.0;
    final maxY = (size.height - 100.0) > minY ? (size.height - 100.0) : minY;
    final y0 = touchY.clamp(minY, maxY);
    final w = dragDistance;
    final h = (95.0 + (progress * 30.0)).clamp(95.0, 130.0); // wave half height

    final path = Path();
    path.moveTo(0, y0 - h);

    // 1. Top inflection and curve towards crest
    path.cubicTo(
      0, y0 - h * 0.72,
      w * 0.14, y0 - h * 0.52,
      w * 0.32, y0 - h * 0.38,
    );
    path.cubicTo(
      w * 0.62, y0 - h * 0.20,
      w, y0 - h * 0.10,
      w, y0,
    );

    // 2. Bottom crest and inflection returning to wall
    path.cubicTo(
      w, y0 + h * 0.10,
      w * 0.62, y0 + h * 0.20,
      w * 0.32, y0 + h * 0.38,
    );
    path.cubicTo(
      w * 0.14, y0 + h * 0.52,
      0, y0 + h * 0.72,
      0, y0 + h,
    );

    path.lineTo(0, y0 - h);
    path.close();

    // 🌟 A. Draw Shadow / Glow
    if (isReached) {
      final glowPaint = Paint()
        ..color = const Color(0xFF4A90E2).withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20.0);
      canvas.drawPath(path, glowPaint);
    } else if (progress > 0.1) {
      final shadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.5 * progress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14.0);
      canvas.drawPath(path, shadowPaint);
    }

    // 🌟 B. Draw Liquid Body with Deep Obsidian Gradient
    final rect = Rect.fromLTRB(0, y0 - h, w, y0 + h);
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF080C14), // Deep black near screen edge
          Color(0xFF101726), // Obsidian black at crest
        ],
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bodyPaint);

    // 🌟 C. Draw Liquid Border / Outline
    final borderPaint = Paint()
      ..color = isReached
          ? const Color(0xFF4A90E2)
          : Colors.white.withValues(alpha: 0.18 + (progress * 0.25))
      ..style = PaintingStyle.stroke
      ..strokeWidth = isReached ? 2.0 : 1.2;
    canvas.drawPath(path, borderPaint);

    // 🌟 D. Draw Circular Crest Badge
    if (w > 8.0) {
      final circleRadius = (18.0 + (progress * 4.0)).clamp(18.0, 22.0);
      final circleX = (w - circleRadius * 0.85).clamp(0.0, w);
      final circleCenter = Offset(circleX, y0);

      // Circle background fill
      final circleBgPaint = Paint()
        ..color = isReached ? const Color(0xFF0D1728) : const Color(0xFF141A28)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(circleCenter, circleRadius, circleBgPaint);

      // Circle border
      final circleBorderPaint = Paint()
        ..color = isReached
            ? const Color(0xFF4A90E2)
            : Colors.white.withValues(alpha: 0.28 + (progress * 0.2))
        ..style = PaintingStyle.stroke
        ..strokeWidth = isReached ? 1.8 : 1.0;
      canvas.drawCircle(circleCenter, circleRadius, circleBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LiquidWavePainter oldDelegate) {
    return oldDelegate.dragDistance != dragDistance ||
        oldDelegate.touchY != touchY ||
        oldDelegate.isReached != isReached ||
        oldDelegate.progress != progress;
  }
}
