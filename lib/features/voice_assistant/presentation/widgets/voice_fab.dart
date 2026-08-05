import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:get/get.dart';
import '../controllers/voice_assistant_controller.dart';
import 'voice_bottom_sheet.dart';
import 'voice_action_dialogs.dart';

class VoiceFAB extends StatelessWidget {
  const VoiceFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final controller = Get.find<VoiceAssistantController>();

        // Reset to idle so the commands guide is shown first
        if (controller.isListening.value) {
          controller.stopListeningAndProcess();
        }
        controller.currentState.value = VoiceState.idle;

        // عرض إشعار التجريبية إن لزم، ثم فتح الـ sheet
        await VoiceActionDialogs.showBetaNoticeIfNeeded(
          onProceed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              barrierColor: Colors.black.withValues(alpha: 0.5),
              builder: (context) => const VoiceAssistantBottomSheet(),
            );
          },
        );
      },
      child: GetX<VoiceAssistantController>(
        builder: (controller) {
          final isListening = controller.isListening.value;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isListening ? 65 : 56,
            height: isListening ? 65 : 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isListening
                    ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)]
                    : [const Color(0xFF6B48FF), const Color(0xFF4A90E2)],
              ),
              boxShadow: [
                BoxShadow(
                  color: (isListening ? const Color(0xFFFF6B6B) : const Color(0xFF6B48FF)).withValues(alpha: 0.4),
                  blurRadius: isListening ? 25 : 15,
                  spreadRadius: isListening ? 5 : 2,
                ),
              ],
            ),
            child: const Icon(
              Iconsax.microphone_2,
              color: Colors.white,
              size: 28,
            ),
          );
        },
      ),
    );
  }
}
