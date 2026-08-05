# 📡 محرك قراءة RSSI والتنعيم — RSSI Engine

## 1. قراءة RSSI عبر MethodChannel

### لماذا MethodChannel وليس حزمة جاهزة؟

1. **`network_info_plus`** لا يوفر RSSI مطلقاً (فقط SSID, BSSID, IP, Gateway)
2. الحزم الجاهزة (`wifi_signal_strength_indicator`, `flutter_internet_signal`) تضيف تبعيات غير مضمونة
3. الكود الأصلي المطلوب **بسيط جداً** (أقل من 40 سطراً Kotlin)
4. نضمن **أداء مثالي** وتحكم كامل بتردد القراءات

### الجانب الأصلي (Kotlin) — `MainActivity.kt`

```kotlin
class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.linkary/wifi_rssi"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getRssi" -> {
                        val wifiManager = applicationContext
                            .getSystemService(Context.WIFI_SERVICE) as WifiManager
                        val wifiInfo = wifiManager.connectionInfo
                        result.success(wifiInfo.rssi) // e.g., -54
                    }
                    "getFrequency" -> {
                        val wifiManager = applicationContext
                            .getSystemService(Context.WIFI_SERVICE) as WifiManager
                        val wifiInfo = wifiManager.connectionInfo
                        result.success(wifiInfo.frequency) // e.g., 2437 or 5180
                    }
                    "getSSID" -> {
                        val wifiManager = applicationContext
                            .getSystemService(Context.WIFI_SERVICE) as WifiManager
                        val wifiInfo = wifiManager.connectionInfo
                        result.success(wifiInfo.ssid?.replace("\"", "") ?: "")
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
```

### الجانب Flutter (Dart) — `wifi_rssi_reader.dart`

```dart
class WifiRssiReader {
  static const _channel = MethodChannel('com.linkary/wifi_rssi');

  /// قراءة RSSI الحالي (dBm)
  /// القيم النموذجية: -30 (قوي جداً) إلى -90 (ضعيف جداً)
  Future<int> getRssi() async {
    try {
      final rssi = await _channel.invokeMethod<int>('getRssi');
      return rssi ?? -100; // fallback لقيمة ضعيفة جداً
    } catch (e) {
      return -100;
    }
  }

  /// قراءة التردد (MHz)
  /// 2400-2500 = 2.4GHz, 5000-5900 = 5GHz
  Future<int> getFrequency() async {
    try {
      final freq = await _channel.invokeMethod<int>('getFrequency');
      return freq ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// هل التردد 5GHz؟
  Future<bool> is5GHz() async {
    final freq = await getFrequency();
    return freq >= 5000;
  }

  /// قراءة SSID للتحقق
  Future<String> getSSID() async {
    try {
      final ssid = await _channel.invokeMethod<String>('getSSID');
      return ssid ?? '';
    } catch (e) {
      return '';
    }
  }
}
```

### لماذا هذا النهج آمن ومعفى من Throttling؟

| الطريقة | خاضعة للقيود؟ | السبب |
|---|---|---|
| `WifiManager.startScan()` | ✅ نعم (4 مرات / 2 دقيقة) | تبحث عن شبكات جديدة |
| `WifiInfo.getRssi()` | ❌ لا | تقرأ الاتصال الحالي فقط |
| `NetworkCallback.onCapabilitiesChanged()` | ❌ لا | إشعار من النظام |

**نحن نستخدم `WifiInfo.getRssi()` → بدون أي قيود ويمكن استدعاؤها كل 200ms بأمان.**

---

## 2. خوارزمية التنعيم (EMA — Exponential Moving Average)

### المشكلة

إشارة الواي فاي (RSSI) **متقلبة جداً** وتتأثر بـ:
- الجدران والأثاث (انعكاسات وامتصاص)
- حركة الأجسام البشرية
- تداخل الأجهزة الإلكترونية الأخرى
- تعدد المسارات (Multipath Fading)

بدون تنعيم، ستقفز القراءة بين -45 و -65 dBm في نفس المكان!

### الحل: فلتر EMA

```
S(t) = α × Y(t) + (1 - α) × S(t-1)
```

