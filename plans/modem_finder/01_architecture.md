# 🏗️ البنية المعمارية — Modem Finder Architecture

## مخطط Clean Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                     │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐ │
│  │           ModemFinderController (GetX)               │ │
│  │  ┌──────────┐ ┌──────────┐ ┌───────────────────┐   │ │
│  │  │ Scanning │ │ Geiger   │ │ Anti-Loss Monitor │   │ │
│  │  │ Engine   │ │ Mode     │ │ (Notifications)   │   │ │
│  │  └─────┬────┘ └────┬─────┘ └────────┬──────────┘   │ │
│  └────────┼────────────┼───────────────┼───────────────┘ │
│           │            │               │                   │
│  ┌────────┴────────────┴───────────────┴───────────────┐ │
│  │                     UI Widgets                       │ │
│  │  ┌──────────────┐ ┌───────────┐ ┌───────────────┐   │ │
│  │  │ProximityRadar│ │HeatmapBar│ │ AntiLossCard │   │ │
│  │  └──────────────┘ └───────────┘ └───────────────┘   │ │
│  └─────────────────────────────────────────────────────┘ │
└──────────────────────────┬──────────────────────────────┘
                           │ يعتمد على
┌──────────────────────────┴──────────────────────────────┐
│                      Domain Layer                        │
│                                                           │
│  ┌───────────────────────────┐ ┌────────────────────────┐│
│  │        Entities           │ │       Services          ││
│  │  ┌──────────────────┐     │ │ ┌────────────────────┐  ││
│  │  │ ProximityLevel   │     │ │ │ RssiSmoother       │  ││
│  │  │ RssiReading      │     │ │ │ (EMA Algorithm)    │  ││
│  │  │ CalibrationData  │     │ │ ├────────────────────┤  ││
│  │  └──────────────────┘     │ │ │ProximityClassifier │  ││
│  │                           │ │ │ (Hot/Cold Zones)   │  ││
│  │                           │ │ ├────────────────────┤  ││
│  │                           │ │ │GeigerRhythm        │  ││
│  │                           │ │ │Calculator          │  ││
│  │                           │ │ └────────────────────┘  ││
│  └───────────────────────────┘ └────────────────────────┘│
└──────────────────────────┬──────────────────────────────┘
                           │ يعتمد على
┌──────────────────────────┴──────────────────────────────┐
│                  Infrastructure Layer                     │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐ │
│  │                    Services                          │ │
│  │  ┌─────────────────┐  ┌──────────────────────────┐  │ │
│  │  │ WifiRssiReader  │  │ GeigerAudioService       │  │ │
│  │  │ (MethodChannel) │  │ (System Sounds / Beeps)  │  │ │
│  │  ├─────────────────┤  ├──────────────────────────┤  │ │
│  │  │ FinderHaptic    │  │ AntiLossService          │  │ │
│  │  │ Service         │  │ (Background Monitor)     │  │ │
│  │  │ (Vibration pkg) │  │ (Notifications)          │  │ │
│  │  └─────────────────┘  └──────────────────────────┘  │ │
│  └─────────────────────────────────────────────────────┘ │
└──────────────────────────┬──────────────────────────────┘
                           │
┌──────────────────────────┴──────────────────────────────┐
│               Native Platform Layer (Android)            │
│                                                           │
│  ┌─────────────────────────────────────────────────────┐ │
│  │              MainActivity.kt (Kotlin)                │ │
│  │  MethodChannel: "com.linkary/wifi_rssi"              │ │
│  │  ┌─────────────────────────────────────────────┐     │ │
│  │  │ ConnectivityManager.NetworkCallback         │     │ │
│  │  │  → WifiInfo.rssi (dBm)                      │     │ │
│  │  │  → WifiInfo.frequency (MHz)                 │     │ │
│  │  │  → WifiInfo.ssid                            │     │ │
│  │  └─────────────────────────────────────────────┘     │ │
│  └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

---

## شجرة الملفات

