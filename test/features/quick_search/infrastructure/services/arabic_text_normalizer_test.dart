import 'package:flutter_test/flutter_test.dart';
import 'package:linkary/features/quick_search/infrastructure/services/arabic_text_normalizer.dart';

void main() {
  group('ArabicTextNormalizer', () {
    test('normalizes hamzas correctly', () {
      expect(ArabicTextNormalizer.normalize('إعدادات'), 'اعدادات');
      expect(ArabicTextNormalizer.normalize('أجهزة'), 'اجهزه');
      expect(ArabicTextNormalizer.normalize('آمن'), 'امن');
      expect(ArabicTextNormalizer.normalize('مسؤول'), 'مسوول');
      expect(ArabicTextNormalizer.normalize('رئيسي'), 'رييسي');
      expect(ArabicTextNormalizer.normalize('سماء'), 'سما');
    });

    test('strips diacritics / tashkeel', () {
      expect(ArabicTextNormalizer.normalize('إِعْدَادَاتُ الشَّبَكَةِ'), 'اعدادات الشبكه');
    });

    test('normalizes ta marbuta and alif maqsura', () {
      expect(ArabicTextNormalizer.normalize('سرعة'), 'سرعه');
      expect(ArabicTextNormalizer.normalize('مستشفى'), 'مستشفي');
    });

    test('handles case and whitespace for mixed languages', () {
      expect(ArabicTextNormalizer.normalize('  Wi-Fi  Password  '), 'wi-fi password');
    });
  });
}
