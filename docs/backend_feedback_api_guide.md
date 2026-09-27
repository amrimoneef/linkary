# 📘 دليل توثيق API صندوق الاقتراحات والملاحظات (Backend Developer Guide)
**مشروع:** تطبيق SAM4G / Linkary Mobile  
**الإصدار المستهدف:** 1.0.3+  
**تاريخ التوثيق:** سبتمبر 2026  
**المسار النهائي (Endpoint):** `POST https://www.sam4g.com/api/feedback/app-settings`

---

## 📌 1. نظرة عامة (Overview)
يوفر هذا الـ API نقطة استقبال مركزية للاقتراحات، الملاحظات، والإبلاغ عن المشاكل التقنية الواردة من مستخدمي تطبيق **Sam4G**.
* يستقبل الطلبات بصيغة `multipart/form-data` لدعم رفع صورة توضيحية اختيارية (Screenshot).
* يدعم استلام البيانات التشخيصية للهاتف والمودم عند موافقة المستخدم لتسريع حل المشاكل.
* يحتوي على توقيع أمني ديناميكي (HMAC-SHA256) لمنع السبام والهجمات العشوائية.

---

## 🌐 2. مواصفات نقطة النهاية (Endpoint Specifications)

| الخاصية | القيمة |
| :--- | :--- |
| **الرابط (URL)** | `https://www.sam4g.com/api/feedback/app-settings` |
| **طريقة الإرسال (Method)** | `POST` |
| **نوع المحتوى (Content-Type)** | `multipart/form-data` |
| **حد معدل الطلبات (Rate Limiting)** | يُنصح بحد أقصى: **5 طلبات / دقيقة** لكل IP أو Nonce لمنع الإغراق. |
| **أقصى حجم للمرفق (Max File Size)** | **5 ميجابايت (5MB)** |
| **أنواع المرفقات المسموحة** | `image/jpeg`, `image/png`, `image/webp` |

---

## 🔐 3. ترويسات الحماية والتحقق (Security Headers & Verification)

يقوم التطبيق بإرسال الترويسات التالية مع كل طلب:

