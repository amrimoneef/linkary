# 🧠 الميزات الذكية الجديدة — Smart Features

## نظرة عامة

هذه الميزات ترفع مراقب التطبيقات من مجرد عارض بيانات إلى **مستشار ذكي** يحلل أنماط الاستخدام ويقدم رؤى قابلة للتنفيذ.

---

## 1. 🔔 نظام التنبيهات الذكية (Smart Alerts)

### أنواع التنبيهات

| النوع | الشرط | المستوى | الرسالة |
|-------|-------|---------|---------|
| استهلاك مفرط | تطبيق > 50% من الإجمالي | ⚠️ تحذير | "واتساب يستهلك 60% من بياناتك" |
| حد يومي | تطبيق > 500 MB / يوم | 🔴 حرج | "يوتيوب تجاوز 500 MB اليوم!" |
| ارتفاع مفاجئ | زيادة > 200% عن المتوسط | ⚠️ تحذير | "تطبيق X يستهلك أكثر من المعتاد بـ 3 أضعاف" |
| تطبيق خلفي | تطبيق نظام > 100 MB | ℹ️ معلومة | "خدمات Google Play استهلكت 150 MB في الخلفية" |
| جلسة طويلة | جلسة > 2 GB | ⚠️ تحذير | "الجلسة الحالية تجاوزت 2 GB" |

### تنفيذ التنبيهات

```dart
// في AppMonitorController
void _checkAlerts() {
  final alerts = _alertsUseCase.execute(
    apps: appsUsage,
    currentFilter: selectedFilter.value,
  );
  
  for (final alert in alerts) {
    // تجنب التكرار: فحص إذا تم عرض هذا التنبيه مسبقاً
    if (!_shownAlerts.contains(alert.uniqueKey)) {
      _shownAlerts.add(alert.uniqueKey);
      
      switch (alert.level) {
        case AlertLevel.critical:
          CustomSnackbar.showError(alert.appName, alert.message);
        case AlertLevel.warning:
          CustomSnackbar.showWarning(alert.appName, alert.message);
        case AlertLevel.info:
          // يعرض كشريط داخل الشاشة بدون snackbar
          break;
      }
    }
  }
}
```

---

## 2. 📂 نظام التصنيف التلقائي (Auto Categorization)

### التصنيفات المتاحة

| التصنيف | الأيقونة | اللون | أمثلة |
|---------|---------|-------|-------|
| شبكات اجتماعية | 💬 | أزرق | WhatsApp, Telegram, Facebook |
| بث الفيديو | 📺 | أحمر | YouTube, Netflix, Shahid |
| ألعاب | 🎮 | ذهبي | PUBG, Clash Royale |
| تصفح الويب | 🌐 | أخضر | Chrome, Firefox, Opera |
| إنتاجية | 📊 | بنفسجي | Gmail, Outlook, Drive |
| VPN | 🔒 | تيل | أي تطبيق VPN |
| نظام | ⚙️ | رمادي | Google Play Services, System UI |
| أخرى | 📦 | رمادي فاتح | غير مصنف |

### عرض التصنيف في الواجهة

```dart
// 1. Donut Chart في الشاشة الرئيسية
CategoryBreakdownChart(
  data: {
    AppCategory.socialMedia: 1500000000,  // 1.5 GB
    AppCategory.streaming: 800000000,     // 800 MB
    AppCategory.gaming: 300000000,        // 300 MB
    AppCategory.system: 200000000,        // 200 MB
  },
)

// 2. شارة التصنيف على كل بطاقة تطبيق
Row(children: [
  CategoryBadge(category: AppCategory.socialMedia),
  Text('واتساب'),
])

// 3. فلترة حسب التصنيف (اختياري - مرحلة متقدمة)
// ChoiceChips إضافية: [الكل] [شبكات] [بث] [ألعاب] [نظام]
```

---

## 3. 📈 تحليل أنماط الاستخدام (Usage Patterns)

### البيانات المُحللة

```dart
class UsageInsights {
  /// أكثر التطبيقات استهلاكاً (Top 3)
  List<AppUsageEntity> topConsumers;
  
  /// إجمالي الاستهلاك حسب الفئة
  Map<AppCategory, int> categoryBreakdown;
  
  /// متوسط الاستهلاك اليومي (آخر 7 أيام)
  int dailyAverage;
  
  /// أعلى يوم استهلاكاً في الأسبوع
  String peakDay;
  int peakDayBytes;
  
  /// اتجاه الاستهلاك (صاعد/ثابت/نازل)
  UsageTrend trend;
  
  /// التطبيقات النشطة حالياً
  List<AppUsageEntity> currentlyActive;
  
  /// عدد التطبيقات التي استخدمت البيانات اليوم
  int activeAppsToday;
}

enum UsageTrend { increasing, stable, decreasing }
```

### عرض الرؤى

