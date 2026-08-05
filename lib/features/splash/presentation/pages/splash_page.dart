import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/splash_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late SplashController controller;

  late AnimationController _rotateController;
  late AnimationController _slowRotateController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    controller = Get.put(SplashController(
      networkInfo: Get.find(),
      authController: Get.find(),
    ));

    // Fast rotation for the 1/3 arc
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Slow rotation for background orbs
    _slowRotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _slowRotateController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  IconData _getCurrentIcon(double progress) {
    if (progress <= 0.25) return Icons.dns_rounded;
    if (progress <= 0.50) return Icons.router_rounded;
    if (progress <= 0.75) return Icons.wifi_find_rounded;
    if (progress < 1.0) return Icons.security_rounded;
    return Icons.check_circle_rounded;
  }

  Color _getIconColor(double progress) {
    if (progress >= 1.0) return AppColors.accentGreen;
    return AppColors.primaryBlue;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: Stack(
        children: [
          // ── LAYER 1: Playful Background Orbs (2 Colors Only) ──
          _buildAnimatedBackground(size, isDark),

          // ── LAYER 2: Main Content ──
          FadeTransition(
            opacity: _fadeAnim,
            child: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Dynamic Changing Icon inside Rotating Arc
                    _buildDynamicLoader(isDark),

                    const SizedBox(height: 56),

                    // App Name (Playful & Lively)
                    Image.asset(
                      isDark
                          ? 'assets/images/الشعار ابيض.png'
                          : 'assets/images/الشعار اسود.png',
                      height: 60,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 12),

                    // Status and Progress directly below
                    Obx(() {
                      final progress = controller.loadingProgress.value;
                      return Column(
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              controller.loadingText.value,
                              key: ValueKey<String>(controller.loadingText.value),
                              style: AppTextStyles.titleMedium(isDark).copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              '${(progress * 100).toInt()}%',
                              key: ValueKey<int>((progress * 100).toInt()),
                              style: AppTextStyles.displayMedium(isDark).copyWith(
                                color: progress >= 1.0 ? AppColors.accentGreen : AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicLoader(bool isDark) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background track circle
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
              width: 4,
            ),
          ),
        ),
        // Inner soft glow background
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark 
                ? AppColors.primaryBlue.withValues(alpha: 0.1) 
                : AppColors.primaryBlue.withValues(alpha: 0.05),
          ),
        ),
        // Rotating 1/3 arc
        AnimatedBuilder(
          animation: _rotateController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotateController.value * 2 * math.pi,
              child: CustomPaint(
                size: const Size(150, 150),
                painter: ArcPainter(
                  color: AppColors.primaryBlue, // A playful bright line color
                  strokeWidth: 4,
                ),
              ),
            );
          },
        ),
        // Central Animated Switcher for changing icons without overlap
        Obx(() {
          final progress = controller.loadingProgress.value;
          final currentIcon = _getCurrentIcon(progress);
          final iconColor = _getIconColor(progress);

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  ...previousChildren,
                  if (currentChild != null) currentChild,
                ],
              );
            },
            child: SizedBox(
              key: ValueKey<IconData>(currentIcon),
              width: 56,
              height: 56,
              child: Icon(
                currentIcon,
                size: 56,
                color: iconColor,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAnimatedBackground(Size size, bool isDark) {
    return AnimatedBuilder(
      animation: _slowRotateController,
      builder: (context, child) {
        final angle = _slowRotateController.value * 2 * math.pi;
        final baseAlpha = isDark ? 0.15 : 0.08;
        
        return Stack(
          children: [
            Positioned(
              left: size.width * 0.5 + math.cos(angle) * size.width * 0.3 - 200,
              top: size.height * 0.3 + math.sin(angle) * size.height * 0.2 - 200,
              child: _glowOrb(color: AppColors.primaryBlue, size: 450, opacity: baseAlpha),
            ),
            Positioned(
              right: size.width * 0.5 + math.cos(angle + math.pi) * size.width * 0.3 - 200,
              bottom: size.height * 0.3 + math.sin(angle + math.pi) * size.height * 0.2 - 200,
              child: _glowOrb(color: AppColors.accentGreen, size: 450, opacity: baseAlpha),
            ),
            // Ultra blur for mesh effect
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ],
        );
      },
    );
  }

  Widget _glowOrb({required Color color, required double size, required double opacity}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: opacity),
            blurRadius: size / 2,
            spreadRadius: size / 4,
          ),
        ],
      ),
    );
  }
}

class ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  ArcPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    // Draw 1/3 of a circle = 2 * pi / 3 radians. Start at top (-pi/2)
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi / 3, false, paint);
  }

  @override
  bool shouldRepaint(covariant ArcPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
  }
}
