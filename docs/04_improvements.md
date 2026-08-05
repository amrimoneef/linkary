# ⚡ تقرير التحسينات المقترحة — Linkary (Harbi Modem Manager)

> **تاريخ المراجعة:** 2026-03-17  
> **المُراجع:** Antigravity AI Code Auditor

---

## التحسينات المعمارية (Architecture)

### 1. إنشاء `ApiClient` مركزي
**الأولوية:** 🔴 عالية  
**الوصف:** جميع Data Sources تُنشئ headers وتتحقق من الجلسة وتبني URLs بشكل مُكرر. يجب إنشاء كلاس مركزي يتولى:
- إدارة `baseUrl` من مكان واحد
- إرفاق `Cookie` تلقائياً
- التحقق من `SESSION_EXPIRED` في كل استجابة
- إضافة timeout للطلبات
- معالجة أخطاء HTTP بشكل موحد

```dart
// lib/core/network/api_client.dart
class ApiClient {
  final http.Client _client;
  final SessionManager _sessionManager;
  static const String baseUrl = 'http://mobile.router';

  Future<Map<String, dynamic>> get(String path, Map<String, String> params) async {
    final sessionId = _sessionManager.currentSessionId;
    if (sessionId == null) throw SessionExpiredException();
    
    final response = await _client.get(
      Uri.parse('$baseUrl/api.cgi?$path'),
      headers: _buildHeaders(sessionId),
    ).timeout(const Duration(seconds: 15));
    
    return _handleResponse(response);
  }
}
```

---

### 2. تطبيق نمط `Either<Failure, Success>` باستخدام `dartz`
**الأولوية:** 🔴 عالية  
**الوصف:** بدلاً من `try/catch` في كل مكان، استخدام `Either` يجعل التعامل مع الأخطاء:
- **صريحاً:** المترجم يُجبرك على التعامل مع حالتي النجاح والفشل
- **نظيفاً:** لا حاجة لـ `replaceAll('Exception:', '')` المُكرر في Controllers
- **قابلاً للاختبار:** يسهل كتابة اختبارات للحالتين

```dart
// قبل (الوضع الحالي):
Future<DashboardEntity> execute() async {
  return await repository.getDashboardData(); // قد يرمي Exception
}

// بعد (الوضع المطلوب):
Future<Either<Failure, DashboardEntity>> execute() async {
  return await repository.getDashboardData(); // يُرجع Left(failure) أو Right(data)
}
```

---

### 3. إنشاء `SessionManager` منفصل
**الأولوية:** 🔴 عالية  
**الوصف:** بدلاً من `Get.find<AuthController>()` في طبقة Infrastructure (انتهاك Clean Architecture)، يجب إنشاء `SessionManager` في `core/network/`:

```dart
class SessionManager {
  String? _sessionId;
  
  String? get currentSessionId => _sessionId;
  
  void setSession(String sessionId) {
    _sessionId = sessionId;
    // حفظ مشفّر في flutter_secure_storage
  }
  
  void clearSession() => _sessionId = null;
}
```

---

## التحسينات الوظيفية (Features)

### 4. إضافة آلية إعادة المحاولة التلقائية (Auto Retry)
**الأولوية:** 🟠 متوسطة  
**الوصف:** عند فشل الاتصال بالمودم (timeout أو خطأ شبكة)، يجب على التطبيق محاولة إعادة الاتصال تلقائياً (2-3 محاولات) قبل عرض رسالة الخطأ. يمكن استخدام حزمة `retry` أو تنفيذ آلية بسيطة يدوياً.

---

### 5. إضافة حفظ إعدادات الثيم (Dark/Light Mode Persistence)
**الأولوية:** 🟠 متوسطة  
**الوصف:** حالياً عند تبديل الوضع الليلي/النهاري وإغلاق التطبيق، يعود للوضع الافتراضي. يجب حفظ تفضيل المستخدم عبر `shared_preferences` أو `GetStorage`.

---

