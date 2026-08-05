import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class VoiceLogger {
  static final List<String> _logs = [];

  static void log(String message) {
    final time = DateTime.now().toIso8601String().substring(11, 19);
    final formattedMsg = '[$time] 🎤 VoiceAssistant: $message';
    _logs.add(formattedMsg);
    developer.log(message, name: 'VoiceAssistant');
    if (kDebugMode) print(formattedMsg);
  }

  static void logSpeech(String text, double confidence) {
    log('🎙️ Speech recognized: "$text" (Confidence: ${(confidence * 100).toStringAsFixed(1)}%)');
  }

  static void logIntent(String rawText, String normalized, String intent, double score, Map<String, dynamic> params) {
    log('🧠 NLP Engine:');
    log('   - Raw text: "$rawText"');
    log('   - Normalized: "$normalized"');
    log('   - Matched Intent: $intent (Score: $score)');
    log('   - Params extracted: $params');
  }

  static void logExecution(String intent, bool success, String responseText) {
    log('⚡ Executor [${success ? "SUCCESS" : "FAILED"}]:');
    log('   - Command Intent: $intent');
    log('   - System Response: "$responseText"');
  }

  static void logError(String error, [String? details]) {
    log('❌ ERROR: $error');
    if (details != null) log('   - Details: $details');
  }
  
  static void logLifecycle(String event) {
    log('🔄 Lifecycle: $event');
  }

  static List<String> getHistory() {
    return _logs;
  }
  
  static void clearHistory() {
    _logs.clear();
  }
}
