import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../utils/constants.dart';
import 'session_manager.dart';
import '../../features/modem_auth/presentation/controllers/auth_controller.dart';

/// خدمة نبض الجلسة المركزية (Session Heartbeat Service)
///
/// تُرسل طلبات خفيفة دورياً للمودم لإبقاء الجلسة حية ومنع انتهائها بسبب عدم النشاط.
/// تتوقف تلقائياً عند انتقال التطبيق للخلفية وتستأنف عند العودة مع تحقق فوري.
class SessionHeartbeatService with WidgetsBindingObserver {
  Timer? _heartbeatTimer;
  bool _isRunning = false;
  bool _isRenewing = false;
  final String _baseUrl = AppConstants.modemBaseUrl;

  /// بدء خدمة الـ Heartbeat
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    WidgetsBinding.instance.addObserver(this);

    // نبض فوري عند البدء
    _performHeartbeat();

    // ثم نبض دوري
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      Duration(seconds: AppConstants.sessionHeartbeatIntervalSeconds),
      (_) => _performHeartbeat(),
    );

    if (kDebugMode) debugPrint('💓 [Heartbeat] Service started (every ${AppConstants.sessionHeartbeatIntervalSeconds}s)');
  }

  /// إيقاف خدمة الـ Heartbeat
  void stop() {
    _isRunning = false;
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    WidgetsBinding.instance.removeObserver(this);
    if (kDebugMode) debugPrint('💔 [Heartbeat] Service stopped');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (kDebugMode) debugPrint('💓 [Heartbeat] App resumed — immediate check + restart');
      // تحقق فوري عند العودة من الخلفية
      _performHeartbeat();
      // إعادة تشغيل الـ Timer
      _heartbeatTimer?.cancel();
      _heartbeatTimer = Timer.periodic(
        Duration(seconds: AppConstants.sessionHeartbeatIntervalSeconds),
        (_) => _performHeartbeat(),
      );
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (kDebugMode) debugPrint('⏸️ [Heartbeat] App paused — timer stopped');
      _heartbeatTimer?.cancel();
      _heartbeatTimer = null;
    }
  }

  /// تنفيذ نبض واحد: طلب خفيف للمودم للتحقق من الجلسة وإبقائها حية
  Future<void> _performHeartbeat() async {
    if (!_isRunning) return;

    try {
      final authController = Get.find<AuthController>();
      final sessionId = authController.currentUser?.sessionId;
      final sn = authController.currentSN.value;

      if (sessionId == null || sessionId.isEmpty) {
        if (kDebugMode) debugPrint('💔 [Heartbeat] No session ID — skipping');
        return;
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // نستخدم get_sys_time لأنه أخف طلب ممكن ويتطلب جلسة صالحة
      final url = '$_baseUrl/api.cgi?path=router&method=get_sys_time&timeout=5&_=$timestamp';

      final response = await http.Client().get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'Cookie': 'CGISID=$sessionId',
        },
      ).timeout(const Duration(seconds: 5));

      final bodyStr = response.body.toLowerCase().replaceAll(' ', '');

      // التحقق من أن الجلسة ما زالت صالحة
      if (_isSessionExpiredResponse(bodyStr)) {
        if (kDebugMode) debugPrint('💔 [Heartbeat] Session expired — attempting renewal');
        await _attemptRenewal(sn);
      } else {
        // الجلسة صالحة — نسجل النبض الناجح
        await SessionManager.setLastHeartbeat(DateTime.now(), sn);
        if (kDebugMode) debugPrint('💓 [Heartbeat] OK — session alive');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('💔 [Heartbeat] Error: $e');
      // لا نطرد المستخدم بسبب خطأ مؤقت في النبض — الـ Polling في Dashboard سيتعامل مع ذلك
    }
  }

  /// التحقق من أن الرد يشير لانتهاء الجلسة
  bool _isSessionExpiredResponse(String bodyStrLower) {
    // فحص دقيق: نتحقق من الأنماط المحددة فقط
    return bodyStrLower.contains('sessionnoexist') ||
        bodyStrLower.contains('sessionfail') ||
        bodyStrLower.contains('authorizationisnotok') ||
        bodyStrLower.contains('"result":100003') ||
        bodyStrLower.contains('"result":125002') ||
        bodyStrLower.contains('anotheruser') ||
        bodyStrLower.contains('login.html') ||
        bodyStrLower.contains('window.location');
  }

  /// محاولة تجديد الجلسة بالمصادقة البيومترية أو كلمة المرور
  Future<void> _attemptRenewal(String? sn) async {
    if (_isRenewing) return; // منع التجديد المتزامن
    _isRenewing = true;

    try {
      final authController = Get.find<AuthController>();
      final renewed = await authController.renewSessionWithBiometricsOrPassword();

      if (renewed) {
        if (kDebugMode) debugPrint('✅ [Heartbeat] Session renewed successfully');
        await SessionManager.setLastHeartbeat(DateTime.now(), sn);
      } else {
        if (kDebugMode) debugPrint('❌ [Heartbeat] Renewal failed — forcing logout');
        stop();
        authController.forceLogout(
          'انتهت الجلسة ⚠️',
          'انتهت صلاحية الجلسة ولم نتمكن من تجديدها. يرجى تسجيل الدخول مجدداً.',
        );
      }
    } finally {
      _isRenewing = false;
    }
  }
}