### 6. إضافة تأكيد قبل العمليات الحساسة
**الأولوية:** 🟠 متوسطة  
**الوصف:** يُنفذ جيداً عند إيقاف WiFi (يظهر حوار تأكيد)، لكنه مفقود عند:
- حفظ إعدادات WiFi (قد تنقطع الشبكة)
- حفظ إعدادات حد السرعة
- حفظ إعدادات MAC Filter
- تغيير كلمة مرور المودم

---

### 7. تنفيذ ميزة "إعادة تشغيل المودم"
**الأولوية:** 🟡 منخفضة  
**الوصف:** الزر موجود حالياً لكنه يعرض `Get.snackbar('تحذير', 'قيد البرمجة!')` فقط. يجب تنفيذ الميزة مع حوار تأكيد وعداد تنازلي.

---

## تحسينات الأداء (Performance)

### 8. تحسين Polling في Dashboard
**الأولوية:** 🟠 متوسطة  
**الوصف الحالي:** `Timer.periodic` كل 5 ثوانٍ بدون شروط.  
**التحسينات:**
- إيقاف الاستعلام عندما يكون التطبيق في الخلفية (`WidgetsBindingObserver`)
- زيادة الفترة تدريجياً عند فشل الاتصال (Exponential Backoff)
- عدم تحديث الواجهة إذا لم تتغير البيانات

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) _pollingTimer?.cancel();
  if (state == AppLifecycleState.resumed) _startPolling();
}
```

---

### 9. استخدام `const` Widgets حيثما أمكن
**الأولوية:** 🟡 منخفضة  
**الوصف:** كثير من الـ Widgets يمكن أن تكون `const` لتحسين الأداء (تتجنب إعادة البناء). مثلاً `SizedBox`, `EdgeInsets`, `TextStyle` الثابتة. Flutter يقوم بتحسين `const` widgets تلقائياً.

---

## تحسينات جودة الكود (Code Quality)

### 10. إزالة عبارات `print()` واستبدالها بنظام Logger
**الأولوية:** 🔴 عالية  
**الوصف:** يوجد أكثر من 10 عبارات `print()` في الكود. يجب استخدام حزمة `logger` مع مستويات مختلفة:

```dart
// lib/core/utils/app_logger.dart
import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message) {
    if (kDebugMode) debugPrint('🔍 $message');
  }
  static void error(String message) {
    if (kDebugMode) debugPrint('❌ $message');
  }
}
```

---

### 11. إضافة اختبارات وحدة (Unit Tests)
**الأولوية:** 🔴 عالية  
**الوصف:** التطبيق لا يحتوي إلا على ملف اختبار واحد (`widget_test.dart`) وهو الملف الافتراضي. يجب إضافة:
- اختبارات لكل UseCase
- اختبارات لـ Models (fromJson/toJson)
- اختبارات للـ Controllers مع Mocking
- اختبارات تكامل للـ Data Sources

**التغطية المستهدفة:** 70%+ للطبقة الـ Domain على الأقل.

---

### 12. تفعيل Lint Rules أكثر صرامة
**الأولوية:** 🟠 متوسطة  
**الوصف:** ملف `analysis_options.yaml` يستخدم الحد الأدنى من القواعد. يُفضل التحويل إلى `flutter_lints` الأحدث أو `very_good_analysis` مع تفعيل:

```yaml
linter:
  rules:
    avoid_print: true
    prefer_const_constructors: true
    prefer_const_declarations: true
    always_use_package_imports: true
    avoid_dynamic_calls: true
```

---

## ملخص التحسينات

| الأولوية | العدد | المجال |
|----------|-------|--------|
| 🔴 عالية | 5 | ApiClient مركزي، Either pattern، SessionManager، Logger، Tests |
| 🟠 متوسطة | 5 | Auto Retry، Theme Persistence، تأكيد العمليات، Polling، Lint Rules |
| 🟡 منخفضة | 2 | إعادة تشغيل المودم، const Widgets |
