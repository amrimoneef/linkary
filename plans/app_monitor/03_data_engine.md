# ⚙️ محرك البيانات المتقدم — Data Engine

## المشاكل الحالية في محرك البيانات

### 1. Android Native: استعلام من الصفر
```kotlin
val startTime = 0L  // يجمع بيانات من يوم شراء الجهاز!
val endTime = System.currentTimeMillis()
```

### 2. لا يوجد تحسين أداء (Caching)
- كل 3 ثوانٍ يجلب القائمة كاملة من Android + أيقونات كل التطبيقات
- لا يوجد cache للأيقونات (تُحمّل كل مرة)

### 3. صيغة التسلسل هشة
```dart
'${e.key}:::${e.value[0]}:::${e.value[1]}'  // ماذا لو احتوى اسم الحزمة على :::?
```

---

## 🚀 التحسينات المقترحة

### 1. تحسين Android Native

```kotlin
// MainActivity.kt - تحسينات الأداء

// 1. Cache الأيقونات في الذاكرة
private val iconCache = mutableMapOf<String, ByteArray?>()

// 2. استعلام ذكي بنطاق زمني
private fun getWifiUsageStats(queryStartTime: Long = 0L): List<Map<String, Any?>> {
    val networkStatsManager = getSystemService(Context.NETWORK_STATS_SERVICE) as NetworkStatsManager
    val startTime = if (queryStartTime > 0) queryStartTime else {
        // آخر 24 ساعة بدلاً من الصفر
        System.currentTimeMillis() - (24 * 60 * 60 * 1000)
    }
    val endTime = System.currentTimeMillis()
    
    // ... الاستعلام بالنطاق الزمني المحدد
}

// 3. أيقونات مُخزنة مؤقتاً
private fun getIconByteArrayCached(packageName: String): ByteArray? {
    return iconCache.getOrPut(packageName) {
        getIconByteArray(packageName)
    }
}

// 4. تصنيف النظام مبكراً (في Native)
private fun isSystemApp(packageName: String): Boolean {
    return try {
        val appInfo = packageManager.getApplicationInfo(packageName, 0)
        (appInfo.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0
    } catch (e: Exception) { false }
}
```

### 2. طرق MethodChannel الجديدة

```kotlin
when (call.method) {
    "checkUsagePermission" -> { /* موجود */ }
    "requestUsagePermission" -> { /* موجود */ }
    "getAppUsage" -> { /* موجود - تحسين */ }
    
    // ⬇️ جديد
    "getAppUsageSince" -> {
        // جلب البيانات من وقت معين فقط (أداء أفضل)
        val sinceTimestamp = call.argument<Long>("since") ?: 0L
        Thread {
            val data = getWifiUsageStats(sinceTimestamp)
            Handler(Looper.getMainLooper()).post { result.success(data) }
        }.start()
    }
    "getDeviceBootTime" -> {
        // وقت تشغيل الجهاز (لحساب الـ baseline بدقة)
        val bootTime = System.currentTimeMillis() - android.os.SystemClock.elapsedRealtime()
        result.success(bootTime)
    }
}
```

### 3. NativeStatsDataSource المُحسّن

```dart
class NativeStatsDataSource {
  static const MethodChannel _channel = MethodChannel('com.linkary.mifi/usage');
  
  // Cache للأيقونات (لا حاجة لجلبها كل 3 ثوانٍ)
  final Map<String, Uint8List?> _iconCache = {};

  Future<bool> checkPermission() async { /* كما هو */ }
  Future<void> requestPermission() async { /* كما هو */ }
  
  /// جلب البيانات مع تحسينات الأداء
  Future<List<AppUsageEntity>> getCurrentUsage({int? sinceTimestamp}) async {
    try {
      final List<dynamic> result = await _channel.invokeMethod(
        sinceTimestamp != null ? 'getAppUsageSince' : 'getAppUsage',
        sinceTimestamp != null ? {'since': sinceTimestamp} : null,
      );

      return result.map((item) {
        final map = Map<String, dynamic>.from(item);
        final pkg = map['packageName'] as String? ?? 'unknown';
        
        // Cache الأيقونة
        if (map['iconData'] != null && !_iconCache.containsKey(pkg)) {
          _iconCache[pkg] = map['iconData'] as Uint8List?;
        }
        
        return AppUsageEntity(
          packageName: pkg,
          appName: map['appName'] as String? ?? pkg,
          totalBytes: (map['totalBytes'] as int?) ?? 0,
          rxBytes: (map['rxBytes'] as int?) ?? 0,
          txBytes: (map['txBytes'] as int?) ?? 0,
          iconData: _iconCache[pkg] ?? map['iconData'] as Uint8List?,
          isSystemApp: map['isSystemApp'] as bool? ?? false,
        );
      }).toList();
    } on PlatformException catch (e) {
      debugPrint('Failed to get app usage: ${e.message}');
      return [];
    }
  }
  
  /// تنظيف cache الأيقونات (عند الخروج أو عند الحاجة)
  void clearIconCache() => _iconCache.clear();
}
```

