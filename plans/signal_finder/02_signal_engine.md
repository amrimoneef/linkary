# 🧮 محرك حساب الإشارة — Signal Score Calculator

## المعادلة الرئيسية

### الوزن النسبي للعوامل الثلاثة:

| المؤشر | الوزن | السبب |
|---|---|---|
| **RSRP** (قوة الإشارة) | **30%** | يحدد مدى وصول الإشارة من البرج |
| **SINR** (نقاء الإشارة) | **50%** | **الأهم للسرعة** — يقيس نسبة الإشارة إلى الضوضاء |
| **RSRQ** (جودة الإشارة) | **20%** | يكشف تداخل الأبراج وازدحام الشبكة |

### الصيغة:
```
CompositeScore = (P_RSRP × 0.30) + (P_SINR × 0.50) + (P_RSRQ × 0.20)
```

حيث `P` هي القيمة المُطبّعة (Normalized) من 0 إلى 100.

---

## 📏 التطبيع (Normalization)

### ما هو التطبيع؟
تحويل القيم الخام (مثل `-95 dBm`) إلى نسبة مئوية (مثل `62.5%`) باستخدام نطاقات مرجعية موثوقة.

### الصيغة العامة:
```
P = ((x - x_min) / (x_max - x_min)) × 100
```
- إذا `x > x_max` → `P = 100`
- إذا `x < x_min` → `P = 0`

---

### 1. تطبيع RSRP (قوة الإشارة)

| الحد | القيمة | الوصف |
|---|---|---|
| `x_max` (ممتاز) | **-80 dBm** | قوة إشارة مثالية |
| `x_min` (سيئ) | **-120 dBm** | لا إشارة تقريباً |

```dart
static double normalizeRSRP(double rsrp) {
  const double min = -120.0; // أسوأ حالة
  const double max = -80.0;  // أفضل حالة
  return ((rsrp - min) / (max - min) * 100).clamp(0.0, 100.0);
}
```

**أمثلة:**
| RSRP الخام | النسبة المُطبّعة |
|---|---|
| -75 dBm | 100% (ممتاز، أعلى من الحد) |
| -80 dBm | 100% |
| -90 dBm | 75% |
| -100 dBm | 50% |
| -110 dBm | 25% |
| -120 dBm | 0% |
| -130 dBm | 0% (أسوأ من الحد) |

---

### 2. تطبيع SINR (نقاء الإشارة — نسبة الإشارة إلى الضوضاء)

| الحد | القيمة | الوصف |
|---|---|---|
| `x_max` (ممتاز) | **25 dB** | لا تشويش تقريباً |
| `x_min` (سيئ) | **0 dB** | تشويش شديد |

```dart
static double normalizeSINR(double sinr) {
  const double min = 0.0;   // تشويش شديد
  const double max = 25.0;  // نقاء مثالي
  return ((sinr - min) / (max - min) * 100).clamp(0.0, 100.0);
}
```

**أمثلة:**
| SINR الخام | النسبة المُطبّعة |
|---|---|
| 30 dB | 100% |
| 25 dB | 100% |
| 20 dB | 80% |
| 15 dB | 60% |
| 10 dB | 40% |
| 5 dB | 20% |
| 0 dB | 0% |

---

### 3. تطبيع RSRQ (جودة الإشارة المرجعية)

| الحد | القيمة | الوصف |
|---|---|---|
| `x_max` (ممتاز) | **-6 dB** | خالي من التداخل |
| `x_min` (سيئ) | **-20 dB** | تداخل شديد بين الأبراج |

```dart
static double normalizeRSRQ(double rsrq) {
  const double min = -20.0; // تداخل شديد
  const double max = -6.0;  // ممتاز
  return ((rsrq - min) / (max - min) * 100).clamp(0.0, 100.0);
}
```

**أمثلة:**
| RSRQ الخام | النسبة المُطبّعة |
|---|---|
| -3 dB | 100% |
| -6 dB | 100% |
| -9 dB | 78.6% |
| -13 dB | 50% |
| -17 dB | 21.4% |
| -20 dB | 0% |

---

## 🏅 تصنيف المناطق (Signal Ranks)

بناءً على `CompositeScore` النهائي:

```dart
enum SignalRank {
  deadZone,    // 🔴 0% - 25%
  critical,    // 🟠 26% - 50%
  stable,      // 🔵 51% - 79%
  legendary,   // 🟢 80% - 100%
}
```

### التفاصيل:

