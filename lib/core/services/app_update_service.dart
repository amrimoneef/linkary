import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:get/get.dart';

class AppUpdateService {
  /// التحقق من التحديثات وإجبار المستخدم على التحديث إن وجد
  static Future<void> checkForUpdate() async {
    // ميزة in_app_update مدعومة فقط على نظام الأندرويد
    if (!Platform.isAndroid) return;

    try {
      // 1. فحص وجود تحديث في متجر جوجل بلاي
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      // 2. إذا توفر تحديث 
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        
        // 3. بدء عملية التحديث الإجباري
        AppUpdateResult result = await InAppUpdate.performImmediateUpdate();
        
        // في حال نجاح التحديث، سيقوم النظام بإعادة تشغيل التطبيق تلقائياً
        if (result == AppUpdateResult.success) {
          debugPrint('تم التحديث بنجاح.');
        } else if (result == AppUpdateResult.userDeniedUpdate) {
          // إذا قام المستخدم بالخروج من شاشة التحديث بطريقة ما (نادرة في الـ Immediate)
          // يمكننا إغلاق التطبيق لإجباره في المرة القادمة، أو عرض رسالة
          debugPrint('المستخدم رفض التحديث.');
          exit(0); // إغلاق التطبيق فوراً لعدم السماح باستخدام النسخة القديمة
        }
      }
    } catch (e) {
      // إذا حدث خطأ (مثلاً لا يوجد اتصال بالإنترنت، أو التطبيق غير محمل من المتجر)
      // نتجاهل الخطأ لكي يستمر التطبيق بالعمل بشكل طبيعي.
      debugPrint('خطأ في فحص التحديثات: $e');
    }
  }
}
