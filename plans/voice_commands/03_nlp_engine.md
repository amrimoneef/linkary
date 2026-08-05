# 🧠 محرك فهم اللغة الطبيعية العربية — Arabic NLP Engine

## 1. نظرة عامة

محرك مخصص يعمل **محلياً بالكامل** بدون إنترنت أو API خارجية.  
يحول النص العربي المنطوق إلى أمر مُهيكل (VoiceIntent) عبر 4 مراحل:

```
النص الخام → التطبيع → التقطيع → التصنيف → حل الأمر
"اكم جهاز متصل" → "كم جهاز متصل" → [كم, جهاز, متصل] → devices.count → execute
```

---

## 2. المرحلة الأولى: تطبيع النص العربي (Arabic Normalizer)

### لماذا؟
الكلام العربي يأتي بأشكال مختلفة: همزات متعددة، تاء مربوطة/مبسوطة، لهجات...  
التطبيع يوحّد كل هذا لتسهيل المطابقة.

### عمليات التطبيع:

```dart
class ArabicNormalizer {
  static String normalize(String text) {
    var result = text.trim().toLowerCase();
    
    // 1. إزالة التشكيل (الفتحة، الضمة، الكسرة...)
    result = result.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    
    // 2. توحيد الألف (أ إ آ → ا)
    result = result.replaceAll(RegExp(r'[أإآ]'), 'ا');
    
    // 3. توحيد الهاء والتاء المربوطة (ة → ه)
    result = result.replaceAll('ة', 'ه');
    
    // 4. توحيد الياء (ى → ي)
    result = result.replaceAll('ى', 'ي');
    
    // 5. إزالة "ال" التعريف للمطابقة المرنة
    result = result.replaceAll(RegExp(r'\bال'), '');
    
    // 6. إزالة الأحرف المكررة الزائدة ("متصلللل" → "متصل")
    result = result.replaceAll(RegExp(r'(.)\1{2,}'), r'$1');
    
    // 7. تنظيف المسافات المتعددة
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return result;
  }
}
```

---

## 3. المرحلة الثانية: التقطيع والاستخلاص (Tokenizer & Entity Extraction)

### 3.1 التقطيع الأساسي
```dart
List<String> tokenize(String normalized) {
  // تقسيم بالمسافات مع إزالة الكلمات الفارغة والشائعة
  final stopWords = {'من', 'في', 'الى', 'عن', 'على', 'هل', 'يا', 'لي', 'هو', 'هي'};
  
  return normalized
    .split(' ')
    .where((w) => w.isNotEmpty && !stopWords.contains(w))
    .toList();
}
```

### 3.2 استخلاص الكيانات (Entity Extraction)

| نوع الكيان | الأمثلة | الطريقة |
|---|---|---|
| **اسم جهاز** | "جهاز أحمد"، "هاتف ماما" | مطابقة مع قائمة الأجهزة المتصلة |
| **وقت** | "من 8 إلى 10"، "بعد الساعة 9"، "الليل" | RegExp + قاموس أوقات |
| **رقم** | "5 كيلو"، "1024" | RegExp للأرقام العربية والهندية |
| **كلمة مرور** | "إلى abc123" | استخلاص ما بعد كلمة "إلى" |

```dart
class EntityExtractor {
  /// استخلاص اسم الجهاز من النص بمطابقته مع الأجهزة المتصلة فعلياً
  static String? extractDeviceName(String text, List<ConnectedDeviceEntity> devices) {
    // 1. مطابقة مباشرة بالاسم المخصص
    for (final device in devices) {
      final name = ArabicNormalizer.normalize(device.name);
      if (text.contains(name) && name.isNotEmpty) {
        return device.mac;
      }
    }
    
    // 2. مطابقة بكلمة بعد "جهاز" أو "هاتف" أو "تلفون"
    final devicePattern = RegExp(r'(?:جهاز|هاتف|تلفون|موبايل|لابتوب|كمبيوتر)\s+(\S+)');
    final match = devicePattern.firstMatch(text);
    if (match != null) {
      final targetName = match.group(1)!;
      for (final device in devices) {
        if (ArabicNormalizer.normalize(device.name).contains(targetName)) {
          return device.mac;
        }
      }
    }
    
    return null; // لم يتم العثور
  }
  
  /// استخلاص الأوقات (ساعات)
  static Map<String, int>? extractTimeRange(String text) {
    // "من 8 إلى 10"
    final rangePattern = RegExp(r'من\s+(\d{1,2})\s+(?:الى|إلى|ل)\s+(\d{1,2})');
    final match = rangePattern.firstMatch(text);
    if (match != null) {
      return {
        'start': int.parse(match.group(1)!) * 60,
        'end': int.parse(match.group(2)!) * 60,
      };
    }
    
    // "بعد الساعة 9 الليل"
    final afterPattern = RegExp(r'بعد\s+(?:الساعه|الساعة)?\s*(\d{1,2})');
    final afterMatch = afterPattern.firstMatch(text);
    if (afterMatch != null) {
      int hour = int.parse(afterMatch.group(1)!);
      if (text.contains('الليل') || text.contains('مساء')) hour += 12;
      return {'start': hour * 60, 'end': 23 * 60 + 59};
    }
    
    return null;
  }
  
  /// استخلاص قيمة رقمية (سرعة، حجم...)
  static int? extractNumber(String text) {
    final pattern = RegExp(r'(\d+)');
    final match = pattern.firstMatch(text);
    if (match != null) return int.parse(match.group(1)!);
    return null;
  }
}
```

