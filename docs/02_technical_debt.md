# 🏗️ تقرير الديون التقنية — Linkary (Harbi Modem Manager)

> **تاريخ المراجعة:** 2026-03-17  
> **المُراجع:** Antigravity AI Code Auditor

---

## 1. مكتبة `dartz` مُعلنة كاعتمادية لكنها غير مُستخدمة
| البند | التفاصيل |
|-------|----------|
| **الملف** | `pubspec.yaml` (سطر 20) |
| **الأولوية** | 🔴 عالية |
| **الوصف** | المكتبة `dartz: ^0.10.1` مُعلنة في الاعتماديات لكنها **لم تُستخدم في أي مكان**. كان المخطط استخدام نمط `Either<Failure, Success>` للتعامل مع الأخطاء (كما هو مذكور في تعليق في `auth_repository_impl.dart` سطر 17)، لكن جميع التطبيقات تستخدم `try/catch` مع `throw Exception` بدلاً من ذلك. |
| **التأثير** | حجم تطبيق أكبر بلا فائدة، وتعامل مع الأخطاء غير موحّد وغير آمن. |
| **الحل** | إما تطبيق نمط `Either` في جميع الطبقات (موصى به بشدة) أو إزالة المكتبة. |

---

## 2. مجلدات `core/` فارغة بالكامل
| البند | التفاصيل |
|-------|----------|
| **المجلدات** | `lib/core/errors/`، `lib/core/network/`، `lib/core/utils/` |
| **الأولوية** | 🔴 عالية |
| **الوصف** | ثلاثة مجلدات أساسية في طبقة `core` فارغة تماماً. في Clean Architecture، هذه المجلدات يُفترض أن تحتوي على: مكونات حيوية مشتركة بين جميع الميزات (Features). |
| **الحل المقترح** | |

```
lib/core/
├── errors/
│   ├── failures.dart          # كلاسات Failure (ServerFailure, CacheFailure, etc.)
│   └── exceptions.dart        # استثناءات مخصصة (ServerException, etc.)
├── network/
│   ├── api_client.dart        # HTTP Client مركزي مع headers و baseUrl و timeout
│   └── session_manager.dart   # إدارة الجلسة (تخزين/قراءة/تنظيف session_id)
└── utils/
    ├── constants.dart         # ثوابت مثل baseUrl والألوان المشتركة
    ├── formatters.dart        # دوال التنسيق (formatSpeed, formatDataUsage, etc.)
    └── validators.dart        # دوال التحقق من المدخلات
```

---

## 3. عنوان `baseUrl` مُكرر يدوياً في 7 ملفات (Code Duplication)
| البند | التفاصيل |
|-------|----------|
| **الملفات** | كل ملفات `*_remote_data_source.dart` |
| **الأولوية** | 🔴 عالية |
| **الوصف** | السطر `final String baseUrl = 'http://mobile.router';` مُكرر في **7 ملفات** مختلفة. إذا تغيّر عنوان المودم، يجب تعديل 7 ملفات يدوياً. |
| **الحل** | إنشاء ملف `core/utils/constants.dart` يحتوي على `ApiConstants.baseUrl` واستخدامه في كل مكان. |

---

## 4. نمط جلب الجلسة مُكرر في كل Data Source (Boilerplate)
| البند | التفاصيل |
|-------|----------|
| **الملفات** | 6 ملفات data source (ما عدا auth) |
| **الأولوية** | 🔴 عالية |
| **الوصف** | الكود التالي مُكرر في كل دالة تقريباً عبر 6 ملفات: |

```dart
final sessionId = Get.find<AuthController>().currentUser?.sessionId;
if (sessionId == null) throw Exception('الجلسة منتهية.');
```

| **المشكلة المعمارية** | طبقة Infrastructure **يجب ألا تعرف** عن طبقة Presentation (`AuthController`). هذا انتهاك صريح لمبادئ Clean Architecture حيث يتدفق الاعتماد في الاتجاه الخطأ. |
| **الحل** | إنشاء `SessionManager` في `core/network/` يُحقن في كل Data Source ويتولى إدارة الجلسة. |

---

## 5. دوال التنسيق مُكررة في ملف واحد بدلاً من مشتركة
| البند | التفاصيل |
|-------|----------|
| **الملف** | `dashboard_controller.dart` (سطر 102-121) |
| **الأولوية** | 🟠 متوسطة |
| **الوصف** | الدوال `formatSpeed()`, `formatDataUsage()`, `formatDuration()` مُعرّفة داخل `DashboardController` رغم أنها تُستخدم من شاشات أخرى (`network_info_page.dart`). يجب فصلها في كلاس مساعد مشترك. |
| **الحل** | نقلها إلى `core/utils/formatters.dart`. |

