import '../entities/auth_entity.dart';

abstract class AuthRepository {
  // هذه الدالة ستقوم بالتنفيذ الفعلي للاتصال بالمودم لاحقاً
  Future<AuthEntity> login(String password);

  // دالة لتسجيل الخروج (لمسح الجلسة)
  Future<void> logout(String sessionId);
  Future<int> getRetryTimes();
  Future<void> reboot(String sessionId);
  Future<void> powerOff(String sessionId);
  Future<void> factoryReset(String sessionId);
  Future<bool> checkIfSetupRequired();
  Future<void> markSetupComplete();
  Future<String?> getSerialNumber();
}