# 🚀 مراحل التنفيذ التفصيلية — Implementation Phases

## نظرة عامة

| المرحلة | الوصف | الملفات | التقدير |
|---|---|---|---|
| 1 | المحرك الأساسي (RSSI + MethodChannel) | 7 ملفات | الأساس التقني |
| 2 | الرادار والواجهات | 5 ملفات | الواجهة الكاملة |
| 3 | عداد جايجر | 3 ملفات | الصوت والاهتزاز |
| 4 | المعايرة + إنذار النسيان | 4 ملفات | الميزات المتقدمة |
| 5 | التكامل والتلميع | تعديلات | الربط النهائي |

---

## المرحلة 1: المحرك الأساسي (Foundation Engine)

### الهدف
بناء القدرة على قراءة RSSI الواي فاي وتنعيمها وتصنيفها.

### الملفات

#### 1.1 الكيانات (Entities)

| الملف | الوصف |
|---|---|
| `domain/entities/proximity_level.dart` | enum: freezing, cold, warm, hot, burning |
| `domain/entities/rssi_reading.dart` | كيان القراءة (raw, smoothed, timestamp) |
| `domain/entities/calibration_data.dart` | بيانات المعايرة (maxRssi, frequency, timestamp) |

#### 1.2 الخدمات الأساسية

| الملف | الوصف |
|---|---|
| `domain/services/rssi_smoother.dart` | خوارزمية EMA + Spike Rejection |
| `domain/services/proximity_classifier.dart` | تصنيف القرب + معايرة ديناميكية |

#### 1.3 MethodChannel (Native)

| الملف | الوصف |
|---|---|
| `infrastructure/services/wifi_rssi_reader.dart` | Dart side: MethodChannel wrapper |
| `MainActivity.kt` (تعديل) | Kotlin side: WifiManager.getRssi() |

#### 1.4 إذن Android

| الملف | التعديل |
|---|---|
| `AndroidManifest.xml` | إضافة `ACCESS_WIFI_STATE` |

### اختبار المرحلة 1
- ✅ تشغيل على جهاز حقيقي
- ✅ طباعة RSSI الخام في الـ Console كل 300ms
- ✅ التحقق من عمل EMA (القراءات سلسة بدون قفزات)
- ✅ التحقق من تصنيف القرب (المشي بعيداً = freezing, قريب = burning)

---

## المرحلة 2: الرادار والواجهات (Radar UI)

### الهدف
بناء الواجهة التفاعلية الكاملة مع الرادار الدائري.

### الملفات

| الملف | الوصف |
|---|---|
| `presentation/controllers/modem_finder_controller.dart` | المتحكم الرئيسي مع Timer و State Management |
| `presentation/pages/modem_finder_page.dart` | الصفحة الرئيسية (Scaffold + Layout) |
| `presentation/widgets/proximity_radar_widget.dart` | CustomPainter مع Animations |
| `presentation/widgets/signal_heatmap_bar.dart` | شريط الحرارة المتدرج |
| `domain/services/geiger_rhythm_calculator.dart` | حاسبة الإيقاع (تُبنى هنا لأن الـ Controller يحتاجها) |

### تفاصيل `modem_finder_controller.dart`

```dart
class ModemFinderController extends GetxController {
  // Dependencies
  final WifiRssiReader rssiReader;
  final RssiSmoother smoother;
  final ProximityClassifier classifier;
  // ... (inject all)

  // State
  var currentRssi = 0.obs;
  var smoothedRssi = 0.0.obs;
  var proximityLevel = ProximityLevel.freezing.obs;
  var proximityPercentage = 0.0.obs;
  var isScanning = false.obs;
  var isGeigerMode = true.obs;
  var isSoundEnabled = true.obs;
  var isCalibrated = false.obs;
  var connectedSSID = ''.obs;
  var wifiFrequency = 0.obs;
  var scanDuration = 0.obs;
  var guidanceMessage = ''.obs;
  var rssiHistory = <RssiReading>[].obs;
  var isConnectedToWifi = true.obs;

  Timer? _scanTimer;
  Timer? _durationTimer;

  static const int maxHistoryPoints = 30;
  static const Duration scanInterval = Duration(milliseconds: 300);

  void startScanning() { /* ... */ }
  void stopScanning() { /* ... */ }
  void calibrate() { /* ... */ }
  Future<void> _fetchAndProcess() async { /* ... */ }

  @override
  void onClose() {
    stopScanning();
    super.onClose();
  }
}
```