```dart
// كارت "رؤى ذكية" في أعلى الشاشة (أحياناً)
Widget _buildInsightCard(UsageInsights insights) {
  return AnimatedSwitcher(
    duration: Duration(milliseconds: 500),
    child: Card(
      child: Column(children: [
        Icon(Iconsax.lamp_on),
        Text('💡 رؤية ذكية'),
        Text(_getInsightMessage(insights)),
      ]),
    ),
  );
}

String _getInsightMessage(UsageInsights insights) {
  if (insights.trend == UsageTrend.increasing) {
    return 'استهلاكك يتزايد بنسبة ${insights.increasePercent}% هذا الأسبوع مقارنة بالسابق';
  }
  if (insights.topConsumers.first.totalBytes > insights.dailyAverage * 0.5) {
    return '${insights.topConsumers.first.appName} يستهلك أكثر من نصف بياناتك اليومية';
  }
  return '${insights.activeAppsToday} تطبيق استخدم البيانات اليوم';
}
```

---

## 4. 🔍 بحث وفلترة متقدمة

### شريط البحث

```dart
class SearchBarWidget extends StatelessWidget {
  // تصميم زجاجي (Glassmorphism)
  // - placeholder: "ابحث في التطبيقات..."
  // - أيقونة بحث مع تأثير focus
  // - زر مسح (clear) عند الكتابة
  // - نتائج فورية (مباشرة أثناء الكتابة)
}
```

### فلترة حسب التصنيف (اختياري)

```dart
// إضافة row ثاني من ChoiceChips تحت الفلاتر الزمنية
// [الكل] [📱 شبكات] [📺 بث] [🎮 ألعاب] [⚙️ نظام]
// يعمل كفلتر ثانوي مع الفلتر الزمني
```

### ترتيب القائمة

```dart
enum SortOption {
  byConsumption,    // الافتراضي: الأكثر استهلاكاً
  byName,           // أبجدي
  byCategory,       // حسب التصنيف
  bySpeed,          // الأنشط حالياً
}
```

---

## 5. 🔄 نظام إعادة التعيين (Reset Controls)

### إعادة تعيين الجلسة

```dart
// زر "إعادة تعيين الجلسة" في القائمة أو الترويسة
void resetSession() {
  // يأخذ snapshot جديد كـ baseline
  // يُصفّر كل العدادات
  // مفيد عند: بدء استخدام جديد أو بعد إعادة الشحن
}
```

### مسح البيانات التاريخية

```dart
// في الإعدادات أو عبر زر في الشاشة
void clearHistory() {
  // يحذف بيانات أقدم من فترة محددة
  // يعرض dialog تأكيد
}
```

---

## 6. 📊 تقارير قابلة للمشاركة (اختياري - مرحلة متقدمة)

### تقرير نصي بسيط

```dart
String generateTextReport() {
  return '''
📊 تقرير استهلاك البيانات - ${DateFormat('yyyy-MM-dd').format(DateTime.now())}
━━━━━━━━━━━━━━━━━━━━━━━━
📥 إجمالي التحميل: ${formatBytes(rxBytes)}
📤 إجمالي الرفع: ${formatBytes(txBytes)}
📦 الإجمالي: ${formatBytes(totalUsage)}

🏆 أكثر التطبيقات استهلاكاً:
${topApps.map((a) => '  • ${a.appName}: ${formatBytes(a.totalBytes)}').join('\n')}

🔗 بواسطة تطبيق Linkary
  ''';
}

// يمكن مشاركته عبر Share.share()
```

---

## 7. 🛡️ كشف التطبيقات المشبوهة (Security Insights)

### ما يمكن كشفه

```dart
// 1. تطبيقات ترفع بيانات أكثر مما تحمل (نسبة tx/rx > 2)
//    → تنبيه: "تطبيق X يرسل بيانات أكثر من استقباله"

// 2. تطبيقات نظام باستهلاك غير طبيعي (> 100 MB/يوم)
//    → تنبيه: "خدمة نظام تستهلك كمية غير معتادة"

// 3. تطبيقات مجهولة (بدون أيقونة أو اسم واضح)
//    → تمييز بعلامة ⚠️
```

> **ملاحظة**: هذه ميزة تحليلية فقط - لا يمكن حظر التطبيقات عبر Linkary لأن ذلك يتطلب VPN أو Root.

---

## 📊 ملخص الميزات الذكية حسب الأولوية

| الميزة | الأولوية | الجهد | التأثير التنافسي |
|--------|----------|-------|------------------|
| تنبيهات الاستهلاك | ⭐⭐⭐ | ⭐⭐ | 🟢 عالي |
| تصنيف التطبيقات | ⭐⭐⭐ | ⭐⭐ | 🟢 عالي |
| بحث وفلترة | ⭐⭐⭐ | ⭐ | 🟢 عالي |
| إعادة تعيين الجلسة | ⭐⭐ | ⭐ | 🟡 متوسط |
| تحليل الأنماط | ⭐⭐ | ⭐⭐⭐ | 🟢 عالي |
| كشف المشبوهات | ⭐ | ⭐⭐ | 🟡 متوسط |
| تقارير مشاركة | ⭐ | ⭐⭐ | 🟡 متوسط |
