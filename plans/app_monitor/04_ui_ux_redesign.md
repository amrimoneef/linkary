# 🎨 إعادة تصميم الواجهة — UI/UX Redesign

## الرؤية التصميمية

الهدف: تحويل مراقب التطبيقات من شاشة بسيطة إلى **لوحة تحكم فضائية تفاعلية** تتناسق مع أسلوب تصميم Linkary الحالي (Glassmorphism + Space Theme + Neon Glow).

> **إلهام التصميم**: GlassWire + Fing + لوحة تحكم فضائية بأسلوب Linkary

---

## 📐 تقسيم الشاشة إلى Widgets مستقلة

### الشاشة الرئيسية (AppMonitorScreen)

```
┌─────────────────────────────────────┐
│  🛸 الترويسة المتدرجة (Header)     │ ← gradient header مع إحصائيات سريعة
│  ┌───────────────────────────────┐  │
│  │  📊 مؤشر السرعة اللحظية      │  │ ← LiveSpeedIndicator (جديد)
│  │  ↓ 2.4 MB/s  ↑ 0.3 MB/s     │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌──────┐  ┌──────┐  ┌──────┐      │
│  │Total │  │ تحميل │  │ رفع  │      │ ← UsageSummaryCard
│  │2.4GB │  │1.8 GB│  │0.6 GB│      │
│  └──────┘  └──────┘  └──────┘      │
├─────────────────────────────────────┤
│  [جلسة] [اليوم] [أسبوع] [شهر]     │ ← FilterChipsBar
├─────────────────────────────────────┤
│  ⚠️ غير متصل بالمودم (إن وجد)    │ ← ConnectionStatusBanner
├─────────────────────────────────────┤
│  📈 الرسم البياني التفاعلي        │ ← UsageChartWidget
│  ┌─────────────────────────────┐    │
│  │ ▓▓▒  ▓▓▓▒  ▓▓▒  ▓▓▓▓▒      │    │ ← fl_chart BarChart/AreaChart
│  │ سبت  أحد  إثن  ثلا  ...    │    │
│  └─────────────────────────────┘    │
├─────────────────────────────────────┤
│  🥧 تصنيف الاستهلاك               │ ← CategoryBreakdownChart
│  [دائرة نسبية]                     │
│  شبكات 45% | بث 30% | ألعاب 15%   │
├─────────────────────────────────────┤
│  🔍 [ بحث في التطبيقات... ]       │ ← SearchBarWidget
├─────────────────────────────────────┤
│  📱 قائمة التطبيقات               │ ← AppUsageTile × N
│  ┌─────────────────────────────┐    │
│  │ [icon] واتساب     1.2 GB   │    │
│  │        ████████░░  45%      │    │ ← شريط تقدم + نسبة
│  │        ↓ 0.8 MB/s مباشر    │    │ ← سرعة لحظية (إن وجدت)
│  ├─────────────────────────────┤    │
│  │ [icon] يوتيوب      800 MB  │    │
│  │        ██████░░░░  30%      │    │
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

### شاشة تفاصيل التطبيق (AppDetailScreen - جديدة!)

```
┌─────────────────────────────────────┐
│  ← العودة    تفاصيل التطبيق       │
├─────────────────────────────────────┤
│  ┌──────────────────────────────┐   │
│  │  [أيقونة كبيرة]             │   │
│  │  واتساب                      │   │
│  │  com.whatsapp                │   │
│  │  📂 شبكات اجتماعية          │   │
│  └──────────────────────────────┘   │
├─────────────────────────────────────┤
│  ┌──────┐  ┌──────┐  ┌──────┐      │
│  │Total │  │ تحميل │  │ رفع  │      │
│  │1.2GB │  │0.9 GB│  │0.3 GB│      │
│  └──────┘  └──────┘  └──────┘      │
├─────────────────────────────────────┤
│  📈 رسم بياني (آخر 7 أيام)        │
│  ┌─────────────────────────────┐    │
│  │       📈                     │    │ ← Line Chart تفاعلي
│  │     /    \    /              │    │
│  │   /        \/               │    │
│  │  /                          │    │
│  └─────────────────────────────┘    │
├─────────────────────────────────────┤
│  🕐 نمط الاستخدام                 │
│  أعلى استخدام: 8:00 م - 11:00 م   │
│  متوسط يومي: 180 MB               │
│  أول نشاط اليوم: 09:15 ص          │
└─────────────────────────────────────┘
```

---

## 🎨 نظام الألوان

### استخدام AppColors + Theme.of(context)

```dart
// بدلاً من:
Color get bgColor => Get.isDarkMode ? ... : ...;

