import 'package:flutter/material.dart';
import 'dart:math';

class VoiceWaveform extends StatefulWidget {
  final bool isListening;

  const VoiceWaveform({super.key, required this.isListening});

  @override
  State<VoiceWaveform> createState() => _VoiceWaveformState();
}

class _VoiceWaveformState extends State<VoiceWaveform> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isListening) {
      return const SizedBox(height: 50, child: Center(child: Text("...", style: TextStyle(fontSize: 24, color: Colors.grey))));
    }

    return SizedBox(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(7, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.3;
              final value = sin((_controller.value * pi * 2) + delay);
              final height = 15 + (value.abs() * 35); // يتراوح بين 15 و 50
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 6,
                height: height,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6B48FF), Color(0xFF4A90E2)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
