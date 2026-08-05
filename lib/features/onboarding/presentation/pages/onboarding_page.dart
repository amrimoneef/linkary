import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingPage extends StatelessWidget {
  OnboardingPage({super.key});

  final OnboardingController controller = Get.put(OnboardingController());

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Listener(
        onPointerMove: (event) => controller.updateTouchPosition(event.localPosition),
        onPointerHover: (event) => controller.updateTouchPosition(event.localPosition),
        onPointerDown: (event) => controller.updateTouchPosition(event.localPosition),
        child: Stack(
          children: [
          // 1. Dynamic Gradient Background
          Obx(() {
            final slideColor = controller.slides[controller.currentPage.value].color;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    slideColor.withValues(alpha: 0.15),
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    slideColor.withValues(alpha: 0.05),
                  ],
                ),
              ),
            );
          }),

          // 2. Morphing, Parallax & Interactive Background Blobs
          Obx(() {
            final scrollOffset = controller.pageScrollPosition.value;
            final currentSlideColor = controller.slides[controller.currentPage.value].color;
            final touchX = controller.touchPosition.value.dx;
            final touchY = controller.touchPosition.value.dy;
            
            // Normalize touch impact (so it shifts the blobs slightly towards the touch)
            // Screen center assumption (approximate) to avoid heavy MediaQuery calls every frame
            final touchShiftX = touchX > 0 ? (touchX - 200) * 0.1 : 0.0;
            final touchShiftY = touchY > 0 ? (touchY - 400) * 0.1 : 0.0;

            return AnimatedBuilder(
              animation: controller.blobController,
              builder: (context, child) {
                final blobValue = controller.blobController.value;
                
                return Stack(
                  children: [
                    // Top Right Blob
                    Positioned(
                      top: -150 + (sin(blobValue * 2 * pi) * 60) - (scrollOffset * 40) + touchShiftY, 
                      right: -100 + (cos(blobValue * 2 * pi) * 60) + (scrollOffset * 30) + touchShiftX,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 700),
                        width: 400 + (sin(blobValue * pi) * 100),
                        height: 400 + (cos(blobValue * pi) * 100),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentSlideColor.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                    // Center Left Blob (New)
                    Positioned(
                      top: 200 + (cos(blobValue * 2 * pi) * 80) + (scrollOffset * 50) - touchShiftY * 0.5,
                      left: -150 + (sin(blobValue * 2 * pi) * 80) - (scrollOffset * 60) + touchShiftX * 0.5,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 700),
                        width: 350 + (cos(blobValue * 3 * pi) * 70),
                        height: 350 + (sin(blobValue * 3 * pi) * 70),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentSlideColor.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                    // Bottom Right Blob
                    Positioned(
                      bottom: -100 + (cos(blobValue * 2 * pi) * 50) + (scrollOffset * 60) - touchShiftY, 
                      right: -50 + (sin(blobValue * 2 * pi) * 50) - (scrollOffset * 40) - touchShiftX,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 700),
                        width: 350 + (cos(blobValue * 1.5 * pi) * 80),
                        height: 350 + (sin(blobValue * 1.5 * pi) * 80),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: currentSlideColor.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          }),

          // 3. Heavy Glassmorphism Overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70),
            child: Container(color: Colors.transparent),
          ),

          // 4. PageView for slides
          SafeArea(
            child: PageView.builder(
              controller: controller.pageController,
              onPageChanged: controller.onPageChanged,
              itemCount: controller.slides.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final slide = controller.slides[index];
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Continuous Floating Animation applied to the Card
                      AnimatedBuilder(
                        animation: controller.breathingController,
                        builder: (context, child) {
                          // Breathing float effect
                          final floatOffset = sin(controller.breathingController.value * pi) * 15;
                          return Transform.translate(
                            offset: Offset(0, -floatOffset),
                            child: child,
                          );
                        },
                        child: TweenAnimationBuilder<double>(
                          // Re-triggers on slide change
                          key: ValueKey('icon_$index'),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value.clamp(0.0, 1.2),
                              child: Opacity(
                                opacity: value.clamp(0.0, 1.0),
                                child: Container(
                                  padding: const EdgeInsets.all(45),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6),
                                    border: Border.all(
                                      color: slide.color.withValues(alpha: 0.5),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: slide.color.withValues(alpha: 0.3),
                                        blurRadius: 50,
                                        spreadRadius: 10,
                                      )
                                    ],
                                  ),
                                  child: Icon(slide.icon, size: 100, color: slide.color),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 70),
                      
                      // Staggered Title Entrance
                      TweenAnimationBuilder<double>(
                        key: ValueKey('title_$index'),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 30 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Staggered Description Entrance (Slightly longer duration)
                      TweenAnimationBuilder<double>(
                        key: ValueKey('desc_$index'),
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 40 * (1 - value)),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            slide.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 17,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              height: 1.6,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                );
              },
            ),
          ),

          // 5. Top Skip Button with Fade
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: Obx(() {
              return AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: controller.currentPage.value == controller.slides.length - 1 ? 0.0 : 1.0,
                child: TextButton(
                  onPressed: controller.completeOnboarding,
                  style: TextButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : Colors.grey[600],
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: const Text(
                    'تخطي',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }),
          ),

          // 6. Bottom Navigation & Indicators
          Positioned(
            bottom: 50,
            left: 30,
            right: 30,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Indicators
                Row(
                  children: List.generate(
                    controller.slides.length,
                    (index) => Obx(() {
                      final isActive = controller.currentPage.value == index;
                      final color = controller.slides[index].color;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(left: 6),
                        height: 8,
                        width: isActive ? 36 : 10,
                        decoration: BoxDecoration(
                          color: isActive ? color : (isDark ? Colors.white24 : Colors.black12),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: isActive ? [
                            BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 1)
                          ] : null,
                        ),
                      );
                    }),
                  ),
                ),

                // Next / Start Button with Pulsing Shadow
                AnimatedBuilder(
                  animation: controller.breathingController,
                  builder: (context, child) {
                    final pulse = sin(controller.breathingController.value * pi) * 10;
                    return Obx(() {
                      final isLast = controller.currentPage.value == controller.slides.length - 1;
                      final slideColor = controller.slides[controller.currentPage.value].color;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        width: isLast ? 140 : 70,
                        height: 60,
                        decoration: BoxDecoration(
                          color: slideColor,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: slideColor.withValues(alpha: 0.6),
                              blurRadius: 20 + pulse,
                              spreadRadius: pulse * 0.2,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            onTap: controller.next,
                            child: Center(
                              child: isLast
                                  ? const Text(
                                      'ابدأ الآن',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24), // Left arrow for RTL progression
                            ),
                          ),
                        ),
                      );
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    )
    );
  }
}