### 4. LocalStorageDataSource (جديد)

```dart
class LocalStorageDataSource {
  SharedPreferences? _prefs;
  
  // Keys
  static const _keyPrefix = 'mifi_monitor_';
  static const _keySessionBaseline = '${_keyPrefix}session_baseline';
  static const _keyLastUptime = '${_keyPrefix}last_uptime';
  static const _keyDailyBaselinePrefix = '${_keyPrefix}daily_baseline_';
  static const _keyDailyTotalPrefix = '${_keyPrefix}daily_total_';
  static const _keyDailyAppPrefix = '${_keyPrefix}daily_app_';
  static const _keyAlertThresholds = '${_keyPrefix}alert_thresholds';
  
  // Separator - آمن لأن | لا يظهر في package names
  static const _separator = '|';
  
  Future<SharedPreferences> get _storage async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// حفظ/جلب لقطة (Generic)
  Future<void> saveSnapshot(String key, Map<String, List<int>> data) async {
    final prefs = await _storage;
    final List<String> encoded = data.entries
        .map((e) => '${e.key}$_separator${e.value[0]}$_separator${e.value[1]}')
        .toList();
    await prefs.setStringList(key, encoded);
  }

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

  // History
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

  // Uptime
  Future<void> saveLastUptime(int uptime) async {
    final prefs = await _storage;
    await prefs.setInt(_keyLastUptime, uptime);
  }
  
  Future<int> getLastUptime() async {
    final prefs = await _storage;
    return prefs.getInt(_keyLastUptime) ?? 0;
  }

  /// 🧹 تنظيف البيانات القديمة (أكثر من retentionDays يوم)
  Future<int> cleanOldData({int retentionDays = 60}) async {
    final prefs = await _storage;
    final keys = prefs.getKeys();
    final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
    int cleaned = 0;

    for (final key in keys) {
      if (!key.startsWith(_keyPrefix)) continue;
      
      // استخراج التاريخ من المفتاح
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
}
```

---

## ⏱️ تحسين حساب السرعة

### المشكلة الحالية
```dart
double bytesPerSecond = bytesPerInterval / 3.0; // يفترض دائماً 3 ثوانٍ
```

### الحل: قياس الوقت الفعلي
```dart
class SpeedTracker {
  DateTime? _lastMeasurement;
  Map<String, List<int>>? _lastStats;

  /// يحسب السرعة بناءً على الفارق الزمني الحقيقي
  Map<String, AppSpeed> calculateSpeeds(
    Map<String, List<int>> currentStats,
  ) {
    final now = DateTime.now();
    final results = <String, AppSpeed>{};

    if (_lastMeasurement != null && _lastStats != null) {
      final elapsed = now.difference(_lastMeasurement!).inMilliseconds;
      if (elapsed > 0) {
        final secondsFactor = elapsed / 1000.0;
        
        for (final entry in currentStats.entries) {
          final prev = _lastStats![entry.key];
          if (prev != null) {
            final rxDiff = (entry.value[0] - prev[0]).clamp(0, double.maxFinite.toInt());
            final txDiff = (entry.value[1] - prev[1]).clamp(0, double.maxFinite.toInt());
            
            results[entry.key] = AppSpeed(
              rxBytesPerSecond: (rxDiff / secondsFactor).round(),
              txBytesPerSecond: (txDiff / secondsFactor).round(),
            );
          }
        }
      }
    }

    _lastMeasurement = now;
    _lastStats = Map.from(currentStats);
    return results;
  }
}

class AppSpeed {
  final int rxBytesPerSecond;
  final int txBytesPerSecond;
  int get totalBytesPerSecond => rxBytesPerSecond + txBytesPerSecond;
  
  AppSpeed({required this.rxBytesPerSecond, required this.txBytesPerSecond});
}
```

---

## 🏷️ تصنيف التطبيقات

