import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BalanceTrackingData {
  final int lastFetchedBalanceBytes;
  final int initialRouterUsageBytes;
  final bool alert5GBFired;
  final bool alert1GBFired;
  final String? expiryDate;

  BalanceTrackingData({
    required this.lastFetchedBalanceBytes,
    required this.initialRouterUsageBytes,
    required this.alert5GBFired,
    required this.alert1GBFired,
    this.expiryDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'lastFetchedBalanceBytes': lastFetchedBalanceBytes,
      'initialRouterUsageBytes': initialRouterUsageBytes,
      'alert5GBFired': alert5GBFired,
      'alert1GBFired': alert1GBFired,
      'expiryDate': expiryDate,
    };
  }

  factory BalanceTrackingData.fromJson(Map<String, dynamic> json) {
    return BalanceTrackingData(
      lastFetchedBalanceBytes: json['lastFetchedBalanceBytes'] as int? ?? 0,
      initialRouterUsageBytes: json['initialRouterUsageBytes'] as int? ?? 0,
      alert5GBFired: json['alert5GBFired'] as bool? ?? false,
      alert1GBFired: json['alert1GBFired'] as bool? ?? false,
      expiryDate: json['expiryDate'] as String?,
    );
  }
}

class BalanceTrackingService {
  static const _storage = FlutterSecureStorage();
  static const _storageKey = 'expected_balance_tracking_data';

  static Future<BalanceTrackingData?> getData() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return BalanceTrackingData.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveData(BalanceTrackingData data) async {
    await _storage.write(key: _storageKey, value: jsonEncode(data.toJson()));
  }

  static Future<void> clearData() async {
    await _storage.delete(key: _storageKey);
  }
}