| النسبة | الرتبة | الرمز | اللون | الوصف بالعربي |
|---|---|---|---|---|
| 0% — 25% | **Dead Zone** | 🔴 | `Color(0xFFFF4444)` | منطقة ميتة — لا تضع المودم هنا! |
| 26% — 50% | **Critical** | 🟠 | `Color(0xFFFF9500)` | تغطية حرجة — ابتعد قليلاً |
| 51% — 79% | **Stable** | 🔵 | `Color(0xFF4A90E2)` | نقطة جيدة — مستقرة |
| 80% — 100% | **Legendary** | 🟢 | `Color(0xFF00E676)` | النقطة الأسطورية — أقصى سرعة! |

---

## 📈 تحليل الاتجاه (Trend Detection)

نقارن آخر 3 قراءات لتحديد اتجاه الإشارة:

```dart
enum SignalTrend {
  improving,   // ⬆️ الإشارة تتحسن — استمر!
  stable,      // ➡️ ثابتة — لا تغيير
  declining,   // ⬇️ الإشارة تضعف — ارجع!
}
```

### الخوارزمية:
```dart
SignalTrend calculateTrend(List<SignalPoint> lastPoints) {
  if (lastPoints.length < 3) return SignalTrend.stable;
  
  final recent = lastPoints.sublist(lastPoints.length - 3);
  final avg1 = recent[0].score;
  final avg2 = recent[2].score;
  final diff = avg2 - avg1;
  
  if (diff > 5) return SignalTrend.improving;
  if (diff < -5) return SignalTrend.declining;
  return SignalTrend.stable;
}
```

- **Threshold = 5%** لتجنب التذبذبات الطبيعية.

---

## 📊 مخطط حساب كامل (مثال عملي)

### السيناريو:
> المستخدم يقف بجانب النافذة، القراءات:
> - RSRP = -88 dBm
> - SINR = 18 dB
> - RSRQ = -10 dB

### الحساب:
```
P_RSRP = ((-88) - (-120)) / ((-80) - (-120)) × 100 = (32/40) × 100 = 80%
P_SINR = (18 - 0) / (25 - 0) × 100 = (18/25) × 100 = 72%
P_RSRQ = ((-10) - (-20)) / ((-6) - (-20)) × 100 = (10/14) × 100 = 71.4%

CompositeScore = (80 × 0.30) + (72 × 0.50) + (71.4 × 0.20)
               = 24 + 36 + 14.28
               = 74.28%
```

### النتيجة:
- **النسبة**: 74% 🔵
- **التصنيف**: نقطة جيدة (Stable)
- **الاهتزاز**: نبضات متوسطة التردد
- **الرسالة**: "مكان جيد! جرّب خطوتين نحو النافذة لـ80%+"

---

## 🔄 معالجة القيم الخام

القيم من المودم تأتي كـ String وقد تحتوي على وحدات أو رموز:

```dart
/// استخراج الرقم من القيمة الخام
static double _parseValue(String raw) {
  // إزالة أي شيء ليس رقماً أو نقطة أو إشارة سالبة
  final cleaned = raw.replaceAll(RegExp(r'[^0-9.\-\+]'), '');
  return double.tryParse(cleaned) ?? 0.0;
}
```

> **ملاحظة:** نفس المنهجية المستخدمة في `EngineeringInfoEntity.getSmartDiagnosis()` الموجودة حالياً.

---

## ⚠️ حالات الحافة (Edge Cases)

| الحالة | المعالجة |
|---|---|
| قيمة RSRP = 0 أو فارغة | تجاهل القراءة، عرض "جاري البحث..." |
| جميع القيم = N/A | عرض حالة "لا إشارة" مع نصيحة إعادة المحاولة |
| القاءات متذبذبة جداً | نطبق **Smoothing** بمتوسط آخر 3 قراءات |
| SINR سالب (تشويش أعلى من الإشارة) | تطبيعه إلى 0% |
| المودم غير متصل بالشبكة | إيقاف الكاشف + عرض رسالة "اتصل بالشبكة أولاً" |

### تنعيم القراءات (Smoothing):
```dart
double _smoothedScore(List<double> recentScores) {
  if (recentScores.isEmpty) return 0;
  // متوسط مرجح: الأحدث أكثر أهمية
  // weights: [0.2, 0.3, 0.5] (الأقدم، الأوسط، الأحدث)
  if (recentScores.length >= 3) {
    return recentScores[recentScores.length - 3] * 0.2 +
           recentScores[recentScores.length - 2] * 0.3 +
           recentScores.last * 0.5;
  }
  return recentScores.last;
}
```

> هذا يمنع "القفز" المفاجئ في النسبة ويعطي تجربة سلسة كالسائل.
