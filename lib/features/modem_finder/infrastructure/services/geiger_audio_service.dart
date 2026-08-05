import 'dart:async';
import 'package:flutter/services.dart';
import '../../domain/entities/proximity_level.dart';
import '../../domain/services/geiger_rhythm_calculator.dart';

class GeigerAudioService {
  Timer? _tickTimer;
  bool _isActive = false;
  bool _isMuted = false;

  void startTicking(ProximityLevel level, GeigerRhythmCalculator calculator) {
    _isActive = true;
    _scheduleTick(level, calculator);
  }

  void _scheduleTick(ProximityLevel level, GeigerRhythmCalculator calculator) {
    _tickTimer?.cancel();
    if (!_isActive) return;

    final interval = calculator.calculateInterval(level);
    
    _tickTimer = Timer(interval, () {
      if (!_isActive) return;
      if (!_isMuted) {
        // Short system click sound
        SystemSound.play(SystemSoundType.click);
      }
      _scheduleTick(level, calculator); // Schedule next tick
    });
  }

  void updateLevel(ProximityLevel level, GeigerRhythmCalculator calculator) {
    if (_isActive) {
      _scheduleTick(level, calculator);
    }
  }

  void stop() {
    _isActive = false;
    _tickTimer?.cancel();
    _tickTimer = null;
  }

  void toggleMute(bool isMuted) {
    _isMuted = isMuted;
  }
  
  bool get isMuted => _isMuted;
  
  void dispose() => stop();
}
