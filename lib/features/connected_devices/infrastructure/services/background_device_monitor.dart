import 'dart:convert';
import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:linkary/core/network/session_manager.dart';

const String backgroundDeviceMonitorTask = "bg_device_monitor_task";

/// خدمة مراقبة الأجهزة المتصلة في الخلفية.
/// تعمل كل 15 دقيقة عبر Workmanager.
/// عند اكتشاف جهاز جديد: ترسل إشعار + تضيفه لقائمة الأجهزة المعلّقة (Pending).
class BackgroundDeviceMonitor {
  static const String _modemBaseUrl = 'http://mobile.router';

  /// الدالة الأساسية التي تُنفّذ في الخلفية (بدون اعتماد على DI)
  static Future<void> checkDevicesAndNotify() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      debugPrint('🔍 [BG Device Monitor] Task started');

      // 1. جلب الرقم التسلسلي الأخير للمودم
      final sn = await SessionManager.getLastSN();

      // 2. تحقق من تفعيل الميزة للمودم (مع fallback بدون SN)
      bool isEnabled = await SessionManager.isBackgroundDeviceMonitorEnabled(sn);
      if (!isEnabled) {
        isEnabled = await SessionManager.isBackgroundDeviceMonitorEnabled();
      }

      if (!isEnabled) {
        debugPrint('⏸️ [BG Device Monitor] Feature disabled in settings');
        return;
      }

      // 3. جلب أو تجديد الجلسة (مع جميع الـ Fallbacks)
      String? sessionId = await SessionManager.getSessionId(sn) ?? await SessionManager.getSessionId();
      String? password = await SessionManager.getLastLoginPassword(sn) ??
          await SessionManager.getLastLoginPassword() ??
          await SessionManager.getPassword(sn) ??
          await SessionManager.getPassword();

      final client = http.Client();

