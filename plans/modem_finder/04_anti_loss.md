# 🔔 جرس إنذار النسيان — Anti-Loss Alarm

## الفكرة

ميزة **حماية استباقية** تمنع ضياع المودم من الأساس:
- إذا ابتعد المستخدم عن المودم وأوشكت إشارة الواي فاي على الانقطاع
- يُصدر التطبيق إشعاراً صوتياً عالياً ينبّه المستخدم

---

## 1. آلية العمل

```
┌─────────────────────────────────────────────┐
│              AntiLossService                 │
│                                               │
│  Timer (كل 10 ثوانٍ)                          │
│     ↓                                         │
│  قراءة RSSI عبر WifiRssiReader               │
│     ↓                                         │
│  هل RSSI < عتبة التنبيه (-75 dBm)؟           │
│     ↓                                         │
│  [لا] → إعادة تصفير العداد                    │
│  [نعم] → زيادة عداد القراءات المتتالية        │
│     ↓                                         │
│  هل العداد ≥ 3 قراءات متتالية؟                │
│     ↓                                         │
│  [لا] → انتظار القراءة التالية                │
│  [نعم] → إرسال إشعار تحذيري! 🔔              │
│     ↓                                         │
│  إعادة تصفير العداد                           │
│  (تجنب تكرار الإشعارات)                       │
│  انتظار 60 ثانية قبل التحقق مجدداً           │
└─────────────────────────────────────────────┘
```

### لماذا 3 قراءات متتالية؟

- قراءة واحدة ضعيفة قد تكون **ضوضاء عابرة** (شخص مر أمام المودم)
- 3 قراءات متتالية (= 30 ثانية) تعني أن المستخدم **يبتعد فعلاً** عن المودم
- هذا يمنع الإنذارات الكاذبة (False Alarms)

---

## 2. التنفيذ — `anti_loss_service.dart`

```dart
class AntiLossService {
  final NotificationService _notificationService;
  
  Timer? _monitorTimer;
  int _consecutiveWeakReadings = 0;
  bool _isActive = false;
  bool _isCooldown = false; // منع تكرار الإشعارات
  
  static const int _checkIntervalSeconds = 10;
  static const double _alertThresholdDbm = -75.0;
  static const int _requiredConsecutiveReadings = 3;
  static const int _cooldownSeconds = 60;

  AntiLossService({required NotificationService notificationService})
      : _notificationService = notificationService;

  /// تفعيل المراقبة
  void startMonitoring() {
    if (_isActive) return;
    _isActive = true;
    _consecutiveWeakReadings = 0;
    
    _monitorTimer = Timer.periodic(
      Duration(seconds: _checkIntervalSeconds),
      (_) => _checkSignal(),
    );
  }

  /// إيقاف المراقبة
  void stopMonitoring() {
    _isActive = false;
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _consecutiveWeakReadings = 0;
  }

  Future<void> _checkSignal() async {
    if (!_isActive || _isCooldown) return;
    
    try {
      final rssiReader = Get.find<WifiRssiReader>();
      final rssi = await rssiReader.getRssi();
      
      if (rssi < _alertThresholdDbm) {
        _consecutiveWeakReadings++;
        
        if (_consecutiveWeakReadings >= _requiredConsecutiveReadings) {
          await _sendAlert();
          _startCooldown();
        }
      } else {
        _consecutiveWeakReadings = 0; // إعادة تصفير
      }
    } catch (e) {
      // إذا فشلت القراءة (ربما انقطع الواي فاي تماماً)
      _consecutiveWeakReadings++;
      if (_consecutiveWeakReadings >= _requiredConsecutiveReadings) {
        await _sendAlert();
        _startCooldown();
      }
    }
  }

  Future<void> _sendAlert() async {
    await _notificationService.showAntiLossAlert(
      title: '⚠️ تنبيه! أنت تبتعد عن المودم',
      body: 'إشارة الواي فاي ضعيفة جداً. تأكد أنك لم تنسَ المودم!',
    );
  }

  void _startCooldown() {
    _isCooldown = true;
    _consecutiveWeakReadings = 0;
    
    Timer(Duration(seconds: _cooldownSeconds), () {
      _isCooldown = false;
    });
  }

  void dispose() => stopMonitoring();
}
```

---

## 3. قناة إشعارات مخصصة

سنحتاج إضافة دالة جديدة في `NotificationService` الموجود:

```dart
// إضافة في notification_service.dart:

Future<void> showAntiLossAlert({
  required String title,
  required String body,
}) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'linkary_anti_loss',           // قناة مختلفة عن تنبيهات الاستهلاك
    'تنبيهات نسيان المودم',
    channelDescription: 'تنبيهات عند ابتعادك عن المودم',
    importance: Importance.max,     // أعلى أهمية
    priority: Priority.max,
    playSound: true,
    enableVibration: true,
    category: AndroidNotificationCategory.alarm, // تصنيف إنذار
    fullScreenIntent: true,         // يظهر حتى في شاشة القفل
    color: Color(0xFFFF6B35),       // برتقالي تحذيري
  );

  const NotificationDetails platformDetails = NotificationDetails(
    android: androidDetails,
  );

  await _flutterLocalNotificationsPlugin.show(
    id: 9999, // ID ثابت لمنع تكرار الإشعارات
    title: title,
    body: body,
    notificationDetails: platformDetails,
  );
}
```

---

## 4. حفظ الإعدادات

```dart
// حفظ حالة التفعيل في SharedPreferences
class AntiLossPreferences {
  static const _key = 'anti_loss_enabled';
  
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false; // مُعطّل افتراضياً
  }
  
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, enabled);
  }
}
```

---

## 5. كارت الإعدادات في الواجهة

```
┌──────────────────────────────────────┐
│  🔔 جرس إنذار النسيان               │
│                                       │
│  يُنبهك إذا ابتعدت عن المودم        │
│  وأوشكت الإشارة على الانقطاع        │
│                                       │
│  [═══════════════╸       ] ✅ مفعّل   │  ← Toggle Switch
│                                       │
│  ℹ️ يتحقق كل 10 ثوانٍ ويُرسل        │
│     إشعاراً إذا ضعفت الإشارة         │
│     لمدة 30 ثانية متواصلة            │
└──────────────────────────────────────┘
```

---

## 6. سيناريوهات الاستخدام

### السيناريو 1: المستخدم ينسى المودم في المقهى
```
المستخدم في المقهى + المودم معه
  ↓
يقوم ليغادر ← ينسى المودم على الطاولة
  ↓
يمشي نحو الباب (RSSI تنخفض)
  ↓
10 ثوانٍ: -60 dBm (عادي)
20 ثانية: -72 dBm (أول قراءة ضعيفة)
30 ثانية: -78 dBm (ثاني قراءة)
40 ثانية: -82 dBm (ثالث قراءة!)
  ↓
🔔 إشعار: "⚠️ تنبيه! أنت تبتعد عن المودم"
  ↓
المستخدم يرجع ويأخذ المودم! ✅
```

### السيناريو 2: إنذار كاذب (شخص يمر أمام المودم)
```
المستخدم قريب من المودم (-45 dBm)
  ↓
شخص يمر أمام المودم → RSSI تنخفض مؤقتاً
  ↓
10 ثوانٍ: -76 dBm (أول قراءة ضعيفة)
20 ثانية: -50 dBm (الشخص مرّ → عادت الإشارة)
  ↓
❌ لا إشعار (قراءة واحدة فقط → تصفير العداد)
```