حيث:
- `S(t)` = القيمة المنعّمة الحالية
- `Y(t)` = القراءة الخام الجديدة
- `S(t-1)` = القيمة المنعّمة السابقة
- `α` = عامل التنعيم (0 < α < 1)

### تكيف عامل α مع التردد

| التردد | α | السبب |
|---|---|---|
| 2.4 GHz | 0.25 | إشارة أكثر استقراراً، تنعيم أقوى |
| 5 GHz | 0.35 | إشارة أكثر تقلباً، حساسية أعلى |

### كشف القفزات الشاذة (Spike Rejection)

إذا تغيرت القراءة بأكثر من **15 dBm** في قراءة واحدة (300ms):
- نتجاهل القراءة الجديدة
- نُبقي على القيمة المنعّمة السابقة
- هذا يمنع "قفزات الأشباح" التي تحدث عند مرور شخص أمام المودم

### التنفيذ — `rssi_smoother.dart`

```dart
class RssiSmoother {
  double _smoothedValue = -100.0;
  bool _isInitialized = false;
  
  static const double _alpha24GHz = 0.25;
  static const double _alpha5GHz = 0.35;
  static const double _spikeThreshold = 15.0; // dBm

  /// إعادة تهيئة المنعّم
  void reset() {
    _smoothedValue = -100.0;
    _isInitialized = false;
  }

  /// تنعيم قراءة RSSI جديدة
  double smooth(int rawRssi, {bool is5GHz = false}) {
    final raw = rawRssi.toDouble();
    
    // أول قراءة: نأخذها كما هي
    if (!_isInitialized) {
      _smoothedValue = raw;
      _isInitialized = true;
      return _smoothedValue;
    }
    
    // كشف القفزات الشاذة
    if ((raw - _smoothedValue).abs() > _spikeThreshold) {
      // نتجاهل القراءة المريبة ونُعيد القيمة السابقة
      return _smoothedValue;
    }
    
    // تطبيق EMA مع عامل α المناسب للتردد
    final alpha = is5GHz ? _alpha5GHz : _alpha24GHz;
    _smoothedValue = alpha * raw + (1 - alpha) * _smoothedValue;
    
    return _smoothedValue;
  }

  double get currentSmoothed => _smoothedValue;
}
```

---

## 3. تصنيف القرب (Proximity Classification)

### العتبات الثابتة (بدون معايرة)

| RSSI (dBm) | المستوى | الوصف | اللون |
|---|---|---|---|
| ≤ -80 | `freezing` | بعيد جداً | أحمر |
| -79 to -70 | `cold` | بعيد | أحمر مصفر قليلا |
| -69 to -60 | `warm` | متوسط | برتقالي  |
| -59 to -50 | `hot` | قريب | اخضر مصفر قليل  |
| ≥ -49 | `burning` | فوق المودم! | أخضر نيون  |

### العتبات الديناميكية (مع معايرة)

عندما يضع المستخدم الهاتف بجانب المودم ويضغط "معايرة":
1. نحفظ أقوى RSSI كـ `calibratedMax` (مثلاً: -25 dBm)
2. نحسب العتبات كنسب من المدى الكامل:

```
المدى = calibratedMax - (-100)    // مثال: -25 - (-100) = 75 dBm
freezing  = calibratedMax - (المدى × 0.80)  // -85 dBm
cold      = calibratedMax - (المدى × 0.60)  // -70 dBm  
warm      = calibratedMax - (المدى × 0.40)  // -55 dBm
hot       = calibratedMax - (المدى × 0.20)  // -40 dBm
burning   = أي شيء أقوى من hot
```

### حساب النسبة المئوية (للرادار)

```dart
double calculatePercentage(double smoothedRssi, {CalibrationData? calibration}) {
  final maxRssi = calibration?.maxRssi ?? -30.0;
  final minRssi = -100.0;
  
  return ((smoothedRssi - minRssi) / (maxRssi - minRssi) * 100)
      .clamp(0.0, 100.0);
}
```

---

## 4. تردد القراءة

| الوضع | التردد | السبب |
|---|---|---|
| البحث النشط (المستخدم يمشي) | كل 300ms | سرعة استجابة عالية |
| مراقبة Anti-Loss | كل 10 ثوانٍ | توفير البطارية |
| خلفية (التطبيق مغلق) | كل 30 ثانية | توفير أقصى للبطارية |