| اسم الترويسة (Header) | الوصف | مثال |
| :--- | :--- | :--- |
| `User-Agent` | اسم التطبيق وإصداره | `Settings-App/1.0.3` |
| `X-App-Package` | اسم حزمة التطبيق الرسمية | `com.sam4g.app_settings` |
| `X-Timestamp` | الطابع الزمني بالثواني (Unix Timestamp) | `1727463000` |
| `X-Request-Nonce` | معرف فريد لكل طلب لمنع هجمات التكرار (Replay Attacks) | `1727463000123_uuid` |
| `X-App-Signature` | توقيع HMAC-SHA256 للتحقق من مصدر الطلب | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` |
| `Accept` | صيغة الرد المطلوبة | `application/json` |

### 🛡️ آلية التحقق من التوقيع في السيرفر (HMAC Verification)
1. **المفتاح السري المشترك (Salt/Secret Key):**
   ```text
   linkary_mobile_feedback_secure_salt_2026
   ```
2. **سلسلة التحقق (Signature Payload):**
   تتكون السلسلة الموقعة من:
   `"$timestamp:$nonce:$path"`
   حيث `$path` هو: `/api/feedback/app-settings`
3. **خوارزمية التشفير:** HMAC بـ `SHA-256`.
4. **فحص الصلاحية الزمنية:** يُرفض الطلب إذا كان الفرق الزمني بين `$timestamp` ووقت السيرفر أكبر من 5 دقائق (300 ثانية).

#### كود التحقق في PHP (Laravel Example):
```php
public function verifySignature(Request $request): bool
{
    $timestamp = $request->header('X-Timestamp');
    $nonce = $request->header('X-Request-Nonce');
    $signature = $request->header('X-App-Signature');
    $package = $request->header('X-App-Package');

    if (!$timestamp || !$nonce || !$signature || $package !== 'com.sam4g.app_settings') {
        return false;
    }

    // رفض الطلبات التي مر عليها أكثر من 5 دقائق
    if (abs(time() - (int)$timestamp) > 300) {
        return false;
    }

    $secret = 'linkary_mobile_feedback_secure_salt_2026';
    $payload = "{$timestamp}:{$nonce}:/api/feedback/app-settings";
    $expectedSignature = hash_hmac('sha256', $payload, $secret);

    return hash_equals($expectedSignature, $signature);
}
```

---

## 📥 4. الحقول المُرسلة (Payload Form Fields)

### الحقول الأساسية:
| الحقل | النوع | إلزامي؟ | الوصف والقيود |
| :--- | :--- | :--- | :--- |
| `category` | String | **نعم** | تصنيف الرسالة. القيم المعتمدة: <br>• `feature_suggestion` (اقتراح ميزة جديدة)<br>• `technical_issue` (مشكلة تقنية أو عطل)<br>• `general_inquiry` (ملاحظة أو استفسار عام) |
| `title` | String | **نعم** | عنوان الاقتراح أو المشكلة (الحد الأقصى: 80 حرفاً). |
| `description` | String | **نعم** | شرح تفصيلي للاقتراح أو المشكلة (الحد الأقصى: 800 حرف). |
| `contact_info` | String | لا | وسيلة تواصل (رقم هاتف للتواصل أو بريد إلكتروني). الحد الأقصى: 100 حرف. |
| `include_diagnostics`| String (Boolean) | **نعم** | `"true"` أو `"false"` لتحديد هل تم إرفاق تشخيص الجهاز. |

### حقول البيانات التشخيصية (تُرسل عند `include_diagnostics == "true"`):
| الحقل | النوع | مثال |
| :--- | :--- | :--- |
| `app_version` | String | `1.0.3+4` |
| `device_model` | String | `Samsung Galaxy S24 Ultra` أو `iPhone 15 Pro` |
| `os_version` | String | `Android 14` أو `iOS 17.5` |
| `modem_model` | String | `Sam4g M56` أو `Sam4g M50` |
| `modem_firmware`| String | `Band: 28 (PCI: 142)` |
| `network_type` | String | `LTE (Yemen Mobile)` |
| `battery_level` | String | `82%` |
| `signal_strength`| String | `4 / 5 (-85 dBm)` |

### الملف المرفق (Attachment):
| اسم الحقل | النوع | إلزامي؟ | الوصف |
| :--- | :--- | :--- | :--- |
| `attachment` | File (Binary) | لا | لقطة شاشة توضيحية بصيغة (JPG/PNG/WEBP)، بحد أقصى 5MB. |

---

## 📤 5. استجابات الخادم (Server Responses)

### ✅ حالة النجاح (200 OK أو 201 Created):
```json
{
  "status": "success",
  "message": "تم استلام اقتراحك بنجاح، شكراً لمشاركتك القيّمة!",
  "data": {
    "feedback_id": "FB-2026-9812",
    "created_at": "2026-09-27T21:55:00Z"
  }
}
```

### ❌ حالة فشل التوقيع الأمني أو الصلاحية (401 Unauthorized):
```json
{
  "status": "error",
  "message": "فشل التحقق الأمني من التوقيع الرقمي للطلب."
}
```

### ❌ حالة وجود أخطاء في المدخلات (422 Unprocessable Entity):
```json
{
  "status": "error",
  "message": "يرجى التأكد من صحة البيانات المدخلة.",
  "errors": {
    "title": ["عنوان الاقتراح مطلوب ويجب ألا يتجاوز 80 حرفاً."],
    "description": ["الوصف مطلوب ويجب ألا يقل عن 10 أحرف."],
    "attachment": ["حجم الصورة يتجاوز الحد المسموح به (5 ميجابايت)."]
  }
}
```

### ❌ تجاوز معدل الطلبات (429 Too Many Requests):
```json
{
  "status": "error",
  "message": "تم إرسال عدد كبير من الطلبات، يرجى الانتظار قليلاً والمحاولة لاحقاً."
}
```

---

## 🗄️ 6. تصميم جدول قاعدة البيانات (Database Schema)

### كود إنشاء الجدول في MySQL / PostgreSQL:
```sql
CREATE TABLE app_feedbacks (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reference_code VARCHAR(32) NOT NULL UNIQUE,
    category ENUM('feature_suggestion', 'technical_issue', 'general_inquiry') NOT NULL,
    title VARCHAR(120) NOT NULL,
    description TEXT NOT NULL,
    contact_info VARCHAR(100) NULL,
    attachment_url VARCHAR(255) NULL,
    
    -- بيانات التشخيص
    has_diagnostics BOOLEAN DEFAULT FALSE,
    app_version VARCHAR(30) NULL,
    device_model VARCHAR(100) NULL,
    os_version VARCHAR(50) NULL,
    modem_model VARCHAR(50) NULL,
    modem_firmware VARCHAR(80) NULL,
    network_type VARCHAR(60) NULL,
    battery_level VARCHAR(20) NULL,
    signal_strength VARCHAR(50) NULL,
    
    -- بيانات إدارية
    client_ip VARCHAR(45) NULL,
    user_agent VARCHAR(150) NULL,
    status ENUM('pending', 'in_review', 'resolved', 'closed') DEFAULT 'pending',
    admin_notes TEXT NULL,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    
    INDEX idx_category (category),
    INDEX idx_status (status),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

## 💻 7. كود جاهز لمتحكم السيرفر (Laravel Controller Implementation)

```php
<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use App\Models\AppFeedback;

class FeedbackController extends Controller
{
    private const HMAC_SALT = 'linkary_mobile_feedback_secure_salt_2026';

    public function store(Request $request)
    {
        // 1. التحقق من التوقيع الأمني HMAC
        if (!$this->isValidSignature($request)) {
            return response()->json([
                'status' => 'error',
                'message' => 'غير مصرح: فشل التحقق الأمني من مصدر الطلب.'
            ], 401);
        }

        // 2. التحقق من صحة المدخلات
        $validated = $request->validate([
            'category' => 'required|in:feature_suggestion,technical_issue,general_inquiry',
            'title' => 'required|string|max:80',
            'description' => 'required|string|max:800',
            'contact_info' => 'nullable|string|max:100',
            'include_diagnostics' => 'required|string',
            'attachment' => 'nullable|image|mimes:jpeg,png,jpg,webp|max:5120', // 5MB
            
            // حقول التشخيص الاختيارية
            'app_version' => 'nullable|string|max:30',
            'device_model' => 'nullable|string|max:100',
            'os_version' => 'nullable|string|max:50',
            'modem_model' => 'nullable|string|max:50',
            'modem_firmware' => 'nullable|string|max:80',
            'network_type' => 'nullable|string|max:60',
            'battery_level' => 'nullable|string|max:20',
            'signal_strength' => 'nullable|string|max:50',
        ]);

        // 3. تخزين المرفق بأمان إن وجد
        $attachmentUrl = null;
        if ($request->hasFile('attachment') && $request->file('attachment')->isValid()) {
            $path = $request->file('attachment')->store('feedbacks/attachments', 'public');
            $attachmentUrl = Storage::url($path);
        }

        // 4. حفظ البيانات في القاعدة
        $feedback = AppFeedback::create([
            'reference_code' => 'FB-' . strtoupper(Str::random(8)),
            'category' => $validated['category'],
            'title' => $validated['title'],
            'description' => $validated['description'],
            'contact_info' => $validated['contact_info'] ?? null,
            'attachment_url' => $attachmentUrl,
            'has_diagnostics' => filter_var($validated['include_diagnostics'], FILTER_VALIDATE_BOOLEAN),
            'app_version' => $validated['app_version'] ?? null,
            'device_model' => $validated['device_model'] ?? null,
            'os_version' => $validated['os_version'] ?? null,
            'modem_model' => $validated['modem_model'] ?? null,
            'modem_firmware' => $validated['modem_firmware'] ?? null,
            'network_type' => $validated['network_type'] ?? null,
            'battery_level' => $validated['battery_level'] ?? null,
            'signal_strength' => $validated['signal_strength'] ?? null,
            'client_ip' => $request->ip(),
            'user_agent' => $request->userAgent(),
            'status' => 'pending',
        ]);

        // 5. الرد بنجاح
        return response()->json([
            'status' => 'success',
            'message' => 'تم استلام اقتراحك بنجاح، شكراً لمشاركتك!',
            'data' => [
                'feedback_id' => $feedback->reference_code,
                'created_at' => $feedback->created_at->toIso8601String(),
            ]
        ], 201);
    }

    private function isValidSignature(Request $request): bool
    {
        $timestamp = $request->header('X-Timestamp');
        $nonce = $request->header('X-Request-Nonce');
        $signature = $request->header('X-App-Signature');
        $package = $request->header('X-App-Package');

        if (!$timestamp || !$nonce || !$signature || $package !== 'com.sam4g.app_settings') {
            return false;
        }

        // رفض الطلبات الأقدم من 5 دقائق (Replay Attack Prevention)
        if (abs(time() - (int)$timestamp) > 300) {
            return false;
        }

        $payload = "{$timestamp}:{$nonce}:/api/feedback/app-settings";
        $computed = hash_hmac('sha256', $payload, self::HMAC_SALT);

        return hash_equals($computed, $signature);
    }
}
```

---

## 🧪 8. تجربة الطلب عبر cURL (Testing with cURL)

```bash
# حساب التوقيع (مثال في Linux bash):
TIMESTAMP=$(date +%s)
NONCE="${TIMESTAMP}_test123"
SECRET="linkary_mobile_feedback_secure_salt_2026"
PAYLOAD="${TIMESTAMP}:${NONCE}:/api/feedback/app-settings"
SIG=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" | sed 's/^.* //')

# إرسال طلب تجريبي:
curl -X POST https://www.sam4g.com/api/feedback/app-settings \
  -H "User-Agent: Settings-App/1.0.3" \
  -H "X-Timestamp: $TIMESTAMP" \
  -H "X-Request-Nonce: $NONCE" \
  -H "X-App-Signature: $SIG" \
  -H "X-App-Package: com.sam4g.app_settings" \
  -H "Accept: application/json" \
  -F "category=feature_suggestion" \
  -F "title=إضافة ويدجت الشاشة الرئيسية" \
  -F "description=نرجو إضافة ويدجت مصغر يعرض الرصيد المتبقي ونسبة البطارية مباشرة." \
  -F "contact_info=770000000" \
  -F "include_diagnostics=true" \
  -F "app_version=1.0.3+4" \
  -F "device_model=Samsung Galaxy S24 Ultra" \
  -F "os_version=Android 14" \
  -F "modem_model=Sam4g M56" \
  -F "network_type=4G (Yemen Mobile)" \
  -F "battery_level=85%" \
  -F "signal_strength=4 / 5 (-82 dBm)"
```
