import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class CustomSnackbar {
  static void show({
    required String title,
    required String message,
    bool isSuccess = false,
    bool isError = false,
    bool isWarning = false,
  }) {
    // إغلاق أي تنبيه مفتوح مسبقاً لمنع التكدس
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Color baseColor = const Color(0xFF1E293B); // لون داكن أنيق كافتراضي
    Color textColor = Colors.white;
    IconData? icon;

    if (isSuccess) {
      baseColor = const Color(0xFF10B981); // Emerald Green
      icon = Iconsax.tick_circle;
    } else if (isError) {
      baseColor = const Color(0xFFEF4444); // Rose Red
      icon = Iconsax.danger;
    } else if (isWarning) {
      baseColor = const Color(0xFFF59E0B); // Amber
      icon = Iconsax.warning_2;
    } else {
      icon = Iconsax.info_circle;
    }

    // إغلاق أي تنبيه مفتوح مسبقاً لمنع التكدس
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }

    Get.snackbar(
      '',
      '',
      titleText: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
      messageText: Text(
        message,
        style: TextStyle(
          color: textColor.withValues(alpha: 0.9),
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: baseColor.withValues(alpha: 0.35), // تأثير الزجاج
      barBlur: 5, // قوة التمويه الزجاجي
      colorText: textColor,
      icon: Icon(icon, color: textColor, size: 28),
      snackPosition: SnackPosition.BOTTOM, // ظهور من الأعلى
      margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      borderRadius: 20,
      duration: const Duration(seconds: 4),
      isDismissible: true,
      dismissDirection: DismissDirection.up,
      forwardAnimationCurve: Curves.easeOutCirc, // حركة سلسة وأنيقة
      reverseAnimationCurve: Curves.easeInCirc,
      boxShadows: [
        BoxShadow(
          color: baseColor.withValues(alpha: 0.3),
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(0, 8),
        )
      ],
      borderWidth: 1,
      borderColor: Colors.white.withValues(alpha: 0.15), // إطار زجاجي لامع
    );
  }

  static void showSuccess(String title, String message) {
    show(title: title, message: message, isSuccess: true);
  }

  static void showError(String title, String message) {
    show(title: title, message: message, isError: true);
  }

  static void showWarning(String title, String message) {
    show(title: title, message: message, isWarning: true);
  }
  
  static void showInfo(String title, String message) {
    show(title: title, message: message); // افتراضي
  }
}
