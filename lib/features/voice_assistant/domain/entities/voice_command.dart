class VoiceCommand {
  final String rawText;
  final String normalizedText;
  final double confidence;
  final DateTime timestamp;

  VoiceCommand({
    required this.rawText,
    required this.normalizedText,
    required this.confidence,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
  
  @override
  String toString() => 'VoiceCommand(raw: "$rawText", norm: "$normalizedText", conf: $confidence)';
}
