import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';

class WhatsNewHelper {
  static const String _prefKey = 'last_shown_whats_new_version';

  static Future<void> checkAndShowWhatsNew({bool force = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    
    final lastShownVersion = prefs.getString(_prefKey);

    // If it's a new version, show the dialog
    if (force || lastShownVersion != currentVersion) {
      await _showWhatsNewDialog(currentVersion);
      // Update the preference so it doesn't show again for this version
      await prefs.setString(_prefKey, currentVersion);
    }
  }

  static Future<void> showWhatsNewDialogManual() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      await _showWhatsNewDialog(packageInfo.version);
    } catch (_) {
      await _showWhatsNewDialog('1.0.4');
    }
  }

  static Future<void> _showWhatsNewDialog(String version) async {
    final isDark = Get.isDarkMode;
    final bgColor = isDark ? const Color(0xFF16213E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF8E9AAA);

    await Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Icon Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.magic_star,
                  color: AppColors.primaryBlue,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                'ما الجديد في التحديث؟',
                style: TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Version Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'الإصدار $version',
                  style: const TextStyle(
                    color: AppColors.primaryPurple,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Features List
              _buildFeatureItem(
                icon: Iconsax.security_user,
                title: 'إجراءات فورية لإشعارات الأجهزة',
                description: 'تحكم فوري بالأجهزة المتصلة مباشرة من درج الإشعارات عبر إمكانية (حظر 🚫، توثيق ✅، أو تجاهل ✖️) بضغطة زر واحدة دون الحاجة للدخول إلى التطبيق.',
                textColor: textColor,
                subTextColor: subTextColor,
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                icon: Iconsax.search_status,
                title: 'البحث السريع الذكي (Spotlight)',
                description: 'محرك بحث متطور وفوري لكافة إعدادات وخصائص المودم باللغة العربية، مع إمكانية الوصول السريع له عبر إيماءة السحب لليمين من أي مكان في التطبيق.',
                textColor: textColor,
                subTextColor: subTextColor,
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                icon: Iconsax.lock,
                title: 'تحسين التحكم الأبوي وجدولة الإنترنت',
                description: 'اصبحت الجدولة تدعم جميع الأيام بشكل مستقل.',
                textColor: textColor,
                subTextColor: subTextColor,
              ),
              const SizedBox(height: 16),
              _buildFeatureItem(
                icon: Iconsax.message_favorite,
                title: 'صندوق المقترحات والدعم المباشر',
                description: 'منظومة عصرية لإرسال ملاحظاتك ومقترحاتك مباشرة لفريق التطوير، مع توثيق تلقائي لطراز المودم وسجل آمن لمتابعة رسائلك السابقة.',
                textColor: textColor,
                subTextColor: subTextColor,
              ),
              const SizedBox(height: 16),
              
              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'رائع، لنبدأ!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primaryBlue, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
