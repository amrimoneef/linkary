import '../entities/voice_intent.dart';
import '../enums/voice_intent_type.dart';
import 'command_registry.dart';

class ScoredIntent {
  final CommandPattern pattern;
  final double score;

  ScoredIntent(this.pattern, this.score);
}

class IntentClassifier {
  static bool _containsWord(String text, String word) {
    if (word.isEmpty) return false;
    final paddedText = ' $text ';
    final target = ' $word ';
    return paddedText.contains(target);
  }

  /// تصنيف النص للنية الأقرب
  static VoiceIntent? classify(String normalizedText) {
    if (normalizedText.isEmpty) return null;

    List<ScoredIntent> scores = [];

    for (final pattern in CommandRegistry.patterns) {
      double score = 0.0;
      bool hasAllRequiredGroups = true;

      // 1. يجب أن يحقق تطابق واحد على الأقل من كل مجموعة Required
      for (final requiredGroup in pattern.requiredKeywords) {
        final alternatives = requiredGroup.split('|');
        bool groupMatched = false;
        
        for (final alt in alternatives) {
          if (_containsWord(normalizedText, alt)) {
            groupMatched = true;
            break;
          }
        }
        
        if (!groupMatched) {
          hasAllRequiredGroups = false;
          break; // فشل في هذه المجموعة، ننتقل للنمط التالي
        }
      }

      if (!hasAllRequiredGroups) continue;

      // أساس النقطة للنمط الذي حقق المتطلبات
      score += pattern.weight;

      // 2. الكلمات المعززة
      for (final kw in pattern.boostKeywords) {
        if (_containsWord(normalizedText, kw)) {
          score += 5.0; // وزن إضافي
        }
      }

      // 3. الكلمات المضادة
      for (final kw in pattern.antiKeywords) {
        if (_containsWord(normalizedText, kw)) {
          score -= 15.0; // خصم قوي
        }
      }

      if (score > 0) {
        scores.add(ScoredIntent(pattern, score));
      }
    }

    if (scores.isEmpty) return null;

    // ترتيب تنازلي حسب أعلى سكور
    scores.sort((a, b) => b.score.compareTo(a.score));

    final topScore = scores.first.score;
    // إذا كان هناك تقارب بالدرجات (أقل من نقطتين فرق)، نطلب توضيح
    if (scores.length > 1 && (topScore - scores[1].score) < 2.0) {
      return VoiceIntent.ambiguous(candidates: [
        scores[0].pattern.intent,
        scores[1].pattern.intent
      ]);
    }

    final topPattern = scores.first.pattern;
    final typeStr = topPattern.intent.split('.').first;
    final VoiceIntentType type;
    switch (typeStr) {
      case 'query': type = VoiceIntentType.query; break;
      case 'action': type = VoiceIntentType.action; break;
      case 'navigate': type = VoiceIntentType.navigate; break;
      default: type = VoiceIntentType.unknown;
    }

    return VoiceIntent(
      type: type,
      category: topPattern.category,
      action: topPattern.intent,
      requiresConfirmation: topPattern.requiresConfirmation,
      matchScore: topScore,
    );
  }
}