```
lib/features/modem_finder/
├── domain/
│   ├── entities/
│   │   ├── proximity_level.dart          # enum: freezing → burning
│   │   ├── rssi_reading.dart             # كيان القراءة الواحدة
│   │   └── calibration_data.dart         # بيانات المعايرة
│   └── services/
│       ├── rssi_smoother.dart            # خوارزمية EMA
│       ├── proximity_classifier.dart     # مصنف القرب
│       └── geiger_rhythm_calculator.dart # حاسبة إيقاع جايجر
│
├── infrastructure/
│   └── services/
│       ├── wifi_rssi_reader.dart         # MethodChannel → WifiManager
│       ├── geiger_audio_service.dart     # أصوات التكتكة
│       ├── finder_haptic_service.dart    # اهتزازات البحث
│       └── anti_loss_service.dart        # مراقب النسيان
│
└── presentation/
    ├── controllers/
    │   └── modem_finder_controller.dart  # المتحكم الرئيسي
    ├── pages/
    │   └── modem_finder_page.dart        # الصفحة الرئيسية
    └── widgets/
        ├── proximity_radar_widget.dart   # الرادار الدائري
        ├── signal_heatmap_bar.dart       # شريط الحرارة
        ├── geiger_mode_toggle.dart       # مفتاح وضع جايجر
        ├── calibration_dialog.dart       # حوار المعايرة
        └── anti_loss_settings_card.dart  # كارت إنذار النسيان
```

---

## تدفق البيانات (Data Flow)

```
┌──────────────┐     MethodChannel      ┌──────────────────┐
│  Android     │ ◄──────────────────── │  WifiRssiReader   │
│  WifiManager │  getRssi() → -54 dBm  │  (Dart)           │
│  (Native)    │  getFrequency() → 5GHz│                    │
└──────────────┘                        └────────┬─────────┘
                                                 │ raw dBm
                                        ┌────────▼─────────┐
                                        │  RssiSmoother    │
                                        │  EMA: α=0.25     │
                                        │  Spike Rejection │
                                        └────────┬─────────┘
                                                 │ smoothed dBm
                                        ┌────────▼─────────┐
                                        │ Proximity        │
                                        │ Classifier       │
                                        │ + Calibration    │
                                        └────────┬─────────┘
                                                 │ ProximityLevel
                              ┌──────────────────┼──────────────────┐
                              │                  │                  │
                     ┌────────▼───────┐ ┌────────▼──────┐ ┌────────▼───────┐
                     │ Geiger Rhythm  │ │ Radar Widget  │ │ Anti-Loss      │
                     │ Calculator    │ │ (UI Update)   │ │ Monitor        │
                     └───────┬────────┘ └───────────────┘ └───────┬────────┘
                             │                                      │
                    ┌────────▼────────┐                    ┌────────▼────────┐
                    │ Audio + Haptic  │                    │ Notification    │
                    │ Services        │                    │ Service         │
                    └─────────────────┘                    └─────────────────┘
```

---

## الحزم المطلوبة

### موجودة بالفعل (لا حاجة لإضافتها):

| الحزمة | الاستخدام |
|---|---|
| `vibration: ^3.1.8` | اهتزازات عداد جايجر |
| `flutter_local_notifications: ^21.0.0` | إشعارات إنذار النسيان |
| `shared_preferences` | حفظ إعدادات Anti-Loss والمعايرة |
| `network_info_plus: ^8.1.0` | التحقق من SSID الشبكة |

### قد تكون مطلوبة (اختياري):

| الحزمة | الاستخدام | بديل |
|---|---|---|
| `audioplayers` | أصوات تكتكة جايجر | `SystemSound.play()` + MethodChannel |

---

## الأذونات

### موجودة مسبقاً:
- ✅ `ACCESS_NETWORK_STATE`
- ✅ `ACCESS_FINE_LOCATION`
- ✅ `VIBRATE`
- ✅ `POST_NOTIFICATIONS`

### مطلوب إضافته:
- ⚠️ `ACCESS_WIFI_STATE` — لقراءة معلومات الواي فاي

---

## نقطة الدخول في DI

```dart
// في injection_container.dart
// ==========================================
// --- ميزة البحث عن مودمي (Modem Finder) ---
// ==========================================
Get.lazyPut(() => WifiRssiReader(), fenix: true);
Get.lazyPut(() => RssiSmoother(), fenix: true);
Get.lazyPut(() => ProximityClassifier(), fenix: true);
Get.lazyPut(() => GeigerRhythmCalculator(), fenix: true);
Get.lazyPut(() => GeigerAudioService(), fenix: true);
Get.lazyPut(() => FinderHapticService(), fenix: true);
Get.lazyPut(() => AntiLossService(
    notificationService: Get.find(),
), fenix: true);
Get.lazyPut(() => ModemFinderController(
    rssiReader: Get.find(),
    smoother: Get.find(),
    classifier: Get.find(),
    rhythmCalculator: Get.find(),
    audioService: Get.find(),
    hapticService: Get.find(),
    antiLossService: Get.find(),
), fenix: true);
```
