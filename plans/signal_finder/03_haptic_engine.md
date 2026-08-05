# 📳 محرك الاهتزاز الذكي — Haptic Feedback Engine

## الفكرة الأساسية

الهاتف يتحول إلى **كاشف معادن ذكي**:
- إشارة ضعيفة → نبضات **خفيفة ومتباعدة** (كل 2 ثانية)
- إشارة متوسطة → نبضات **معتدلة** (كل ثانية)
- إشارة جيدة → نبضات **سريعة** (كل 400ms)
- إشارة أسطورية (80%+) → نبضات **متسارعة محمومة** + اهتزاز احتفالي عند الوصول!

---

## 🎵 أنماط الاهتزاز حسب النسبة

### جدول الأنماط:

| النسبة | التصنيف | نوع النبضة | المدة | الفاصل الزمني | الشعور |
|---|---|---|---|---|---|
| 0% — 10% | Dead Zone (ميت) | لا اهتزاز | — | — | صمت تام |
| 11% — 25% | Dead Zone | خفيفة جداً | 30ms | 2000ms | نبض بعيد... بعيد... |
| 26% — 40% | Critical | خفيفة | 50ms | 1200ms | نبض... نبض... |
| 41% — 50% | Critical | متوسطة | 70ms | 800ms | نبض.. نبض.. |
| 51% — 65% | Stable | واضحة | 80ms | 500ms | نبنب . نبنب |
| 66% — 79% | Stable | قوية | 100ms | 350ms | نبنبنب! |
| 80% — 89% | Legendary | سريعة | 120ms | 200ms | نبنبنبنبنب!! |
| 90% — 100% | Legendary | محمومة | 150ms | 100ms | BRRRRRRR!! 🔥 |

---

## 🔧 التصميم التقني

### الفئة: `HapticFeedbackService`

```dart
import 'dart:async';
import 'package:vibration/vibration.dart';

class HapticFeedbackService {
  Timer? _pulseTimer;
  double _lastScore = 0;
  bool _isActive = false;

  /// بدء نظام الاهتزاز النابض
  void startPulsing(double score) {
    _lastScore = score;
    _isActive = true;
    _schedulePulse();
  }

  /// تحديث النبضات بقيمة جديدة (تُستدعى كل 2 ثانية)
  void updateScore(double score) {
    _lastScore = score;
    // النبض القادم سيستخدم القيمة الجديدة تلقائياً
  }

  /// إيقاف الاهتزاز
  void stopPulsing() {
    _isActive = false;
    _pulseTimer?.cancel();
    _pulseTimer = null;
  }

  /// جدولة النبضة التالية
  void _schedulePulse() {
    if (!_isActive) return;
    
    _pulseTimer?.cancel();
    
    final interval = _calculateInterval(_lastScore);
    final duration = _calculateDuration(_lastScore);
    
    if (interval == Duration.zero) return; // لا اهتزاز في المنطقة الميتة
    
    _pulseTimer = Timer(interval, () {
      if (!_isActive) return;
      Vibration.vibrate(duration: duration.inMilliseconds);
      _schedulePulse(); // جدولة النبضة التالية
    });
  }

  /// حساب الفاصل الزمني بين النبضات
  Duration _calculateInterval(double score) {
    if (score <= 10) return Duration.zero; // صمت تام
    if (score <= 25) return const Duration(milliseconds: 2000);
    if (score <= 40) return const Duration(milliseconds: 1200);
    if (score <= 50) return const Duration(milliseconds: 800);
    if (score <= 65) return const Duration(milliseconds: 500);
    if (score <= 79) return const Duration(milliseconds: 350);
    if (score <= 89) return const Duration(milliseconds: 200);
    return const Duration(milliseconds: 100); // 90%+ → محموم!
  }

  /// حساب مدة النبضة الواحدة
  Duration _calculateDuration(double score) {
    if (score <= 25) return const Duration(milliseconds: 30);
    if (score <= 40) return const Duration(milliseconds: 50);
    if (score <= 50) return const Duration(milliseconds: 70);
    if (score <= 65) return const Duration(milliseconds: 80);
    if (score <= 79) return const Duration(milliseconds: 100);
    if (score <= 89) return const Duration(milliseconds: 120);
    return const Duration(milliseconds: 150);
  }

  /// 🎉 اهتزاز احتفالي عند اكتشاف النقطة الأسطورية!
  void playFoundSpotCelebration() async {
    // نمط احتفالي: 3 نبضات قوية متتالية
    await Vibration.vibrate(
      pattern: [0, 200, 100, 200, 100, 400],
      // [0ms wait, 200ms vibrate, 100ms pause, 200ms vibrate, 100ms pause, 400ms vibrate]
    );
  }

  /// 🏆 اهتزاز عند كسر الرقم القياسي (Best Score)
  void playNewRecordPulse() async {
    await Vibration.vibrate(
      pattern: [0, 100, 50, 100, 50, 300],
    );
  }

  /// تنظيف
  void dispose() {
    stopPulsing();
  }
}
```