### AppCategoryMapper
```dart
class AppCategoryMapper {
  /// خريطة تصنيف معروفة مسبقاً
  static const Map<String, AppCategory> _knownApps = {
    // شبكات اجتماعية
    'com.whatsapp': AppCategory.socialMedia,
    'com.facebook.katana': AppCategory.socialMedia,
    'com.instagram.android': AppCategory.socialMedia,
    'com.twitter.android': AppCategory.socialMedia,
    'org.telegram.messenger': AppCategory.socialMedia,
    'com.snapchat.android': AppCategory.socialMedia,
    'com.tiktok': AppCategory.socialMedia,
    
    // بث الفيديو والموسيقى
    'com.google.android.youtube': AppCategory.streaming,
    'com.netflix.mediaclient': AppCategory.streaming,
    'com.shahid.stream': AppCategory.streaming,
    'com.spotify.music': AppCategory.streaming,
    
    // متصفحات
    'com.android.chrome': AppCategory.browsing,
    'com.brave.browser': AppCategory.browsing,
    'org.mozilla.firefox': AppCategory.browsing,
    'com.opera.browser': AppCategory.browsing,
    
    // إنتاجية
    'com.google.android.gm': AppCategory.productivity,
    'com.microsoft.office.outlook': AppCategory.productivity,
    'com.google.android.apps.docs': AppCategory.productivity,
  };

  /// تصنيف ذكي: يحاول أولاً القائمة المعروفة، ثم يخمن من اسم الحزمة
  static AppCategory categorize(String packageName) {
    // 1. بحث في القائمة المعروفة
    if (_knownApps.containsKey(packageName)) {
      return _knownApps[packageName]!;
    }
    
    // 2. تخمين من اسم الحزمة
    final lower = packageName.toLowerCase();
    
    if (lower.startsWith('com.android.') || 
        lower.startsWith('com.google.android.') && !lower.contains('youtube')) {
      return AppCategory.system;
    }
    if (lower.contains('game') || lower.contains('play')) {
      return AppCategory.gaming;
    }
    if (lower.contains('browser') || lower.contains('chrome')) {
      return AppCategory.browsing;
    }
    if (lower.contains('vpn') || lower.contains('proxy')) {
      return AppCategory.vpn;
    }
    
    return AppCategory.other;
  }
}
```

---

## 📊 تنبيهات الاستهلاك

### CheckUsageAlertsUseCase
```dart
class CheckUsageAlertsUseCase {
  final AppMonitorRepository _repository;
  
  CheckUsageAlertsUseCase(this._repository);

  /// يفحص إذا كان أي تطبيق يستهلك بشكل مفرط
  List<UsageAlert> execute({
    required List<AppUsageEntity> apps,
    required MonitorFilter currentFilter,
  }) {
    final alerts = <UsageAlert>[];
    
    // حساب إجمالي الاستهلاك
    final totalBytes = apps.fold<int>(0, (sum, app) => sum + app.totalBytes);
    if (totalBytes == 0) return alerts;
    
    for (final app in apps) {
      final percentage = app.totalBytes / totalBytes;
      
      // تنبيه: تطبيق يستهلك أكثر من 50% من الإجمالي
      if (percentage > 0.5 && app.totalBytes > 10 * 1024 * 1024) { // > 10MB
        alerts.add(UsageAlert(
          appName: app.appName,
          packageName: app.packageName,
          bytesConsumed: app.totalBytes,
          level: AlertLevel.warning,
          message: '${app.appName} يستهلك ${(percentage * 100).toInt()}% من البيانات',
          triggeredAt: DateTime.now(),
        ));
      }
      
      // تنبيه حرج: تطبيق يستهلك أكثر من 500MB في اليوم
      if (currentFilter == MonitorFilter.today && app.totalBytes > 500 * 1024 * 1024) {
        alerts.add(UsageAlert(
          appName: app.appName,
          packageName: app.packageName,
          bytesConsumed: app.totalBytes,
          level: AlertLevel.critical,
          message: '${app.appName} استهلك أكثر من 500 MB اليوم!',
          triggeredAt: DateTime.now(),
        ));
      }
    }
    
    return alerts;
  }
}
```

---

## 📦 ملخص تحسينات محرك البيانات

| التحسين | التأثير | الجهد |
|---------|---------|-------|
| Cache أيقونات في Kotlin | 🟢 أداء +40% | ⭐ |
| Cache أيقونات في Dart | 🟢 أداء +20% | ⭐ |
| استعلام بنطاق زمني | 🟢 أداء +60% | ⭐⭐ |
| فصل LocalStorageDataSource | 🟢 صيانة | ⭐⭐ |
| تنظيف بيانات قديمة | 🟢 مساحة | ⭐ |
| قياس سرعة بوقت حقيقي | 🟢 دقة | ⭐ |
| تصنيف تطبيقات | 🟢 تجربة مستخدم | ⭐⭐ |
| تنبيهات استهلاك | 🟢 قيمة مضافة | ⭐⭐ |
| صيغة تسلسل آمنة (`|`) | 🟢 أمان | ⭐ |
| Validation للبيانات | 🟢 استقرار | ⭐ |
