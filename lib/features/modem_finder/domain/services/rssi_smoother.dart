import 'dart:math' as math;

class RssiSmoother {
  double _smoothedValue = -100.0;
  bool _isInitialized = false;
  
  // Median filter window
  final List<int> _recentReadings = [];
  static const int _medianWindowSize = 5;

  // Adaptive EMA parameters
  static const double _baseAlpha24GHz = 0.25;
  static const double _baseAlpha5GHz = 0.35;
  static const double _highMotionAlpha = 0.6; // Faster response when moving
  static const double _lowMotionAlpha = 0.15; // Slower response when still
  
  double _lastMedian = -100.0;

  /// Reset the smoother
  void reset() {
    _smoothedValue = -100.0;
    _isInitialized = false;
    _recentReadings.clear();
    _lastMedian = -100.0;
  }

  /// Smooth a new RSSI reading
  double smooth(int rawRssi, {bool is5GHz = false}) {
    // Stage 1: Median Filter
    _recentReadings.add(rawRssi);
    if (_recentReadings.length > _medianWindowSize) {
      _recentReadings.removeAt(0);
    }

    if (_recentReadings.isEmpty) return rawRssi.toDouble();

    // Calculate Median
    final sortedReadings = List<int>.from(_recentReadings)..sort();
    final median = sortedReadings[sortedReadings.length ~/ 2].toDouble();

    // First reading initialization
    if (!_isInitialized) {
      _smoothedValue = median;
      _lastMedian = median;
      _isInitialized = true;
      return _smoothedValue;
    }

    // Stage 2: Adaptive EMA
    _lastMedian = median;

    // Adaptive spike threshold based on median jumps
    if ((median - _smoothedValue).abs() > 20.0) {
      // Just take it, might be a big location change
      _smoothedValue = median;
      return _smoothedValue;
    }

    // Determine alpha based on motion (difference from previous smoothed value)
    double motionFactor = (median - _smoothedValue).abs() / 10.0; // 0.0 to >1.0
    motionFactor = motionFactor.clamp(0.0, 1.0);
    
    final baseAlpha = is5GHz ? _baseAlpha5GHz : _baseAlpha24GHz;
    // Blend between low motion and high motion alphas based on movement
    double alpha = _lowMotionAlpha + motionFactor * (_highMotionAlpha - _lowMotionAlpha);
    
    // Ensure we don't go below base if we want it somewhat responsive
    alpha = math.max(alpha, baseAlpha);

    _smoothedValue = alpha * median + (1 - alpha) * _smoothedValue;

    return _smoothedValue;
  }

  double get currentSmoothed => _smoothedValue;
}
