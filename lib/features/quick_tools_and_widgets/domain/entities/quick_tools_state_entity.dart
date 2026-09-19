class QuickToolsStateEntity {
  final bool isNotificationEnabled;
  final bool isConnected;
  final String balanceText;
  final String daysRemaining;
  final int batteryLevel;
  final bool isCharging;
  final int signalBars;
  final String signalText;
  final int connectedDevicesCount;
  final DateTime lastUpdated;
  final String networkSpeed;
  final String packageName;
  final int currentSessionUsageBytes;
  final int totalAccumulatedUsageBytes;
  final int? expectedBalanceBytes;
  final int totalPlanBytes;

  const QuickToolsStateEntity({
    this.isNotificationEnabled = false,
    this.isConnected = false,
    this.balanceText = '-- GB',
    this.daysRemaining = '-- يوم',
    this.batteryLevel = 0,
    this.isCharging = false,
    this.signalBars = 0,
    this.signalText = 'غير متصل',
    this.connectedDevicesCount = 0,
    required this.lastUpdated,
    this.networkSpeed = '0 KB/s',
    this.packageName = 'باقة نشطة',
    this.currentSessionUsageBytes = 0,
    this.totalAccumulatedUsageBytes = 0,
    this.expectedBalanceBytes,
    this.totalPlanBytes = 0,
  });

  QuickToolsStateEntity copyWith({
    bool? isNotificationEnabled,
    bool? isConnected,
    String? balanceText,
    String? daysRemaining,
    int? batteryLevel,
    bool? isCharging,
    int? signalBars,
    String? signalText,
    int? connectedDevicesCount,
    DateTime? lastUpdated,
    String? networkSpeed,
    String? packageName,
    int? currentSessionUsageBytes,
    int? totalAccumulatedUsageBytes,
    int? expectedBalanceBytes,
    int? totalPlanBytes,
  }) {
    return QuickToolsStateEntity(
      isNotificationEnabled: isNotificationEnabled ?? this.isNotificationEnabled,
      isConnected: isConnected ?? this.isConnected,
      balanceText: balanceText ?? this.balanceText,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      isCharging: isCharging ?? this.isCharging,
      signalBars: signalBars ?? this.signalBars,
      signalText: signalText ?? this.signalText,
      connectedDevicesCount:
          connectedDevicesCount ?? this.connectedDevicesCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      networkSpeed: networkSpeed ?? this.networkSpeed,
      packageName: packageName ?? this.packageName,
      currentSessionUsageBytes:
          currentSessionUsageBytes ?? this.currentSessionUsageBytes,
      totalAccumulatedUsageBytes:
          totalAccumulatedUsageBytes ?? this.totalAccumulatedUsageBytes,
      expectedBalanceBytes:
          expectedBalanceBytes ?? this.expectedBalanceBytes,
      totalPlanBytes: totalPlanBytes ?? this.totalPlanBytes,
    );
  }

  /// وقت آخر تحديث بتنسيق 12 ساعة (مثال: 10:48 م أو 08:30 ص)
  String get lastUpdated12h {
    final h = lastUpdated.hour;
    final m = lastUpdated.minute.toString().padLeft(2, '0');
    final hour12 = (h == 0) ? 12 : (h > 12 ? h - 12 : h);
    final period = h >= 12 ? 'م' : 'ص';
    return '$hour12:$m $period';
  }

  /// اسم الباقة النظيف بدون DATA_ONLY
  String get cleanPackageName {
    var cleaned = packageName
        .replaceAll(RegExp(r'[_-\s]*DATA_ONLY[_-\s]*', caseSensitive: false), ' ')
        .trim();
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.isNotEmpty ? cleaned : 'باقة نشطة';
  }

  /// استخراج القيمة العددية للرصيد (مثلاً "28.4" من "28.4 GB")
  String get balanceNumericValue {
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(balanceText);
    return match?.group(1) ?? '--';
  }

  /// استخراج وحدة القياس (GB أو MB)
  String get balanceUnit {
    if (balanceText.toUpperCase().contains('MB')) return 'MB';
    return 'GB';
  }

  /// القيمة العددية كـ double
  double get balanceNumericDouble {
    final val = double.tryParse(balanceNumericValue);
    return val ?? 0.0;
  }

  /// حجم إجمالي الباقة بالجيجابايت
  double get totalPlanGigabytes {
    if (totalPlanBytes > 0) {
      return totalPlanBytes / (1024 * 1024 * 1024);
    }
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(cleanPackageName);
    if (match != null) {
      final val = double.tryParse(match.group(1)!) ?? 0.0;
      if (val > 0) return val;
    }
    return balanceNumericDouble > 40 ? 80.0 : 40.0;
  }

  /// استهلاك الجلسة الحالية بتنسيق الوحدة أولاً (مثال: GB 1.2 أو MB 450)
  String get currentSessionUsageText => _formatBytesUnitFirst(currentSessionUsageBytes);

  /// الاستهلاك المتراكم بتنسيق الوحدة أولاً (مثال: GB 40.0)
  String get accumulatedUsageText => _formatBytesUnitFirst(totalAccumulatedUsageBytes);

  /// دالة مساعدة لتنسيق البيانات بالوحدة أولاً
  static String _formatBytesUnitFirst(int bytes) {
    if (bytes <= 0) return 'GB 0.0';
    if (bytes < 1024 * 1024 * 1024) {
      final mb = (bytes / (1024 * 1024)).toStringAsFixed(1);
      return 'MB $mb';
    } else {
      final gb = (bytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
      return 'GB $gb';
    }
  }

  /// شريط التقدم الحقيقي المحسوب بدقة من الرصيد المتوقع بالنسبة للباقة الحالية (0.0 إلى 1.0)
  double get quotaProgressRatio {
    // 1. إذا توفرت بيانات الرصيد المتوقع بالبايت وحجم الباقة بالبايت
    if (totalPlanBytes > 0 && expectedBalanceBytes != null && expectedBalanceBytes! > 0) {
      return (expectedBalanceBytes! / totalPlanBytes).clamp(0.01, 1.0);
    }

    // 2. إذا توفر الرصيد الرقمي وحجم الباقة المحسوب
    final totalGb = totalPlanGigabytes;
    final remainingGb = balanceNumericDouble;
    if (totalGb > 0 && remainingGb > 0) {
      return (remainingGb / totalGb).clamp(0.01, 1.0);
    }

    return 0.5;
  }

  /// نسبة التقدم كعدد صحيح (1 إلى 100) للويدجت وشريط الإشعارات
  int get quotaProgressPercent => (quotaProgressRatio * 100).round().clamp(1, 100);
}
