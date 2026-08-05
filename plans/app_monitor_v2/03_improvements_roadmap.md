# 🚀 تحسينات وميزات منافسة مقترحة — Improvements Roadmap
## رفع مراقب التطبيقات لمستوى احترافي منافس

---

## 📋 الحلول لنقاط الضعف المتبقية

### الحل W1: تقسيم Controller الضخم

#### المشكلة
`AppMonitorController` = 514 سطر، و `refreshUsage()` وحدها = 220 سطر مع 10 مسؤوليات.

#### الحل: استخراج Services و تقسيم المنطق

```dart
// ❌ قبل: كل شيء في Controller
class AppMonitorController {
  Future<void> refreshUsage() async {
    // 220+ سطر...
  }
}

// ✅ بعد: منطق موزع
class AppMonitorController {
  final UsageDataEngine _dataEngine;        // جلب ومعالجة البيانات
  final UsagePersistenceService _persistence; // حفظ واسترجاع
  final UsageAggregator _aggregator;         // تجميع أسبوعي/شهري

  Future<void> refreshUsage() async {
    final rawData = await _dataEngine.fetchCurrentData();
    final processed = _dataEngine.processDeltas(rawData);
    final aggregated = await _aggregator.aggregate(processed, selectedFilter.value);
    await _persistence.save(aggregated);
    _updateUI(aggregated);
  }
}
```

#### الملفات الجديدة المقترحة
- `domain/services/usage_data_engine.dart` — جلب ومعالجة البيانات الخام
- `domain/services/usage_aggregator.dart` — تجميع البيانات حسب الفلتر
- `domain/services/usage_persistence_service.dart` — إدارة الحفظ والاسترجاع

---

### الحل W2: الترقية من SharedPreferences إلى SQLite (مستقبلي)

#### المشكلة
SharedPreferences تُستخدم كقاعدة بيانات لمئات المفاتيح.

#### الحل المرحلي (v2.0): تحسين SharedPreferences الحالية
```dart
// 1. استخدام JSON batch بدلاً من مفاتيح منفصلة
// قبل: 30 مفتاح لتخزين شهر (daily_app_2024-01-01, daily_app_2024-01-02, ...)
// بعد: مفتاح واحد لكل أسبوع بصيغة JSON مضغوطة

// 2. إضافة checksum للتحقق من سلامة البيانات
// 3. Lazy loading — لا يُحمّل كل البيانات مرة واحدة
```

#### الحل الكامل (v3.0): SQLite مع sqflite
```dart
// مستقبلاً — عندما تكبر البيانات بشكل يستدعي ذلك
class MonitorDatabase {
  static const _dbName = 'app_monitor.db';
  
  Future<Database> get database async => openDatabase(
    join(await getDatabasesPath(), _dbName),
    onCreate: (db, version) {
      db.execute('''
        CREATE TABLE daily_usage (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          package_name TEXT NOT NULL,
          rx_bytes INTEGER DEFAULT 0,
          tx_bytes INTEGER DEFAULT 0,
          UNIQUE(date, package_name)
        )
      ''');
    },
    version: 1,
  );
}
```

---

### الحل W3: حساب سرعة دقيق

```dart
// ❌ قبل
String formatSpeed(int bytesPerInterval) {
  double bytesPerSecond = bytesPerInterval / 3.0; // يفترض 3 ثوانٍ دائماً
}

// ✅ بعد
DateTime? _lastPollTime;

Future<void> _pollAndCalculateSpeed() async {
  final now = DateTime.now();
  final elapsed = _lastPollTime != null
    ? now.difference(_lastPollTime!).inMilliseconds / 1000.0
    : 3.0; // fallback
  
  _lastPollTime = now;
  
  // حساب السرعة بناءً على الزمن الفعلي
  final speed = deltaBytes / elapsed;
}
```

---

### الحل W4: إضافة Error State

```dart
enum MonitorState {
  loading,
  ready,
  error,
  noPermission,
  disconnected,
  empty,
}

// في Controller
var state = MonitorState.loading.obs;
var errorMessage = ''.obs;

// في UI
Obx(() {
  switch (controller.state.value) {
    case MonitorState.loading:
      return ShimmerLoadingWidget();
    case MonitorState.error:
      return ErrorBanner(
        message: controller.errorMessage.value,
        onRetry: () => controller.refreshUsage(),
      );
    case MonitorState.empty:
      return EmptyStateWidget(message: 'لا توجد بيانات استهلاك بعد');
    // ...
  }
})
```

