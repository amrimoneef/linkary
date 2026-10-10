import 'dart:convert';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:linkary/core/network/session_manager.dart';

/// معالج خلفي عام ومستقل يتم استدعاؤه مباشرة من نظام أندرويد
@pragma('vm:entry-point')
void deviceNotificationActionTapBackground(NotificationResponse response) {
  DeviceNotificationService.onDeviceNotificationBackgroundAction(response);
}

/// خدمة مركزية لإدارة إشعارات الأجهزة المتصلة وتنفيذ الإجراءات التفاعلية (حظر، توثيق، تجاهل)
/// مباشرة من شريط الإشعارات بدون فتح التطبيق.
class DeviceNotificationService {
  static const String channelId = 'new_device_alerts_v2';
  static const String channelName = 'إشعارات الأجهزة الجديدة';
  static const String channelDesc = 'تنبيهات عند اتصال جهاز جديد بالمودم مع إمكانية اتخاذ إجراء مباشر';

  static const String feedbackChannelId = 'device_action_feedback';
  static const String feedbackChannelName = 'تأكيدات إجراءات الأجهزة';

  static const String actionBlock = 'device_action_block';
  static const String actionTrust = 'device_action_trust';
  static const String actionDismiss = 'device_action_dismiss';
  static const String payloadType = 'new_device_alert';

  static const String _modemBaseUrl = 'http://mobile.router';

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static void Function()? _onOpenConnectedDevicesCallback;

  /// دالة لترميز حمولة الإشعار
  static String encodePayload({
    required String mac,
    required String deviceName,
    String? sn,
  }) {
    return jsonEncode({
      'type': payloadType,
      'mac': mac.toUpperCase(),
      'name': deviceName,
      'sn': sn ?? '',
    });
  }

  /// دالة لتحليل حمولة الإشعار
  static Map<String, dynamic> parsePayload(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return {};
  }

  /// استخراج نوع الإجراء ('block', 'trust', 'dismiss')
  static String extractActionType(String actionId) {
    if (actionId.startsWith(actionBlock)) return 'block';
    if (actionId.startsWith(actionTrust)) return 'trust';
    if (actionId.startsWith(actionDismiss)) return 'dismiss';
    return 'unknown';
  }

  /// معرف رقمي ثابت لكل جهاز بناءً على الـ MAC الخاص به
  static int getNotificationId(String mac) {
    return mac.toUpperCase().hashCode.abs() % 100000;
  }

  /// تهيئة خدمة الإشعارات والقنوات التفاعلية
  static Future<void> initialize({
    void Function()? onOpenConnectedDevices,
  }) async {
    _onOpenConnectedDevicesCallback = onOpenConnectedDevices;
    if (_isInitialized) return;

    WidgetsFlutterBinding.ensureInitialized();

    const AndroidInitializationSettings initAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');
    const InitializationSettings initSettings =
        InitializationSettings(android: initAndroid);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onForegroundNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: deviceNotificationActionTapBackground,
    );

