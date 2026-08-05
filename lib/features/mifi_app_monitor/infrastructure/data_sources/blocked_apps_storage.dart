import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/blocked_app.dart';

class BlockedAppsStorage {
  static const _appsKey = 'mifi_firewall_blocked_apps';
  static const _enabledKey = 'mifi_firewall_enabled';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _storage async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<List<BlockedApp>> getBlockedApps() async {
    final prefs = await _storage;
    final jsonString = prefs.getString(_appsKey);
    if (jsonString == null) return [];
    
    try {
      final list = jsonDecode(jsonString) as List;
      return list.map((e) => BlockedApp.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveBlockedApps(List<BlockedApp> apps) async {
    final prefs = await _storage;
    final jsonString = jsonEncode(apps.map((e) => e.toJson()).toList());
    await prefs.setString(_appsKey, jsonString);
  }

  Future<void> setFirewallEnabled(bool enabled) async {
    final prefs = await _storage;
    await prefs.setBool(_enabledKey, enabled);
  }

  Future<bool> getFirewallEnabled() async {
    final prefs = await _storage;
    return prefs.getBool(_enabledKey) ?? false;
  }
}
