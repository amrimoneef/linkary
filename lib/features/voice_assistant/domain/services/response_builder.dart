import 'dart:math';
import '../entities/voice_response.dart';

class ResponseBuilder {
  static final _random = Random();

  static String getRandom(List<String> options) {
    return options[_random.nextInt(options.length)];
  }

  static VoiceResponse success({
    required String text,
    String? displayText,
  }) {
    return VoiceResponse(
      success: true,
      spokenText: text,
      displayText: displayText ?? text,
    );
  }

  static VoiceResponse error([String? text]) {
    final msg = text ?? getRandom([
      'عذراً، حدث خطأ أثناء تنفيذ الأمر',
      'لم أتمكن من إتمام ذلك',
      'واجهت مشكلة، يرجى المحاولة مرة أخرى',
    ]);
    return VoiceResponse(
      success: false,
      spokenText: msg,
      displayText: msg,
    );
  }

  static VoiceResponse notUnderstood() {
    final msg = getRandom([
      'عذراً، لم أفهم الأمر. ممكن تعيد؟',
      'لم أستطع التعرف على ما قلت. حاول بكلمات أبسط',
      'عفواً، قصرت في الفهم. ممكن توضح؟',
    ]);
    return VoiceResponse(
      success: false,
      spokenText: msg,
      displayText: 'لم يتم التعرف على الأمر',
    );
  }
}
