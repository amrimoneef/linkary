# 🔍 تدقيق الحالة الحالية — مراقب التطبيقات v1.x
## Comprehensive Audit: Strengths, Weaknesses, and Issues

---

## 📁 خريطة الملفات الحالية (بعد الإصدار الأول)

```
mifi_app_monitor/
├── domain/
│   ├── entities/
│   │   ├── app_usage_entity.dart          (38 سطر)  ← كيان كامل مع category و speeds
│   │   └── app_category.dart              (70 سطر)  ← 12 فئة مع أيقونات وألوان
│   ├── repositories/
│   │   └── app_monitor_repository.dart    (30 سطر)  ← واجهة شاملة
│   ├── services/
│   │   └── modem_session_service.dart     (26 سطر)  ← خدمة كشف المودم
│   └── use_cases/
│       ├── calculate_usage_delta_usecase.dart  (51 سطر)
│       ├── categorize_apps_usecase.dart        (26 سطر)
│       └── check_usage_alerts_usecase.dart     (49 سطر)
├── infrastructure/
│   ├── data_sources/
│   │   ├── native_stats_data_source.dart      (57 سطر)
│   │   └── local_storage_data_source.dart     (200 سطر)
│   ├── mappers/
│   │   └── app_category_mapper.dart           (83 سطر)
│   └── repositories/
│       └── app_monitor_repository_impl.dart   (99 سطر)
└── presentation/
    ├── controllers/
    │   └── app_monitor_controller.dart        (514 سطر) ⚠️
    ├── pages/
    │   ├── app_monitor_screen.dart            (393 سطر)
    │   └── app_detail_screen.dart             (393 سطر)
    └── widgets/
        ├── app_usage_tile.dart                (256 سطر)
        ├── category_breakdown_card.dart       (114 سطر)
        ├── connection_status_banner.dart      (73 سطر)
        ├── daily_infographic_widget.dart      (241 سطر)
        ├── filter_chips_bar.dart              (71 سطر)
        ├── live_speed_indicator.dart          (77 سطر)
        ├── permission_gate_widget.dart        (96 سطر)
        ├── pulse_icon_wrapper.dart            (111 سطر)
        ├── search_bar_widget.dart             (50 سطر)
        └── usage_summary_card.dart            (163 سطر)

+ android/app/src/main/kotlin/.../MainActivity.kt  (172 سطر)
```

**المجموع**: 22 ملف Dart + 1 ملف Kotlin ≈ 3,049 سطر

---

## ✅ نقاط القوة الحالية

### 1. 🏗️ بنية معمارية نظيفة ومنظمة
- **Clean Architecture** مطبقة بشكل جيد (Domain → Infrastructure → Presentation)
- **3 Use Cases** مستقلة: حساب الفرق، التصنيف، التنبيهات
- **فصل واضح** بين Data Sources (Native + Local Storage)
- **DI مركزي** مسجل في `injection_container.dart` مع `fenix: true`
- **ModemSessionService** منفصل لكشف إعادة التشغيل

### 2. 📊 نظام تتبع بيانات متقدم
- **Dual Baseline System**: جلسة (boot-based) + يومي (midnight-based)
- **Delta Calculation** دقيق مع حد أدنى قابل للتخصيص
- **Smart Recovery**: إعادة بناء baseline من DB إذا فُقد
- **Daily App Totals**: تخزين منفصل لكل تطبيق لكل يوم
- **History**: دعم حتى 30 يوم مع الأسبوع/الشهر aggregation
- **Cleanup Policy**: تنظيف تلقائي للبيانات > 60 يوم

### 3. 🎨 واجهة مستخدم احترافية
- **10 Widgets مستقلة** — تقسيم ممتاز
- **Ambient Glow Effects** — خلفيات متوهجة
- **Pulse Animation** — نبض للتطبيقات النشطة في الوقت الفعلي
- **Hero Animation** — انتقال سلس للأيقونات
- **Staggered Entry** — ظهور تدريجي للقائمة
- **Theme-aware** — يدعم الوضع الفاتح والداكن
- **RTL** — تصميم عربي أولاً

### 4. 🧠 ميزات ذكية
- **12 فئة تصنيف** مع أيقونات وألوان (اجتماعي، بث، ألعاب، VPN، تسوق...)
- **Pie Chart** لتوزيع الاستهلاك حسب الفئة
- **App Goals** — سقف استهلاك لكل تطبيق مع تنبيهات 90% + 100%
- **Spike Detection** — كشف الارتفاعات المفاجئة (> 15MB/interval)
- **Daily Report** — تقرير قابل للمشاركة كصورة احترافية