// نستخدم:
class AppMonitorScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    // ...
  }
}
```

### الألوان المخصصة للمراقب

```dart
class MonitorColors {
  // ألوان البيانات (ثابتة بين الثيمات)
  static const downloadColor = Color(0xFF00D2FF);   // سماوي نيون
  static const uploadColor = Color(0xFF00FF87);      // أخضر نيون
  static const totalColor = Color(0xFF8E2DE2);       // بنفسجي
  
  // ألوان التصنيفات
  static const socialColor = Color(0xFF6B8DF2);      // أزرق
  static const streamingColor = Color(0xFFFF6B6B);   // أحمر
  static const gamingColor = Color(0xFFFFBB5C);      // ذهبي
  static const browsingColor = Color(0xFF43E97B);    // أخضر
  static const systemColor = Color(0xFF9B9B9B);      // رمادي
  static const vpnColor = Color(0xFF00BCD4);         // تيل
  static const otherColor = Color(0xFFB0BEC5);       // رمادي فاتح
  
  // ألوان التنبيهات
  static const alertWarning = Color(0xFFFFA726);
  static const alertCritical = Color(0xFFEF5350);
}
```

---

## 🧩 تفصيل كل Widget

### 1. LiveSpeedIndicator (مؤشر السرعة اللحظية)

```dart
/// مؤشر يعرض سرعة التحميل والرفع في الوقت الفعلي
/// مع تأثير نبض عند النشاط
class LiveSpeedIndicator extends StatelessWidget {
  final int rxSpeed;  // Bytes/s
  final int txSpeed;  // Bytes/s
  
  // التصميم:
  // ┌──────────────────────────────────┐
  // │  ↓ 2.4 MB/s    ↑ 0.3 MB/s      │
  // │  ════════════  ═══               │ ← خطوط متحركة تمثل النشاط
  // └──────────────────────────────────┘
  
  // - يختفي عند عدم وجود نشاط (AnimatedSize)
  // - يعرض خطوط متحركة (Shimmer effect) أثناء النقل النشط
  // - يتغير لون السرعة حسب القيمة (أخضر → أصفر → أحمر)
}
```

### 2. UsageSummaryCard (كارت الإحصائيات)

```dart
/// كارت زجاجي يعرض الإجمالي + تحميل + رفع
/// مع مؤشر دائري تفاعلي
class UsageSummaryCard extends StatelessWidget {
  final int totalBytes;
  final int rxBytes;
  final int txBytes;
  final double? progressRatio;  // نسبة من الباقة (إن وجدت)
  
  // التصميم:
  // يستبدل CircularProgressIndicator(value: 0.7) الحالي
  // بمؤشر دائري ديناميكي يعرض:
  // - نسبة التحميل/الرفع بلونين مختلفين
  // - تأثير متوهج (glow) حول الحلقة
  // - معلومات متمركزة (الإجمالي + الوحدة)
}
```

### 3. UsageChartWidget (الرسم البياني التفاعلي)

```dart
/// رسم بياني تفاعلي يدعم:
/// - النقر على يوم لرؤية تفاصيله
/// - تبديل بين BarChart و AreaChart
/// - عرض Tooltip بتفاصيل الاستهلاك
/// - تأثيرات حركية عند التحميل
class UsageChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> historyStats;
  final MonitorFilter currentFilter;
  
  // تحسينات على الرسم الحالي:
  // 1. إضافة BarTouchData مع tooltip
  // 2. تأثير gradient على الأعمدة
  // 3. عرض legend (تحميل / رفع) 
  // 4. دعم mode: BarChart أو AreaChart
}
```

### 4. CategoryBreakdownChart (دائرة التصنيفات)

```dart
/// رسم دائري (Pie/Donut Chart) يعرض توزيع الاستهلاك حسب التصنيف
class CategoryBreakdownChart extends StatelessWidget {
  final Map<AppCategory, int> categoryTotals;
  
