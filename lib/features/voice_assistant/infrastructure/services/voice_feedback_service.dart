import 'package:flutter/services.dart';

class VoiceFeedbackService {
  
  /// تأثير لمسي عند بدء الاستماع
  static void playStartListening() {
    HapticFeedback.lightImpact();
    // اختياري: تشغيل ملف صوتي قصير (نغمة بدء الاستماع)
    // AudioPlayer().play(AssetSource('sounds/start_listen.mp3'));
  }

  /// تأثير لمسي عند انتهاء الاستماع أو المعالجة
  static void playStopListening() {
    HapticFeedback.mediumImpact();
  }

  /// تأثير عند نجاح تنفيذ الأمر
  static void playSuccess() {
    HapticFeedback.lightImpact();
  }

  /// تأثير عند الفشل في فهم الأمر
  static void playError() {
    HapticFeedback.heavyImpact();
  }

  /// تأثير عند طلب التأكيد 
  static void playConfirm() {
    HapticFeedback.selectionClick();
  }
}
