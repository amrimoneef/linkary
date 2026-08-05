import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/app_usage_entity.dart';

class NativeStatsDataSource {
  // اسم القناة يجب أن يطابق تماماً ما كتبناه في Kotlin
  static const MethodChannel _channel = MethodChannel('com.linkary.mifi/usage');

  /// التحقق من وجود الصلاحية
  Future<bool> checkPermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('checkUsagePermission');
      return hasPermission;
    } catch (e) {
      debugPrint('Error checking permission: $e');
      return false;
    }
  }

  /// طلب الصلاحية (فتح شاشة الإعدادات)
  Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod('requestUsagePermission');
    } catch (e) {
      debugPrint('Error requesting permission: $e');
    }
  }

  /// جلب قائمة الاستهلاك الحالية من نواة الأندرويد
  Future<List<AppUsageEntity>> getCurrentUsage({int? startTime, int? endTime}) async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod('getAppUsage', {
        'startTime': startTime ?? 0,
        'endTime': endTime ?? DateTime.now().millisecondsSinceEpoch,
      });

      if (result == null) return [];

      List<AppUsageEntity> apps = [];
      for (var item in result) {
        final map = Map<String, dynamic>.from(item);
        apps.add(AppUsageEntity(
          packageName: map['packageName'],
          appName: map['appName'],
          totalBytes: map['totalBytes'],
          rxBytes: map['rxBytes'] ?? 0,
          txBytes: map['txBytes'] ?? 0,
          lastActiveTime: map['lastActiveTime'] != null && map['lastActiveTime'] > 0 
              ? DateTime.fromMillisecondsSinceEpoch(map['lastActiveTime']) 
              : null,
          usageTime: map['usageTime'] != null && map['usageTime'] > 0 
              ? Duration(milliseconds: map['usageTime']) 
              : null,

          iconData: map['iconData'] as Uint8List?,
        ));
      }
      return apps;
    } on PlatformException catch (e) {
      debugPrint('Failed to get app usage: ${e.message}');
      return [];
    }
  }

  /// جلب قائمة بجميع التطبيقات المثبتة في الجهاز
  Future<List<AppUsageEntity>> getInstalledApps() async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod('getInstalledApps');

      if (result == null) return [];

      List<AppUsageEntity> apps = [];
      for (var item in result) {
        final map = Map<String, dynamic>.from(item);
        apps.add(AppUsageEntity(
          packageName: map['packageName'],
          appName: map['appName'],
          totalBytes: 0,
          rxBytes: 0,
          txBytes: 0,
          isSystemApp: map['isSystemApp'] ?? false,
          lastActiveTime: map['lastActiveTime'] != null && map['lastActiveTime'] > 0 
              ? DateTime.fromMillisecondsSinceEpoch(map['lastActiveTime']) 
              : null,
          usageTime: map['usageTime'] != null && map['usageTime'] > 0 
              ? Duration(milliseconds: map['usageTime']) 
              : null,

          iconData: map['iconData'] as Uint8List?,
        ));
      }
      return apps;
    } on PlatformException catch (e) {
      debugPrint('Failed to get installed apps: ${e.message}');
      return [];
    }
  }
}