### 5. 🔄 مرونة تشغيلية
- **LifecycleObserver** — يوقف Polling عند الخلفية ويستأنف عند العودة
- **Auto-reconnect** — يستعيد baseline من التخزين عند إعادة الاتصال
- **Session Reset** — إعادة تعيين الجلسة يدوياً
- **RefreshIndicator** — سحب للتحديث

### 6. 🤖 Android Native محسّن
- **NetworkStatsManager** — أفضل API متاحه
- **Background Thread** — لا يجمد الواجهة
- **Icon Cache (LruCache)** — 100 أيقونة محفوظة
- **Icon Downscale** — 64×64 بكفاءة عالية
- **1KB Filter** — يتجاهل التطبيقات بأقل من 1KB

---

## ❌ نقاط الضعف والمشاكل المتبقية

### 🔴 حرج — يؤثر على الاستقرار والدقة

#### W1. Controller ضخم ومعقد جداً (514 سطر)
**الملف**: `app_monitor_controller.dart`

```dart
// refreshUsage() وحدها = 220+ سطر!
Future<void> refreshUsage() async {
  // 1. Fetch RAW data (2 calls)
  // 2. Modem Session Sync
  // 3. Initial Baselines (4 paths)
  // 4. Calculate Deltas (2 types)
  // 5. Data Aggregation (3 filter modes)
  // 6. Categorization
  // 7. Summary Totals (3 filter modes)
  // 8. Discrepancy handling
  // 9. Filtering & Alerts
  // 10. Persistence
  // 11. Chart sync
  // ... كل هذا في دالة واحدة!
}
```

**المشكلة**:
- دالة `refreshUsage()` تحتوي على **10 مسؤوليات مختلفة** في ~220 سطر
- صعبة الاختبار والصيانة
- أي خطأ في أي خطوة يُبتلع بـ `catch (e)` واحد في النهاية
- خلط بين منطق الأعمال (Business Logic) ومنطق العرض (UI Logic)

**التأثير**: صعوبة تتبع الأخطاء، استحالة اختبار الوحدات

---

#### W2. SharedPreferences كقاعدة بيانات رئيسية
**الملف**: `local_storage_data_source.dart`

```dart
// تخزين مئات المفاتيح: daily_baseline_{date}, daily_app_{date}, daily_total_{date}
// لكل يوم × 3 أنواع = ~90 مفتاح لشهر واحد
// كل مفتاح app totals = عشرات الـ entries مسلسلة كنص
```

**المشاكل**:
- **SharedPreferences ليست مصممة لقواعد البيانات** — مصممة لإعدادات بسيطة
- **تسلسل نصي هش**: `"com.whatsapp|12345|6789"` — separator قد يتعارض
- **لا يوجد indexing** — البحث يتطلب قراءة كل شيء
- **لا يوجد transactions** — كتابة جزئية قد تُفسد البيانات
- **لا يوجد data integrity** — لا checksum ولا validation
- **أداء خطي** — كلما زادت البيانات، بطئ الأداء

**التأثير**: أداء متدهور مع الوقت، احتمال فساد بيانات

---

#### W3. حساب السرعة غير دقيق
**الملف**: `app_monitor_controller.dart:509`

```dart
String formatSpeed(int bytesPerInterval) {
  double bytesPerSecond = bytesPerInterval / 3.0;  // ← يفترض دائماً 3 ثوانٍ!
}
```

**المشكلة**:
- Timer.periodic(3s) لا يضمن تنفيذ دقيق كل 3 ثوانٍ بالضبط
- في الخلفية أو عند ضغط المعالج، قد يتأخر التنفيذ
- يجب حساب الفارق الزمني الفعلي بين كل polling

---

#### W4. لا يوجد Error State في الواجهة
**الملف**: `app_monitor_screen.dart`

```dart
// 3 حالات فقط: Loading → No Permission → Data
// ❌ لا يوجد: Error State, Empty State, No Connection
```

**المشكلة**:
- إذا فشل الجلب، لا توجد رسالة خطأ
- لا يوجد زر "إعادة المحاولة"
- لا تمييز بين "لا بيانات بعد" و "خطأ في الجلب"

---

#### W5. اعتماد `CalculateUsageDeltaUseCase` لا يحافظ على category/icon
**الملف**: `calculate_usage_delta_usecase.dart:34`

