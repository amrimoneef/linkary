# 🏗️ البنية المعمارية — كاشف النقطة الذهبية

## Clean Architecture Flow

```
┌──────────────────────────────────────────────────────────────┐
│                    Presentation Layer                         │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │         SignalFinderController (GetX)                  │   │
│  │  ├─ compositeScore (0-100%) .obs                     │   │
│  │  ├─ signalRank (enum) .obs                           │   │
│  │  ├─ historyPoints (RxList<SignalPoint>)               │   │
│  │  ├─ guidanceMessage (String) .obs                    │   │
│  │  ├─ bestScore (double) .obs                          │   │
│  │  ├─ bestScoreTimestamp (DateTime?) .obs               │   │
│  │  ├─ isScanning (bool) .obs                           │   │
│  │  ├─ sessionDuration (int) .obs                       │   │
│  │  ├─ trendDirection (enum) .obs                       │   │
│  │  └─                                                   │   │
│  └─────────────┬────────────────────────────────────────┘   │
│                │ يستخدم                                      │
│  ┌─────────────▼────────────────────────────────────────┐   │
│  │         SignalFinderPage (StatefulWidget)              │   │
│  │  ├─ _CompositeScoreGauge (دائرة النسبة)              │   │
│  │  ├─ _SignalRankBadge (شارة التصنيف)                  │   │
│  │  ├─ _GuidanceMessageCard (نصيحة متغيرة)              │   │
│  │  ├─ _MetricsRow (RSRP / SINR / RSRQ مصغّرة)         │   │
│  │  ├─ _LiveEkgGraph (CustomPainter - الرسم البياني)    │   │
│  │  └─ _SessionSummarySheet (ملخص الجلسة عند الإيقاف)   │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│                     Domain Layer                              │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  SignalScoreCalculator (Pure Logic)                    │   │
│  │  ├─ normalizeRSRP(double) → double (0-100)           │   │
│  │  ├─ normalizeSINR(double) → double (0-100)           │   │
│  │  ├─ normalizeRSRQ(double) → double (0-100)           │   │
│  │  ├─ calculateComposite(rsrp, sinr, rsrq) → double    │   │
│  │  ├─ classifyRank(double score) → SignalRank           │   │
│  │  └─ generateGuidance(score, trend, rank) → String     │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Entities                                              │   │
│  │  ├─ SignalPoint (score, rsrp, sinr, rsrq, timestamp) │   │
│  │  ├─ SignalRank (enum: dead, critical, stable, legend) │   │
│  │  └─ SignalTrend (enum: improving, stable, declining)  │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│                  Infrastructure Layer                         │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  HapticFeedbackService                                 │   │
│  │  ├─ _calculateInterval(double score) → Duration       │   │
│  │  ├─ startPulsing(double score)                        │   │
│  │  ├─ stopPulsing()                                     │   │
│  │  └─ playFoundSpotCelebration()                        │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Re-uses: DashboardRemoteDataSource.fetchEngInfo()     │   │
│  │  (لا حاجة لمصدر بيانات جديد—نستخدم الموجود)          │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## 📁 هيكل الملفات

```
lib/features/signal_finder/
├── domain/
│   ├── entities/
│   │   ├── signal_point.dart              # نقطة قراءة واحدة
│   │   ├── signal_rank.dart               # enum التصنيفات الأربعة
│   │   └── signal_trend.dart              # enum اتجاه الإشارة
│   └── services/
│       └── signal_score_calculator.dart    # محرك الحساب (Pure Logic)
│
├── infrastructure/
│   └── services/
│       └── haptic_feedback_service.dart    # خدمة الاهتزاز الذكي
│
└── presentation/
    ├── controllers/
    │   └── signal_finder_controller.dart   # GetX Controller
    ├── pages/
    │   └── signal_finder_page.dart         # الشاشة الرئيسية
    └── widgets/
        ├── composite_score_gauge.dart      # عداد النسبة الدائري
        ├── signal_rank_badge.dart          # شارة التصنيف المتحركة
        ├── guidance_message_card.dart      # بطاقة النصيحة
        ├── live_ekg_graph.dart             # الرسم البياني الحي (CustomPainter)
        ├── metrics_mini_row.dart           # صف المؤشرات الثلاثة المصغّرة
        └── session_summary_sheet.dart      # ملخص الجلسة (Bottom Sheet)