---

## 🔁 تدفق نظام الاهتزاز

```
┌──────────────────────────────────────────────────────────┐
│                  Signal Finder Controller                  │
│                                                          │
│  كل 2 ثانية (Timer):                                    │
│  ┌──────────────────────────────────────────────────┐   │
│  │ 1. fetchEngineeringInfo()                         │   │
│  │ 2. calculateCompositeScore() → score = 72%        │   │
│  │ 3. hapticService.updateScore(72)                  │   │
│  │    └─ يحدّث _lastScore فقط                        │   │
│  └──────────────────────────────────────────────────┘   │
│                                                          │
│  نظام الاهتزاز يعمل بشكل مستقل:                        │
│  ┌──────────────────────────────────────────────────┐   │
│  │ Timer مستقل يعتمد على _lastScore:                │   │
│  │                                                    │   │
│  │ score=72% → interval=350ms → duration=100ms       │   │
│  │ [BUZZ]...350ms...[BUZZ]...350ms...[BUZZ]          │   │
│  │                                                    │   │
│  │ عند تحديث score إلى 85%:                         │   │
│  │ score=85% → interval=200ms → duration=120ms       │   │
│  │ [BUZZ]..200ms..[BUZZ]..200ms..[BUZZ]..200ms..     │   │
│  │         ↑ التسارع المحسوس!                        │   │
│  │                                                    │   │
│  │ عند الوصول لـ 95%:                                │   │
│  │ score=95% → interval=100ms → duration=150ms       │   │
│  │ [BUZZBUZZBUZZBUZZBUZZ!!]                          │   │
│  └──────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────┘
```

---

## 🎆 الأحداث الخاصة

### 1. احتفال اكتشاف النقطة الأسطورية
يُطلق **مرة واحدة** عندما ينتقل التصنيف من Stable → Legendary لأول مرة:

```dart
if (newRank == SignalRank.legendary && previousRank != SignalRank.legendary) {
  hapticService.playFoundSpotCelebration();
  // + عرض رسالة "🎉 قف! أنت في النقطة الذهبية!"
  // + تأثير بصري ذهبي على الشاشة
}
```

### 2. رقم قياسي جديد
يُطلق عند تجاوز أعلى قراءة مُسجّلة في الجلسة:

```dart
if (newScore > bestScore.value) {
  bestScore.value = newScore;
  bestScoreTimestamp.value = DateTime.now();
  hapticService.playNewRecordPulse();
  // + عرض شارة "🏆 رقم قياسي جديد!"
}
```

---

## 📱 إعدادات الأندرويد

### الإذن المطلوب (AndroidManifest.xml):
```xml
<uses-permission android:name="android.permission.VIBRATE"/>
```

> **ملاحظة:** هذا الإذن لا يحتاج Runtime Permission (إذن تلقائي).  
> على iOS، الاهتزاز مدعوم افتراضياً عبر Taptic Engine.

---

## ⚠️ ملاحظات مهمة

1. **البطارية**: نظام الاهتزاز لا يستهلك طاقة ملحوظة لأن الفترات قصيرة (30-150ms).
2. **التوافق**: بعض الأجهزة لا تدعم أنماط الاهتزاز المعقدة — نستخدم `Vibration.hasVibrator()` و `Vibration.hasCustomVibrationsSupport()` للتحقق.
3. **Fallback**: في حال عدم دعم الأنماط المخصصة، نستخدم `HapticFeedback.mediumImpact()` من Flutter الأصلي.
4. **المستخدم يتحكم**: زر لتعطيل/تفعيل الاهتزاز في شاشة الكاشف.
