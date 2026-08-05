import 'package:flutter/widgets.dart';

class VoiceResponse {
  final bool success;
  final String spokenText;
  final String displayText;
  final Widget? richWidget;
  final bool requiresConfirmation;
  final VoidCallback? onConfirm;

  VoiceResponse({
    required this.success,
    required this.spokenText,
    required this.displayText,
    this.richWidget,
    this.requiresConfirmation = false,
    this.onConfirm,
  });

  factory VoiceResponse.confirmationRequired({
    required String message,
    required VoidCallback onConfirm,
  }) {
    return VoiceResponse(
      success: true, // It's technically active
      spokenText: message,
      displayText: message,
      requiresConfirmation: true,
      onConfirm: onConfirm,
    );
  }

  factory VoiceResponse.error(String message) {
    return VoiceResponse(
      success: false,
      spokenText: message,
      displayText: message,
    );
  }
}
