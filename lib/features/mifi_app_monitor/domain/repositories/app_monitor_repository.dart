import '../entities/app_usage_entity.dart';

abstract class AppMonitorRepository {
  Future<bool> checkUsagePermission();
  Future<void> requestUsagePermission();
  Future<List<AppUsageEntity>> getCurrentSystemUsage({int? startTime, int? endTime});
  Future<Map<String, List<int>>> getBaselineSnapshot();
  Future<void> saveBaselineSnapshot(Map<String, List<int>> snapshot);

  // Daily Stats Support
  Future<Map<String, List<int>>> getDailyBaseline();
  Future<void> saveDailyBaseline(Map<String, List<int>> snapshot);
  Future<void> saveDailyTotal(int rx, int tx);
  
  // High Precision Daily App Stats (Map: PackageName -> [rx, tx])
  Future<Map<String, List<int>>> getDailyAppTotals(DateTime date);
  Future<void> saveDailyAppTotals(Map<String, List<int>> totals);
  
  Future<List<Map<String, dynamic>>> getHistory(int days);
  Future<List<Map<String, dynamic>>> getAppHistory(String packageName, int days);

  // Session & Sync Persistence
  Future<void> saveLastUptime(int uptime);
  Future<int> getLastUptime();

  // App Goals
  Future<void> saveAppGoal(String packageName, int limitBytes);
  Future<Map<String, int>> getAppGoals();
  Future<void> removeAppGoal(String packageName);
  
  // Auto-Block Settings
  Future<Map<String, bool>> getAppAutoBlockPrefs();
  Future<void> saveAppAutoBlock(String packageName, bool enabled);
  Future<void> removeAppAutoBlock(String packageName);

  Future<List<AppUsageEntity>> getInstalledApps();
  Future<void> resetAppUsage(String packageName);
}