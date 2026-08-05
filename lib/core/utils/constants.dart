class AppConstants {
  static const String modemBaseUrl = 'http://mobile.router';
  static const int requestTimeoutSeconds = 15;

  // ─── Session Management ───
  /// الفاصل الزمني بين كل نبض للجلسة (بالثواني) — لإبقاء الجلسة حية على المودم
  static const int sessionHeartbeatIntervalSeconds = 60;

  /// أقصى عدد محاولات لتجديد الجلسة تلقائياً قبل طرد المستخدم
  static const int sessionMaxRenewalAttempts = 3;

  /// فترة الانتظار بين كل محاولة تجديد (بالثواني)
  static const int sessionRenewalCooldownSeconds = 5;

  /// فترة مراقبة الشبكة (بالثواني) — كل كم ثانية نتحقق من اتصال المودم
  static const int networkMonitorIntervalSeconds = 10;

  /// عدد الفحوصات الفاشلة المتتالية قبل اعتبار الشبكة منقطعة
  static const int networkDisconnectThreshold = 3;
}
