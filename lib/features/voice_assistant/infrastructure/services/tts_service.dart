import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  
  TtsService() {
    _initializeTts();
  }

  Future<void> _initializeTts() async {
    // إعدادات اللغة والصوت المبدئية
    await _flutterTts.setLanguage("ar-SA");
    await _flutterTts.setSpeechRate(0.5); // سرعة طبيعية للفهم
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    // في Android يمكننا تعيين المحرك الافتراضي إذا أردنا
    // await _flutterTts.setEngine("com.google.android.tts");
  }

  /// تغيير إعدادات الصوت إذا لزم الأمر
  Future<void> configureVoice({double rate = 0.5, double pitch = 1.0}) async {
    await _flutterTts.setSpeechRate(rate);
    await _flutterTts.setPitch(pitch);
  }

  /// نطق نص عربي
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    await _flutterTts.speak(text);
  }

  /// إيقاف النطق الحالي
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
