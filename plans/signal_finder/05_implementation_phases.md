# 📅 مراحل التنفيذ — Implementation Phases

## النظرة العامة

| المرحلة | الوصف | الملفات | التقدير الزمني |
|---|---|---|---|
| **Phase 1** | البنية التحتية (Domain + Entities) | 4 ملفات | ~30 دقيقة |
| **Phase 2** | محرك الاهتزاز (Infrastructure) | 1 ملف + pubspec | ~20 دقيقة |
| **Phase 3** | المتحكم (Controller + DI) | 2 ملف | ~45 دقيقة |
| **Phase 4** | الواجهة الرئيسية (Page + Widgets) | 7 ملفات | ~2 ساعة |
| **Phase 5** | التكامل والاختبار | تعديلات | ~30 دقيقة |

**الإجمالي التقريبي:** ~4 ساعات

---

## 🔹 Phase 1: البنية التحتية (Domain Layer)

### الهدف: إنشاء الكيانات ومحرك الحساب

#### الملفات:

**1. `lib/features/signal_finder/domain/entities/signal_point.dart`**
```dart
class SignalPoint {
  final double compositeScore;  // 0-100
  final double rsrp;
  final double sinr;
  final double rsrq;
  final DateTime timestamp;
  
  SignalPoint({
    required this.compositeScore,
    required this.rsrp,
    required this.sinr,
    required this.rsrq,
    required this.timestamp,
  });
}
```

**2. `lib/features/signal_finder/domain/entities/signal_rank.dart`**
```dart
enum SignalRank {
  deadZone,    // 0-25%
  critical,    // 26-50%
  stable,      // 51-79%
  legendary,   // 80-100%
}
```

**3. `lib/features/signal_finder/domain/entities/signal_trend.dart`**
```dart
enum SignalTrend {
  improving,
  stable,
  declining,
}
```

**4. `lib/features/signal_finder/domain/services/signal_score_calculator.dart`**
- `normalizeRSRP()`, `normalizeSINR()`, `normalizeRSRQ()`
- `calculateComposite()`
- `classifyRank()`
- `calculateTrend()`
- `generateGuidance()`
- `smoothScore()`

### التحقق:
- [ ] استيراد الملفات بنجاح
- [ ] كتابة 3 حالات اختبار ذهنية (dead zone, stable, legendary)

---

## 🔹 Phase 2: محرك الاهتزاز (Infrastructure Layer)

### الهدف: إنشاء خدمة اهتزاز كاشف المعادن

#### الخطوات:

1. **إضافة حزمة `vibration`:**
   ```yaml
   # pubspec.yaml
   vibration: ^2.0.0
   ```

2. **إضافة إذن Android:**
   ```xml
   <!-- android/app/src/main/AndroidManifest.xml -->
   <uses-permission android:name="android.permission.VIBRATE"/>
   ```

3. **إنشاء `lib/features/signal_finder/infrastructure/services/haptic_feedback_service.dart`:**
   - `startPulsing(score)`
   - `updateScore(score)`
   - `stopPulsing()`
   - `playFoundSpotCelebration()`
   - `playNewRecordPulse()`
   - `dispose()`

### التحقق:
- [ ] `flutter pub get` بنجاح
- [ ] استدعاء `Vibration.vibrate(duration: 100)` يعمل

---

## 🔹 Phase 3: المتحكم (Controller + DI)

### الهدف: إنشاء المتحكم الرئيسي وتسجيله في DI

#### الملفات:

**1. `lib/features/signal_finder/presentation/controllers/signal_finder_controller.dart`**

```dart
class SignalFinderController extends GetxController {
  // Dependencies
  final GetEngineeringInfoUseCase getEngineeringInfoUseCase;
  final SignalScoreCalculator scoreCalculator;
  final HapticFeedbackService hapticService;
  
  // Reactive State
  var compositeScore = 0.0.obs;
  var currentRank = SignalRank.deadZone.obs;
  var currentTrend = SignalTrend.stable.obs;
  var guidanceMessage = ''.obs;
  var bestScore = 0.0.obs;
  var bestScoreTimestamp = Rxn<DateTime>();
  var isScanning = false.obs;
  var sessionDuration = 0.obs;
  var historyPoints = <SignalPoint>[].obs;
  var isHapticsEnabled = true.obs;
  
  // Raw values for display
  var rawRsrp = ''.obs;
  var rawSinr = ''.obs;
  var rawRsrq = ''.obs;
  var normalizedRsrp = 0.0.obs;
  var normalizedSinr = 0.0.obs;
  var normalizedRsrq = 0.0.obs;
  
  Timer? _scanTimer;
  Timer? _durationTimer;
  
  // Methods
  void startScanning() { ... }
  void stopScanning() { ... }
  void _onTick() { ... }        // كل 2 ثانية
  void _updateScore() { ... }
  void _updateHaptics() { ... }
  void _updateGuidance() { ... }
  void _addToHistory() { ... }
  void _checkBestScore() { ... }
  void toggleHaptics() { ... }
  
  @override
  void onClose() {
    stopScanning();
    hapticService.dispose();
    super.onClose();
  }
}
```

