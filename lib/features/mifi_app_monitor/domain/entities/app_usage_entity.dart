import 'dart:typed_data';
import 'app_category.dart';

class AppUsageEntity {
  final String packageName;
  final String appName;
  final int totalBytes;
  final int rxBytes;
  final int txBytes;
  final int rxSpeed; // 📥 Current Download Speed in Bytes/s
  final int txSpeed; // 📤 Current Upload Speed in Bytes/s
  final Uint8List? iconData;
  final AppCategory category;      // Added category
  final bool isSystemApp;          // Added flag for system apps
  final DateTime? lastActiveTime;  // Added for history tracking
  final Duration? usageTime;       // ⏱️ Real usage time from system


  AppUsageEntity({
    required this.packageName,
    required this.appName,
    required this.totalBytes,
    required this.rxBytes,
    required this.txBytes,
    this.rxSpeed = 0,
    this.txSpeed = 0,
    this.iconData,
    this.category = AppCategory.other,
    this.isSystemApp = false,
    this.lastActiveTime,
    this.usageTime,

  });

  // Calculate percentage helper
  double getUsagePercentage(int totalSessionBytes) {
    if (totalSessionBytes == 0) return 0.0;
    return (totalBytes / totalSessionBytes).clamp(0.0, 1.0);
  }

  bool get isCurrentlyActive => rxSpeed > 0 || txSpeed > 0;
}