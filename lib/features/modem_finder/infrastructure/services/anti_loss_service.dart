import 'package:flutter/services.dart';

class AntiLossService {
  static const MethodChannel _channel = MethodChannel('com.linkary/anti_loss');

  Future<bool> startAntiLoss({String soundName = 'alarm1', String? bssid}) async {
    try {
      final bool? result = await _channel.invokeMethod('startAntiLoss', {
        'soundName': soundName,
        if (bssid != null && bssid.isNotEmpty) 'bssid': bssid,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      print("Failed to start anti-loss service: '${e.message}'.");
      return false;
    }
  }

  Future<void> previewAlarmSound(String soundName) async {
    try {
      await _channel.invokeMethod('previewAlarmSound', {'soundName': soundName});
    } on PlatformException catch (e) {
      print("Failed to preview sound: '${e.message}'.");
    }
  }

  Future<bool> stopAntiLoss() async {
    try {
      final bool? result = await _channel.invokeMethod('stopAntiLoss');
      return result ?? false;
    } on PlatformException catch (e) {
      print("Failed to stop anti-loss service: '${e.message}'.");
      return false;
    }
  }

  Future<bool> isAntiLossRunning() async {
    try {
      final bool? result = await _channel.invokeMethod('isAntiLossRunning');
      return result ?? false;
    } on PlatformException catch (e) {
      print("Failed to check anti-loss status: '${e.message}'.");
      return false;
    }
  }
}