  // التصميم:
  // ┌─────────────────────────────────┐
  // │    ┌──────┐                     │
  // │    │ 🥧  │  شبكات ██ 45%      │
  // │    │     │  بث    ██ 30%      │
  // │    │     │  ألعاب  █ 15%      │
  // │    └──────┘  نظام  ▪ 10%      │
  // └─────────────────────────────────┘
  //
  // كارت زجاجي مع:
  // - Donut Chart (PieChart في fl_chart)
  // - Legend تفاعلي (النقر على فئة يبرزها)
  // - نص مركزي يعرض عدد التطبيقات النشطة
}
```

### 5. AppUsageTile (بطاقة التطبيق)

```dart
/// بطاقة تطبيق واحد في القائمة
/// تدعم النقر للانتقال إلى التفاصيل
class AppUsageTile extends StatelessWidget {
  final AppUsageEntity app;
  final int maxBytes;  // لحساب عرض شريط التقدم
  final int totalBytes;  // لحساب النسبة المئوية
  final VoidCallback onTap;
  
  // التحسينات:
  // 1. شريط تقدم مزدوج (rx + tx) بألوان مختلفة مع rounded corners
  // 2. نسبة مئوية بجانب الحجم
  // 3. شارة "نشط الآن" (نقطة خضراء متوهجة) إذا rxSpeed > 0 أو txSpeed > 0
  // 4. أيقونة التصنيف بجانب الاسم (🎮 👤 📺 🌐)
  // 5. سرعة لحظية صغيرة أسفل الاسم (عند النشاط)
  // 6. GestureDetector → Hero Animation → AppDetailScreen
  // 7. سلايد بسيط للحذف من القائمة (اختياري)
}
```

### 6. ConnectionStatusBanner (شريط حالة الاتصال)

```dart
/// شريط ذكي يظهر فقط عند عدم الاتصال بالمودم
class ConnectionStatusBanner extends StatelessWidget {
  final bool isConnected;
  
  // التحسينات:
  // 1. AnimatedContainer مع expand/collapse ناعم
  // 2. أيقونة متحركة (WiFi مشطوب)
  // 3. ألوان وأيقونات مختلفة حسب الحالة:
  //    - أحمر: غير متصل
  //    - أصفر: جاري الاتصال
  //    - أخضر: متصل (يختفي تلقائياً بعد 2 ثانية)
}
```

### 7. PermissionGateWidget (شاشة الصلاحية)

```dart
/// شاشة طلب الصلاحية بتصميم احترافي
class PermissionGateWidget extends StatelessWidget {
  final VoidCallback onRequestPermission;
  
