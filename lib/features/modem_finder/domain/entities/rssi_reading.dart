class RssiReading {
  final int rawDbm;
  final double smoothedDbm;
  final DateTime timestamp;

  RssiReading({
    required this.rawDbm,
    required this.smoothedDbm,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
