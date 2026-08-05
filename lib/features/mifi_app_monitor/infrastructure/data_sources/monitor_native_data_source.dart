import 'package:flutter/services.dart';

class MonitorNativeDataSource {
  static const _channel = MethodChannel('com.linkary.mifi/monitor');

  Future<void> startMonitor() async {
    await _channel.invokeMethod('startMonitor');
  }

  Future<void> stopMonitor() async {
    await _channel.invokeMethod('stopMonitor');
  }

  Future<bool> isMonitorRunning() async {
    try {
      return await _channel.invokeMethod('isMonitorRunning') ?? false;
    } on PlatformException {
      return false;
    }
  }
}