  // التحسينات:
  // 1. أيقونة متحركة (Lottie-style بـ CustomPainter)
  // 2. خطوات مصورة (كيف تمنح الصلاحية)
  // 3. زر بتأثير gradient + glow
  // 4. رسالة واضحة عن سبب الحاجة للصلاحية
}
```

---

## 🎭 التأثيرات الحركية (Animations)

### 1. تأثير دخول القائمة (Staggered Entry)
```dart
// كل بطاقة تطبيق تدخل بتأخير بسيط عن السابقة
// مثل: https://docs.flutter.dev/cookbook/effects/staggered-menu-animation
AnimatedBuilder → SlideTransition + FadeTransition
delay: Duration(milliseconds: index * 50)
```

### 2. تأثير التحديث (Refresh Pulse)
```dart
// عند التحديث كل 3 ثوانٍ، نبضة خفيفة على الأرقام المتغيرة
// ScaleTransition(1.0 → 1.05 → 1.0) مدتها 300ms
// تُعطي إحساساً بالحياة والتحديث المستمر
```

### 3. Hero Animation للتفاصيل
```dart
// أيقونة التطبيق تنتقل بسلاسة من القائمة إلى شاشة التفاصيل
Hero(tag: 'app_icon_${app.packageName}', child: appIcon)
```

### 4. شريط السرعة النبضي
```dart
// خط أسفل مؤشر السرعة يتحرك من اليسار لليمين
// يتسارع مع ازدياد السرعة (مستوحى من تكنيك GlassWire)
LinearProgressIndicator مع AnimationController
```

---

## 📐 تصميم الترويسة (Header) الجديد

```dart
/// ترويسة بتدرج لوني مع إحصائيات سريعة
/// مستوحاة من تصميم NetworkInfoPage header
Widget _buildHeader(BuildContext context) {
  return Container(
    padding: EdgeInsets.only(top: 50, bottom: 30, left: 25, right: 25),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: isDark 
          ? [Color(0xFF1A1A3E), Color(0xFF0D0D2B)]
          : [Color(0xFF667EEA), Color(0xFF764BA2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(35),
        bottomRight: Radius.circular(35),
      ),
    ),
    child: Column(
      children: [
        // Row: عنوان + أيقونة تحديث + حالة الاتصال
        // LiveSpeedIndicator
        // UsageSummaryCard (داخل الترويسة)
      ],
    ),
  );
}
```

---

## 🔤 الخطوط والأحجام

| العنصر | الخط | الحجم | الوزن |
|--------|------|-------|-------|
| عنوان الشاشة | System Default | 18sp | Bold |
| عنوان قسم | System Default | 16sp | Bold |
| اسم التطبيق | System Default | 14sp | SemiBold |
| حجم الاستهلاك | Monospace | 13sp | Bold |
| السرعة | Monospace | 12sp | Regular |
| النسبة المئوية | System Default | 11sp | Regular |
| تسمية الفلتر | System Default | 12sp | Medium |

---

## 📱 تصميم شاشة التفاصيل (AppDetailScreen)

### الهيكل المقترح

```dart
class AppDetailScreen extends StatelessWidget {
  final AppUsageEntity app;
  final AppMonitorController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // SliverAppBar مع أيقونة Hero
          SliverAppBar(
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(app.appName),
              background: _buildAppHeader(),
            ),
          ),
          
          // إحصائيات سريعة (تحميل + رفع + إجمالي)
          SliverToBoxAdapter(child: _buildQuickStats()),
          
          // رسم بياني (استهلاك آخر 7 أيام)
          SliverToBoxAdapter(child: _buildDailyChart()),
          
          // تفصيل الجلسة الحالية
          SliverToBoxAdapter(child: _buildSessionBreakdown()),
          
          // نمط الاستخدام
          SliverToBoxAdapter(child: _buildUsagePattern()),
        ],
      ),
    );
  }
}
```

### المعلومات المعروضة في التفاصيل

| المعلومة | المصدر | الأولوية |
|----------|--------|----------|
| اسم التطبيق + أيقونة | Entity | ✅ أساسي |
| اسم الحزمة | Entity | ✅ أساسي |
| التصنيف | CategoryMapper | ✅ أساسي |
| إجمالي اليوم | DailyAppTotals | ✅ أساسي |
| تحميل / رفع منفصل | Entity | ✅ أساسي |
| السرعة اللحظية | Entity | ✅ أساسي |
| رسم بياني 7 أيام | DailyAppTotals × 7 | ⭐ مهم |
| نسبة من الإجمالي | حساب | ⭐ مهم |
| تطبيق نظام؟ | Entity | ⭐ مهم |
| متوسط يومي | حساب | 💡 تحسين |

---

## ♿ إمكانية الوصول (Accessibility)

1. **Semantics Labels**: كل Widget يحمل وصفاً للقارئات الصوتية
2. **Contrast Ratio**: ≥ 4.5:1 لكل نص على خلفيته
3. **Touch Targets**: ≥ 48×48 dp لكل عنصر تفاعلي
4. **RTL Support**: دعم كامل للعربية (Directionality.rtl)

---

## 📊 ملخص التحسينات البصرية

| الجانب | الحالي | المقترح |
|--------|--------|---------|
| الترويسة | AppBar بسيط | Gradient Header مع إحصائيات |
| السرعة | غير معروضة | مؤشر نبضي حي |
| المؤشر الدائري | ثابت 70% | ديناميكي مع rx/tx |
| الرسم البياني | BarChart بدون تفاعل | تفاعلي مع Tooltip |
| التصنيفات | لا يوجد | Donut Chart |
| البحث | لا يوجد UI | شريط بحث زجاجي |
| بطاقة التطبيق | بسيطة | شارة نشاط + تصنيف + سرعة |
| تفاصيل التطبيق | لا يوجد | شاشة كاملة مع رسوم |
| الحركيات | لا يوجد | دخول + نبض + Hero |
| الثيم | `Get.isDarkMode` | `Theme.of(context)` |
