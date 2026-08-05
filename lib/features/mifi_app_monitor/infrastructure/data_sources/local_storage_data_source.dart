import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageDataSource {
  SharedPreferences? _prefs;
  
  // Keys
  static const _keyPrefix = 'mifi_monitor_';
  static const _keySessionBaseline = '${_keyPrefix}session_baseline';
  static const _keyLastUptime = '${_keyPrefix}last_uptime';
  static const _keyDailyBaselinePrefix = '${_keyPrefix}daily_baseline_';
  static const _keyDailyTotalPrefix = '${_keyPrefix}daily_total_';
  static const _keyDailyAppPrefix = '${_keyPrefix}daily_app_';
  static const _keyAppGoals = '${_keyPrefix}app_goals';
  static const _keyAppAutoBlock = '${_keyPrefix}app_auto_block';
  
  // Separator - safe as it doesn't appear in package names
  static const _separator = '|';
  
  Future<SharedPreferences> get _storage async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Saves a snapshot of app usage stats
  Future<void> saveSnapshot(String key, Map<String, List<int>> data) async {
    final prefs = await _storage;
    final List<String> encoded = data.entries
        .map((e) => '${e.key}$_separator${e.value[0]}$_separator${e.value[1]}')
        .toList();
    await prefs.setStringList(key, encoded);
  }

  /// Retrieves a snapshot of app usage stats
  Future<Map<String, List<int>>> getSnapshot(String key) async {
    final prefs = await _storage;
    final List<String>? saved = prefs.getStringList(key);
    if (saved == null) return {};

    final Map<String, List<int>> result = {};
    for (final item in saved) {
      final parts = item.split(_separator);
      if (parts.length >= 3) {
        result[parts[0]] = [
          int.tryParse(parts[1]) ?? 0,
          int.tryParse(parts[2]) ?? 0,
        ];
      }
    }
    return result;
  }

  // Session Baseline
  Future<void> saveSessionBaseline(Map<String, List<int>> data) =>
      saveSnapshot(_keySessionBaseline, data);
      
  Future<Map<String, List<int>>> getSessionBaseline() =>
      getSnapshot(_keySessionBaseline);

  // Daily operations
  String _dailyKey(String prefix, DateTime date) =>
      '$prefix${DateFormat('yyyy-MM-dd').format(date)}';
  
  Future<void> saveDailyBaseline(Map<String, List<int>> data) =>
      saveSnapshot(_dailyKey(_keyDailyBaselinePrefix, DateTime.now()), data);
  
  Future<Map<String, List<int>>> getDailyBaseline() =>
      getSnapshot(_dailyKey(_keyDailyBaselinePrefix, DateTime.now()));

  Future<void> saveDailyTotal(int rx, int tx) async {
    final prefs = await _storage;
    final key = _dailyKey(_keyDailyTotalPrefix, DateTime.now());
    await prefs.setString(key, '$rx,$tx');
  }

  Future<Map<String, List<int>>> getDailyAppTotals(DateTime date) =>
      getSnapshot(_dailyKey(_keyDailyAppPrefix, date));
  
  Future<void> saveDailyAppTotals(Map<String, List<int>> data) =>
      saveSnapshot(_dailyKey(_keyDailyAppPrefix, DateTime.now()), data);

  /// Retrieves historical usage totals for a given number of days
  Future<List<Map<String, dynamic>>> getHistory(int days) async {
    final prefs = await _storage;
    List<Map<String, dynamic>> history = [];

    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final key = _dailyKey(_keyDailyTotalPrefix, date);
      final saved = prefs.getString(key);
      
      int rx = 0, tx = 0;
      if (saved != null) {
        final parts = saved.split(',');
        rx = int.tryParse(parts[0]) ?? 0;
        tx = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      }

      history.add({
        'dayIndex': days - 1 - i,
        'dayName': DateFormat('EEEE').format(date),
        'date': DateFormat('yyyy-MM-dd').format(date),
        'rx': rx,
        'tx': tx,
      });
    }
    return history;
  }

  /// Retrieves the usage history for a specific application across a range of days
  Future<List<Map<String, dynamic>>> getAppHistory(String packageName, int days) async {
    List<Map<String, dynamic>> appHistory = [];

    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dayAppTotals = await getDailyAppTotals(date);
      
      final stats = dayAppTotals[packageName] ?? [0, 0];
      
      appHistory.add({
        'dayIndex': days - 1 - i,
        'dayName': DateFormat('EEEE').format(date),
        'date': DateFormat('yyyy-MM-dd').format(date),
        'rx': stats[0],
        'tx': stats[1],
      });
    }
    return appHistory;
  }

  // Uptime persistence
  Future<void> saveLastUptime(int uptime) async {
    final prefs = await _storage;
    await prefs.setInt(_keyLastUptime, uptime);
  }
  
  Future<int> getLastUptime() async {
    final prefs = await _storage;
    return prefs.getInt(_keyLastUptime) ?? 0;
  }

  // App Goals Persistence
  Future<void> saveAppGoal(String packageName, int limitBytes) async {
    final prefs = await _storage;
    final goals = await getAppGoals();
    goals[packageName] = limitBytes;
    
    final encoded = goals.entries.map((e) => '${e.key}$_separator${e.value}').toList();
    await prefs.setStringList(_keyAppGoals, encoded);
  }

  Future<Map<String, int>> getAppGoals() async {
    final prefs = await _storage;
    final saved = prefs.getStringList(_keyAppGoals);
    if (saved == null) return {};

    final Map<String, int> result = {};
    for (final item in saved) {
      final parts = item.split(_separator);
      if (parts.length >= 2) {
        result[parts[0]] = int.tryParse(parts[1]) ?? 0;
      }
    }
    return result;
  }

  Future<void> removeAppGoal(String packageName) async {
    final prefs = await _storage;
    final goals = await getAppGoals();
    goals.remove(packageName);
    
    final encoded = goals.entries.map((e) => '${e.key}$_separator${e.value}').toList();
    await prefs.setStringList(_keyAppGoals, encoded);
  }

  Future<Map<String, bool>> getAppAutoBlockPrefs() async {
    final prefs = await _storage;
    final list = prefs.getStringList(_keyAppAutoBlock) ?? [];
    Map<String, bool> results = {};
    for (var item in list) {
      final parts = item.split(_separator);
      if (parts.length >= 2) {
        results[parts[0]] = parts[1] == 'true';
      }
    }
    return results;
  }

  Future<void> saveAppAutoBlock(String packageName, bool enabled) async {
    final prefs = await _storage;
    final current = await getAppAutoBlockPrefs();
    current[packageName] = enabled;
    
    final encoded = current.entries.map((e) => '${e.key}$_separator${e.value}').toList();
    await prefs.setStringList(_keyAppAutoBlock, encoded);
  }

  Future<void> removeAppAutoBlock(String packageName) async {
    final prefs = await _storage;
    final current = await getAppAutoBlockPrefs();
    current.remove(packageName);
    
    final encoded = current.entries.map((e) => '${e.key}$_separator${e.value}').toList();
    await prefs.setStringList(_keyAppAutoBlock, encoded);
  }

  /// 🧹 Clean up old data (> retentionDays days)
  Future<int> cleanOldData({int retentionDays = 60}) async {
    final prefs = await _storage;
    final keys = prefs.getKeys();
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    int cleaned = 0;

    for (final key in keys) {
      if (!key.startsWith(_keyPrefix)) continue;
      
      final dateMatch = RegExp(r'(\d{4}-\d{2}-\d{2})$').firstMatch(key);
      if (dateMatch != null) {
        final date = DateTime.tryParse(dateMatch.group(1)!);
        if (date != null && date.isBefore(cutoff)) {
          await prefs.remove(key);
          cleaned++;
        }
      }
    }
    
    debugPrint('🧹 Cleaned $cleaned old monitor entries');
    return cleaned;
  }

  Future<void> resetAppUsage(String packageName) async {
    final prefs = await _storage;
    final now = DateTime.now();
    
    // For LocalStorageDataSource, we provide a way to clear TODAY's recorded totals for this app
    final todayAppTotals = await getDailyAppTotals(now);
    todayAppTotals[packageName] = [0, 0];
    await saveDailyAppTotals(todayAppTotals);
  }
}
