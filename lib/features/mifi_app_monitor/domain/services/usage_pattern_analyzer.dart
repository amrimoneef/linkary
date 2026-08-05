import '../entities/app_usage_entity.dart';
import '../repositories/app_monitor_repository.dart';

class UsageInsight {
  final bool isHigherThanAverage;
  final int differencePercentage;
  final String formattedMessage;

  UsageInsight({
    required this.isHigherThanAverage,
    required this.differencePercentage,
    required this.formattedMessage,
  });
}

class UsagePatternAnalyzer {
  final AppMonitorRepository _repository;
  
  // Cache the average bytes per day so we don't process JSON history every 3 seconds
  int? _cachedAverageBytesPerDay;
  DateTime? _lastCacheTime;

  UsagePatternAnalyzer(this._repository);

  Future<UsageInsight?> generateDailyInsight({
    required int todayTotalBytes,
  }) async {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    // If cache is empty or it's a new day, refresh the cache
    if (_cachedAverageBytesPerDay == null || _lastCacheTime == null || _lastCacheTime!.day != now.day) {
      final history = await _repository.getHistory(7);
      
      if (history.length < 2) {
        return null; // Not enough data for insight
      }

      int pastDaysCount = 0;
      int pastDaysTotalBytes = 0;

      for (var day in history) {
        if (day['date'] != todayStr) {
          pastDaysCount++;
          pastDaysTotalBytes += ((day['rx'] as int) + (day['tx'] as int));
        }
      }

      if (pastDaysCount == 0) return null;

      _cachedAverageBytesPerDay = pastDaysTotalBytes ~/ pastDaysCount;
      _lastCacheTime = now;
    }
    
    if (_cachedAverageBytesPerDay == null || _cachedAverageBytesPerDay == 0) return null; // Avoid division by zero

    double ratio = todayTotalBytes / _cachedAverageBytesPerDay!;
    int diffPercentage = ((ratio - 1) * 100).abs().toInt();

    if (diffPercentage < 5) {
      return UsageInsight(
        isHigherThanAverage: false,
        differencePercentage: 0,
        formattedMessage: "✨ استهلاكك اليوم ضمن المعدل الطبيعي مقارنة بالأيام الماضية.",
      );
    } else if (ratio > 1) {
      return UsageInsight(
        isHigherThanAverage: true,
        differencePercentage: diffPercentage,
        formattedMessage: " استهلاكك اليوم أعلى من المعتاد بـ $diffPercentage%",
      );
    } else {
      return UsageInsight(
        isHigherThanAverage: false,
        differencePercentage: diffPercentage,
        formattedMessage: " استهلاكك اليوم أقل من المعتاد بـ $diffPercentage%",
      );
    }
  }
}
