# 🎨 تصميم الواجهة — UI/UX Design

## الفلسفة التصميمية

تصميم **غامق ومتوهج** (Dark Neon Aesthetic) يتغير لونه ديناميكياً مع القرب من المودم:
- بارد → ألوان باردة (أزرق جليدي)
- ساخن → ألوان حارة (أحمر نيون مشتعل)

---

## 1. الصفحة الرئيسية (`modem_finder_page.dart`)

### التخطيط العام

```
┌─────────────────────────────────────┐
│ ←  أين مودمي؟            🔊  ⚙️   │  AppBar شفاف
├─────────────────────────────────────┤
│                                      │
│   الشبكة المتصلة: SAM_4G (5GHz)    │  معلومات الشبكة
│                                      │
│        ╭─────────────────╮           │
│       ╱                   ╲          │
│      │    ╭───────────╮    │         │
│      │   ╱   ░░░░░░░   ╲   │        │  الرادار الدائري
│      │  │    72%         │  │        │  (يتغير لونه ويتوهج)
│      │   ╲  -54 dBm    ╱   │        │
│      │    ╰───────────╯    │         │
│       ╲                   ╱          │
│        ╰─────────────────╯           │
│                                      │
│  ❄️ ████████████████░░░░░░ 🔥       │  شريط الحرارة
│                                      │
│  ┌──────────────────────────────┐    │
│  │                              │    │
│  │  🎯 أنت تقترب! استمر...    │    │  رسالة التوجيه
│  │     الإشارة تقوى            │    │
│  │                              │    │
│  └──────────────────────────────┘    │
│                                      │
│  ┌─────────┐     ┌──────────────┐    │
│  │ 🎯      │     │ 📻           │    │  أزرار التحكم
│  │ معايرة  │     │ وضع جايجر   │    │
│  └─────────┘     └──────────────┘    │
│                                      │
│  ┌──────────────────────────────┐    │
│  │ 🔔 جرس إنذار النسيان       │    │  كارت Anti-Loss
│  │    مفعّل ✅                  │    │
│  └──────────────────────────────┘    │
│                                      │
│       ┌──────────────────┐           │
│       │   ◉ ابدأ البحث   │          │  زر البدء/الإيقاف
│       └──────────────────┘           │
└─────────────────────────────────────┘
```

---

## 2. الرادار الدائري (`proximity_radar_widget.dart`)

### التصميم

ويدجت مخصص بـ `CustomPainter` مع `AnimationController`:

```
الحلقة الخارجية: خط رفيع نابض (radar sweep)
  ↓
الحلقة الوسطى: تدرج لوني شبه شفاف
  ↓
الدائرة المركزية: النسبة المئوية + dBm
```

### الألوان حسب المستوى

| ProximityLevel | لون الرادار | تأثير الوهج (Glow) |
|---|---|---|
| `freezing` | `Color(0xFF00B4D8)` أزرق جليدي | خافت، بطيء |
| `cold` | `Color(0xFF0077B6)` أزرق | متوسط |
| `warm` | `Color(0xFFFF8C42)` برتقالي | واضح |
| `hot` | `Color(0xFFFF3D3D)` أحمر | قوي، نابض |
| `burning` | `Color(0xFFFF073A)` أحمر نيون | مشتعل! نبضات سريعة |

### الأنيميشنات

1. **Radar Sweep**: حلقة دائرية تدور بسرعة ثابتة (مثل رادار حقيقي)
2. **Glow Pulse**: نبضة توهج تتسارع مع القرب
3. **Scale Bounce**: الرادار يكبر قليلاً عند الانتقال لمستوى جديد
4. **Number Tween**: النسبة المئوية تتغير بتدرج سلس (Tween)

### الكود التقريبي

```dart
class ProximityRadarWidget extends StatefulWidget {
  final double percentage;        // 0-100
  final ProximityLevel level;
  final int rssiDbm;

  // ...
}

class _ProximityRadarWidgetState extends State<ProximityRadarWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _sweepController;   // دوران الرادار
  late AnimationController _glowController;    // نبضة الوهج
  
  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    _glowController = AnimationController(
      vsync: this,
      duration: _glowDuration(widget.level),
    )..repeat(reverse: true);
  }
  
  Duration _glowDuration(ProximityLevel level) {
    switch (level) {
      case ProximityLevel.freezing: return const Duration(milliseconds: 2000);
      case ProximityLevel.cold: return const Duration(milliseconds: 1500);
      case ProximityLevel.warm: return const Duration(milliseconds: 1000);
      case ProximityLevel.hot: return const Duration(milliseconds: 600);
      case ProximityLevel.burning: return const Duration(milliseconds: 300);
    }
  }
  
  // ...
}
```

---

## 3. شريط الحرارة (`signal_heatmap_bar.dart`)

```
❄️ ██████████████████░░░░░░░░ 🔥
   ←── أزرق ──→←── أحمر ──→
         ▲
         │ مؤشر RSSI (يتحرك بسلاسة)
```

