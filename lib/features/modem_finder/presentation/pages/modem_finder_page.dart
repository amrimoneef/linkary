import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../domain/entities/proximity_level.dart';
import '../controllers/modem_finder_controller.dart';
import '../widgets/proximity_radar_widget.dart';
import 'modem_finder_settings_page.dart';

class ModemFinderPage extends StatefulWidget {
  const ModemFinderPage({Key? key}) : super(key: key);

  @override
  State<ModemFinderPage> createState() => _ModemFinderPageState();
}

class _ModemFinderPageState extends State<ModemFinderPage> with SingleTickerProviderStateMixin {
  final controller = Get.find<ModemFinderController>();
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 1.0, curve: Curves.easeOut)),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic)),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF070B19) : const Color(0xFFF4F7FC),
      body: Obx(() {
        final color = _getColorForLevel(controller.proximityLevel.value);
        
        return Stack(
          children: [
            // Ambient Animated Background Glow
            AnimatedPositioned(
              duration: const Duration(milliseconds: 1500),
              curve: Curves.easeInOutSine,
              top: controller.isScanning.value ? 0 : -200,
              left: -150,
              right: -150,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 1000),
                height: MediaQuery.of(context).size.width + 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withValues(alpha: 0.25),
                      color.withValues(alpha: 0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
            
            // Floating Particles or extra ambient glow can go here...
            
            SafeArea(
              child: Column(
                children: [
                  // Premium Custom App Bar
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                              onPressed: () => Get.back(),
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'أين المودم؟',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: IconButton(
                              icon: const Icon(Iconsax.setting_2, size: 22),
                              onPressed: () => Get.to(() => const ModemFinderSettingsPage()),
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (!controller.isConnectedToWifi.value)
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(30),
                                decoration: BoxDecoration(
                                  color: AppColors.errorRed.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3), width: 2),
                                ),
                                child: const Icon(Iconsax.wifi_square, size: 70, color: AppColors.errorRed),
                              ),
                              const SizedBox(height: 30),
                              Text('غير متصل بشبكة المودم', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black87)),
                              const SizedBox(height: 12),
                              Text('يرجى الاتصال بالواي فاي أولاً لتبدأ عملية البحث الاستكشافية', 
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 15, color: isDark ? Colors.white60 : Colors.black54, height: 1.5)
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              const SizedBox(height: 15),
                              
                              // Sleek Network Badge
                              GlassCard(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                borderRadius: 30,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Iconsax.wifi, size: 16, color: AppColors.primaryBlue),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      controller.connectedSSID.value,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.1,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const Spacer(),
                              
                              // Hero Radar Widget
                              ProximityRadarWidget(
                                percentage: controller.proximityPercentage.value,
                                level: controller.proximityLevel.value,
                                distanceInMeters: controller.estimatedDistance.value,
                                distanceMin: controller.distanceMin.value,
                                distanceMax: controller.distanceMax.value,
                                isScanning: controller.isScanning.value,
                              ),
                              
                              if (!controller.isCalibrated.value)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16.0),
                                  child: GestureDetector(
                                    onTap: () => Get.to(() => const ModemFinderSettingsPage()),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentOrange.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.5)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Iconsax.warning_2, size: 16, color: AppColors.accentOrange),
                                          const SizedBox(width: 8),
                                          Text(
                                            'قم بمعايرة المودم لدقة أفضل',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              
                              const Spacer(),
                              
                              // Floating Controls Panel (Premium Look)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                                child: GlassCard(
                                  padding: const EdgeInsets.all(24),
                                  borderRadius: 35,
                                  child: Column(
                                    children: [
                                      // Dynamic Guidance Message
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: color.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Icon(Iconsax.radar_2, color: color, size: 24),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: AnimatedSwitcher(
                                              duration: const Duration(milliseconds: 400),
                                              switchInCurve: Curves.easeOut,
                                              switchOutCurve: Curves.easeIn,
                                              child: Text(
                                                controller.guidanceMessage.value,
                                                key: ValueKey(controller.guidanceMessage.value),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.4,
                                                  color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 24),
                                      Container(height: 1, color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
                                      const SizedBox(height: 24),

                                      // Geiger & Action Buttons
                                      Row(
                                        children: [
                                          // Geiger Mode Toggle
                                          Expanded(
                                            flex: 2,
                                            child: InkWell(
                                              onTap: controller.toggleGeigerMode,
                                              borderRadius: BorderRadius.circular(20),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                                decoration: BoxDecoration(
                                                  color: controller.isGeigerMode.value 
                                                      ? AppColors.accentOrange.withValues(alpha: 0.15)
                                                      : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: controller.isGeigerMode.value 
                                                        ? AppColors.accentOrange.withValues(alpha: 0.3)
                                                        : Colors.transparent,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Iconsax.sound, 
                                                      color: controller.isGeigerMode.value ? AppColors.accentOrange : Colors.grey,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'نبضات',
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        color: controller.isGeigerMode.value 
                                                            ? AppColors.accentOrange
                                                            : (isDark ? Colors.white70 : Colors.black54),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          // Main Action Button
                                          Expanded(
                                            flex: 3,
                                            child: InkWell(
                                              onTap: () {
                                                if (controller.isScanning.value) {
                                                  controller.stopScanning();
                                                } else {
                                                  controller.startScanning();
                                                }
                                              },
                                              borderRadius: BorderRadius.circular(20),
                                              child: AnimatedContainer(
                                                duration: const Duration(milliseconds: 300),
                                                padding: const EdgeInsets.symmetric(vertical: 16),
                                                decoration: BoxDecoration(
                                                  color: controller.isScanning.value 
                                                      ? AppColors.errorRed 
                                                      : AppColors.primaryBlue,
                                                  borderRadius: BorderRadius.circular(20),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: (controller.isScanning.value ? AppColors.errorRed : AppColors.primaryBlue).withValues(alpha: 0.3),
                                                      blurRadius: 15,
                                                      offset: const Offset(0, 5),
                                                    )
                                                  ],
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      controller.isScanning.value ? Iconsax.stop_circle : Iconsax.radar,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      controller.isScanning.value ? 'إيقاف' : 'ابدأ البحث',
                                                      style: const TextStyle(
                                                        fontSize: 16, 
                                                        fontWeight: FontWeight.w900, 
                                                        color: Colors.white,
                                                        letterSpacing: 1.0,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Color _getColorForLevel(ProximityLevel level) {
    switch (level) {
      case ProximityLevel.freezing: return const Color(0xFFEF4444); // أحمر (بعيد جداً)
      case ProximityLevel.cold:     return const Color(0xFFFF9800); // برتقالي (بعيد)
      case ProximityLevel.warm:     return const Color(0xFFFFC107); // أصفر (متوسط)
      case ProximityLevel.hot:      return const Color(0xFF2ECC71); // أخضر فاتح (قريب)
      case ProximityLevel.burning:  return const Color(0xFF00E676); // أخضر زاهي (قريب جداً)
    }
  }
}