```dart
deltaUsage.add(AppUsageEntity(
  packageName: currentApp.packageName,
  appName: currentApp.appName,
  iconData: currentApp.iconData,     // ✅ محفوظ
  totalBytes: actualTotal,
  rxBytes: actualRx > 0 ? actualRx : 0,
  txBytes: actualTx > 0 ? actualTx : 0,
  rxSpeed: rxSpeed,
  txSpeed: txSpeed,
  // ❌ category مفقود — يرجع AppCategory.other افتراضياً
  // ❌ isSystemApp مفقود
  // ❌ lastActiveTime مفقود
));
```

**المشكلة**: Use Case تُنشئ entities جديدة بدون نقل الحقول الإضافية (category, isSystemApp, lastActiveTime)

---

### 🟠 مهم — يؤثر على جودة المنتج

#### W6. `CategorizeAppsUseCase` يعتمد على Infrastructure
**الملف**: `categorize_apps_usecase.dart:3`

```dart
import '../../infrastructure/mappers/app_category_mapper.dart';
// ❌ Domain يستورد Infrastructure — انتهاك Clean Architecture!
```

**المشكلة**: طبقة Domain يجب ألا تعتمد على Infrastructure مباشرة. الـ Mapper يجب أن يكون في Domain أو يُحقن كتابعية.

---

#### W7. `AppDetailScreen` لا يتحدث مع البيانات الحية
**الملف**: `app_detail_screen.dart`

```dart
// الشاشة تستقبل الكيان مرة واحدة عبر constructor
final AppUsageEntity app;
// ❌ لا تتحدث — الأرقام ثابتة ولا تُحدَّث في الوقت الفعلي
```

**المشكلة**: بيانات التطبيق في شاشة التفاصيل ثابتة ولا تتغير أثناء المشاهدة

---

#### W8. تكرار ألوان/ثيم في كل Widget
```dart
// نفس الكود يتكرر في كل ملف:
final text = Theme.of(context).brightness == Brightness.dark
    ? Colors.white : const Color(0xFF111827);
final subText = Theme.of(context).brightness == Brightness.dark
    ? Colors.white54 : const Color(0xFF6B7280);
final cardBg = Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFF16213E) : const Color(0xFFE5E7EB);
```

**الملفات**: كل ملف Widget تقريباً (10+ ملفات)
**المشكلة**: أي تغيير في الألوان يتطلب تعديل 10+ ملفات

---

#### W9. `_getArabicDayShort` مكررة
```dart
// نفس الدالة في ملفين:
// app_monitor_screen.dart:262
// app_detail_screen.dart:220
String _getArabicDayShort(String englishDay) { ... }
```

---

#### W10. Week/Month Aggregation بطيء
**الملف**: `app_monitor_controller.dart:250`

```dart
// Sequential DB calls — واحدة تلو الأخرى
for (int i = 1; i < aggregationDays; i++) {
  final date = DateTime.now().subtract(Duration(days: i));
  final dailyMap = await repository.getDailyAppTotals(date);  // ← await في حلقة!
}
```

**المشكلة**: 30 عملية `await` متتالية لعرض الشهر. يجب استخدام `Future.wait` للتوازي.

---

#### W11. Discrepancy Logic قد ينتج "بيانات مجهولة" وهمية
**الملف**: `app_monitor_controller.dart:313`

```dart
if (totalCapByModem > sumOfAllAttributedApps && selectedFilter.value != MonitorFilter.session) {
  int diff = totalCapByModem - sumOfAllAttributedApps;
  if (diff > 5242880) { // 5MB threshold
    categorizedApps.add(AppUsageEntity(
      packageName: 'com.linkary.internal.discrepancy',
      appName: 'بيانات مجهولة / نظام قديم',
      // ...
    ));
  }
}
```

**المشكلة**:
- المقارنة بين `totalCapByModem` (من daily totals المخزنة) و `sumOfAllAttributedApps` (محسوب حيّاً) قد تكون غير عادلة
- يمكن أن ينتج عناصر "بيانات مجهولة" ضخمة بشكل خاطئ
- Threshold الـ 5MB قد يكون أكبر أو أصغر من اللازم

---

### 🟡 تحسينات مطلوبة — لرفع المستوى

#### W12. لا يوجد نظام إشعارات Push
- التنبيهات تظهر فقط داخل الشاشة
- لا يوجد Local Notification عند تجاوز سقف الاستهلاك
- المستخدم يجب أن يفتح الشاشة ليرى التنبيه

#### W13. لا يوجد Export للبيانات
- التقرير الحالي صورة فقط (Screenshot)
- لا يوجد تصدير CSV/JSON للبيانات التاريخية
- لا يوجد نسخ احتياطي

#### W14. CategoryMapper محدود
- يغطي ~25 تطبيق معروف فقط
- Prefix guessing قد يُصنف تطبيقات بشكل خاطئ
- `com.android.*` كلها تُصنف كـ system (لكن YouTube مستثنى فقط)