```

---

## 🔗 التكامل مع المشروع الحالي

### 1. إعادة استخدام مصدر البيانات
```dart
// ✅ لا ننشئ مصدر بيانات جديد!
// نستخدم GetEngineeringInfoUseCase الموجود مباشرةً
final GetEngineeringInfoUseCase getEngineeringInfoUseCase;
```

- الـ `DashboardRemoteDataSource.fetchEngineeringInfo()` يجلب RSRP, SINR, RSRQ من API المودم.
- الكاشف يستدعيها بتردد أعلى (كل 2 ثانية بدلاً من 5 ثوانٍ).

### 2. تسجيل الـ DI
```dart
// في injection_container.dart — نضيف:

// --- ميزة كاشف النقطة الذهبية (Signal Finder) ---
Get.lazyPut(() => HapticFeedbackService(), fenix: true);
Get.lazyPut(() => SignalScoreCalculator(), fenix: true);
Get.lazyPut(() => SignalFinderController(
    getEngineeringInfoUseCase: Get.find(),
    scoreCalculator: Get.find(),
    hapticService: Get.find(),
), fenix: true);
```

### 3. الوصول للشاشة
```dart
// من Dashboard أو Network Info أو أي شاشة:
Get.to(() => SignalFinderPage());
```

---

## 🔄 دورة حياة الميزة

```
┌─── المستخدم يفتح الشاشة ──────────────────────────────────┐
│                                                              │
│  1. onInit() — تهيئة controller                              │
│  2. startScanning() — بدء Timer (كل 2 ثانية)                │
│  3. كل 2 ثانية:                                             │
│     ├─ fetchEngineeringInfo() → RSRP, SINR, RSRQ جديدة     │
│     ├─ calculateComposite() → نسبة 0-100%                   │
│     ├─ classifyRank() → Dead / Critical / Stable / Legendary │
│     ├─ updateHaptics() → اهتزاز بتردد يتناسب مع القوة      │
│     ├─ addToHistory() → نقطة جديدة في الرسم البياني        │
│     ├─ updateGuidance() → رسالة نصية ذكية                   │
│     └─ checkBestScore() → تحديث أعلى قراءة                 │
│  4. المستخدم يضغط "إيقاف" أو يغادر الشاشة                 │
│  5. stopScanning() — إيقاف Timer + إيقاف الاهتزاز          │
│  6. showSessionSummary() — عرض ملخص الجلسة                 │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## ⚡ ملاحظات فنية حرجة

### الأداء:
- **Timer كل 2 ثانية** — لا يؤثر على البطارية (ليس كل frame).
- **الرسم البياني**: يحتفظ بآخر 15 نقطة فقط (30 ثانية ÷ 2 = 15 نقطة).
- **الاهتزاز**: Timer مستقل بتردد ديناميكي، يتوقف تلقائياً عند الخروج.

### الأمان:
- لا يتم حفظ أي بيانات حساسة.
- الميزة **لا تحتاج صلاحيات جديدة** (VIBRATE فقط على Android وهو لا يتطلب إذن runtime).
- الكاشف يتوقف تلقائياً في `onClose()` لمنع تسرب الذاكرة.

### التوافق مع AGENTS.md:
- ✅ Clean Architecture (Domain → Infrastructure → Presentation)
- ✅ GetX reactive state (`.obs`, `Rxn<T>`, `RxList`)
- ✅ DI via `Get.lazyPut()` with `fenix: true`
- ✅ `package:linkary/...` imports
- ✅ عربي أولاً مع دعم إنجليزي
- ✅ `onClose()` لإيقاف الـ Timer والاهتزاز
