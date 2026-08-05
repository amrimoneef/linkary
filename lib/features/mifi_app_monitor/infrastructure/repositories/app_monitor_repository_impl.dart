import '../../domain/entities/app_usage_entity.dart';
import '../../domain/repositories/app_monitor_repository.dart';
import '../data_sources/native_stats_data_source.dart';
import '../data_sources/local_storage_data_source.dart';

class AppMonitorRepositoryImpl implements AppMonitorRepository {
  final NativeStatsDataSource nativeDataSource;
  final LocalStorageDataSource localStorage;

  AppMonitorRepositoryImpl({
    required this.nativeDataSource,
    required this.localStorage,
  });

  @override
  Future<bool> checkUsagePermission() async {
    return await nativeDataSource.checkPermission();
  }

  @override
  Future<void> requestUsagePermission() async {
    await nativeDataSource.requestPermission();
  }

  @override
  Future<List<AppUsageEntity>> getCurrentSystemUsage({int? startTime, int? endTime}) async {
    return await nativeDataSource.getCurrentUsage(startTime: startTime, endTime: endTime);
  }

  @override
  Future<Map<String, List<int>>> getBaselineSnapshot() async {
    return await localStorage.getSessionBaseline();
  }

  @override
  Future<void> saveBaselineSnapshot(Map<String, List<int>> snapshot) async {
    await localStorage.saveSessionBaseline(snapshot);
  }

  @override
  Future<Map<String, List<int>>> getDailyBaseline() async {
    return await localStorage.getDailyBaseline();
  }

  @override
  Future<void> saveDailyBaseline(Map<String, List<int>> snapshot) async {
    await localStorage.saveDailyBaseline(snapshot);
  }

  @override
  Future<void> saveDailyTotal(int rx, int tx) async {
    await localStorage.saveDailyTotal(rx, tx);
  }

  @override
  Future<Map<String, List<int>>> getDailyAppTotals(DateTime date) async {
    return await localStorage.getDailyAppTotals(date);
  }

  @override
  Future<void> saveDailyAppTotals(Map<String, List<int>> totals) async {
    await localStorage.saveDailyAppTotals(totals);
  }

  @override
  Future<List<Map<String, dynamic>>> getHistory(int days) async {
    return await localStorage.getHistory(days);
  }

  @override
  Future<List<Map<String, dynamic>>> getAppHistory(String packageName, int days) async {
    return await localStorage.getAppHistory(packageName, days);
  }

  @override
  Future<int> getLastUptime() async {
    return await localStorage.getLastUptime();
  }

  @override
  Future<void> saveLastUptime(int uptime) async {
    await localStorage.saveLastUptime(uptime);
  }

  @override
  Future<void> saveAppGoal(String packageName, int limitBytes) async {
    await localStorage.saveAppGoal(packageName, limitBytes);
  }

  @override
  Future<Map<String, int>> getAppGoals() async {
    return await localStorage.getAppGoals();
  }

  @override
  Future<void> removeAppGoal(String packageName) async {
    await localStorage.removeAppGoal(packageName);
  }

  @override
  Future<Map<String, bool>> getAppAutoBlockPrefs() async {
    return await localStorage.getAppAutoBlockPrefs();
  }

  @override
  Future<void> saveAppAutoBlock(String packageName, bool enabled) async {
    await localStorage.saveAppAutoBlock(packageName, enabled);
  }

  @override
  Future<void> removeAppAutoBlock(String packageName) async {
    await localStorage.removeAppAutoBlock(packageName);
  }

  @override
  Future<List<AppUsageEntity>> getInstalledApps() async {
    return await nativeDataSource.getInstalledApps();
  }

  @override
  Future<void> resetAppUsage(String packageName) async {
    await localStorage.resetAppUsage(packageName);
  }
}