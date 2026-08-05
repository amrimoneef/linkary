class DashboardEntity {
  final String networkType; // مثل: 4g
  final int signalLevel;    // مثل: 5 (قوة الإشارة من 0 إلى 5)
  final int rssi;           // قوة الإشارة بالديسيبل (مثل: 64)
  final String ipv4Ip;      // الـ IP الداخلي (مثل: 100.82.160.201)
  final String networkName; // اسم مزود الخدمة (مثل: 421 10)
  final int batteryCapacity;
  final bool isCharging;
  final String phoneNumber;
  final String imei;
  final int txSpeed;
  final int rxSpeed;
  final int currentDuration;
  final int totalDuration;
  final int currentUsage;
  final int totalUsage;
  final bool isDataConnected;

  DashboardEntity({
    required this.networkType,
    required this.signalLevel,
    required this.rssi,
    required this.ipv4Ip,
    required this.networkName,
    required this.batteryCapacity,
    required this.isCharging,
    required this.phoneNumber,
    required this.imei,
    required this.txSpeed,
    required this.rxSpeed,
    required this.currentDuration,
    required this.currentUsage,
    required this.totalUsage,
    required this.totalDuration,
    required this.isDataConnected,
  });
}