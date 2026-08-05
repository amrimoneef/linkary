import '../entities/voice_command.dart';
import '../entities/voice_intent.dart';
import '../enums/command_category.dart';
import '../enums/voice_intent_type.dart';
import 'arabic_normalizer.dart';
import 'dialect_synonyms.dart';
import 'intent_classifier.dart';
import 'command_resolver.dart';
import '../../infrastructure/services/voice_logger.dart';

class VoiceCommandInterpreter {
  /// كلمات التنشيط الخاصة بـ "سام"
  static const _wakeWords = [
    'يا سام',
    'يا سامي',
    'سام',
    'سامي',
    'يا ساام',
    'ساام',
  ];

  /// إزالة كلمة التنشيط من بداية النص
  static String _stripWakeWord(String text) {
    // نوحّد الهمزات للمقارنة
    String normalize(String s) => s
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .trim();

    final normText = normalize(text);

    for (final ww in _wakeWords) {
      final normWw = normalize(ww);
      if (normText.startsWith(normWw)) {
        // احذف الكلمة من الأصل بالطول نفسه مع مسافة
        final stripped = text.substring(ww.length).trimLeft();
        VoiceLogger.logLifecycle('Wake word "$ww" detected — remaining: "$stripped"');
        return stripped;
      }
    }
    return text;
  }

  /// تحويل النص المنطوق إلى أمر مبني (Intent)
  VoiceIntent interpret(VoiceCommand command) {
    if (command.confidence < 0.2) {
      return VoiceIntent.unknown(); // ثقة منخفضة جداً
    }

    // 0. إزالة كلمة التنشيط "سام"/"يا سام" إن وُجدت
    final textAfterWakeWord = _stripWakeWord(command.normalizedText.trim());

    // إذا كانت الرسالة فقط "يا سام" أو "سام" بدون أمر — رد بترحيب
    if (textAfterWakeWord.isEmpty) {
      return VoiceIntent(
        type: VoiceIntentType.query,
        category: CommandCategory.help,
        action: 'query.sam.greeting',
        matchScore: 1.0,
      );
    }

    // 1. التطبيع ومعالجة اللهجات
    final normalized = ArabicNormalizer.normalize(textAfterWakeWord);
    final unified = DialectSynonyms.unifyDialects(normalized);

    // 2. التصنيف المبدئي
    final intent = IntentClassifier.classify(unified);

    // 3. إذا لم ينجح في الفهم
    if (intent == null) {
      VoiceLogger.logIntent(command.rawText, unified, 'UNKNOWN', 0.0, {});
      return VoiceIntent.unknown();
    }

    // 4. استخلاص الكيانات وحل المعاملات
    final resolvedIntent = CommandResolver.resolve(intent, unified);

    VoiceLogger.logIntent(command.rawText, unified, resolvedIntent.action, resolvedIntent.matchScore, resolvedIntent.params);

    return resolvedIntent;
  }
}
