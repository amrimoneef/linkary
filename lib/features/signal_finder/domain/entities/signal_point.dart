class SignalPoint {
  final double compositeScore; // 0-100
  final double rsrp;
  final double sinr;
  final double rsrq;
  final DateTime timestamp;

  SignalPoint({
    required this.compositeScore,
    required this.rsrp,
    required this.sinr,
    required this.rsrq,
    required this.timestamp,
  });
}