---

### الحل W5: CalculateUsageDeltaUseCase ينقل Category

```dart
// ✅ إصلاح بسيط
deltaUsage.add(AppUsageEntity(
  packageName: currentApp.packageName,
  appName: currentApp.appName,
  iconData: currentApp.iconData,
  totalBytes: actualTotal,
  rxBytes: actualRx > 0 ? actualRx : 0,
  txBytes: actualTx > 0 ? actualTx : 0,
  rxSpeed: rxSpeed,
  txSpeed: txSpeed,
  category: currentApp.category,         // ✅ إضافة
  isSystemApp: currentApp.isSystemApp,    // ✅ إضافة
  lastActiveTime: currentApp.lastActiveTime, // ✅ إضافة
));
```

---

### الحل W6: إصلاح Clean Architecture violation

```dart
// ❌ قبل: Domain يستورد Infrastructure
// categorize_apps_usecase.dart
import '../../infrastructure/mappers/app_category_mapper.dart';

// ✅ بعد: حقن الـ Mapper كتابعية
class CategorizeAppsUseCase {
  final AppCategoryClassifier _classifier; // واجهة في Domain
  
  CategorizeAppsUseCase(this._classifier);
  
  List<AppUsageEntity> execute(List<AppUsageEntity> apps) {
    return apps.map((app) {
      final category = _classifier.classify(app.packageName);
      return app.copyWith(category: category);
    }).toList();
  }
}

// Domain interface
abstract class AppCategoryClassifier {
  AppCategory classify(String packageName);
}

// Infrastructure implementation
class AppCategoryMapperImpl implements AppCategoryClassifier {
  @override
  AppCategory classify(String packageName) {
    return AppCategoryMapper.categorize(packageName);
  }
}
```

---

### الحل W8: Theme Constants مركزية

```dart
// ✅ ملف جديد: widgets/monitor_theme.dart
class MonitorTheme {
  static Color textColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
      ? Colors.white : const Color(0xFF111827);
      
  static Color subTextColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
      ? Colors.white54 : const Color(0xFF6B7280);
      
  static Color cardBg(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF16213E) : const Color(0xFFE5E7EB);
      
  static Color glowColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF4A90E2) : const Color(0xFF60A5FA);
}

// استخدام في أي Widget:
Text('Hello', style: TextStyle(color: MonitorTheme.textColor(context)));
```

---

### الحل W10: Parallel aggregation

```dart
// ❌ قبل: Sequential
for (int i = 1; i < 30; i++) {
  final dailyMap = await repository.getDailyAppTotals(date); // ← await في حلقة!
}

// ✅ بعد: Parallel
final futures = List.generate(29, (i) {
  final date = DateTime.now().subtract(Duration(days: i + 1));
  return repository.getDailyAppTotals(date);
});
final results = await Future.wait(futures); // ← كلها في نفس الوقت
```

---

## 🌟 ميزات جديدة مقترحة

### الميزة 1: 📊 رسوم بيانية متقدمة

#### 1.1 Line Chart تفاعلي
```
استهلاك
 250 │         ╱╲
 200 │        ╱  ╲     ╱╲
 150 │   ╱╲  ╱    ╲   ╱  ╲
 100 │  ╱  ╲╱      ╲ ╱    ╲
  50 │ ╱            ╳      ╲
   0 └──────────────────────────
     سبت  أحد  إثن  ثلا  أرب  خمي  جمع
                    📥 تحميل  📤 رفع
```

- **Touch-to-reveal**: اضغط على أي نقطة لرؤية التفاصيل
- **Zoom**: كبّر لرؤية الساعات بدلاً من الأيام
- **Data Labels**: أرقام واضحة على النقاط المميزة

#### 1.2 Heatmap أسبوعي
```
       سبت  أحد  إثن  ثلا  أرب  خمي  جمع
00-04  ░░   ░░   ░░   ░░   ░░   ░░   ░░
04-08  ░░   ░░   ░░   ░░   ░░   ░░   ░░
08-12  ▒▒   ▓▓   ▒▒   ▒▒   ▓▓   ▒▒   ██
12-16  ▓▓   ██   ▓▓   ▓▓   ██   ▓▓   ██
16-20  ██   ██   ██   ██   ██   ██   ██
20-24  ▓▓   ▓▓   ▓▓   ▓▓   ▓▓   ▓▓   ▓▓

░ = قليل  ▒ = متوسط  ▓ = عالي  █ = مفرط
```