      try {
        if (sessionId == null || sessionId.isEmpty) {
          if (password != null && password.isNotEmpty) {
            sessionId = await _performSilentBackgroundLogin(client, sn, password);
          }
        }

        if (sessionId == null || sessionId.isEmpty) {
          debugPrint('❌ [BG Device Monitor] No sessionId or password available');
          return;
        }

        // 4. جلب الأجهزة المتصلة
        var response = await _fetchConnectedClients(client, sessionId);

        // إذا كانت الجلسة منتهية، نحاول التجديد الصامت فوراً
        if (_isSessionExpiredResponse(response)) {
          debugPrint('🔄 [BG Device Monitor] Session expired — performing background login...');
          if (password != null && password.isNotEmpty) {
            sessionId = await _performSilentBackgroundLogin(client, sn, password);
            if (sessionId != null && sessionId.isNotEmpty) {
              response = await _fetchConnectedClients(client, sessionId);
            }
          }
        }

        if (response == null || response.statusCode != 200 || response.body.isEmpty) {
          debugPrint('⚠️ [BG Device Monitor] Empty or invalid response from modem');
          return;
        }

        final data = jsonDecode(response.body);
        if (data['clients_info'] == null) return;

        final List clients = data['clients_info'];
        final currentMacs = clients
            .map((c) => (c['mac_addr'] ?? c['mac'] ?? '').toString().toUpperCase())
            .where((mac) => mac.isNotEmpty)
            .toList();

        // 5. جلب القوائم المحفوظة للمودم (مع fallback)
        List<String> knownMacs = await SessionManager.getKnownMacs(sn);
        if (knownMacs.isEmpty) {
          knownMacs = await SessionManager.getKnownMacs();
        }

        List<String> pendingMacs = await SessionManager.getPendingMacs(sn);
        if (pendingMacs.isEmpty) {
          pendingMacs = await SessionManager.getPendingMacs();
        }

        // 6. البحث عن أجهزة جديدة غير معروفة وغير معلقة
        final newMacs = currentMacs.where((mac) =>
          !knownMacs.contains(mac) && !pendingMacs.contains(mac)
        ).toList();

        debugPrint('📱 [BG Device Monitor] Found ${currentMacs.length} total, ${newMacs.length} new devices');

        // 7. إرسال إشعارات وتحديث القائمة المعلقة
        if (newMacs.isNotEmpty) {
          final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

          const AndroidInitializationSettings initAndroid =
              AndroidInitializationSettings('@drawable/ic_notification');
          const InitializationSettings initSettings =
              InitializationSettings(android: initAndroid);
          await flutterLocalNotificationsPlugin.initialize(settings: initSettings);

          for (var mac in newMacs) {
            await SessionManager.addPendingMac(mac, sn);
            await SessionManager.addPendingMac(mac);

            final deviceInfo = clients.firstWhere(
              (c) => (c['mac_addr'] ?? c['mac'] ?? '').toString().toUpperCase() == mac,
              orElse: () => {},
            );
            final deviceName = (deviceInfo['host_name'] ?? deviceInfo['name'] ?? 'غير معروف').toString();

            final id = Random().nextInt(100000);
            const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
              'new_device_alerts_v2',
              'إشعارات الأجهزة الجديدة',
              channelDescription: 'تنبيهات عند اتصال جهاز جديد بالمودم',
              importance: Importance.max,
              priority: Priority.high,
              showWhen: true,
              playSound: true,
              enableVibration: true,
            );
            const NotificationDetails platformDetails =
                NotificationDetails(android: androidDetails);

            await flutterLocalNotificationsPlugin.show(
              id: id,
              title: 'جهاز جديد متصل!',
              body: 'تم اكتشاف جهاز جديد ($deviceName) متصل بشبكة الواي فاي.',
              notificationDetails: platformDetails,
            );
          }
        }
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Background Device Monitor Error: $e');
    }
  }

  /// طلب جلب الأجهزة المتصلة
  static Future<http.Response?> _fetchConnectedClients(http.Client client, String sessionId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final url = '$_modemBaseUrl/api.cgi?path=statistics&method=get_conn_clients_info&timeout=20&_=$timestamp';

      return await client.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json, text/javascript, */*; q=0.01',
          'X-Requested-With': 'XMLHttpRequest',
          'Cookie': 'CGISID=$sessionId',
        },
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('⚠️ [BG Device Monitor] HTTP get failed: $e');
      return null;
    }
  }

  /// فحص هل الرد يشير لانتهاء الجلسة
  static bool _isSessionExpiredResponse(http.Response? response) {
    if (response == null) return true;
    final bodyStr = response.body.toLowerCase().replaceAll(' ', '');
    return bodyStr.contains('sessionnoexist') ||
        bodyStr.contains('sessionfail') ||
        bodyStr.contains('"result":100003') ||
        bodyStr.contains('"result":125002') ||
        bodyStr.contains('login.html');
  }

  /// تسجيل دخول صامت بالخلفية باستخدام كلمة المرور المحفوظة
  static Future<String?> _performSilentBackgroundLogin(http.Client client, String? sn, String password) async {
    try {
      final userId = Random().nextInt(90000000 + 10000000).toString();
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json, text/javascript, */*; q=0.01',
        'X-Requested-With': 'XMLHttpRequest',
      };

      // 1. طلب rand
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

      // 2. طلب الدخول
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
          await SessionManager.saveSessionId(sessionId); // fallback
          await SessionManager.setLastHeartbeat(DateTime.now(), sn);
          debugPrint('🔑 [BG Silent Login] Successfully generated new session ID');
          return sessionId;
        }
      }
      return null;
    } catch (e) {
      debugPrint('🔑 [BG Silent Login] Failed: $e');
      return null;
    }
  }
}

/// تسجيل مهمة الفحص الدوري في الخلفية (كل 15 دقيقة)
Future<void> registerBackgroundDeviceMonitor() async {
  await Workmanager().registerPeriodicTask(
    "bg_device_monitor_unique",
    backgroundDeviceMonitorTask,
    frequency: const Duration(minutes: 15),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );
}

/// إلغاء مهمة الفحص الدوري
Future<void> cancelBackgroundDeviceMonitor() async {
  await Workmanager().cancelByUniqueName("bg_device_monitor_unique");
}
