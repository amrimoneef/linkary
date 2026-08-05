import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../entities/calibration_data.dart';

class CalibrationService {
  static const String _keyMaxRssi = 'modem_finder_calibrated_max_rssi';
  static const String _keyCalibrationData = 'modem_finder_calibration_data';
  static const String _keyAntiLossEnabled = 'modem_finder_anti_loss_enabled';

  Future<void> saveMaxRssi(int rssi) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMaxRssi, rssi);
  }

  Future<void> saveCalibrationData(CalibrationData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCalibrationData, jsonEncode(data.toJson()));
    await prefs.setInt(_keyMaxRssi, data.maxRssi.toInt()); // legacy fallback
  }

  Future<CalibrationData?> getCalibrationData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyCalibrationData);
    if (jsonStr != null) {
      try {
        return CalibrationData.fromJson(jsonDecode(jsonStr));
      } catch (e) {
        // Fallback
      }
    }
    
    final maxRssi = prefs.getInt(_keyMaxRssi);
    if (maxRssi != null) {
      return CalibrationData(maxRssi: maxRssi.toDouble(), frequency: 2400); // legacy fallback
    }
    return null;
  }

  Future<int?> getMaxRssi() async {
    final data = await getCalibrationData();
    return data?.maxRssi.toInt();
  }
  
  Future<void> resetCalibration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyMaxRssi);
    await prefs.remove(_keyCalibrationData);
  }

  Future<void> saveAntiLossEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAntiLossEnabled, enabled);
  }

  Future<bool> getAntiLossEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAntiLossEnabled) ?? false;
  }

  Future<void> saveAlarmSound(String soundName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('anti_loss_sound_name', soundName);
  }

  Future<String> getAlarmSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('anti_loss_sound_name') ?? 'alarm1';
  }

  Future<void> saveHideWelcomeMessage(bool hide) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hide_modem_finder_welcome', hide);
  }

  Future<bool> getHideWelcomeMessage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('hide_modem_finder_welcome') ?? false;
  }
}
