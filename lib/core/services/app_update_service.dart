import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/custom_snackbar.dart';

class AppUpdateService {
  static const String _playStoreUrl = 'https://play.google.com/store/apps/details?id=com.sam4g.app_settings';

  /// التحقق من التحديثات وعرض واجهة مخصصة ومرنة (اختيارية للمستخدم)
  static Future<void> checkForUpdate({bool isManual = false}) async {
    if (!Platform.isAndroid) return;

    try {
      // 1. فحص توفر تحديث في متجر جوجل بلاي
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate().timeout(
        const Duration(milliseconds: 2500),
      );

      // 2. إذا توفر تحديث جديد
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        await _showUpdateDialog(updateInfo);
      } else {
        if (isManual) {
          CustomSnackbar.showSuccess('أنت محدث!', 'أنت تستخدم أحدث إصدار متوفر من التطبيق.');
        }
      }
    } catch (e) {
      debugPrint('ℹ️ [AppUpdate] Check status: $e');
      if (isManual) {
        if (e.toString().contains('ERROR_APP_NOT_OWNED') || e.toString().contains('-10')) {
          CustomSnackbar.showInfo(
            'تنبيه التحديث',
            'التطبيق مثبت حالياً كنسخة يدوية. ميزة التحديث التلقائي تعمل تلقائياً للنسخ المحملة من متجر Google Play.',
          );
        } else {
          CustomSnackbar.showInfo('المتجر', 'تعذر الاتصال بمتجر Google Play حالياً. يرجى التحقق من اتصال الإنترنت.');
        }
      }
    }
  }

  /// دالة للمعاينة والاختبار المباشر لواجهة التحديث
  static Future<void> showPreviewDialog() async {
    await _showUpdateDialog(null);
  }

  /// عرض نافذة منبثقة فاخرة وجذابة للتحديث (اختيارية تماماً)
  static Future<void> _showUpdateDialog([AppUpdateInfo? updateInfo]) async {
    final context = Get.context;
    if (context == null) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF16213E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    await Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0072FF).withValues(alpha: isDark ? 0.25 : 0.15),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: const Color(0xFF0072FF).withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🚀 Glowing Icon Badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0072FF).withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Iconsax.arrow_up_3,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),

              // 🏷️ Badge Version
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0072FF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Iconsax.magic_star, color: Color(0xFF0072FF), size: 14),
                    SizedBox(width: 6),
                    Text(
                      'يتوفر إصدار جديد الآن',
                      style: TextStyle(
                        color: Color(0xFF0072FF),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                'تحديث جديد متوفر للتطبيق',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                'نعمل دائما على تطوير التطبيق لنيل رضاكم، و تقديم افضل تجربة للمستخدمين، و يسعدنا اطلاعكم على التحديث الجديد ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: subTextColor,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),

              // 🌟 Benefits Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.grey.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                ),
                child: Column(
                  children: [
                    _buildFeatureItem('تحسينات في الأداء وسرعة الاستجابة', textColor),
                    const SizedBox(height: 8),
                    _buildFeatureItem('أحدث التحديثات الأمنية والتوافق', textColor),
                    const SizedBox(height: 8),
                    _buildFeatureItem('ميزات وتجربة استخدام أكثر سلاسة', textColor),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 🚀 Buttons
              Row(
                children: [
                  // Dismiss / Later Button
                  Expanded(
                    flex: 2,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Get.back(),
                      child: Text(
                        'لاحقاً',
                        style: TextStyle(
                          color: subTextColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Update Now Button
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0072FF).withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          Get.back();
                          await _startUpdateProcess(updateInfo);
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.direct_up, color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'تحديث الآن',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
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
    );
  }

  static Widget _buildFeatureItem(String text, Color textColor) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  /// بدء عملية التحديث المرن أو فتح المتجر
  static Future<void> _startUpdateProcess([AppUpdateInfo? updateInfo]) async {
    try {
      if (updateInfo != null && updateInfo.flexibleUpdateAllowed) {
        // تحديث مرن في الخلفية
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          await InAppUpdate.completeFlexibleUpdate();
        }
      } else if (updateInfo != null && updateInfo.immediateUpdateAllowed) {
        // تحديث مباشر من جوجل بلاي
        await InAppUpdate.performImmediateUpdate();
      } else {
        // توجيه لصفحة التطبيق في Google Play
        _openPlayStore();
      }
    } catch (e) {
      debugPrint('⚠️ InAppUpdate direct process failed, falling back to Play Store: $e');
      _openPlayStore();
    }
  }

  /// فتح صفحة التطبيق في متجر Google Play
  static Future<void> _openPlayStore() async {
    try {
      final Uri uri = Uri.parse(_playStoreUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('❌ Error launching Play Store: $e');
    }
  }
}
