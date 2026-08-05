# 💎 اقتراحات احترافية — Linkary (Harbi Modem Manager)

> **تاريخ المراجعة:** 2026-03-17  
> **المُراجع:** Antigravity AI Code Auditor  
> **الهدف:** رفع مستوى التطبيق من "مشروع عملي" إلى "منتج احترافي"

---

## 🏗️ هيكلية المشروع المثالية

### 1. إعادة هيكلة مجلد `core/` بالكامل
**التأثير:** يحوّل المشروع من مجموعة ميزات مستقلة إلى تطبيق متماسك.

```
lib/
├── core/
│   ├── di/
│   │   └── injection_container.dart    # نقل الملف هنا
│   ├── errors/
│   │   ├── failures.dart               # ServerFailure, CacheFailure, SessionFailure
│   │   └── exceptions.dart             # ServerException, SessionExpiredException
│   ├── network/
│   │   ├── api_client.dart             # HTTP Client موحد
│   │   ├── session_manager.dart        # إدارة الجلسة
│   │   └── network_info.dart           # فحص الاتصال بالشبكة
│   ├── theme/
│   │   ├── app_theme.dart              # الثيم الكامل (light + dark)
│   │   ├── app_colors.dart             # الألوان المركزية
│   │   └── app_text_styles.dart        # أنماط النصوص
│   ├── utils/
│   │   ├── constants.dart              # الثوابت
│   │   ├── formatters.dart             # formatSpeed, formatDataUsage, etc.
│   │   ├── validators.dart             # التحقق من المدخلات
│   │   └── app_logger.dart             # نظام التسجيل
│   └── widgets/
│       ├── glass_card.dart             # البطاقة الزجاجية المشتركة
│       ├── loading_indicator.dart      # مؤشر التحميل الموحد
│       └── error_widget.dart           # واجهة الخطأ الموحدة
```

---

## 🎨 الهوية البصرية والتصميم

### 2. إنشاء نظام ثيم مركزي (Design System)
**الحالة الحالية:** الألوان مُعرّفة كـ getters في كل صفحة على حدة، وتتكرر في 6+ ملفات.  
**الحل:**

```dart
// lib/core/theme/app_colors.dart
class AppColors {
  // الألوان الأساسية
  static const primaryPurple = Color(0xFF6B48FF);
  static const primaryBlue = Color(0xFF4A90E2);
  static const accentGreen = Color(0xFF50E3C2);

  // ألوان الوضع الداكن
  static const darkBg = Color(0xFF0A0E21);
  static const darkCard = Color(0xFF16213E);

  // ألوان الوضع الفاتح
  static const lightBg = Color(0xFFF5F7FA);
  static const lightCard = Colors.white;
}
```

```dart
// lib/core/theme/app_theme.dart
class AppTheme {
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,
    fontFamily: 'Cairo',
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryBlue,
      secondary: AppColors.accentGreen,
      surface: AppColors.darkCard,
    ),
    // ... كامل تكوينات الثيم
  );
}
```

---

### 3. إضافة الخط العربي Cairo فعلياً
**الحالة الحالية:** `fontFamily: 'Cairo'` مُحدد لكن الخط غير موجود.  
**الحل:**

```yaml
# pubspec.yaml
dependencies:
  google_fonts: ^6.1.0  # أسهل طريقة

# أو تنزيل الخط يدوياً:
flutter:
  fonts:
    - family: Cairo
      fonts:
        - asset: assets/fonts/Cairo-Regular.ttf
        - asset: assets/fonts/Cairo-Bold.ttf
          weight: 700
        - asset: assets/fonts/Cairo-Light.ttf
          weight: 300
```

---

### 4. Widgets مشتركة قابلة لإعادة الاستخدام
**الحالة الحالية:** كل صفحة تُعيد بناء الألوان والبطاقات من الصفر.  
**الحل:** استخراج مكونات مشتركة:

```dart
// lib/core/widgets/glass_card.dart
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  
  const GlassCard({required this.child, this.padding, this.borderRadius = 25});
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [BoxShadow(...)],
      ),
      child: child,
    );
  }
}
```

---

## 📱 تجربة المستخدم (UX)

