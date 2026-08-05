import 'dart:math' as math;
import '../entities/calibration_data.dart';

class DistanceResult {
  final double distance;
  final double minDistance;
  final double maxDistance;

  DistanceResult({
    required this.distance,
    required this.minDistance,
    required this.maxDistance,
  });
}

/// خوارزمية قياس البعد بدقة عالية (مطابقة لخدمة الحماية من فقدان المودم في أندرويد)
class DistanceEstimator {
  static const double _defaultTxPower = -50.0; // قوة الإشارة عند مسافة 1 متر
  static const double _defaultPathLossExponent = 2.5; // معامل الفقدان للبيئات الداخلية

  /// حساب المسافة بالأمتار بدقة عالية اعتماداً على النموذج الرياضي Log-distance Path Loss
  DistanceResult estimateDistance(double smoothedRssi, int frequency, {CalibrationData? calibration}) {
    if (smoothedRssi >= 0 || smoothedRssi <= -100) {
      return DistanceResult(distance: 0.0, minDistance: 0.0, maxDistance: 0.0);
    }

    double txPower = _defaultTxPower;
    
    // إذا قام المستخدم بمعايرة المودم، يتم ضبط التردد وقوة الإشارة المعايرة
    if (calibration != null) {
      txPower = calibration.maxRssi - (3.01 * _defaultPathLossExponent);
    }

    // معادلة قياس البعد: 10^((txPower - rssi) / (10 * n))
    double distance = math.pow(10.0, (txPower - smoothedRssi) / (10.0 * _defaultPathLossExponent)).toDouble();
    
    distance = distance.clamp(0.0, 25.0);
    double errorMargin = distance * 0.15; // هامش ثقة دقيق 15%

    return DistanceResult(
      distance: distance,
      minDistance: (distance - errorMargin).clamp(0.0, 25.0),
      maxDistance: (distance + errorMargin).clamp(0.0, 25.0),
    );
  }
}
