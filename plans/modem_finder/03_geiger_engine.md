# 📻 عداد جايجر الصوتي والاهتزازات — Geiger Counter Engine

## الفلسفة

تماماً كأجهزة كشف الإشعاع (Geiger Counter) أو كاشفات المعادن (Metal Detector):
- التطبيق يُصدر أصوات "تكتكة" خفيفة (Beeps) واهتزازات (Haptic Ticks)
- كلما اقتربت من المودم، **تزداد سرعة التكتكات والاهتزازات**
- المستخدم **لا يحتاج للنظر إلى الشاشة** — يضع الهاتف في يده ويمشي

---

## 1. حاسبة الإيقاع (GeigerRhythmCalculator)

### جدول الإيقاعات

| ProximityLevel | الفاصل بين التكتكات | مدة الاهتزاز | مدة الصوت | الوصف |
|---|---|---|---|---|
| `freezing` | 2500 ms | 15 ms | 30 ms | طقة خافتة كل 2.5 ثانية |
| `cold` | 1500 ms | 30 ms | 50 ms | طقة بطيئة |
| `warm` | 700 ms | 60 ms | 80 ms | إيقاع واضح |
| `hot` | 300 ms | 90 ms | 100 ms | تكتكة سريعة! |
| `burning` | 80 ms | 130 ms | 120 ms | طنين مستمر تقريباً! 🔥 |

### التنفيذ

```dart
class GeigerRhythmCalculator {
  /// حساب الفاصل بين التكتكات (بالمللي ثانية)
  Duration calculateInterval(ProximityLevel level) {
    switch (level) {
      case ProximityLevel.freezing:
        return const Duration(milliseconds: 2500);
      case ProximityLevel.cold:
        return const Duration(milliseconds: 1500);
      case ProximityLevel.warm:
        return const Duration(milliseconds: 700);
      case ProximityLevel.hot:
        return const Duration(milliseconds: 300);
      case ProximityLevel.burning:
        return const Duration(milliseconds: 80);
    }
  }

  /// حساب مدة الاهتزاز الواحد (بالمللي ثانية)
  int calculateVibrationDuration(ProximityLevel level) {
    switch (level) {
      case ProximityLevel.freezing: return 15;
      case ProximityLevel.cold: return 30;
      case ProximityLevel.warm: return 60;
      case ProximityLevel.hot: return 90;
      case ProximityLevel.burning: return 130;
    }
  }

  /// حساب ارتفاع الصوت (0.0 - 1.0)
  double calculateVolume(ProximityLevel level) {
    switch (level) {
      case ProximityLevel.freezing: return 0.2;
      case ProximityLevel.cold: return 0.35;
      case ProximityLevel.warm: return 0.55;
      case ProximityLevel.hot: return 0.75;
      case ProximityLevel.burning: return 1.0;
    }
  }
}
```

---

## 2. خدمة الأصوات (GeigerAudioService)

### الخيارات المتاحة

#### الخيار A: أصوات النظام (بدون ملفات إضافية) — **مُقترح للبداية**
```dart
class GeigerAudioService {
  Timer? _tickTimer;
  bool _isActive = false;
  bool _isMuted = false;

  void startTicking(ProximityLevel level, GeigerRhythmCalculator calculator) {
    _isActive = true;
    _scheduleTick(level, calculator);
  }

  void _scheduleTick(ProximityLevel level, GeigerRhythmCalculator calculator) {
    _tickTimer?.cancel();
    if (!_isActive) return;

    final interval = calculator.calculateInterval(level);
    
    _tickTimer = Timer(interval, () {
      if (!_isActive) return;
      if (!_isMuted) {
        // صوت نقرة قصيرة من النظام
        SystemSound.play(SystemSoundType.click);
      }
      _scheduleTick(level, calculator); // جدولة النقرة التالية
    });
  }

  void updateLevel(ProximityLevel level, GeigerRhythmCalculator calculator) {
    if (_isActive) {
      _scheduleTick(level, calculator);
    }
  }

  void stop() {
    _isActive = false;
    _tickTimer?.cancel();
  }

  void toggleMute() => _isMuted = !_isMuted;
  bool get isMuted => _isMuted;
  
  void dispose() => stop();
}
```