### 5. شاشة Splash احترافية
**الوصف:** إضافة شاشة تحميل أولية تتحقق من:
- الاتصال بشبكة WiFi المودم
- صلاحية الجلسة المحفوظة (إذا وُجدت)
- التوجيه التلقائي: Dashboard إذا كانت الجلسة صالحة، Login إذا لا

---

### 6. دعم Offline Graceful Degradation
**الوصف:** إضافة فحص اتصال قبل كل طلب مع عرض رسالة واضحة:

```dart
class NetworkInfo {
  static Future<bool> isConnectedToModem() async {
    try {
      final result = await InternetAddress.lookup('mobile.router')
          .timeout(const Duration(seconds: 3));
      return result.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
```

---

### 7. إشعارات ذكية (Smart Notifications)
**الوصف:** إضافة مميزات ذكية مثل:
- تنبيه عند اقتراب نفاد الباقة (90%+)
- تنبيه عند ضعف الإشارة (إشارة أقل من 2/5)
- تنبيه عند اتصال جهاز جديد غير معروف
- تنبيه عند انخفاض البطارية أقل من 20%

---

### 8. صفحة معلومات "حول التطبيق" (About Page)
**الوصف:** إضافة صفحة تعرض:
- إصدار التطبيق والبناء
- موديل المودم المتصل
- رابط لسجل التغييرات
- معلومات المطور والدعم

---

## 🔧 البنية التحتية والعمليات (DevOps)

### 9. إعداد CI/CD أساسي
**الوصف:** إعداد GitHub Actions أو GitLab CI لتشغيل:

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
```

---

### 10. ملف README.md احترافي
**الحالة الحالية:** الملف الحالي بسيط جداً.  
**الحل:** إنشاء README يتضمن:
- لقطات شاشة للتطبيق
- وصف المميزات
- متطلبات التشغيل
- تعليمات البناء
- هيكلية المشروع
- المساهمة والترخيص

---

### 11. إضافة ملف CHANGELOG.md
**الوصف:** توثيق التغييرات في كل إصدار:

```markdown
# سجل التغييرات

## [1.1.0] - 2026-03-17
### مُضاف
- ميزة التحكم الأبوي
- ميزة مرشح MAC

### مُصلح
- إصلاح انهيار شاشة الشبكة عند فقدان الاتصال
```

---

## 🚀 ميزات متقدمة للمستقبل

### 12. دعم أنواع مودمات متعددة
**الوصف:** حالياً التطبيق مُصمم لمودم واحد محدد. يمكن إنشاء طبقة تجريد (Modem Adapter) تدعم أنواع مختلفة:

```dart
abstract class ModemAdapter {
  Future<DashboardEntity> getDashboardData();
  Future<void> login(String password);
  // ...
}

class HuaweiModemAdapter implements ModemAdapter { ... }
class ZTEModemAdapter implements ModemAdapter { ... }
```

---

### 13. رسوم بيانية لاستهلاك البيانات
**الوصف:** استخدام حزمة `fl_chart` لعرض:
- رسم بياني لاستهلاك البيانات عبر الزمن
- مقارنة سرعة التنزيل والرفع
- إحصائيات استهلاك كل جهاز

---

### 14. التوطين (Localization / i18n)
**الحالة الحالية:** النصوص مكتوبة مباشرة في الكود بالعربية.  
**الحل:** استخدام نظام التوطين الرسمي لـ Flutter لدعم لغات متعددة (عربي، إنجليزي):

```yaml
# pubspec.yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: any
```

---

### 15. دعم خاصية العرض على الأجهزة اللوحية (Tablet Layout)
**الوصف:** استخدام `LayoutBuilder` و `MediaQuery` لتقديم تجربة محسّنة على الأجهزة اللوحية بعرض أكبر من 600dp.

---

## ملخص الاقتراحات

| المجال | عدد الاقتراحات | الأهم |
|--------|----------------|-------|
| 🏗️ الهيكلية | 1 | إعادة هيكلة `core/` |
| 🎨 التصميم | 3 | Design System، خط Cairo، Widgets مشتركة |
| 📱 تجربة المستخدم | 4 | Splash، Offline، Notifications، About |
| 🔧 DevOps | 3 | CI/CD، README، CHANGELOG |
| 🚀 ميزات متقدمة | 4 | Multi-modem، Charts، i18n، Tablet |
