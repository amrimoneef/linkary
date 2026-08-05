import '../entities/proximity_level.dart';

class GeigerRhythmCalculator {
  /// Calculate the interval between ticks (in milliseconds)
  Duration calculateInterval(ProximityLevel level) {
    switch (level) {
      case ProximityLevel.freezing:
        return const Duration(milliseconds: 2500);
      case ProximityLevel.cold:
        return const Duration(milliseconds: 1500);
      case ProximityLevel.warm:
        return const Duration(milliseconds: 700);
      case ProximityLevel.hot:
        return const Duration(milliseconds: 300);
      case ProximityLevel.burning:
        return const Duration(milliseconds: 80);
    }
  }

  /// Calculate the vibration duration (in milliseconds)
  int calculateVibrationDuration(ProximityLevel level) {
    switch (level) {
      case ProximityLevel.freezing: return 15;
      case ProximityLevel.cold: return 30;
      case ProximityLevel.warm: return 60;
      case ProximityLevel.hot: return 90;
      case ProximityLevel.burning: return 130;
    }
  }

  /// Calculate the audio volume (0.0 - 1.0)
  double calculateVolume(ProximityLevel level) {
    switch (level) {
      case ProximityLevel.freezing: return 0.2;
      case ProximityLevel.cold: return 0.35;
      case ProximityLevel.warm: return 0.55;
      case ProximityLevel.hot: return 0.75;
      case ProximityLevel.burning: return 1.0;
    }
  }
}
