import '../enums/command_category.dart';

class CommandPattern {
  final String intent;
  final CommandCategory category;
  final List<String> requiredKeywords; // مجموعات كلمات بحاجة لتطابق واحدة من كل مجموعة (مفصولة بـ |)
  final List<String> boostKeywords;    // تزيد من احتمالية هذا الأمر
  final List<String> antiKeywords;     // تقلل من احتمالية هذا الأمر
  final int weight;
  final bool requiresConfirmation;

  CommandPattern({
    required this.intent,
    required this.category,
    required this.requiredKeywords,
    this.boostKeywords = const [],
    this.antiKeywords = const [],
    this.weight = 10,
    this.requiresConfirmation = false,
  });
}

class CommandRegistry {
  static final List<CommandPattern> patterns = [

    // ═══════════════════════════════════════════════════
    // ─── الأجهزة المتصلة ─────────────────────────────
    // ═══════════════════════════════════════════════════
    CommandPattern(
      intent: 'query.devices.count',
      category: CommandCategory.devices,
      requiredKeywords: ['جهاز|اجهزه|متصل|متصلين|موصول|موصوله'],
      boostKeywords: ['كم', 'عدد', 'كم عدد', 'قديش', 'شقد', 'اديش'],
      antiKeywords: ['احظر', 'امنع', 'سم', 'قيد', 'سرعه', 'رقابه'],
      weight: 12,
    ),
    CommandPattern(
      intent: 'query.devices.list',
      category: CommandCategory.devices,
      requiredKeywords: ['اجهزه|متصل|متصلين|موصول'],
      boostKeywords: ['اعرض', 'قائمه', 'اذكر', 'من', 'مين', 'ما', 'ماهي', 'وريني', 'شوفني'],
      antiKeywords: ['كم', 'احظر', 'قيد'],
      weight: 10,
    ),

    // ═══════════════════════════════════════════════════
    // ─── الأمان (حظر والسماح) ────────────────────────
    // ═══════════════════════════════════════════════════
    CommandPattern(
      intent: 'action.security.block',
      category: CommandCategory.security,
      requiredKeywords: ['احظر|امنع|بلوك|حجب|اطرد|ابلك|سكر|اقفل|كتل', 'جهاز|هاتف|تلفون|لابتوب|موبايل|جوال|تابلت'],
      boostKeywords: ['نت', 'واي فاي'],
      antiKeywords: ['ارفع', 'فك', 'قيد', 'اعد', 'سرعه'],
      requiresConfirmation: true,
      weight: 15,
    ),
    CommandPattern(
      intent: 'action.security.unblock',
      category: CommandCategory.security,
      requiredKeywords: ['ارفع|فك|اسمح|اعد|افتح|حل', 'جهاز|حظر|منع|البلوك'],
      weight: 15,
    ),

    // ═══════════════════════════════════════════════════
    // ─── الشبكة والتفاصيل ────────────────────────────
    // ═══════════════════════════════════════════════════
    CommandPattern(
      intent: 'query.network.signal',
      category: CommandCategory.network,
      requiredKeywords: ['اشاره|شبكه|تغطيه|سيقنال|اشارة'],
      boostKeywords: ['كم', 'قوه', 'مستوى', 'قديش', 'وين'],
      weight: 10,
    ),
    CommandPattern(
      intent: 'query.network.battery',
      category: CommandCategory.network,
      requiredKeywords: ['بطاريه|شحن|باطري'],
      boostKeywords: ['كم', 'نسبه', 'قديش', 'مستوى'],
      weight: 10,
    ),
    CommandPattern(
      intent: 'query.network.speed',
      category: CommandCategory.speed,
      requiredKeywords: ['سرعه|نت|انترنت|سبيد|داونلود'],
      boostKeywords: ['كم', 'كيف', 'تحميل', 'رفع', 'حالي', 'الان'],
      antiKeywords: ['حدد', 'قيد', 'خفف', 'قلل', 'زد', 'غير', 'بدل', 'تغيير'],
      weight: 10,
    ),

    // ═══════════════════════════════════════════════════
    // ─── النظام ──────────────────────────────────────
    // ═══════════════════════════════════════════════════
    CommandPattern(
      intent: 'action.system.reboot',
      category: CommandCategory.system,
      requiredKeywords: ['اعد|ريستارت|ريبوت|ريسيت|اعيد|اشتغل'],
      boostKeywords: ['تشغيل', 'مودم', 'راوتر', 'جهاز', 'شبكه'],
      antiKeywords: ['مصنع', 'ضبط', 'فاكتري'],
      requiresConfirmation: true,
      weight: 20,
    ),
    CommandPattern(
      intent: 'action.system.logout',
      category: CommandCategory.system,
      requiredKeywords: ['سجل|اخرج|خروج|لوق اوت'],
      boostKeywords: ['حساب', 'تطبيق', 'خروج'],
      requiresConfirmation: true,
      weight: 15,
    ),
    CommandPattern(
      intent: 'action.system.factory_reset',
      category: CommandCategory.system,
      requiredKeywords: ['ضبط|فاكتري|اعاده|مصنع|ريست'],
      boostKeywords: ['مصنع', 'اصلي', 'كامل'],
      requiresConfirmation: true,
      weight: 25,
    ),

    // ═══════════════════════════════════════════════════
    // ─── إعدادات الواي فاي ───────────────────────────
    // ═══════════════════════════════════════════════════
    CommandPattern(
      intent: 'action.wifi.changePassword',
      category: CommandCategory.wifi,
      requiredKeywords: ['غير|بدل|تغيير|عدل', 'باسورد|رمز|كلمه|سر|كود'],
      boostKeywords: ['شبكه', 'واي فاي', 'مرور'],
      requiresConfirmation: true,
      weight: 20,
    ),
    CommandPattern(
      intent: 'action.wifi.changeSsid',
      category: CommandCategory.wifi,
      requiredKeywords: ['غير|بدل|تغيير|عدل', 'اسم', 'شبكه|واي فاي'],
      requiresConfirmation: true,
      weight: 20,
    ),

    // ═══════════════════════════════════════════════════
    // ─── الرصيد والاستهلاك ───────────────────────────
    // ═══════════════════════════════════════════════════
    CommandPattern(
      intent: 'query.bill.balance',
      category: CommandCategory.bill,
      requiredKeywords: ['رصيد|باقه|بيانات|كردت'],
      boostKeywords: ['كم', 'باقي', 'متوفر', 'متبقي', 'معي'],
      antiKeywords: ['حجم', 'حدد', 'ضبط', 'اضبط'],
      weight: 15,
    ),
    CommandPattern(
      intent: 'query.usage.current',
      category: CommandCategory.usage,
      requiredKeywords: ['استهلكت|استهلاك|صرفت|استخدمت|استخدام|خلصت'],
      boostKeywords: ['كم', 'بيانات', 'نت', 'قديش'],
      antiKeywords: ['حجم', 'اضبط', 'حدد'],
      weight: 15,
    ),
    CommandPattern(
      intent: 'action.usage.setQuota',
      category: CommandCategory.usage,
      requiredKeywords: ['حدد|اضبط|ضبط|حجم|كمية|قيد', 'باقه|بيانات|استهلاك|نت'],
      boostKeywords: ['جيجا', 'ميجا', 'gb', 'mb'],
      weight: 18,
    ),

    // ═══════════════════════════════════════════════════
    // ─── تحديد السرعة ─────────────────────────────────
    // ═══════════════════════════════════════════════════
    CommandPattern(
      intent: 'action.speed.setGlobal',
      category: CommandCategory.speed,
      requiredKeywords: ['حدد|قيد|خفف|قلل|اضبط|ضبط|سم|اشغل', 'سرعه|نت|انترنت|سبيد'],
      boostKeywords: ['عام', 'كل', 'للكل', 'جميع', 'ميجا', 'mb', 'kb'],
      antiKeywords: ['جهاز', 'هاتف', 'تلفون', 'موبايل'],
      weight: 18,
    ),
    CommandPattern(
      intent: 'action.speed.setDevice',
      category: CommandCategory.speed,
      requiredKeywords: ['حدد|قيد|خفف|قلل|اضبط|ضبط|سم|اشغل', 'سرعه|نت|انترنت|سبيد', 'جهاز|هاتف|تلفون|موبايل|لاب|جوال'],
      boostKeywords: ['ميجا', 'mb', 'kb', 'معين', 'محدد'],
      weight: 20,
    ),
    CommandPattern(
      intent: 'action.speed.disable',
      category: CommandCategory.speed,
      requiredKeywords: ['ارفع|فك|الغي|اوقف|علق|اعطل', 'سرعه|قيد|حد|تحديد'],
      weight: 16,
    ),

    // ═══════════════════════════════════════════════════
    // ─── الرقابة الأبوية ──────────────────────────────
    // ═══════════════════════════════════════════════════
    CommandPattern(
      intent: 'action.parental.enable',
      category: CommandCategory.parental,
      requiredKeywords: ['شغل|فعل|خلي|فتح|شغيل|تشغيل|طفل', 'رقابه|اطفال|اولاد|مراقبه|حمايه|اطفال|تحكم'],
      weight: 20,
    ),
    CommandPattern(
      intent: 'action.parental.disable',
      category: CommandCategory.parental,
      requiredKeywords: ['عطل|اوقف|الغي|طفي|وقف|بند|شيل', 'رقابه|اطفال|اولاد|مراقبه|حمايه|تحكم'],
      weight: 20,
    ),
    CommandPattern(
      intent: 'action.parental.scheduleDevice',
      category: CommandCategory.parental,
      requiredKeywords: ['جدول|اقطع|امنع|حجب|قيد|وقت', 'جهاز|هاتف|موبايل|اطفال|ولد'],
      boostKeywords: ['ساعه', 'دقيقه', 'ليل', 'نهار', 'فجر', 'مدرسه', 'نوم'],
      weight: 18,
    ),
    CommandPattern(
      intent: 'action.parental.openPage',
      category: CommandCategory.parental,
      requiredKeywords: ['افتح|روح|انتقل|اعرض|وريني|اذهب', 'رقابه|اطفال|مراقبه|حمايه|اولاد'],
      weight: 15,
    ),

    // ═══════════════════════════════════════════════════
    // ─── إعدادات النظام ──────────────────────────────
    // ═══════════════════════════════════════════════════
    CommandPattern(
      intent: 'action.settings.darkMode',
      category: CommandCategory.system,
      requiredKeywords: ['غير|بدل|شغل|طفي|فعل|عطل|حول', 'وضع|مود|ثيم|واجهه|لون'],
      boostKeywords: ['ليلي', 'مظلم', 'داكن', 'فاتح', 'نهاري', 'دارك', 'لايت'],
      weight: 18,
    ),
    CommandPattern(
      intent: 'action.settings.biometric',
      category: CommandCategory.system,
      requiredKeywords: ['بصمه|وجه|فيس|فنجر|بايومتريك'],
      boostKeywords: ['فعل', 'شغل', 'عطل', 'الغي', 'تسجيل', 'دخول'],
      weight: 18,
    ),
    CommandPattern(
      intent: 'action.settings.networkMode',
      category: CommandCategory.network,
      requiredKeywords: ['شبكه|نت|انترنت|سيقنال', '4g|5g|lte|3g|نوع'],
      boostKeywords: ['غير', 'بدل', 'حول', 'افضل'],
      weight: 18,
    ),

    // ═══════════════════════════════════════════════════
    // ─── التنقل الشامل ───────────────────────────────
    // ═══════════════════════════════════════════════════
    CommandPattern(
      intent: 'navigate.page',
      category: CommandCategory.navigation,
      requiredKeywords: ['افتح|روح|خذني|انتقل|وديني|اذهب|اعرض|وريني'],
      boostKeywords: [
        'اعدادات', 'رصيد', 'اجهزه', 'تحكم', 'فلتر', 'رادار', 'تغطيه', 'اشاره',
        'فحص', 'سرعه', 'رقابه', 'اطفال', 'استهلاك', 'بيانات', 'حساب', 'لوحه',
        'داشبورد', 'رئيسيه', 'شبكه', 'مودم', 'سبيد', 'تست',
      ],
      weight: 5,
    ),

    // ═══════════════════════════════════════════════════
    // ─── المساعدة ─────────────────────────────────────
    // ═══════════════════════════════════════════════════
    CommandPattern(
      intent: 'query.help',
      category: CommandCategory.help,
      requiredKeywords: ['ساعدني|مساعده|ايش تقدر|شو تقدر|تعليمات|اوامر|قائمه اوامر|كيف'],
      boostKeywords: ['تعرف', 'تقدر', 'عندك'],
      weight: 12,
    ),
  ];
}
