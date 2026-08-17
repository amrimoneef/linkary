import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/fcm_notification_service.dart';
import '../network/session_manager.dart';

class PermissionsDialog extends StatelessWidget {
  const PermissionsDialog({super.key});

  static Future<void> showIfNeeded() async {
    final hasRequested = await SessionManager.hasRequestedPermissions();
    if (!hasRequested) {
      await Get.dialog(
        const PermissionsDialog(),
        barrierDismissible: false,
      );
      await SessionManager.setPermissionsRequested();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // أيقونة جذابة
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.notification,
                size: 64,
                color: AppColors.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            
            // العنوان
            Text(
              'ابقَ على اطلاع دائم',
              style: AppTextStyles.titleLarge(isDark).copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // الوصف
            Text(
              'نحتاج إلى صلاحية إرسال الإشعارات لنبقيك على علم بحالة المودم، التنبيهات الأمنية، وأي تحديثات هامة تتعلق بالشبكة الخاصة بك فور حدوثها.',
              style: AppTextStyles.bodyMedium(isDark).copyWith(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // أزرار الإجراءات
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Get.back(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'ليس الآن',
                      style: AppTextStyles.labelLarge(isDark).copyWith(
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // طلب الصلاحية من النظام للإشعارات
                      await FcmNotificationService().requestPermission();
                      
                      if (Platform.isAndroid) {
                        try {
                          final isGranted = await Permission.ignoreBatteryOptimizations.isGranted;
                          if (!isGranted) {
                            await Permission.ignoreBatteryOptimizations.request();
                          }
                        } catch (e) {
                          debugPrint('Error: $e');
                        }
                      }
                      
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'السماح',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo', // assuming this is the font used
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
