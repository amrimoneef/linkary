import '../enums/command_category.dart';
import '../enums/voice_intent_type.dart';

class VoiceIntent {
  final VoiceIntentType type;
  final CommandCategory category;
  final String action;
  final Map<String, dynamic> params;
  final double matchScore;
  final String message; // For needsMoreInfo or ambiguous
  final List<dynamic>? candidates; // For ambiguous
  final bool requiresConfirmation;

  VoiceIntent({
    required this.type,
    required this.category,
    required this.action,
    this.params = const {},
    this.matchScore = 0.0,
    this.message = '',
    this.candidates,
    this.requiresConfirmation = false,
  });

  factory VoiceIntent.unknown() {
    return VoiceIntent(
      type: VoiceIntentType.unknown,
      category: CommandCategory.unknown,
      action: 'unknown',
    );
  }

  factory VoiceIntent.needsMoreInfo({required String message}) {
    return VoiceIntent(
      type: VoiceIntentType.needsMoreInfo,
      category: CommandCategory.unknown,
      action: 'more_info',
      message: message,
    );
  }

  factory VoiceIntent.ambiguous({required List<dynamic> candidates}) {
    return VoiceIntent(
      type: VoiceIntentType.ambiguous,
      category: CommandCategory.unknown,
      action: 'ambiguous',
      candidates: candidates,
    );
  }
}
