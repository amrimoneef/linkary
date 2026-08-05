import 'dart:async';
import 'package:vibration/vibration.dart';
import '../../domain/entities/proximity_level.dart';
import '../../domain/services/geiger_rhythm_calculator.dart';

class FinderHapticService {
  Timer? _tickTimer;
  bool _isActive = false;

  /// Start the pulse vibration pattern
  void startTicking(ProximityLevel level, GeigerRhythmCalculator calculator) {
    _isActive = true;
    _scheduleTick(level, calculator);
  }

  void _scheduleTick(ProximityLevel level, GeigerRhythmCalculator calculator) {
    _tickTimer?.cancel();
    if (!_isActive) return;

    final interval = calculator.calculateInterval(level);
    final duration = calculator.calculateVibrationDuration(level);

    _tickTimer = Timer(interval, () {
      if (!_isActive) return;
      _vibrate(duration);
      _scheduleTick(level, calculator);
    });
  }

  Future<void> _vibrate(int durationMs) async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      final hasCustom = await Vibration.hasCustomVibrationsSupport();
      if (hasCustom == true) {
        Vibration.vibrate(duration: durationMs);
      } else {
        Vibration.vibrate();
      }
    }
  }

  /// 🎉 Celebration pattern for "Found the Modem!"
  Future<void> playFoundCelebration() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;

    final hasCustom = await Vibration.hasCustomVibrationsSupport();
    if (hasCustom == true) {
      // Distinct pattern: two quick pulses then a long one
      await Vibration.vibrate(
        pattern: [0, 150, 80, 150, 80, 500],
      );
    } else {
      Vibration.vibrate();
    }
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

  void dispose() => stop();
}