### المواصفات
- عرض كامل مع padding
- تدرج لوني: أزرق → سماوي → أخضر → أصفر → برتقالي → أحمر
- مؤشر دائري يتبع القراءة بأنيميشن سلس
- أيقونة ثلج ❄️ على اليسار (RTL: اليمين) ونار 🔥 على اليمين

---

## 4. رسالة التوجيه (Guidance Message)

### الرسائل حسب المستوى والاتجاه

| المستوى | الاتجاه | الرسالة |
|---|---|---|
| `freezing` | - | "المودم بعيد جداً... جرب غرفة أخرى" |
| `cold` | improving | "الإشارة تتحسن! استمر في هذا الاتجاه" |
| `cold` | declining | "الاتجاه خاطئ... جرب اتجاهاً آخر" |
| `cold` | stable | "الإشارة ضعيفة... تحرك ببطء وراقب التغيير" |
| `warm` | improving | "أنت تقترب! الإشارة تقوى 💪" |
| `warm` | declining | "كنت أقرب قبل قليل... ارجع خطوة" |
| `warm` | stable | "منطقة متوسطة... تحرك لليمين أو اليسار" |
| `hot` | improving | "قريب جداً! ابحث حولك 👀" |
| `hot` | declining | "ابتعدت قليلاً... ارجع!" |
| `hot` | stable | "أنت قريب جداً... ابحث تحت الوسائد!" |
| `burning` | - | "🔥 المودم هنا! أنت تقف فوقه!" |

### كشف الاتجاه (Trend Detection)

نفس مبدأ `signal_finder` — نقارن آخر 3 قراءات:
```dart
SignalTrend detectTrend(List<RssiReading> recent) {
  if (recent.length < 3) return SignalTrend.stable;
  
  final diff = recent.last.smoothedRssi - recent[recent.length - 3].smoothedRssi;
  if (diff > 3.0) return SignalTrend.improving;  // الإشارة تقوى
  if (diff < -3.0) return SignalTrend.declining;  // الإشارة تضعف
  return SignalTrend.stable;
}
```

---

## 5. حوار المعايرة (`calibration_dialog.dart`)

```
┌──────────────────────────────────────┐
│           🎯 معايرة المكان           │
│                                       │
│  ضع هاتفك بجانب المودم مباشرة       │
│  واضغط "معايرة" لتحسين دقة الرادار  │
│                                       │
│          ┌──────────────┐             │
│          │   📱 ← → 📡  │            │
│          │   (بجانب بعض) │            │
│          └──────────────┘             │
│                                       │
│  الإشارة الحالية: -28 dBm ✅ ممتاز   │
│                                       │
│   [إلغاء]           [✅ معايرة]       │
└──────────────────────────────────────┘
```

عند الضغط:
1. يأخذ 5 قراءات RSSI سريعة (كل 200ms)
2. يحسب المتوسط كأقوى إشارة مرجعية
3. يحفظ في `SharedPreferences`
4. يعرض رسالة تأكيد: "تمت المعايرة! الرادار الآن أدق بنسبة X%"

---

## 6. الثيم والألوان

### الوضع الداكن (الأساسي لهذه الميزة)

```dart
// خلفية الصفحة
bgColor: Color(0xFF0A0E21)  // أزرق غامق جداً

// الكروت
cardColor: Color(0xFF16213E)

// ألوان القرب
static const Map<ProximityLevel, Color> proximityColors = {
  ProximityLevel.freezing: Color(0xFF00B4D8),
  ProximityLevel.cold:     Color(0xFF0077B6),
  ProximityLevel.warm:     Color(0xFFFF8C42),
  ProximityLevel.hot:      Color(0xFFFF3D3D),
  ProximityLevel.burning:  Color(0xFFFF073A),
};

// تدرج شريط الحرارة
heatmapGradient: [
  Color(0xFF00B4D8), // أزرق
  Color(0xFF00D4AA), // سماوي أخضر
  Color(0xFFFFD166), // أصفر
  Color(0xFFFF8C42), // برتقالي
  Color(0xFFFF3D3D), // أحمر
  Color(0xFFFF073A), // أحمر نيون
]
```

### الوضع الفاتح

نفس الألوان مع خلفية فاتحة ومؤشرات مخفّفة.

---

## 7. الحالات الخاصة

### غير متصل بالواي فاي
```
┌──────────────────────────────────────┐
│                                       │
│       📡❌                             │
│                                       │
│  غير متصل بشبكة واي فاي             │
│  اتصل بشبكة المودم أولاً            │
│  ثم ارجع هنا للبحث                   │
│                                       │
│      [فتح إعدادات الواي فاي]         │
│                                       │
└──────────────────────────────────────┘
```

### الإشارة ممتازة من البداية (المودم بجانبك)
```
┌──────────────────────────────────────┐
│                                       │
│       🎉                              │
│                                       │
│  المودم بجانبك بالفعل!               │
│  الإشارة ممتازة (-28 dBm)           │
│                                       │
└──────────────────────────────────────┘
```
