import '../entities/rssi_reading.dart';

enum SignalTrend {
  improving,
  worsening,
  stable,
  unknown
}

class TrendAnalyzer {
  static const int _windowSize = 20;

  SignalTrend analyze(List<RssiReading> history) {
    if (history.length < 5) return SignalTrend.unknown;

    final readings = history.length > _windowSize 
        ? history.sublist(history.length - _windowSize) 
        : history;

    // Calculate Linear Regression Slope
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumX2 = 0;
    int n = readings.length;

    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += readings[i].smoothedDbm;
      sumXY += i * readings[i].smoothedDbm;
      sumX2 += i * i;
    }

    double denominator = (n * sumX2) - (sumX * sumX);
    if (denominator == 0) return SignalTrend.stable;

    double slope = ((n * sumXY) - (sumX * sumY)) / denominator;

    // A slope > 0.3 dBm per tick (300ms) means it's improving noticeably (~1 dBm/sec)
    if (slope > 0.3) return SignalTrend.improving;
    if (slope < -0.3) return SignalTrend.worsening;
    
    return SignalTrend.stable;
  }
}
