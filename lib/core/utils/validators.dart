class Validators {
  static String? validateWifiSsid(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'اسم الشبكة مطلوب';
    }
    if (value.trim().length > 32) {
      return 'اسم الشبكة لا يمكن أن يتجاوز 32 حرفاً';
    }
    return null;
  }

  static String? validateWifiPassword(String? value, {bool isEncryptionNone = false}) {
    if (isEncryptionNone) return null; // لا يوجد تشفير
    if (value == null || value.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 8) {
      return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
    }
    if (value.length > 63) {
      return 'كلمة المرور لا يمكن أن تتجاوز 63 حرفاً';
    }
    return null;
  }

  static String? validateAdminPassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    if (value.length < 5) {
      return 'كلمة المرور قصيرة جداً';
    }
    return null;
  }

  static String? validatePasswordMatch(String? pass1, String? pass2) {
    if (pass1 != pass2) return 'كلمتي المرور غير متطابقتين';
    return null;
  }

  static String? validateMacAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'عنوان MAC مطلوب';
    }
    // Pattern لمطابقة XX:XX:XX:XX:XX:XX أو XX-XX-XX-XX-XX-XX
    final macExp = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
    if (!macExp.hasMatch(value.trim())) {
      return 'صيغة MAC غير صالحة';
    }
    return null;
  }
}
