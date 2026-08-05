import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/splash_controller.dart';
import 'splash_page.dart';

class ModemConnectionErrorPage extends StatelessWidget {
  const ModemConnectionErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon with glowing background
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.errorRed.withValues(alpha: 0.1),
                ),
                child: const Center(
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 64,
                    color: AppColors.errorRed,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Title
              Text(
                'الشبكة غير متصلة',
                style: AppTextStyles.displayMedium(isDark).copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Explanation
              Text(
                'يبدو أنك لست متصلاً بالمودم، يرجى التوصيل بشبكة المودم والمحاولة مرة أخرى.',
                style: AppTextStyles.bodyLarge(isDark).copyWith(
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.delete<SplashController>();
                    Get.offAll(() => const SplashPage());
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    'إعادة المحاولة',
                    style: AppTextStyles.labelLarge(true).copyWith(
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
