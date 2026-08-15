import 'package:flutter/services.dart';

class WifiRssiReader {
  static const _channel = MethodChannel('com.linkary/wifi_rssi');

  /// Read all wifi info at once to minimize platform channel overhead
  Future<Map<String, dynamic>> getWifiInfo() async {
    try {
      final data = await _channel.invokeMapMethod<String, dynamic>('getWifiInfo');
      return data ?? {};
    } catch (e) {
      return {};
    }
  }

  /// Read current RSSI (dBm)
  /// Typical values: -30 (very strong) to -90 (very weak)
  Future<int> getRssi() async {
    try {
      final rssi = await _channel.invokeMethod<int>('getRssi');
      return rssi ?? -100; // fallback to very weak
    } catch (e) {
      return -100;
    }
  }

  /// Read frequency (MHz)
  /// 2400-2500 = 2.4GHz, 5000-5900 = 5GHz
  Future<int> getFrequency() async {
    try {
      final freq = await _channel.invokeMethod<int>('getFrequency');
      return freq ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Is the frequency 5GHz?
  Future<bool> is5GHz() async {
    final freq = await getFrequency();
    return freq >= 5000;
  }

  /// Read SSID for verification
  Future<String> getSSID() async {
    try {
      final ssid = await _channel.invokeMethod<String>('getSSID');
      return ssid ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Read BSSID (Access Point MAC address) for modem network verification
  Future<String> getBSSID() async {
    try {
      final bssid = await _channel.invokeMethod<String>('getBSSID');
      return bssid ?? '';
    } catch (e) {
      return '';
    }
  }
}
