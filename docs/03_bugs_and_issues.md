# 🐛 تقرير الأخطاء والمشاكل — Linkary (Harbi Modem Manager)

> **تاريخ المراجعة:** 2026-03-17  
> **المُراجع:** Antigravity AI Code Auditor

---

## 1. 🔴 انهيار التطبيق عند فتح شاشة "الشبكة" بدون بيانات
| البند | التفاصيل |
|-------|----------|
| **الملف** | `network_info_page.dart` (سطر 98) |
| **الخطورة** | 🔴 حرجة — يُسبب انهيار التطبيق |
| **الوصف** | في دالة `_buildHeader()` يوجد `data!.networkName` مع استخدام عامل `!` (force unwrap). إذا كان `dashboardData.value` يساوي `null` (مثلاً قبل اكتمال التحميل أو عند حدوث خطأ)، سينهار التطبيق فوراً بخطأ `Null check operator used on a null value`. |
| **الحل** | استخدام `data?.networkName ?? 'غير متوفر'` والتحقق من null قبل بناء الواجهة بالكامل. |

---

## 2. 🔴 `http.Client` بدون `fenix: true` يُسبب أخطاء بعد تسجيل الخروج
| البند | التفاصيل |
|-------|----------|
| **الملف** | `injection_container.dart` (سطر 58) |
| **الخطورة** | 🔴 حرجة |
| **الوصف** | `Get.lazyPut(() => http.Client())` مُسجل بدون `fenix: true`. عند انتهاء الجلسة وتوجيه المستخدم لشاشة تسجيل الدخول عبر `Get.offAll()` ثم تسجيل الدخول مجدداً، لن يتم إعادة إنشاء الـ Client وستحدث أخطاء. نفس المشكلة تنطبق على `AuthRemoteDataSource` و `AuthRepository` و `LoginUseCase`. |
| **الحل** | إضافة `fenix: true` لجميع التسجيلات أو استخدام `Get.put` بدلاً من `Get.lazyPut` للمكونات الأساسية. |

---

## 3. 🟠 دالة `logout()` غير مُنفذة
| البند | التفاصيل |
|-------|----------|
| **الملف** | `auth_repository_impl.dart` (سطر 27-30) |
| **الخطورة** | 🟠 متوسطة |
| **الوصف** | دالة `logout()` فارغة تماماً — لا تمسح الجلسة من المودم ولا تنظف البيانات المحلية. عند إعادة التوجيه لشاشة الدخول (عند انتهاء الجلسة)، تبقى بيانات الجلسة القديمة في الذاكرة. |
| **الحل** | تنفيذ دالة logout: إرسال طلب إغلاق الجلسة للمودم، وتنظيف `currentUser` في `AuthController`. |

---

## 4. 🟠 `TextEditingController` لا يتم تنظيفه (Memory Leak)
| البند | التفاصيل |
|-------|----------|
| **الملفات** | `login_page.dart` (سطر 10)، `wifi_settings_controller.dart` (سطر 22-23)، `speed_limit_controller.dart` (سطر 19-20) |
| **الخطورة** | 🟠 متوسطة |
| **الوصف** | `TextEditingController` يتم إنشاؤه لكن لا يتم استدعاء `dispose()` عليه عند تدمير الكونترولر أو الصفحة. هذا يُسبب تسرب ذاكرة. |
| **الحل** | إضافة `@override void onClose()` في Controllers و `dispose()` في StatelessWidget (أو تحويلها إلى StatefulWidget). |

```dart
@override
void onClose() {
  ssidController.dispose();
  passwordController.dispose();
  super.onClose();
}
```

---

## 5. 🟠 عدم معالجة حالة فشل الاتصال بالمودم بشكل موحد
| البند | التفاصيل |
|-------|----------|
| **الملفات** | جميع Data Sources |
| **الخطورة** | 🟠 متوسطة |
| **الوصف** | بعض Data Sources تتحقق من `statusCode` والبعض لا. بعضها يتحقق من `SESSION_EXPIRED` والبعض لا. التعامل مع أخطاء الشبكة غير موحد. |
| **أمثلة** | |