#### W15. لا يوجد فلتر حسب الفئة
- المستخدم يمكنه البحث بالاسم فقط
- لا يوجد فلتر "اعرض فقط الألعاب" أو "اعرض فقط VPN"

#### W16. Search لا يُمسح تلقائياً
- عند تغيير Filter (جلسة ← يوم)، حقل البحث يبقى — قد يخفي نتائج

---

## 📊 مصفوفة المشاكل حسب الأولوية

| # | المشكلة | الخطورة | الجهد | التأثير |
|---|---------|---------|-------|---------|
| W1 | Controller ضخم | 🔴 حرج | ⭐⭐⭐ عالي | صيانة مستحيلة |
| W2 | SharedPreferences كـ DB | 🔴 حرج | ⭐⭐⭐ عالي | أداء/فساد |
| W3 | حساب سرعة غير دقيق | 🔴 حرج | ⭐ منخفض | بيانات مضللة |
| W4 | لا Error State | 🟠 مهم | ⭐⭐ متوسط | تجربة سيئة |
| W5 | Delta لا ينقل category | 🟠 مهم | ⭐ منخفض | تصنيف مفقود |
| W6 | Domain يستورد Infra | 🟠 مهم | ⭐ منخفض | انتهاك معماري |
| W7 | تفاصيل ثابتة | 🟠 مهم | ⭐⭐ متوسط | تجربة ناقصة |
| W8 | تكرار الألوان | 🟡 تحسين | ⭐⭐ متوسط | صيانة صعبة |
| W9 | دالة مكررة | 🟡 تحسين | ⭐ منخفض | DRY violation |
| W10 | Aggregation بطيء | 🟠 مهم | ⭐ منخفض | أداء |
| W11 | Discrepancy وهمي | 🟡 تحسين | ⭐⭐ متوسط | بيانات مضللة |
| W12 | لا Push Notifications | 🟡 تحسين | ⭐⭐ متوسط | ميزة ناقصة |
| W13 | لا Export | 🟡 تحسين | ⭐⭐ متوسط | ميزة ناقصة |
| W14 | Mapper محدود | 🟡 تحسين | ⭐⭐ متوسط | تصنيف ناقص |
| W15 | لا فلتر بالفئة | 🟡 تحسين | ⭐ منخفض | ميزة ناقصة |
| W16 | Search لا يُمسح | 🟡 تحسين | ⭐ منخفض | UX |

---

## 🆚 مقارنة مع التطبيقات المنافسة

| الجانب | Linkary v1 | GlassWire | NetGuard | الهدف v2 |
|--------|-----------|-----------|----------|----------|
| مراقبة حية | ✅ | ✅ | ❌ | ✅ |
| حظر تطبيقات | ❌ | ✅ | ✅✅ | ✅ |
| تصنيف تلقائي | ✅ | ✅ | ❌ | ✅✅ |
| رسوم بيانية | ✅ | ✅✅ | ❌ | ✅✅ |
| تنبيهات ذكية | ✅ (داخلي) | ✅✅ (push) | ❌ | ✅✅ |
| تقارير مشاركة | ✅ | ❌ | ❌ | ✅✅ |
| مرتبط بالمودم | ✅✅✅ | ❌ | ❌ | ✅✅✅ |
| حظر على مستوى الشبكة | ❌ | ❌ (جهاز فقط) | ❌ (VPN) | ✅✅ (مودم) |
| لا يحتاج Root | ✅ | ✅ | ✅ | ✅ |

> **الميزة التنافسية الأكبر**: حظر التطبيقات على مستوى **المودم** وليس الجهاز — لا يحتاج VPN، لا يحتاج Root، ولا يمكن للتطبيق تجاوزه.

---

## 🔒 ثغرات أمنية متبقية

### 1. بيانات مكشوفة
```dart
// SharedPreferences تُخزن كنص عادي
// أسماء التطبيقات واستهلاكها مكشوفة لأي root user
```

### 2. لا validation للبيانات من Native
```dart
// NativeStatsDataSource لا يتحقق من صحة القيم
apps.add(AppUsageEntity(
  packageName: map['packageName'],  // قد يكون null
  appName: map['appName'],          // قد يكون null
  totalBytes: map['totalBytes'],    // قد يكون سالب نظرياً
));
```

### 3. Gateway IP مكشوف
```dart
static const String TARGET_GATEWAY_IP = '192.168.8.1';
// ← Hardcoded في الكود — يجب أن يكون configurable
```
