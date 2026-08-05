import '../entities/app_usage_entity.dart';
import '../repositories/app_monitor_repository.dart';

class AlertMessage {
  final String? packageName;
  final String? appName;
  final String message;
  final bool isSpammy; // true for speed spikes, false for global/goal limit
  final bool isGoalExceeded; // true when app hits 100% of its goal

  AlertMessage({
    this.packageName,
    this.appName,
    required this.message,
    this.isSpammy = false,
    this.isGoalExceeded = false,
  });

  @override
  String toString() => message;
}

class CheckUsageAlertsUseCase {
  final AppMonitorRepository _repository;
  
  // Alert thresholds
  static const int HIGH_USAGE_THRESHOLD = 536870912; // 512MB session
  static const int SPIKE_THRESHOLD_BYTES_PER_INTERVAL = 15728640; // 15MB in 3 seconds (~40Mbps)

  CheckUsageAlertsUseCase(this._repository);

  /// Checks if a session or app has exceeded safe/typical usage limits.
  /// Returns a list of alert messages if any.
  Future<List<AlertMessage>> execute({
    required int currentSessionTotal,
    required List<AppUsageEntity> apps,
    required Map<String, int> appGoals,
  }) async {
    List<AlertMessage> alerts = [];
    
    // 1. Session Global Alert
    if (currentSessionTotal > HIGH_USAGE_THRESHOLD) {
      alerts.add(AlertMessage(
        message: 'تنبيه: استهلاك الجلسة الحالية تجاوز 512 ميجابايت.',
      ));
    }

    // 2. Individual App Alerts (Goals & Spikes)
    for (var app in apps) {
      // Goal Check
      final goal = appGoals[app.packageName];
      if (goal != null && goal > 0) {
        double percentage = (app.totalBytes / goal);
        if (percentage >= 1.0) {
          alerts.add(AlertMessage(
            packageName: app.packageName,
            appName: app.appName,
            message: 'تنبيه: تجاوز تطبيق ${app.appName} سقف الاستهلاك المحدد (${goal ~/ 1048576} ميجابايت).',
            isGoalExceeded: true,
          ));
        } else if (percentage >= 0.9) {
          alerts.add(AlertMessage(
            packageName: app.packageName,
            appName: app.appName,
            message: 'تنبيه: تطبيق ${app.appName} قارب على تجاوز سقف الاستهلاك (90%).',
          ));
        }
      }

      // Spike Detection (Abnormal Background/Sudden usage)
      if (app.rxSpeed + app.txSpeed > SPIKE_THRESHOLD_BYTES_PER_INTERVAL) {
        alerts.add(AlertMessage(
          packageName: app.packageName,
          appName: app.appName,
          message: 'تنبيه: تطبيق ${app.appName} يستهلك بيانات عالية جداً الآن (${(app.rxSpeed + app.txSpeed) ~/ 1048576} MB/s).',
          isSpammy: true,
        ));
      }
    }
    
    return alerts;
  }
}