| الملف | يتحقق من statusCode | يتحقق من SESSION_EXPIRED |
|-------|---------------------|-------------------------|
| `auth_remote_data_source.dart` | ❌ | ❌ |
| `dashboard_remote_data_source.dart` | ❌ | ✅ |
| `connected_devices_remote_data_source.dart` | ✅ | ❌ |
| `settings_remote_data_source.dart` | ✅ | ✅ (فقط في fetch) |
| `speed_limit_remote_data_source.dart` | ❌ | ✅ (فقط في fetch) |

| **الحل** | إنشاء `ApiClient` مركزي في `core/network/` يتضمن جميع فحوصات الأخطاء بشكل موحد. |

---

## 6. 🟠 حالة التدوير الدائري (Circular Progress) ثابتة وليست ديناميكية
| البند | التفاصيل |
|-------|----------|
| **الملف** | `dashboard_page.dart` (سطر 142) |
| **الخطورة** | 🟡 منخفضة (مشكلة وظيفية) |
| **الوصف** | `CircularProgressIndicator(value: 0.7)` تستخدم قيمة ثابتة `0.7` بدلاً من حساب النسبة الفعلية من الاستهلاك. نفس المشكلة للـ `LinearProgressIndicator(value: 0.5)` في بطاقات السرعة. |
| **الحل** | حساب النسبة الفعلية مثلاً: `value: currentUsage / maxPackageData`. |

---

## 7. 🟡 استخدام `withValues(alpha: )` (Deprecated Performance Issue)
| البند | التفاصيل |
|-------|----------|
| **الملفات** | أكثر من **40 موضع** عبر التطبيق |
| **الخطورة** | 🟡 منخفضة |
| **الوصف** | `Color.withValues(alpha: )` يُنشئ كائن `Color` جديداً في كل إطار أثناء إعادة البناء. في Flutter 3.x، يُفضل استخدام `Color.withValues(alpha: 0.3)` لأداء أفضل. |
| **الحل** | استبدال `color.withValues(alpha: 0.3)` بـ `color.withValues(alpha: 0.3)` أو تعريف الألوان كثوابت. |

---

## 8. 🟡 تكرار `@override` في `AllSettingsPage`
| البند | التفاصيل |
|-------|----------|
| **الملف** | `all_settings_page.dart` (سطر 27) |
| **الخطورة** | 🟡 منخفضة |
| **الوصف** | `@override` مكتوبة مرتين قبل دالة `build()`. لن يُسبب خطأ لكنه كود زائد. |
| **الحل** | إزالة `@override` المُكررة. |

---

## 9. 🟡 متغير `var temp` غير ضروري في Polling
| البند | التفاصيل |
|-------|----------|
| **الملف** | `dashboard_controller.dart` (سطر 81-82) |
| **الخطورة** | 🟡 منخفضة |
| **الوصف** | المتغير `var temp` يُنشأ فقط ليُعيّن مباشرةً لـ `dashboardData.value`. لا فائدة منه. |
| **الحل** | `dashboardData.value = result;` مباشرة بدون `temp`. |

---

## 10. 🟡 استخدام `dynamic` كنوع مُعامِل في `_buildDeviceCard`
| البند | التفاصيل |
|-------|----------|
| **الملف** | `connected_devices_page.dart` (سطر 157) |
| **الخطورة** | 🟡 منخفضة |
| **الوصف** | `Widget _buildDeviceCard(dynamic device)` يستخدم `dynamic` بدلاً من `ConnectedDeviceEntity`. هذا يُفقد فوائد type-safety ويجعل الكود عرضة لأخطاء runtime. |
| **الحل** | تغيير النوع إلى `ConnectedDeviceEntity`. |

---

## 11. 🟡 استدعاء `update()` غير ضروري مع `Obx`
| البند | التفاصيل |
|-------|----------|
| **الملف** | `dashboard_controller.dart` (سطر 83) |
| **الخطورة** | 🟡 منخفضة |
| **الوصف** | استدعاء `update()` بعد تحديث `dashboardData.value` غير ضروري لأن `Obx` تستجيب تلقائياً لتغيرات `Rx` المتغيرات. `update()` يُستخدم فقط مع `GetBuilder` وليس مع `Obx`. |
| **الحل** | إزالة `update();`. |

---

## ملخص الأخطاء

| الخطورة | العدد |
|---------|-------|
| 🔴 حرجة | 2 |
| 🟠 متوسطة | 4 |
| 🟡 منخفضة | 5 |
