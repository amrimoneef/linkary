import '../entities/app_usage_entity.dart';

class CalculateUsageDeltaUseCase {
  /// Calculates usage since a baseline snapshot (Session/Daily)
  List<AppUsageEntity> execute({
    required List<AppUsageEntity> currentStats,
    required Map<String, List<int>> baselineStats, // [rx, tx]
    Map<String, List<int>>? previousStats, // [rx, tx] for speed calculation
    int minBytesThreshold = 10240, // 👈 Default 10KB
  }) {
    List<AppUsageEntity> deltaUsage = [];

    for (var currentApp in currentStats) {
      final baseline = baselineStats[currentApp.packageName] ?? [0, 0];
      final baselineRx = baseline[0];
      final baselineTx = baseline[1];

      final actualRx = currentApp.rxBytes - baselineRx;
      final actualTx = currentApp.txBytes - baselineTx;
      final actualTotal = actualRx + actualTx;

      // Speed calculation
      int rxSpeed = 0;
      int txSpeed = 0;
      if (previousStats != null && previousStats.containsKey(currentApp.packageName)) {
        final prev = previousStats[currentApp.packageName]!;
        rxSpeed = (currentApp.rxBytes - prev[0]).clamp(0, double.maxFinite.toInt());
        txSpeed = (currentApp.txBytes - prev[1]).clamp(0, double.maxFinite.toInt());
      }

      // Filter based on threshold OR current activity
      if (actualTotal >= minBytesThreshold || rxSpeed > 0 || txSpeed > 0) {
        deltaUsage.add(
          AppUsageEntity(
            packageName: currentApp.packageName,
            appName: currentApp.appName,
            iconData: currentApp.iconData,
            totalBytes: actualTotal,
            rxBytes: actualRx > 0 ? actualRx : 0,
            txBytes: actualTx > 0 ? actualTx : 0,
            rxSpeed: rxSpeed,
            txSpeed: txSpeed,
          ),
        );
      }
    }

    deltaUsage.sort((a, b) => b.totalBytes.compareTo(a.totalBytes));
    return deltaUsage;
  }
}