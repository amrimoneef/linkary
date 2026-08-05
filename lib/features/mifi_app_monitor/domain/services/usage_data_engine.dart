import '../entities/app_usage_entity.dart';
import '../repositories/app_monitor_repository.dart';
import '../use_cases/calculate_usage_delta_usecase.dart';
import 'modem_session_service.dart';

class UsageSnapshot {
  final List<AppUsageEntity> sessionDelta;
  final List<AppUsageEntity> todayDelta;
  final List<AppUsageEntity> rawBootStats;
  final Map<String, List<int>> newSessionBaseline;
  final Map<String, List<int>> newDailyBaseline;
  final int currentUptime;
  final bool modemRestarted;

  UsageSnapshot({
    required this.sessionDelta,
    required this.todayDelta,
    required this.rawBootStats,
    required this.newSessionBaseline,
    required this.newDailyBaseline,
    required this.currentUptime,
    required this.modemRestarted,
  });
}

class UsageDataEngine {
  final AppMonitorRepository repository;
  final CalculateUsageDeltaUseCase deltaUseCase;
  final ModemSessionService sessionService;

  UsageDataEngine({
    required this.repository,
    required this.deltaUseCase,
    required this.sessionService,
  });

  Future<UsageSnapshot> fetchAndProcess({
    required Map<String, List<int>>? sessionBaseline,
    required Map<String, List<int>> dailyBaseline,
    required Map<String, List<int>>? previousStats,
    required int? lastModemUptime,
    required bool isConnectedToTargetMiFi,
  }) async {
    // 1. Fetch RAW data from Android
    final sysStatsBoot = await repository.getCurrentSystemUsage();
    
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final sysStatsToday = await repository.getCurrentSystemUsage(startTime: midnight);
    
    final currentUptime = sessionService.getCurrentModemUptime();

    // 2. Modem Session Sync
    bool modemRestarted = false;
    if (sessionService.hasModemRestarted(currentUptime, lastModemUptime ?? 0)) {
      modemRestarted = true;
    }

    // 3. Baselines Setup & Recovery
    Map<String, List<int>> updatedSessionBaseline = sessionBaseline ?? {};
    Map<String, List<int>> updatedDailyBaseline = Map.from(dailyBaseline);

    if ((sessionBaseline == null || sessionBaseline.isEmpty || modemRestarted) && isConnectedToTargetMiFi) {
      updatedSessionBaseline = {for (var app in sysStatsBoot) app.packageName: [app.rxBytes, app.txBytes]};
      await repository.saveBaselineSnapshot(updatedSessionBaseline);
      
      final baselineToday = {for (var app in sysStatsToday) app.packageName: [app.rxBytes, app.txBytes]};
      await repository.saveDailyBaseline(baselineToday);
      updatedDailyBaseline = baselineToday;
    } else if (isConnectedToTargetMiFi && updatedDailyBaseline.isEmpty) {
      updatedDailyBaseline = await repository.getDailyBaseline();
      
      if (updatedDailyBaseline.isEmpty) {
         final currentDbTotals = await repository.getDailyAppTotals(DateTime.now());
         final currentSessionDelta = deltaUseCase.execute(
           currentStats: sysStatsBoot,
           baselineStats: updatedSessionBaseline,
         );
         
         updatedDailyBaseline = Map.from(currentDbTotals);
         for (var app in currentSessionDelta) {
           final base = updatedDailyBaseline[app.packageName] ?? [0, 0];
           updatedDailyBaseline[app.packageName] = [
             (base[0] - app.rxBytes).clamp(0, double.maxFinite.toInt()),
             (base[1] - app.txBytes).clamp(0, double.maxFinite.toInt())
           ];
         }
      }
    }

    // 4. Calculate Deltas
    final sessionDeltaList = deltaUseCase.execute(
      currentStats: sysStatsBoot,
      baselineStats: updatedSessionBaseline,
      previousStats: previousStats, 
      minBytesThreshold: 0,
    );

    final todayDeltaList = deltaUseCase.execute(
      currentStats: sysStatsToday,
      baselineStats: updatedDailyBaseline,
      minBytesThreshold: 0,
    );

    return UsageSnapshot(
      sessionDelta: sessionDeltaList,
      todayDelta: todayDeltaList,
      rawBootStats: sysStatsBoot,
      newSessionBaseline: updatedSessionBaseline,
      newDailyBaseline: updatedDailyBaseline,
      currentUptime: currentUptime,
      modemRestarted: modemRestarted,
    );
  }
}