**2. تعديل `lib/core/di/injection_container.dart`:**
```dart
// إضافة في نهاية initDI():

// --- ميزة كاشف النقطة الذهبية (Signal Finder) ---
Get.lazyPut(() => HapticFeedbackService(), fenix: true);
Get.lazyPut(() => SignalScoreCalculator(), fenix: true);
Get.lazyPut(() => SignalFinderController(
    getEngineeringInfoUseCase: Get.find(),
    scoreCalculator: Get.find(),
    hapticService: Get.find(),
), fenix: true);
```

### التحقق:
- [ ] `Get.find<SignalFinderController>()` يعمل بدون أخطاء
- [ ] استدعاء `startScanning()` يبدأ الـ Timer
- [ ] `onClose()` يوقف الـ Timer والاهتزاز

---

## 🔹 Phase 4: الواجهة (Presentation Layer)

### الهدف: بناء الشاشة وجميع المكونات

#### الترتيب (من الداخل للخارج):

**4.1 — `composite_score_gauge.dart`** (~30 دقيقة)
- CustomPainter لرسم الدائرة
- TweenAnimationBuilder لتنعيم الأرقام
- توهج نابض بلون التصنيف

**4.2 — `signal_rank_badge.dart`** (~15 دقيقة)
- AnimatedContainer لتغيير اللون
- ScaleTransition عند الترقية
- Shimmer effect لـ Legendary

**4.3 — `guidance_message_card.dart`** (~15 دقيقة)
- بطاقة زجاجية (Glassmorphism)
- AnimatedSwitcher للنصوص

**4.4 — `metrics_mini_row.dart`** (~15 دقيقة)
- 3 بطاقات صغيرة (RSRP, SINR, RSRQ)
- القيم الخام + النسب المُطبّعة

**4.5 — `live_ekg_graph.dart`** (~45 دقيقة) ⭐ الأكثر تعقيداً
- CustomPainter بالكامل
- خط ناعم (Cubic Bezier)
- تأثير التوهج المزدوج
- تعبئة متدرجة
- نقطة نابضة
- خطوط مرجعية أفقية

**4.6 — `session_summary_sheet.dart`** (~20 دقيقة)
- Bottom Sheet بملخص الجلسة
- إحصائيات + نصيحة نهائية

**4.7 — `signal_finder_page.dart`** (~30 دقيقة)
- تجميع كل المكونات
- AppBar شفاف
- خلفية مع وهج محيطي
- زر التحكم (بدء/إيقاف)

### التحقق:
- [ ] الشاشة تظهر بدون أخطاء
- [ ] الدائرة تتحرك بسلاسة
- [ ] الرسم البياني يتمرر
- [ ] الألوان تتغير حسب التصنيف

---

## 🔹 Phase 5: التكامل والتلميع

### الهدف: ربط الميزة بالتطبيق الرئيسي

#### الخطوات:

1. **إضافة زر الوصول في Dashboard أو NetworkInfo:**
   - زر في `NetworkInfoPage` يفتح كاشف النقطة الذهبية
   - أو بطاقة في Dashboard

2. **تشغيل `replace_theme.py`:**
   - تحويل أي `Get.isDarkMode` إلى `Theme.of(context)`

3. **ضبط صلاحية الاهتزاز:**
   - التحقق من `Vibration.hasVibrator()` قبل بدء الاهتزاز
   - Fallback: `HapticFeedback.mediumImpact()`

4. **اختبار شامل:**
   - [ ] فتح الشاشة → بدء المسح → مشي → إيقاف → ملخص
   - [ ] تغيير التصنيف يغير الألوان والاهتزاز
   - [ ] كسر رقم قياسي يُطلق احتفال
   - [ ] الخروج من الشاشة يوقف كل شيء
   - [ ] الرسم البياني يعرض آخر 30 ثانية بشكل صحيح
   - [ ] النصائح تتغير حسب السياق

5. **`flutter analyze`:**
   - [ ] لا أخطاء أو تحذيرات جديدة

---

## 📊 ملخص الملفات

### ملفات جديدة (12 ملف):

| # | الملف | النوع |
|---|---|---|
| 1 | `domain/entities/signal_point.dart` | Entity |
| 2 | `domain/entities/signal_rank.dart` | Enum |
| 3 | `domain/entities/signal_trend.dart` | Enum |
| 4 | `domain/services/signal_score_calculator.dart` | Service |
| 5 | `infrastructure/services/haptic_feedback_service.dart` | Service |
| 6 | `presentation/controllers/signal_finder_controller.dart` | Controller |
| 7 | `presentation/pages/signal_finder_page.dart` | Page |
| 8 | `presentation/widgets/composite_score_gauge.dart` | Widget |
| 9 | `presentation/widgets/signal_rank_badge.dart` | Widget |
| 10 | `presentation/widgets/guidance_message_card.dart` | Widget |
| 11 | `presentation/widgets/live_ekg_graph.dart` | Widget |
| 12 | `presentation/widgets/metrics_mini_row.dart` | Widget |
| 13 | `presentation/widgets/session_summary_sheet.dart` | Widget |

### ملفات مُعدّلة (2 ملف):

| # | الملف | التعديل |
|---|---|---|
| 1 | `lib/core/di/injection_container.dart` | إضافة تسجيل DI |
| 2 | `pubspec.yaml` | إضافة `vibration` |
