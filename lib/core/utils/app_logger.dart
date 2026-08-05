import 'package:flutter/foundation.dart';

/// 🛡️ مسجل آمن للإنتاج
///
/// يمنع تسريب أي معلومات عبر logcat في نسخة الإنتاج.
/// يطبع فقط في وضع التطوير (kDebugMode).
class AppLogger {
  AppLogger._();

  /// طباعة معلومات تصحيح (Debug فقط)
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint(message);
    }
  }

  /// طباعة خطأ (Debug فقط)
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('❌ $message');
      if (error != null) debugPrint('Details: $error');
    }
  }

  /// طباعة تحذير (Debug فقط)
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ $message');
    }
  }

  /// طباعة نجاح (Debug فقط)
  static void success(String message) {
    if (kDebugMode) {
      debugPrint('✅ $message');
    }
  }
}
