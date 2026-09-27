class ArabicTextNormalizer {
  static final RegExp _tashkeelRegex = RegExp(r'[\u064B-\u065F\u0670]');

  /// Normalizes Arabic text by removing diacritics, unifying hamzas,
  /// converting ta marbuta to ha, and alif maqsura to ya.
  static String normalize(String text) {
    if (text.isEmpty) return '';

    String cleaned = text.trim().toLowerCase();

    // 1. Remove Tashkeel (diacritics: Fatha, Damma, Kasra, Sukun, Shadda, Tanween)
    cleaned = cleaned.replaceAll(_tashkeelRegex, '');

    // 2. Unify Hamzas (أ, إ, آ, ٱ -> ا, ؤ -> و, ئ -> ي, ء -> remove)
    cleaned = cleaned
        .replaceAll(RegExp(r'[إأآٱ]'), 'ا')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ء', '');

    // 3. Unify Ta Marbuta (ة -> ه)
    cleaned = cleaned.replaceAll('ة', 'ه');

    // 4. Unify Alif Maqsura (ى -> ي)
    cleaned = cleaned.replaceAll('ى', 'ي');

    // 5. Replace multiple spaces with a single space
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

    return cleaned;
  }
}