    // إنشاء قنوات الإشعارات على نظام أندرويد
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // 1. قناة تنبيهات الأجهزة الجديدة مع الأزرار التفاعلية
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );

      // 2. قناة تأكيدات الإجراءات (Feedbacks)
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          feedbackChannelId,
          feedbackChannelName,
          description: 'تأكيدات فورية لإجراءات الحظر والتوثيق من الإشعار',
          importance: Importance.high,
          playSound: true,
          enableVibration: false,
        ),
      );
    }

    _isInitialized = true;
  }

  /// استجابة الإشعار عندما يكون التطبيق في المقدمة
  static void _onForegroundNotificationResponse(NotificationResponse response) {
    final actionId = response.actionId;
    if (actionId != null && actionId.isNotEmpty) {
      // تم النقر على أحد أزرار الإجراءات أثناء فتح التطبيق
      onDeviceNotificationBackgroundAction(response);
      return;
    }

    // تم النقر على نص الإشعار نفسه: فتح شاشة الأجهزة المتصلة
    final payload = parsePayload(response.payload);
    if (payload['type'] == payloadType) {
      _onOpenConnectedDevicesCallback?.call();
    }
  }

  /// عرض إشعار تنبيه الجهاز المتصل مع أزرار (حظر، توثيق، تجاهل)
  static Future<void> showDeviceAlert({
    required String mac,
    required String deviceName,
    String? sn,
  }) async {
    await initialize();

    final int notifId = getNotificationId(mac);
    final String payload = encodePayload(mac: mac, deviceName: deviceName, sn: sn);

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      category: AndroidNotificationCategory.alarm,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          actionBlock,
          'حظر 🚫',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          actionTrust,
          'توثيق ✅',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          actionDismiss,
          'تجاهل ✖️',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    final NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _plugin.show(
      id: notifId,
      title: 'جهاز متصل جديد!',
      body: 'تم اكتشاف جهاز $deviceName متصل بشبكتك',
      notificationDetails: platformDetails,
      payload: payload,
    );
  }

  /// إظهار إشعار تأكيد سريع للعملية
  static Future<void> showFeedbackNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      feedbackChannelId,
      feedbackChannelName,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      autoCancel: true,
    );
    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformDetails,
    );
  }

  /// المعالج الخلفي المستقل (Headless Entry Point) المنفّذ عند النقر على أي زر إجراء
  @pragma('vm:entry-point')
  static Future<void> onDeviceNotificationBackgroundAction(
      NotificationResponse response) async {
    WidgetsFlutterBinding.ensureInitialized();

    final actionId = response.actionId ?? '';
    final actionType = extractActionType(actionId);
    final payload = parsePayload(response.payload);

    final mac = (payload['mac'] ?? '').toString().toUpperCase();
    final deviceName = (payload['name'] ?? 'جهاز غير معروف').toString();
    final sn = (payload['sn'] ?? '').toString();

    if (mac.isEmpty) return;

    if (actionType == 'block') {
      await executeBlockDevice(mac: mac, deviceName: deviceName, sn: sn);
    } else if (actionType == 'trust') {
      await executeTrustDevice(mac: mac, deviceName: deviceName, sn: sn);
    } else if (actionType == 'dismiss') {
      await executeDismissDevice(mac: mac, deviceName: deviceName, sn: sn);
    }
  }

  /// 🚫 تنفيذ إجراء الحظر الصامت بالمودم
  static Future<bool> executeBlockDevice({
    required String mac,
    required String deviceName,
    String? sn,
  }) async {
    final client = http.Client();
    try {
      final activeSn = (sn != null && sn.isNotEmpty) ? sn : await SessionManager.getLastSN();

      String? sessionId = await SessionManager.getSessionId(activeSn) ??
          await SessionManager.getSessionId();
      String? password = await SessionManager.getLastLoginPassword(activeSn) ??
          await SessionManager.getLastLoginPassword() ??
          await SessionManager.getPassword(activeSn) ??
          await SessionManager.getPassword();

      if (sessionId == null || sessionId.isEmpty) {
        if (password != null && password.isNotEmpty) {
          sessionId = await _performSilentLogin(client, activeSn, password);
        }
      }

      if (sessionId == null || sessionId.isEmpty) {
        await showFeedbackNotification(
          id: getNotificationId(mac) + 10,
          title: 'تعذر حظر الجهاز',
          body: 'انتهت جلسة المودم، يرجى فتح التطبيق لتأكيد الحظر.',
        );
        return false;
      }

      // 1. جلب قائمة الحظر الحالية
      final time = DateTime.now().millisecondsSinceEpoch;
      final filterUrl =
          '$_modemBaseUrl/api.cgi?path=wireless&method=wifi_get_mac_filter&timeout=20&_=$time';
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'Cookie': 'CGISID=$sessionId',
        'reset_time': '1',
      };

      var filterRes = await client.get(Uri.parse(filterUrl), headers: headers);

      // تجديد الجلسة إذا كانت منتهية
      if (_isSessionExpired(filterRes)) {
        if (password != null && password.isNotEmpty) {
          sessionId = await _performSilentLogin(client, activeSn, password);
          if (sessionId != null && sessionId.isNotEmpty) {
            headers['Cookie'] = 'CGISID=$sessionId';
            filterRes = await client.get(Uri.parse(filterUrl), headers: headers);
          }
        }
      }

      List<String> denyList = [];
      if (filterRes.statusCode == 200 && filterRes.body.isNotEmpty) {
        final filterData = jsonDecode(filterRes.body);
        final rawDeny = filterData['wireless']?['AP0']?['maclist_deny'];
        if (rawDeny != null && rawDeny.toString().isNotEmpty) {
          denyList = rawDeny
              .toString()
              .split(RegExp(r'[\s;,]+'))
              .where((m) => m.isNotEmpty && m.contains(':'))
              .map((m) => m.toUpperCase())
              .toList();
        }
      }

      if (!denyList.contains(mac)) {
        denyList.add(mac);
      }

      // 2. إرسال طلب تفعيل الحظر وحفظ القائمة
      final saveUrl =
          '$_modemBaseUrl/api.cgi?path=wireless&method=wifi_set_mac_filter&timeout=20';
      final payload = {
        "wifi_device": "0",
        "macfilter": "deny",
        "maclist_deny": denyList.join(' '),
      };

      try {
        final saveRes = await client.post(
          Uri.parse(saveUrl),
          headers: headers,
          body: jsonEncode(payload),
        ).timeout(const Duration(seconds: 10));

        final body = jsonDecode(saveRes.body);
        final isOk = body['wireless']?['setting_response'] == 'OK';
        if (!isOk) {
          debugPrint('⚠️ [DeviceNotificationService] Modem responded without OK');
        }
      } catch (e) {
        // عند إعادة تشغيل شبكة الواي فاي من المودم لتطبيق الحظر، قد يحصل SocketException أو Timeout طبيعي
        debugPrint('ℹ️ [DeviceNotificationService] Wi-Fi reset during block: $e');
      }

      // 3. تحديث التخزين المحلي
      await SessionManager.removePendingMac(mac, activeSn);
      await SessionManager.removePendingMac(mac);
      await SessionManager.untrustDevice(mac, activeSn);
      await SessionManager.untrustDevice(mac);
      await SessionManager.addBlockedMac(mac, activeSn);
      await SessionManager.addBlockedMac(mac);

      // 4. إشعار تأكيد سريع
      await showFeedbackNotification(
        id: getNotificationId(mac) + 10,
        title: 'تم حظر الجهاز بنجاح 🚫',
        body: 'تم حظر $deviceName وفصله عن شبكة المودم.',
      );

      return true;
    } catch (e) {
      debugPrint('❌ [DeviceNotificationService] Block error: $e');
      await showFeedbackNotification(
        id: getNotificationId(mac) + 10,
        title: 'خطأ في حظر الجهاز',
        body: 'تعذر إتمام حظر $deviceName .تحقق من اتصالك بالمودم.',
      );
      return false;
    } finally {
      client.close();
    }
  }

  /// ✅ تنفيذ إجراء التوثيق الصامت
  static Future<void> executeTrustDevice({
    required String mac,
    required String deviceName,
    String? sn,
  }) async {
    try {
      final activeSn = (sn != null && sn.isNotEmpty) ? sn : await SessionManager.getLastSN();

      await SessionManager.trustDevice(mac, activeSn);
      await SessionManager.trustDevice(mac);
      await SessionManager.removeBlockedMac(mac, activeSn);
      await SessionManager.removeBlockedMac(mac);

      await showFeedbackNotification(
        id: getNotificationId(mac) + 10,
        title: 'تم توثيق الجهاز بنجاح ✅',
        body: 'تمت إضافة $deviceName إلى قائمة الأجهزة الموثوقة.',
      );
    } catch (e) {
      debugPrint('❌ [DeviceNotificationService] Trust error: $e');
    }
  }

  /// ✖️ تنفيذ إجراء التجاهل (مسح الإشعار الحالي فقط من شريط الإشعارات)
  static Future<void> executeDismissDevice({
    required String mac,
    required String deviceName,
    String? sn,
  }) async {
    try {
      // مسح الإشعار الحالي فقط دون التأثير على حالة الجهاز أو منع إشعاراته المستقبلية
      await _plugin.cancel(id: getNotificationId(mac));
    } catch (e) {
      debugPrint('❌ [DeviceNotificationService] Dismiss error: $e');
    }
  }

  /// فحص هل الرد يشير لانتهاء الجلسة
  static bool _isSessionExpired(http.Response? response) {
    if (response == null) return true;
    final bodyStr = response.body.toLowerCase().replaceAll(' ', '');
    return bodyStr.contains('sessionnoexist') ||
        bodyStr.contains('sessionfail') ||
        bodyStr.contains('"result":100003') ||
        bodyStr.contains('"result":125002') ||
        bodyStr.contains('login.html');
  }

  /// تسجيل دخول صامت في الخلفية
  static Future<String?> _performSilentLogin(
      http.Client client, String? sn, String password) async {
    try {
      final userId = Random().nextInt(90000000 + 10000000).toString();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/javascript, */*; q=0.01',
        'X-Requested-With': 'XMLHttpRequest',
      };

      final randResp = await client.post(
        Uri.parse('$_modemBaseUrl/api.cgi?path=account&method=get_rand&timeout=20'),
        headers: headers,
        body: jsonEncode({"type": "admin", "user_id": userId}),
      ).timeout(const Duration(seconds: 8));

      if (randResp.statusCode != 200 || randResp.body.isEmpty) return null;
      final randData = jsonDecode(randResp.body);
      if (randData['result'] != 0) return null;

      final String rand = randData['rand'];
      final rawString = rand + password.toLowerCase();
      final hashedPassword = md5.convert(utf8.encode(rawString)).toString();

      final loginResp = await client.post(
        Uri.parse('$_modemBaseUrl/api.cgi?path=account&method=login&timeout=20'),
        headers: headers,
        body: jsonEncode({
          "type": "admin",
          "username": "admin",
          "password": hashedPassword,
          "user_id": userId
        }),
      ).timeout(const Duration(seconds: 8));

      if (loginResp.statusCode != 200) return null;
      final loginData = jsonDecode(loginResp.body);

      if (loginData['result'] == 0 || loginData['result'] == 3) {
        final cookies = loginResp.headers['set-cookie'] ?? '';
        final match = RegExp(r'CGISID=([^;]+)').firstMatch(cookies);
        final sessionId = match?.group(1);

        if (sessionId != null && sessionId.isNotEmpty) {
          await SessionManager.saveSessionId(sessionId, sn);
          await SessionManager.saveSessionId(sessionId);
          await SessionManager.setLastHeartbeat(DateTime.now(), sn);
          return sessionId;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
