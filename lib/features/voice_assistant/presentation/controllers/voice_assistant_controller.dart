import 'package:get/get.dart';
import '../../domain/services/voice_command_interpreter.dart';
import '../../domain/services/voice_command_executor.dart';
import '../../infrastructure/services/speech_recognition_service.dart';
import '../../infrastructure/services/tts_service.dart';
import '../../infrastructure/services/voice_feedback_service.dart';
import '../../domain/entities/voice_command.dart';
import '../../domain/entities/voice_response.dart';
import '../../infrastructure/services/voice_logger.dart';

enum VoiceState { idle, listening, processing, success, error, confirm }

class VoiceAssistantController extends GetxController {
  final SpeechRecognitionService _speechService;
  final TtsService _ttsService;
  final VoiceCommandInterpreter _interpreter;
  final VoiceCommandExecutor _executor;

  VoiceAssistantController({
    required SpeechRecognitionService speechService,
    required TtsService ttsService,
    required VoiceCommandInterpreter interpreter,
    required VoiceCommandExecutor executor,
  })  : _speechService = speechService,
        _ttsService = ttsService,
        _interpreter = interpreter,
        _executor = executor;

  var currentState = VoiceState.idle.obs;
  var recognizedText = ''.obs;
  var assistantResponse = ''.obs;
  var isListening = false.obs;
  
  VoiceResponse? _lastResponse;

  @override
  void onInit() {
    super.onInit();
    _speechService.onStatusChange = (status) {
      VoiceLogger.logLifecycle('STT Status changed: $status');
      if (status == 'done' || status == 'notListening') {
         // نترك المعالجة لـ finalResult أو الضغط اليدوي لتجنب التكرار والسباق
      }
    };
    // 🎙️ تم إزالة التهيئة التلقائية هنا لمنع طلب صلاحية الميكروفون عند فتح التطبيق
    // يتم تهيئة خدمة التعرف على الصوت وطلب الإذن عند ضغط المستخدم على زر المساعد لأول مرة
  }

  void toggleListening() {
    if (isListening.value) {
      stopListeningAndProcess();
    } else {
      startListening();
    }
  }

  void startListening() async {
    _ttsService.stop();
    recognizedText.value = '';
    assistantResponse.value = '';
    currentState.value = VoiceState.listening;
    isListening.value = true;
    
    VoiceFeedbackService.playStartListening();

    await _speechService.startListening(
      onResult: (text, confidence, isFinal) {
        recognizedText.value = text;
        if (isFinal && isListening.value) {
          stopListeningAndProcess();
        }
      },
    );
  }

  void stopListeningAndProcess() async {
    if (!isListening.value) return;
    
    VoiceLogger.logLifecycle('Stopping listening and starting processing...');
    isListening.value = false;
    await _speechService.stopListening();
    VoiceFeedbackService.playStopListening();

    final text = recognizedText.value.trim();
    if (text.isEmpty) {
      VoiceLogger.logLifecycle('Recognized text is empty, returning to idle.');
      currentState.value = VoiceState.idle;
      return;
    }

    currentState.value = VoiceState.processing;
    assistantResponse.value = "جاري التفكير...";
    
    try {
      final command = VoiceCommand(
        rawText: text,
        normalizedText: text,
        confidence: 1.0, 
      );

      VoiceLogger.logLifecycle('Interpreting command: "$text"');
      final intent = _interpreter.interpret(command);
      
      VoiceLogger.logLifecycle('Executing intent: ${intent.action}');
      final response = await _executor.execute(intent);
      _lastResponse = response;

      assistantResponse.value = response.displayText;

      if (response.requiresConfirmation) {
        currentState.value = VoiceState.confirm;
        VoiceFeedbackService.playConfirm();
      } else if (response.success) {
        currentState.value = VoiceState.success;
        VoiceFeedbackService.playSuccess();
      } else {
        currentState.value = VoiceState.error;
        VoiceFeedbackService.playError();
      }

      VoiceLogger.logExecution(intent.action, response.success, response.displayText);
      await _ttsService.speak(response.spokenText);
    } catch (e) {
      VoiceLogger.logError('Processing failed', e.toString());
      currentState.value = VoiceState.error;
      assistantResponse.value = "عفواً، حدث خطأ داخلي";
      await _ttsService.speak("عفواً، حدث خطأ داخلي");
    }
  }

  void confirmAction() async {
    if (_lastResponse?.requiresConfirmation == true && _lastResponse?.onConfirm != null) {
      currentState.value = VoiceState.processing;
      try {
        _lastResponse!.onConfirm!();
        currentState.value = VoiceState.success;
        assistantResponse.value = "تم التنفيذ بنجاح";
        await _ttsService.speak("تم التنفيذ بنجاح");
        VoiceFeedbackService.playSuccess();
      } catch (e) {
        currentState.value = VoiceState.error;
        assistantResponse.value = "حدث خطأ أثناء التنفيذ";
        await _ttsService.speak("حدث خطأ أثناء التنفيذ");
        VoiceFeedbackService.playError();
      }
    }
  }

  void cancelAction() {
    VoiceLogger.logLifecycle('User cancelled the confirmation action');
    currentState.value = VoiceState.idle;
    assistantResponse.value = "تم الإلغاء";
    _ttsService.speak("تم الإلغاء");
  }
}






