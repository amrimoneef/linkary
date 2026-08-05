import 'package:freerasp/freerasp.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// 🛡️ خدمة الحماية المركزية ضد الهندسة العكسية والعبث
///
/// تستخدم freeRASP لكشف التهديدات في وقت التشغيل:
/// - Root/Jailbreak
/// - أدوات الاختراق (Frida, Shadow)
/// - المصححات (Debuggers)
/// - التعديل على التطبيق (Tampering)
/// - المحاكيات (Emulators)
/// - التثبيت من مصادر غير رسمية
class AppSecurityService {
  static final AppSecurityService _instance = AppSecurityService._();
  static AppSecurityService get instance => _instance;
  AppSecurityService._();

  /// يتم استدعاؤها مرة واحدة في main() قبل runApp()
  Future<void> initialize() async {
    // 🛡️ تعطيل مؤقت لاكتشاف سبب الانهيار
    debugPrint('🛡️ [SECURITY] Talsec is temporarily disabled for debugging');
    return;
    /*
    try {
      final config = TalsecConfig(
        androidConfig: AndroidConfig(
          packageName: 'com.sam4g.app_settings',
          signingCertHashes: [
            'qJL+4fgDYzMIfsatW9JR6WIE0MD8GDYM2bpA8l1Tx2g=', 
          ],
          supportedStores: ['com.android.vending', 'com.sec.android.app.samsungapps'], 
        ),
        watcherMail: 'amrimoneef@gmail.com',
        isProd: !kDebugMode, 
      );

      final callback = ThreatCallback(
        onAppIntegrity: () => debugPrint('🛡️ [SECURITY] App Integrity mismatch'),
        onObfuscationIssues: () => debugPrint('🛡️ [SECURITY] Obfuscation issues'),
        onDebug: () => debugPrint('🛡️ [SECURITY] Debugger detected'),
        onDeviceBinding: () => debugPrint('🛡️ [SECURITY] Device binding issues'),
        onDeviceID: () => debugPrint('🛡️ [SECURITY] Device ID issues'),
        onHooks: () => debugPrint('🛡️ [SECURITY] Hooks detected'),
        onPasscode: () => debugPrint('⚠️ [SECURITY] No passcode set'),
        onPrivilegedAccess: () => debugPrint('🛡️ [SECURITY] Root detected'),
        onSecureHardwareNotAvailable: () => debugPrint('⚠️ [SECURITY] Secure hardware not available'),
        onSimulator: () => debugPrint('⚠️ [SECURITY] Simulator detected'),
        onUnofficialStore: () => debugPrint('⚠️ [SECURITY] Unofficial store detected'),
      );

      Talsec.instance.attachListener(callback);
      await Talsec.instance.start(config);
      
    } catch (e) {
      debugPrint('🛡️ [SECURITY] Failed to initialize Talsec: $e');
    }
    */
  }

  /// 🔴 إغلاق التطبيق فوراً عند كشف تهديد
  void _terminateApp(String reason) {
    if (kDebugMode) {
      debugPrint('🛡️ [SECURITY THREAT] $reason');
    }
    // إغلاق فوري — لا نعطي المهاجم أي فرصة
    SystemNavigator.pop();
  }
}
