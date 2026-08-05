import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'voice_logger.dart';

class SpeechRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;
  String _localeId = 'ar_SA'; // الافتراضي السعودية
  Function(String)? onStatusChange;

  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    VoiceLogger.logLifecycle('Initializing SpeechToText...');
    _isAvailable = await _speech.initialize(
      onError: (val) => VoiceLogger.logError('STT Error', val.errorMsg),
      onStatus: (val) {
         VoiceLogger.logLifecycle('STT Status changed: $val');
         if (onStatusChange != null) onStatusChange!(val);
      },
    );
    
    if (_isAvailable) {
      // البحث عن اللغات العربية المتوفرة
      var locales = await _speech.locales();
      VoiceLogger.logLifecycle('Found ${locales.length} available locales dynamically');
      
      var arabicLocale = locales.firstWhere(
        (locale) => locale.localeId.toLowerCase().startsWith('ar'),
        orElse: () {
          VoiceLogger.logLifecycle('Warning: No Arabic locale found on device! Forcing "ar-SA".');
          return stt.LocaleName('ar-SA', 'Arabic (Saudi Arabia)');
        },
      );
      _localeId = arabicLocale.localeId;
      VoiceLogger.logLifecycle('STT initialized with locale: $_localeId');
    } else {
      VoiceLogger.logError('STT initialization failed or permissions not granted');
    }
    
    return _isAvailable;
  }

  Future<void> startListening({
    required Function(String text, double confidence, bool isFinal) onResult,
  }) async {
    if (!_isAvailable) {
      final initOk = await initialize();
      if (!initOk) return;
    }

    await _speech.listen(
      onResult: (result) {
        if(result.recognizedWords.isNotEmpty) {
           VoiceLogger.logSpeech(result.recognizedWords, result.confidence);
           onResult(result.recognizedWords, result.confidence, result.finalResult);
        }
      },
      localeId: _localeId,
      cancelOnError: false,
      listenMode: stt.ListenMode.confirmation, 
      pauseFor: const Duration(seconds: 3), // يتوقف تلقائياً بعد 3 ثوانٍ من الصمت
    );
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }
}
