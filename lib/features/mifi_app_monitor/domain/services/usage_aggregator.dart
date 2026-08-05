import '../entities/app_usage_entity.dart';
import '../repositories/app_monitor_repository.dart';
import '../../presentation/controllers/app_monitor_controller.dart' show MonitorFilter;

class AggregatedResult {
  final List<AppUsageEntity> apps;
  final int totalRx;
  final int totalTx;

  AggregatedResult({
    required this.apps,
    required this.totalRx,
    required this.totalTx,
  });
}

class UsageAggregator {
  final AppMonitorRepository repository;

  UsageAggregator({required this.repository});

  Future<AggregatedResult> aggregate({
    required MonitorFilter filter,
    required List<AppUsageEntity> sessionDelta,
    required List<AppUsageEntity> todayDelta,
    required List<AppUsageEntity> rawBootStats,
  }) async {
    List<AppUsageEntity> rawDisplayList = [];
    int periodRxCount = 0;
    int periodTxCount = 0;

    int liveTodayRx = todayDelta.fold(0, (sum, app) => sum + app.rxBytes);
    int liveTodayTx = todayDelta.fold(0, (sum, app) => sum + app.txBytes);

    if (filter == MonitorFilter.session) {
      rawDisplayList = List.from(sessionDelta);
      periodRxCount = sessionDelta.fold(0, (sum, app) => sum + app.rxBytes);
      periodTxCount = sessionDelta.fold(0, (sum, app) => sum + app.txBytes);
    } 
    else if (filter == MonitorFilter.today) {
      rawDisplayList = List.from(todayDelta);
      periodRxCount = liveTodayRx;
      periodTxCount = liveTodayTx;
    }
    else {
      // Week or Month: Aggregation from DB (Days 1..N) + Live Today
      Map<String, List<int>> aggregatedMap = {};
      int aggregationDays = filter == MonitorFilter.week ? 7 : 30;

      for (int i = 1; i < aggregationDays; i++) {
        final date = DateTime.now().subtract(Duration(days: i));
        final dailyMap = await repository.getDailyAppTotals(date);
        dailyMap.forEach((pkg, bytes) {
          aggregatedMap[pkg] = [(aggregatedMap[pkg]?[0] ?? 0) + bytes[0], (aggregatedMap[pkg]?[1] ?? 0) + bytes[1]];
        });
      }
      
      // Add Live Today (Midnight Stats - Baseline At Connect)
      for (var appToday in todayDelta) {
        final current = aggregatedMap[appToday.packageName] ?? [0, 0];
        aggregatedMap[appToday.packageName] = [current[0] + appToday.rxBytes, current[1] + appToday.txBytes];
      }

      for (var app in rawBootStats) {
        final total = aggregatedMap[app.packageName];
        if (total != null && (total[0] > 0 || total[1] > 0)) {
           rawDisplayList.add(AppUsageEntity(
            packageName: app.packageName,
            appName: app.appName,
            totalBytes: total[0] + total[1],
            rxBytes: total[0],
            txBytes: total[1],
            rxSpeed: 0,
            txSpeed: 0,
            iconData: app.iconData,
          ));
        }
      }

      // Calculate totals for Week/Month from History + Today Live
      int chartDays = filter == MonitorFilter.month ? 30 : 7;
      final history = await repository.getHistory(chartDays);
      
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      for (var day in history) {
        if (day['date'] == todayStr) {
          periodRxCount += liveTodayRx;
          periodTxCount += liveTodayTx;
        } else {
          periodRxCount += (day['rx'] as int);
          periodTxCount += (day['tx'] as int);
        }
      }
    }

    return AggregatedResult(
      apps: rawDisplayList,
      totalRx: periodRxCount,
      totalTx: periodTxCount,
    );
  }
}
