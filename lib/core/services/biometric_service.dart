import 'package:local_auth/local_auth.dart';

/// خدمة المصادقة البيومترية (البصمة / الوجه)
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// هل الجهاز يدعم البصمة أو التعرف على الوجه؟
  Future<bool> isDeviceSupported() async {
    try {
      return await _localAuth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// هل يوجد بصمة أو وجه مسجل على الجهاز؟
  Future<bool> canAuthenticate() async {
    try {
      final isSupported = await _localAuth.isDeviceSupported();
      if (!isSupported) return false;

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// طلب المصادقة البيومترية من المستخدم
  Future<bool> authenticate() async {
    try {
      return await _localAuth.authenticate(
        localizedReason: 'قم بالتحقق من هويتك لتسجيل الدخول',
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }
}