---

## 6. كلاس `CalibrateDataUsageUseCase` معرّف في ملف Entity
| البند | التفاصيل |
|-------|----------|
| **الملف** | `data_usage_entity.dart` (سطر 15-23) |
| **الأولوية** | 🟠 متوسطة |
| **الوصف** | UseCase معرّف داخل ملف Entity بدلاً من ملفه الخاص. هذا يخلط مسؤوليات طبقة Domain ويجعل الكود أصعب في الصيانة. |
| **الحل** | نقل `CalibrateDataUsageUseCase` إلى ملف منفصل في `data_usage/domain/usecases/`. |

---

## 7. استخدام `import` مُطلق غير متسق (Absolute vs Relative Imports)
| البند | التفاصيل |
|-------|----------|
| **الملفات** | عدة ملفات |
| **الأولوية** | 🟡 منخفضة |
| **الوصف** | بعض الاستيرادات تستخدم `package:linkary/...` وأخرى `../../...`. عدم التوحيد يُصعّب إعادة الهيكلة. |
| **الحل** | اعتماد نمط واحد — يُفضّل `package:linkary/...` دائماً للاتساق. |

---

## 8. استخدام `Get.put()` في الواجهة بدلاً من DI Container
| البند | التفاصيل |
|-------|----------|
| **الملف** | `main_layout_page.dart` (سطر 14) |
| **الأولوية** | 🟡 منخفضة |
| **الوصف** | `MainLayoutController` يُسجّل عبر `Get.put()` في صفحة الواجهة بدلاً من `injection_container.dart`. هذا يكسر نمط DI الموحد المُتبع في باقي التطبيق. |
| **الحل** | نقل تسجيل `MainLayoutController` إلى `injection_container.dart`. |

---

## 9. استيراد غير مُستخدم
| البند | التفاصيل |
|-------|----------|
| **الملف** | `data_usage_entity.dart` → يستورد `data_usage_repository.dart` |
| **الملف** | `dashboard_page.dart` → يستورد `dart:ui` |
| **الملف** | `injection_container.dart` → يستورد `data_usage_entity.dart` |
| **الأولوية** | 🟡 منخفضة |
| **الوصف** | استيرادات غير مُستخدمة أو غير ضرورية. `data_usage_entity.dart` يستورد `repository` لأن الـ UseCase موضوع فيه خطأً (انظر البند 6). |

---

## 10. عدم اتساق استخدام `fenix: true` في DI Container
| البند | التفاصيل |
|-------|----------|
| **الملف** | `injection_container.dart` |
| **الأولوية** | 🟡 منخفضة |
| **الوصف** | بعض التسجيلات تستخدم `fenix: true` (لإعادة الإنشاء بعد التنظيف) وبعضها لا. مثلاً: `AuthRemoteDataSource` و `AuthRepository` و `LoginUseCase` و `GetRetryTimesUseCase` بدون `fenix`، بينما باقي الميزات تستخدمه. هذا قد يسبب أخطاء عند العودة لصفحة تسجيل الدخول. |
| **الحل** | توحيد استراتيجية `fenix` بناءً على دورة حياة كل مكون. |

---

## 11. خط Cairo مُعلن لكنه غير مُعرّف في Assets
| البند | التفاصيل |
|-------|----------|
| **الملف** | `main.dart` (سطر 22) |
| **الأولوية** | 🟠 متوسطة |
| **الوصف** | `fontFamily: 'Cairo'` مُحدد في الثيم لكن لا يوجد إعلان عن الخط في `pubspec.yaml` ولا ملفات خط في مجلد `fonts/`. سيتم استخدام الخط الافتراضي للنظام. |
| **الحل** | إما تنزيل خط Cairo وإضافته في `pubspec.yaml` أو استخدام حزمة `google_fonts`. |

---

## ملخص الديون التقنية

| الأولوية | العدد | الوصف |
|----------|-------|-------|
| 🔴 عالية | 4 | dartz غير مُستخدم، core فارغ، baseUrl مُكرر، انتهاك Clean Architecture |
| 🟠 متوسطة | 3 | دوال مُكررة، UseCase في ملف Entity، خط Cairo مفقود |
| 🟡 منخفضة | 4 | imports غير متسقة، DI غير موحد، استيرادات غير مُستخدمة، fenix غير متسق |