- يُظهر أنماط الاستخدام عبر الأيام والساعات
- يحتاج تخزين بيانات ساعية (مستقبلي)

---

### الميزة 2: 🔔 نظام إشعارات محلية متقدم

```dart
class SmartNotificationService {
  // 1. تنبيه تجاوز سقف التطبيق
  Future<void> notifyGoalExceeded(String appName, int currentBytes, int goalBytes);
  
  // 2. تنبيه استهلاك مفاجئ (Spike)
  Future<void> notifySpikeDetected(String appName, int speedBps);
  
  // 3. ملخص يومي في وقت محدد
  Future<void> scheduleDailySummary(TimeOfDay time);
  
  // 4. تنبيه وصول لنسبة من الباقة الشهرية
  Future<void> notifyDataPlanThreshold(double percentUsed);
}
```

**التبعية**: `flutter_local_notifications` (لا تحتاج إنترنت)

---

### الميزة 3: 🏷️ فلتر حسب الفئة

```
[الكل] [اجتماعي 💬] [بث 🎞] [ألعاب 🎮] [VPN 🔒] [نظام 🛠]
```

```dart
// إضافة في Controller
var selectedCategory = Rxn<AppCategory>(); // null = الكل

void filterByCategory(AppCategory? category) {
  selectedCategory.value = category;
  _applyFilter();
}

void _applyFilter() {
  var filtered = appsUsage.toList();
  
  // فلتر البحث
  if (searchQuery.isNotEmpty) {
    filtered = filtered.where((app) => 
      app.appName.toLowerCase().contains(searchQuery.value.toLowerCase())
    ).toList();
  }
  
  // فلتر الفئة
  if (selectedCategory.value != null) {
    filtered = filtered.where((app) => 
      app.category == selectedCategory.value
    ).toList();
  }
  
  filteredAppsUsage.value = filtered;
}
```

---

### الميزة 4: 📋 تقارير شاملة

#### 4.1 تقرير PDF
```dart
class ReportGenerator {
  Future<File> generatePdfReport({
    required List<AppUsageEntity> apps,
    required Map<AppCategory, int> categories,
    required List<Map<String, dynamic>> history,
    required DateTimeRange period,
  }) async {
    // توليد PDF مع:
    // 1. ملخص الاستهلاك
    // 2. Top 10 تطبيقات
    // 3. توزيع حسب الفئات
    // 4. رسم بياني للتاريخ
    // 5. التطبيقات المحظورة
  }
}
```

#### 4.2 Export CSV
```dart
Future<File> exportToCsv(int days) async {
  final StringBuffer csv = StringBuffer();
  csv.writeln('Date,Package,App Name,Category,Download (MB),Upload (MB)');
  
  for (int i = 0; i < days; i++) {
    final date = DateTime.now().subtract(Duration(days: i));
    final dailyData = await repository.getDailyAppTotals(date);
    
    dailyData.forEach((pkg, bytes) {
      csv.writeln('${date.toIso8601String()},$pkg,...');
    });
  }
  
  return File('linkary_export.csv')..writeAsString(csv.toString());
}
```

---

### الميزة 5: 🧠 تحليل ذكي للأنماط

#### 5.1 مقارنة مع المعدل
```dart
class UsagePatternAnalyzer {
  /// يقارن استهلاك اليوم مع متوسط آخر 7 أيام
  Map<String, UsageAnomaly> detectAnomalies(
    Map<String, int> todayUsage,
    Map<String, List<int>> weekHistory,
  ) {
    final anomalies = <String, UsageAnomaly>{};
    
    todayUsage.forEach((pkg, todayBytes) {
      final avgBytes = weekHistory[pkg]?.average ?? 0;
      final ratio = avgBytes > 0 ? todayBytes / avgBytes : 0;
      
      if (ratio > 2.0) {
        anomalies[pkg] = UsageAnomaly(
          type: AnomalyType.spike,
          message: 'استهلاك أعلى بـ ${ratio.toStringAsFixed(1)}x من المعتاد',
        );
      }
    });
    
    return anomalies;
  }
}
```

#### 5.2 توقع الاستهلاك
```
📊 توقع الاستهلاك الشهري
━━━━━━━━━━━━━━━━━━━━━━━━
بناءً على معدل آخر 7 أيام:
📈 المتوقع: 15.5 GB/شهر
📦 باقتك: 20 GB
🟢 آمن — لديك هامش 4.5 GB
```

---