---

## 4. المرحلة الثالثة: تصنيف النية (Intent Classification)

### النهج: Keyword Scoring + Pattern Matching

بدلاً من ML أو AI سحابي، نستخدم **سجل أنماط مسبق** مع **نظام نقاط مرجح**.

### 4.1 سجل الأوامر (Command Registry)

```dart
class CommandRegistry {
  static final List<CommandPattern> patterns = [
    
    // ─── الأجهزة المتصلة ─────────────────────────────
    CommandPattern(
      intent: 'query.devices.count',
      category: CommandCategory.devices,
      requiredKeywords: ['جهاز|اجهزه|متصل|متصلين'],
      boostKeywords: ['كم', 'عدد', 'كم عدد'],
      antiKeywords: ['احظر', 'امنع', 'سم'],
      weight: 10,
    ),
    CommandPattern(
      intent: 'query.devices.list',
      category: CommandCategory.devices,
      requiredKeywords: ['اجهزه|متصل|متصلين'],
      boostKeywords: ['اعرض', 'قائمه', 'اذكر', 'من', 'مين'],
      weight: 10,
    ),

    // ─── الأمان ─────────────────────────────────────
    CommandPattern(
      intent: 'action.security.block',
      category: CommandCategory.security,
      requiredKeywords: ['احظر|امنع|بلوك|حجب|اطرد'],
      entityType: EntityType.device,
      requiresConfirmation: true,
      weight: 15,
    ),
    CommandPattern(
      intent: 'action.security.unblock',
      category: CommandCategory.security,
      requiredKeywords: ['ارفع|فك|اسمح|اعد'],
      boostKeywords: ['حظر', 'بلوك', 'منع'],
      entityType: EntityType.device,
      weight: 15,
    ),

    // ─── النظام ─────────────────────────────────────
    CommandPattern(
      intent: 'action.system.reboot',
      category: CommandCategory.system,
      requiredKeywords: ['اعد|ريستارت|ريبوت|اعاده'],
      boostKeywords: ['تشغيل', 'مودم', 'راوتر'],
      requiresConfirmation: true,
      weight: 20, // أمر خطير = وزن عالٍ لمنع التنفيذ الخاطئ
    ),
    
    // ... باقي الأوامر بنفس النمط
  ];
}
```

### 4.2 محرك التصنيف (Intent Classifier)

```dart
class IntentClassifier {
  VoiceIntent? classify(String normalizedText, List<CommandPattern> patterns) {
    List<ScoredIntent> scores = [];

    for (final pattern in patterns) {
      double score = 0;
      bool hasRequired = false;

      // 1. فحص الكلمات المطلوبة (required)
      for (final group in pattern.requiredKeywords) {
        final alternatives = group.split('|');
        if (alternatives.any((kw) => normalizedText.contains(kw))) {
          hasRequired = true;
          score += pattern.weight;
        }
      }

      if (!hasRequired) continue; // لا يمكن أن يكون هذا الأمر

      // 2. إضافة نقاط للكلمات المعززة (boost)
      for (final kw in pattern.boostKeywords) {
        if (normalizedText.contains(kw)) score += 3;
      }

      // 3. خصم نقاط للكلمات المضادة (anti)
      for (final kw in pattern.antiKeywords) {
        if (normalizedText.contains(kw)) score -= 10;
      }

      if (score > 0) {
        scores.add(ScoredIntent(pattern: pattern, score: score));
      }
    }

    if (scores.isEmpty) return null;

    // ترتيب حسب أعلى نقاط
    scores.sort((a, b) => b.score.compareTo(a.score));
    
    // التحقق من وجود تعارض (Ambiguity)
    if (scores.length > 1 && scores[0].score == scores[1].score) {
      // تعارض! — نطلب توضيح من المستخدم
      return VoiceIntent.ambiguous(candidates: scores.take(3).toList());
    }

    return scores.first.toIntent();
  }
}
```

---

## 5. المرحلة الرابعة: حل الأمر (Command Resolver)

