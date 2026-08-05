class ArabicNormalizer {
  static String normalize(String text) {
    var result = text.trim().toLowerCase();
    
    // 1. إزالة التشكيل (الفتحة، الضمة، الكسرة، التنوين...)
    result = result.replaceAll(RegExp(r'[\u064B-\u065F\u0670]'), '');
    
    // 2. توحيد الألف (أ إ آ -> ا)
    result = result.replaceAll(RegExp(r'[أإآ]'), 'ا');
    
    // 3. توحيد الهاء والتاء المربوطة (ة -> ه)
    result = result.replaceAll('ة', 'ه');
    
    // 4. توحيد الياء (ى -> ي)
    result = result.replaceAll('ى', 'ي');
    
    // 5. إزالة "ال" التعريف للمطابقة المرنة
    result = result.replaceAll(RegExp(r'\bال'), '');
    
    // 6. إزالة الأحرف المكررة الزائدة ("متصلللل" -> "متصل")
    result = result.replaceAll(RegExp(r'(.)\1{2,}'), r'$1');
    
    // 7. إزالة علامات الترقيم والرموز الخاصة
    result = result.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '');
    
    // 8. تنظيف المسافات المتعددة
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return result;
  }
}
