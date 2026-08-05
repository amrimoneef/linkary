import '../entities/calibration_data.dart';
import '../entities/proximity_level.dart';

class ProximityClassifier {
  ProximityLevel _currentLevel = ProximityLevel.freezing;
  bool _isInitialized = false;
  static const double _hysteresisMargin = 2.0;

  void reset() {
    _isInitialized = false;
    _currentLevel = ProximityLevel.freezing;
  }

  /// Classify proximity based on smoothed RSSI and optional calibration
  ProximityLevel classify(double smoothedRssi, {CalibrationData? calibration}) {
    double freezingThreshold = -79.0;
    double coldThreshold = -69.0;
    double warmThreshold = -59.0;
    double hotThreshold = -49.0;

    if (calibration != null) {
      // Dynamic thresholds based on calibration
      final maxRssi = calibration.maxRssi;
      final range = maxRssi - (-100.0); // Assuming -100 is the minimum
      
      freezingThreshold = maxRssi - (range * 0.80);
      coldThreshold = maxRssi - (range * 0.60);
      warmThreshold = maxRssi - (range * 0.40);
      hotThreshold = maxRssi - (range * 0.20);
    }
    
    if (!_isInitialized) {
      if (smoothedRssi >= hotThreshold) _currentLevel = ProximityLevel.burning;
      else if (smoothedRssi >= warmThreshold) _currentLevel = ProximityLevel.hot;
      else if (smoothedRssi >= coldThreshold) _currentLevel = ProximityLevel.warm;
      else if (smoothedRssi >= freezingThreshold) _currentLevel = ProximityLevel.cold;
      else _currentLevel = ProximityLevel.freezing;
      _isInitialized = true;
      return _currentLevel;
    }
    
    // Apply Hysteresis
    switch (_currentLevel) {
      case ProximityLevel.burning:
        if (smoothedRssi < hotThreshold - _hysteresisMargin) _currentLevel = ProximityLevel.hot;
        break;
      case ProximityLevel.hot:
        if (smoothedRssi >= hotThreshold + _hysteresisMargin) _currentLevel = ProximityLevel.burning;
        else if (smoothedRssi < warmThreshold - _hysteresisMargin) _currentLevel = ProximityLevel.warm;
        break;
      case ProximityLevel.warm:
        if (smoothedRssi >= warmThreshold + _hysteresisMargin) _currentLevel = ProximityLevel.hot;
        else if (smoothedRssi < coldThreshold - _hysteresisMargin) _currentLevel = ProximityLevel.cold;
        break;
      case ProximityLevel.cold:
        if (smoothedRssi >= coldThreshold + _hysteresisMargin) _currentLevel = ProximityLevel.warm;
        else if (smoothedRssi < freezingThreshold - _hysteresisMargin) _currentLevel = ProximityLevel.freezing;
        break;
      case ProximityLevel.freezing:
        if (smoothedRssi >= freezingThreshold + _hysteresisMargin) _currentLevel = ProximityLevel.cold;
        break;
    }

    return _currentLevel;
  }
  
  double calculatePercentage(double smoothedRssi, {CalibrationData? calibration}) {
    final maxRssi = calibration?.maxRssi ?? -30.0;
    const minRssi = -100.0;
    
    double percentage = ((smoothedRssi - minRssi) / (maxRssi - minRssi) * 100);
    return percentage.clamp(0.0, 100.0);
  }
}