يجمع بين النية المصنفة والكيانات المستخلصة:

```dart
class CommandResolver {
  VoiceIntent resolve(String normalizedText, String rawIntent) {
    final devices = Get.find<ConnectedDevicesController>().devices;
    
    switch (rawIntent) {
      case 'action.security.block':
        final mac = EntityExtractor.extractDeviceName(normalizedText, devices);
        if (mac == null) {
          return VoiceIntent.needsMoreInfo(
            message: 'أي جهاز تريد حظره؟ قل اسم الجهاز',
          );
        }
        return VoiceIntent(
          type: VoiceIntentType.action,
          category: CommandCategory.security,
          action: 'block',
          params: {'mac': mac},
          requiresConfirmation: true,
        );
        
      case 'query.devices.count':
        return VoiceIntent(
          type: VoiceIntentType.query,
          category: CommandCategory.devices,
          action: 'count',
          params: {},
        );
        
      // ... باقي الأوامر
    }
  }
}
```

---

## 6. التعامل مع اللهجات العربية

### قاموس مرادفات اللهجات

```dart
class DialectSynonyms {
  static final Map<String, List<String>> synonyms = {
    // الفعل الأساسي : [مرادفات لهجوية]
    'احظر': ['امنع', 'بلوك', 'حجب', 'اطرد', 'ابلك', 'شل'],
    'ارفع': ['فك', 'شل', 'اسمح', 'فتح'],
    'اعد_تشغيل': ['ريستارت', 'ريبوت', 'اعد', 'شغل من جديد', 'سكر وافتح'],
    'شغل': ['فعل', 'حط', 'خلي', 'اشتغل'],
    'عطل': ['اوقف', 'طفي', 'الغي', 'وقف', 'سكر'],
    'كم': ['قد ايش', 'قديش', 'اديش', 'شقد', 'كم عدد'],
    'سرعه': ['نت', 'انترنت', 'نت', 'سبيد'],
    'جهاز': ['هاتف', 'تلفون', 'موبايل', 'لابتوب', 'كمبيوتر', 'تابلت', 'جوال'],
    'واي_فاي': ['شبكه', 'نت', 'وايرلس', 'الراوتر', 'المودم'],
  };

  /// استبدال كل المرادفات بالشكل الأساسي الموحد
  static String unifyDialects(String text) {
    var result = text;
    for (final entry in synonyms.entries) {
      for (final synonym in entry.value) {
        result = result.replaceAll(synonym, entry.key);
      }
    }
    return result;
  }
}
```

---

## 7. معالجة حالات الحافة (Edge Cases)

### 7.1 الأمر غير مفهوم
```dart
if (intent == null) {
  return VoiceResponse(
    success: false,
    spokenText: 'لم أفهم الأمر. حاول مرة أخرى أو قل "مساعدة" لعرض الأوامر المتاحة',
    displayText: 'لم يتم التعرف على الأمر',
  );
}
```

### 7.2 الأمر يحتاج معلومات إضافية
```dart
if (intent.type == VoiceIntentType.needsMoreInfo) {
  // فتح جلسة استماع جديدة للحصول على المعلومة الناقصة
  ttsService.speak(intent.message); // "أي جهاز تريد حظره؟"
  speechService.startListening(); // الاستماع للإجابة
}
```

### 7.3 تعارض بين أوامر
```dart
if (intent.type == VoiceIntentType.ambiguous) {
  ttsService.speak('هل تقصد ${candidate1} أم ${candidate2}؟');
  speechService.startListening(); // الاستماع للتوضيح
}
```

### 7.4 نسبة ثقة منخفضة
```dart
if (command.confidence < 0.6) {
  ttsService.speak('لم أتأكد. هل قلت "${command.rawText}"؟');
  // عرض النص مع خيار تصحيح يدوي
}
```

---

## 8. جدول اختبار المحرك

| المدخل | النية المتوقعة | المعاملات |
|---|---|---|
| "كم جهاز متصل" | `query.devices.count` | — |
| "قد ايش الأجهزة" | `query.devices.count` | — |
| "احظر جهاز أحمد" | `action.security.block` | `{mac: "AA:BB:CC:..."}` |
| "بلوك الآيفون" | `action.security.block` | `{mac: "..."}` |
| "أعد تشغيل المودم" | `action.system.reboot` | — |
| "ريستارت" | `action.system.reboot` | — |
| "كم الرصيد" | `query.bill.balance` | — |
| "غير الباسورد إلى 123abc" | `action.wifi.changePassword` | `{password: "123abc"}` |
| "كم البطارية" | `query.network.battery` | — |
| "قيد جهاز محمد من 9 إلى 12" | `action.parental.restrict` | `{mac:'...',start:540,end:720}` |