### الميزة 6: 🎨 تحسينات واجهة المستخدم

#### 6.1 Shimmer Loading
```dart
// بدلاً من CircularProgressIndicator بسيط
class ShimmerLoadingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (context, index) => ShimmerCard(), // skeleton loading
    );
  }
}
```

#### 6.2 Swipe Actions
```dart
// سحب على التطبيق يكشف أزرار سريعة
Dismissible(
  key: Key(app.packageName),
  background: _buildBlockAction(),   // سحب يمين = حظر
  secondaryBackground: _buildGoalAction(), // سحب يسار = تحديد سقف
  // ...
)
```

#### 6.3 بطاقة ملخص متطورة
```
┌─────────────────────────────────────┐
│  📊 ملخص الاستهلاك                  │
│                                     │
│      ┌───────────┐                  │
│      │  245.6 MB │   📥 185.2 MB   │
│      │  إجمالي   │   📤  60.4 MB   │
│      └───────────┘                  │
│                                     │
│  🟢 متصل بالمودم  •  15 تطبيق نشط  │
│  ⏱️ مدة الجلسة: 3 ساعات 27 دقيقة   │
│                                     │
│  📈 أعلى من المعدل اليومي بـ 23%    │
│  ⚡ السرعة الحالية: 2.4 MB/s ↓      │
└─────────────────────────────────────┘
```

---

### الميزة 7: 🔄 Widget للشاشة الرئيسية (Home Widget)

> عرض ملخص الاستهلاك مباشرة على الشاشة الرئيسية بدون فتح التطبيق

```
┌─────────────────────┐
│  Linkary Monitor     │
│  ━━━━━━━━━━━━━━━━━  │
│  📊 اليوم: 245 MB   │
│  📥 185 MB  📤 60 MB │
│  🔝 YouTube: 120 MB │
│  ⚡ 2.4 MB/s ↓       │
└─────────────────────┘
```

**التبعية**: `home_widget` package

---

### الميزة 8: 📱 App Comparison

> مقارنة استهلاك تطبيقين أو أكثر جنباً إلى جنب

```
┌───────────────────────────────────┐
│  📊 مقارنة الاستهلاك              │
│                                   │
│  YouTube      │    TikTok         │
│  ────────────│────────────       │
│  📥 450 MB   │    📥 320 MB      │
│  📤  30 MB   │    📤  85 MB      │
│  📊 480 MB   │    📊 405 MB      │
│  🏆 الأعلى   │                   │
│                                   │
│      [رسم بياني مقارن]            │
│  Y│ ▓▓ ▒▒  ▓▓ ▒▒  ▓▓ ▒▒         │
│   │ ▓▓ ▒▒  ▓▓ ▒▒  ▓▓ ▒▒         │
│   └─ سبت ── أحد ── إثن ──       │
│      ▓ YouTube  ▒ TikTok         │
└───────────────────────────────────┘
```

---

## 📊 أولوية الميزات

| # | الميزة | الأهمية | الجهد | ROI |
|---|--------|---------|-------|-----|
| 🛡️ | حظر التطبيقات | 🔴 عالي جداً | ⭐⭐⭐⭐ | ★★★★★ |
| W1 | تقسيم Controller | 🔴 عالي | ⭐⭐⭐ | ★★★★ |
| W3 | حساب سرعة دقيق | 🔴 عالي | ⭐ | ★★★★★ |
| W4 | Error States | 🟠 مهم | ⭐⭐ | ★★★★ |
| W5 | Delta ينقل category | 🟠 مهم | ⭐ | ★★★★ |
| 3 | فلتر بالفئة | 🟡 تحسين | ⭐ | ★★★★ |
| W8 | Theme مركزي | 🟡 تحسين | ⭐⭐ | ★★★ |
| 2 | إشعارات Push | 🟡 تحسين | ⭐⭐⭐ | ★★★ |
| 1 | رسوم بيانية متقدمة | 🟡 تحسين | ⭐⭐⭐ | ★★★ |
| 4 | تقارير PDF/CSV | 🟡 تحسين | ⭐⭐⭐ | ★★ |
| 5 | تحليل أنماط | 🟡 تحسين | ⭐⭐⭐ | ★★ |
| 6 | تحسينات UI | 🟡 تحسين | ⭐⭐ | ★★★ |
| 7 | Home Widget | 🟢 مستقبلي | ⭐⭐⭐ | ★★ |
| 8 | مقارنة تطبيقات | 🟢 مستقبلي | ⭐⭐ | ★★ |
