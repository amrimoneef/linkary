import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// خدمة حفظ تفضيلات المساعد الصوتي
class VoicePrefsService {
  static const _storage = FlutterSecureStorage();
  static const _keyBetaNoticeSeen = 'voice_beta_notice_dismissed';

  /// هل تم إخفاء إشعار التجريبية بشكل دائم؟
  static Future<bool> isBetaNoticeDismissed() async {
    final value = await _storage.read(key: _keyBetaNoticeSeen);
    return value == 'true';
  }

  /// حفظ قرار الإخفاء الدائم
  static Future<void> dismissBetaNotice() async {
    await _storage.write(key: _keyBetaNoticeSeen, value: 'true');
  }
}
