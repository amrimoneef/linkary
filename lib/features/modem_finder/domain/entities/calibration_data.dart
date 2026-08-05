class CalibrationPoint {
  final double distance; // in meters
  final double rssi;
  
  CalibrationPoint({required this.distance, required this.rssi});
  
  Map<String, dynamic> toJson() => {
    'distance': distance,
    'rssi': rssi,
  };
  
  factory CalibrationPoint.fromJson(Map<String, dynamic> json) => CalibrationPoint(
    distance: (json['distance'] as num).toDouble(),
    rssi: (json['rssi'] as num).toDouble(),
  );
}

class CalibrationData {
  final double maxRssi; // The strongest signal recorded
  final int frequency; // 2400 (2.4GHz) or 5000 (5GHz)
  final DateTime timestamp;
  final List<CalibrationPoint> points; // For multi-point calibration

  CalibrationData({
    required this.maxRssi,
    required this.frequency,
    DateTime? timestamp,
    this.points = const [],
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'maxRssi': maxRssi,
    'frequency': frequency,
    'timestamp': timestamp.toIso8601String(),
    'points': points.map((p) => p.toJson()).toList(),
  };
  
  factory CalibrationData.fromJson(Map<String, dynamic> json) => CalibrationData(
    maxRssi: (json['maxRssi'] as num).toDouble(),
    frequency: json['frequency'] as int,
    timestamp: DateTime.parse(json['timestamp']),
    points: (json['points'] as List?)?.map((p) => CalibrationPoint.fromJson(p)).toList() ?? [],
  );
}