#### الخيار B: أصوات مخصصة عبر MethodChannel (لتجربة أفضل)
- نضيف ملف صوتي قصير (`tick.wav`) في `assets/sounds/`
- نستخدم Android `SoundPool` لتشغيله بكفاءة (مصمم لأصوات قصيرة متكررة)
- هذا يعطي صوتاً أكثر حدة ومميزاً عن أصوات النظام

---

## 3. خدمة الاهتزازات (FinderHapticService)

### تصميم مستقل عن signal_finder

هذه الخدمة **مستقلة تماماً** عن `HapticFeedbackService` في signal_finder. لها أنماط اهتزاز مختلفة مصممة لـ "البحث عن المودم":

```dart
class FinderHapticService {
  Timer? _tickTimer;
  bool _isActive = false;

  /// بدء نمط الاهتزاز النبضي
  void startTicking(ProximityLevel level, GeigerRhythmCalculator calculator) {
    _isActive = true;
    _scheduleTick(level, calculator);
  }

  void _scheduleTick(ProximityLevel level, GeigerRhythmCalculator calculator) {
    _tickTimer?.cancel();
    if (!_isActive) return;

    final interval = calculator.calculateInterval(level);
    final duration = calculator.calculateVibrationDuration(level);

    _tickTimer = Timer(interval, () {
      if (!_isActive) return;
      _vibrate(duration);
      _scheduleTick(level, calculator);
    });
  }

  Future<void> _vibrate(int durationMs) async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      final hasCustom = await Vibration.hasCustomVibrationsSupport();
      if (hasCustom == true) {
        Vibration.vibrate(duration: durationMs);
      } else {
        Vibration.vibrate();
      }
    }
  }

  /// 🎉 احتفال "وجدت المودم!"
  Future<void> playFoundCelebration() async {
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator != true) return;

    final hasCustom = await Vibration.hasCustomVibrationsSupport();
    if (hasCustom == true) {
      // نمط مميز: نبضتان سريعتان ثم نبضة طويلة
      await Vibration.vibrate(
        pattern: [0, 150, 80, 150, 80, 500],
      );
    } else {
      Vibration.vibrate();
    }
  }

  void updateLevel(ProximityLevel level, GeigerRhythmCalculator calculator) {
    if (_isActive) {
      _scheduleTick(level, calculator);
    }
  }

  void stop() {
    _isActive = false;
    _tickTimer?.cancel();
  }

  void dispose() => stop();
}
```

---

## 4. تنسيق وضع جايجر في المتحكم

```dart
// في ModemFinderController:

void _onProximityChanged(ProximityLevel newLevel) {
  if (!isGeigerMode.value) return;
  
  final calculator = Get.find<GeigerRhythmCalculator>();
  
  // تحديث الصوت
  if (isSoundEnabled.value) {
    audioService.updateLevel(newLevel, calculator);
  }
  
  // تحديث الاهتزاز
  hapticService.updateLevel(newLevel, calculator);
  
  // احتفال عند الوصول لمستوى burning!
  if (newLevel == ProximityLevel.burning && 
      proximityLevel.value != ProximityLevel.burning) {
    hapticService.playFoundCelebration();
  }
}
```

---

## 5. تجربة المستخدم المتوقعة

```
المستخدم يفتح "أين مودمي؟"
  ↓
يضغط "ابدأ البحث"
  ↓
يمسك الهاتف في يده ويمشي في الغرفة
  ↓
📱 طق........طق........طق  (بارد - بطيء)
  ↓ يمشي باتجاه المودم
📱 طق....طق....طق  (دافئ - أسرع)
  ↓ يقترب أكثر
📱 طق..طق..طق  (حار - سريع!)
  ↓ يضع يده فوق المودم
📱 طقطقطقطقطقطقطق! 🔥  (مشتعل - مستمر!)
  ↓
🎉 احتفال + رسالة: "وجدت المودم!"
```