### اختبار المرحلة 2
- ✅ الصفحة تظهر بشكل صحيح
- ✅ الرادار يتحرك ويتغير لونه
- ✅ شريط الحرارة يتحدث مع القراءات
- ✅ رسالة التوجيه تتغير حسب الحالة
- ✅ زر البدء/الإيقاف يعمل

---

## المرحلة 3: عداد جايجر (Geiger Counter)

### الهدف
إضافة التكتكات الصوتية والاهتزازات.

### الملفات

| الملف | الوصف |
|---|---|
| `infrastructure/services/geiger_audio_service.dart` | أصوات التكتكة |
| `infrastructure/services/finder_haptic_service.dart` | اهتزازات البحث |
| `presentation/widgets/geiger_mode_toggle.dart` | مفتاح وضع جايجر |

### الربط مع المتحكم

```dart
// إضافة في modem_finder_controller.dart:

void _onProximityChanged(ProximityLevel newLevel) {
  // تحديث الاهتزاز والصوت
  if (isGeigerMode.value) {
    hapticService.updateLevel(newLevel, rhythmCalculator);
    if (isSoundEnabled.value) {
      audioService.updateLevel(newLevel, rhythmCalculator);
    }
  }
  
  // احتفال burning!
  if (newLevel == ProximityLevel.burning && 
      proximityLevel.value != ProximityLevel.burning) {
    hapticService.playFoundCelebration();
  }
}
```

### اختبار المرحلة 3
- ✅ الاهتزازات تتسارع عند الاقتراب
- ✅ الأصوات تتسارع عند الاقتراب
- ✅ زر كتم الصوت يعمل (يبقى الاهتزاز)
- ✅ مفتاح جايجر يفعّل/يعطّل الوضع بالكامل
- ✅ احتفال عند الوصول لمستوى burning

---

## المرحلة 4: المعايرة + إنذار النسيان (Calibration + Anti-Loss)

### الهدف
إضافة الميزات المتقدمة.

### الملفات

| الملف | الوصف |
|---|---|
| `presentation/widgets/calibration_dialog.dart` | حوار المعايرة |
| `infrastructure/services/anti_loss_service.dart` | خدمة مراقبة النسيان |
| `presentation/widgets/anti_loss_settings_card.dart` | كارت الإعدادات |
| `notification_service.dart` (تعديل) | إضافة `showAntiLossAlert()` |

### اختبار المرحلة 4
- ✅ حوار المعايرة يعمل ويحفظ البيانات
- ✅ الدقة تتحسن بعد المعايرة (العتبات ديناميكية)
- ✅ إشعار النسيان يظهر عند الابتعاد لمدة 30 ثانية
- ✅ لا إنذارات كاذبة (تذبذبات عابرة لا تُفعّل الإنذار)
- ✅ حالة التفعيل/التعطيل محفوظة

---

## المرحلة 5: التكامل والتلميع (Integration & Polish)

### الهدف
ربط كل شيء وتلميع التجربة النهائية.

### المهام

| المهمة | التفاصيل |
|---|---|
| DI Registration | تسجيل جميع المكونات في `injection_container.dart` |
| Navigation | إضافة زر الوصول للميزة (Dashboard أو Settings) |
| Theme Compliance | تشغيل `replace_theme.py` لاستبدال `Get.isDarkMode` |
| Error States | التعامل مع حالات الخطأ (لا واي فاي، لا أذونات) |
| Localization | التأكد من دعم العربية والإنجليزية |
| Performance | التأكد من عدم تسرب الذاكرة (Timer cleanup) |
| Build Test | `flutter build apk --debug` بنجاح |
| Analysis | `flutter analyze` بدون أخطاء |

### اختبار المرحلة 5
- ✅ `flutter analyze` → 0 errors
- ✅ `flutter build apk --debug` → نجاح
- ✅ التنقل من Dashboard/Settings إلى الميزة يعمل
- ✅ الثيم الداكن والفاتح يعملان بشكل صحيح
- ✅ الأداء مستقر بدون تسريب ذاكرة

---

## ملخص الملفات الجديدة (إجمالي)

```
الملفات الجديدة: 16 ملف
├── domain/entities/     (3 ملفات)
├── domain/services/     (3 ملفات)
├── infrastructure/      (4 ملفات)
├── presentation/        (6 ملفات)
│   ├── controllers/     (1)
│   ├── pages/           (1)
│   └── widgets/         (4)

الملفات المعدلة: 3 ملفات
├── AndroidManifest.xml      (إذن واحد)
├── injection_container.dart (DI)
├── notification_service.dart (دالة جديدة)
├── MainActivity.kt          (MethodChannel)
```
