import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../features/modem_auth/presentation/controllers/auth_controller.dart';
import '../widgets/custom_snackbar.dart';

class SessionHelper {
  static bool _isLoggingOut = false;
  static bool _isRenewing = false;

  /// يتحقق مما إذا كان الخطأ ناتجاً عن انتهاء الجلسة أو فصل الاتصال بالمودم
  /// يحاول التجديد التلقائي أولاً قبل طرد المستخدم
  /// يُرجع true إذا كان خطأ جلسة/اتصال وتمت المعالجة، ويرجع false خلاف ذلك
  static bool handleSessionError(dynamic error) {
    if (error == null) return false;
    
    final errorStr = error.toString().toLowerCase();
    
    final isSessionExpired = errorStr.contains('session_expired') || 
        errorStr.contains('session no exist') || 
        errorStr.contains('100003') || 
        errorStr.contains('125002') || 
        errorStr.contains('الجلسة منتهية') || 
        errorStr.contains('الجلسة غير صالحة');

    // فحص دقيق للاتصال المنقطع — نستثني timeout البسيط
    final isDefinitiveDisconnect = errorStr.contains('socketexception') || 
        errorStr.contains('connection refused') ||
        errorStr.contains('host lookup') ||
        errorStr.contains('network is unreachable') ||
        errorStr.contains('فشل الاتصال') ||
        errorStr.contains('انقطع الاتصال');

    // Timeout عابر — مجرد بطء مؤقت، ليس انقطاعاً
    final isTransientTimeout = !isDefinitiveDisconnect && (
        errorStr.contains('timeoutexception') ||
        errorStr.contains('انتهى وقت الطلب'));

    if (isDefinitiveDisconnect) {
      // انقطاع حقيقي — طرد فوري
      if (!_isLoggingOut) {
        _isLoggingOut = true;
        if (kDebugMode) debugPrint('🔌 [SessionHelper] Definitive disconnect detected');
        Get.find<AuthController>().forceLogout(
          'انقطع الاتصال',
          'تم تغيير الشبكة أو فصل الواي فاي. يرجى إعادة الاتصال بالمودم.',
        );
        Future.delayed(const Duration(seconds: 3), () => _isLoggingOut = false);
      }
      return true;
    }

    if (isTransientTimeout) {
      // Timeout عابر — تحذير بسيط فقط، لا طرد
      if (!_isLoggingOut) {
        if (kDebugMode) debugPrint('⏱️ [SessionHelper] Transient timeout — warning only');
        CustomSnackbar.showWarning(
          'اتصال بطيء',
          'المودم يستغرق وقتاً طويلاً للرد. تأكد من جودة الإشارة.',
        );
      }
      return true;
    }

    if (isSessionExpired) {
      // انتهاء الجلسة — محاولة تجديد أولاً
      if (!_isLoggingOut && !_isRenewing) {
        _isRenewing = true;
        if (kDebugMode) debugPrint('🔄 [SessionHelper] Session expired — attempting renewal');

        _attemptRenewalThenLogout();
      }
      return true;
    }
    
    return false;
  }

  /// محاولة تجديد الجلسة بالمصادقة/كلمة المرور، وإذا فشلت يتم الطرد
  static Future<void> _attemptRenewalThenLogout() async {
    try {
      final authController = Get.find<AuthController>();
      final renewed = await authController.renewSessionWithBiometricsOrPassword();

      if (renewed) {
        if (kDebugMode) debugPrint('✅ [SessionHelper] Session renewed — user stays');
      } else {
        if (kDebugMode) debugPrint('❌ [SessionHelper] Renewal failed — forcing logout');
        if (!_isLoggingOut) {
          _isLoggingOut = true;
          authController.forceLogout(
            'انتهت الجلسة ⚠️',
            'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مجدداً.',
          );
          Future.delayed(const Duration(seconds: 3), () => _isLoggingOut = false);
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [SessionHelper] Renewal error: $e');
      if (!_isLoggingOut) {
        _isLoggingOut = true;
        try {
          Get.find<AuthController>().forceLogout(
            'انتهت الجلسة',
            'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مجدداً.',
          );
        } catch (_) {}
        Future.delayed(const Duration(seconds: 3), () => _isLoggingOut = false);
      }
    } finally {
      _isRenewing = false;
    }
  }
}
