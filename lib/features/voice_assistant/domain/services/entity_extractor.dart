import '../../../connected_devices/domain/entities/connected_device_entity.dart';
import 'arabic_normalizer.dart';

class EntityExtractor {
  /// استخلاص اسم الجهاز من النص بمطابقته مع الأجهزة المتصلة الجلبناها من المودم
  static String? extractDeviceMac(String normalizedText, List<ConnectedDeviceEntity> devices) {
    if (devices.isEmpty) return null;

    // 1. مطابقة مباشرة بالاسم (المخصص أو الأصلي)
    for (final device in devices) {
      final name = ArabicNormalizer.normalize(device.name);
      if (name.isNotEmpty && normalizedText.contains(name)) {
        return device.mac;
      }
    }
    
    // 2. البحث عن كلمة تأتي بعد كلمة "جهاز" أو مرادفاتها
    final devicePattern = RegExp(r'(?:جهاز|هاتف|تلفون|موبايل|لاب|لابتوب|كمبيوتر|جوال)\s+(\S+)');
    final match = devicePattern.firstMatch(normalizedText);
    
    if (match != null) {
      final targetName = match.group(1)!;
      for (final device in devices) {
        if (ArabicNormalizer.normalize(device.name).contains(targetName)) {
          return device.mac;
        }
      }
    }
    
    return null;
  }
  
  /// استخلاص أي كلمة مرور (تأتي عادة في نهاية السلسلة أو بعد كلمة معينة)
  static String? extractPassword(String text) {
    // مثلاً: "الى 123abc"
    final pattern = RegExp(r'(?:الي|الى|ب|باسورد)\s+([a-zA-Z0-9!@#\$%\^&\*]+)');
    final match = pattern.firstMatch(text);
    if (match != null) return match.group(1);
    
    // أو نأخذ آخر كلمة إنجليزية/رقمية
    final lastWordPattern = RegExp(r'([a-zA-Z0-9!@#\$%\^&\*]+)$');
    final lastMatch = lastWordPattern.firstMatch(text.trim());
    if (lastMatch != null) return lastMatch.group(1);

    return null;
  }
  
  /// استخلاص قيمة رقمية (سرعة)
  static int? extractNumber(String text) {
    final pattern = RegExp(r'(\d+)');
    final match = pattern.firstMatch(text);
    if (match != null) return int.parse(match.group(1)!);
    return null;
  }
}
