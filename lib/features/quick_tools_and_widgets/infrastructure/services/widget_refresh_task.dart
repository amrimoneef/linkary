import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// اسم مهمة WorkManager لتحديث الويدجت من الضغط على زر التحديث
const String widgetRefreshTask = 'widgetRefreshTask';

/// اسم مهمة WorkManager لتحديث الويدجت عند فتح الشاشة
const String widgetScreenUnlockTask = 'widgetScreenUnlockTask';

const String _modemBase = 'http://mobile.router';
const String _appGroup  = 'group.com.sam4g.app_settings';

/// الحد الأدنى بين تحديثَين تلقائيَّين عند فتح الشاشة (3 دقائق)
const int _minAutoUpdateIntervalMs = 3 * 60 * 1000;
const String _lastAutoUpdateKey = 'widget_last_auto_update_ms';

// ══════════════════════════════════════════════════════════════════════════════
/// نقطة الدخول الوحيدة للمهمة — تُستدعى من callbackDispatcher في main.dart
// ══════════════════════════════════════════════════════════════════════════════
class WidgetRefreshTask {
  WidgetRefreshTask._();

  /// يُنفِّذ التحديث:
  ///  - [isManual] = true  → تحديث يدوي من زر التحديث (بلا rate-limit)
  ///  - [isManual] = false → تحديث تلقائي عند فتح الشاشة (مع rate-limit 3 دق)
  static Future<bool> run({bool isManual = false}) async {
    try {
      HomeWidget.setAppGroupId(_appGroup);

      // ── Rate Limit للتحديث التلقائي فقط ────────────────────────────────────
      if (!isManual) {
        final prefs = await SharedPreferences.getInstance();
        final lastMs = prefs.getInt(_lastAutoUpdateKey) ?? 0;
        final elapsed = DateTime.now().millisecondsSinceEpoch - lastMs;
        if (elapsed < _minAutoUpdateIntervalMs) {
          debugPrint('[WidgetRefresh] ⏭️ Auto-update skipped (${elapsed ~/ 1000}s < 180s)');
          return true;
        }
        await prefs.setInt(
          _lastAutoUpdateKey,
          DateTime.now().millisecondsSinceEpoch,
        );
      }

      debugPrint('[WidgetRefresh] 🔄 Fetching modem data...');

      // ── جلب البيانات من المودم بشكل متوازٍ ─────────────────────────────────
      final results = await Future.wait([
        _fetchRouterInfo(),       // حالة الاتصال + إشارة + أجهزة + سرعة
        _fetchBatteryInfo(),      // بطارية المودم
      ]);

      final router  = results[0];
      final battery = results[1];

      // ── قراءة البيانات القديمة (رصيد، أيام) من SharedPreferences ────────────
      // هذه البيانات يكتبها Flutter عند آخر تشغيل — لن نمسحها
      final prefs = await SharedPreferences.getInstance();
      final balanceVal    = prefs.getString('flutter.balance_val')    ?? '--';
      final balanceUnit   = prefs.getString('flutter.balance_unit')   ?? 'GB';
      final balanceText   = prefs.getString('flutter.balance_text')   ?? '-- GB';
      final daysRemaining = prefs.getString('flutter.days_remaining') ?? '-- يوم متبقي';
      final totalText     = prefs.getString('flutter.total_text')     ?? 'GB 0.0';
      final consumedText  = prefs.getString('flutter.consumed_text')  ?? 'GB 0.0';
      final quotaProgress = prefs.getInt('flutter.quota_progress_int') ?? 0;
      final packageName   = prefs.getString('flutter.package_name')   ?? 'باقة نشطة';

      // ── استخراج بيانات المودم الجديدة ────────────────────────────────────────
      final isConnected   = router['isConnected'] as bool? ?? false;
      final signalBars    = router['signalBars']  as int?  ?? 0;
      final signalText    = router['signalText']  as String? ?? 'غير متصل';
      final devicesCount  = router['devicesCount'] as int? ?? 0;
      final networkSpeed  = router['networkSpeed'] as String? ?? '0 KB/s';
      final batteryLevel  = battery['capacity']   as int?  ?? 0;
      final isCharging    = battery['isCharging'] as bool? ?? false;

      // ── توقيت التحديث ─────────────────────────────────────────────────────
      final now = DateTime.now();
      final hour   = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      final minute = now.minute.toString().padLeft(2, '0');
      final period = now.hour >= 12 ? 'م' : 'ص';
      final timeStr = '$hour:$minute $period';

      // ── كتابة كل البيانات دفعةً واحدة ───────────────────────────────────────
      await Future.wait([
        HomeWidget.saveWidgetData<bool>  ('is_connected',       isConnected),
        HomeWidget.saveWidgetData<int>   ('battery_level',      batteryLevel),
        HomeWidget.saveWidgetData<bool>  ('is_charging',        isCharging),
        HomeWidget.saveWidgetData<int>   ('signal_bars',        signalBars),
        HomeWidget.saveWidgetData<String>('signal_text',        signalText),
        HomeWidget.saveWidgetData<int>   ('devices_count',      devicesCount),
        HomeWidget.saveWidgetData<String>('network_speed',      networkSpeed),
        HomeWidget.saveWidgetData<String>('last_updated_time',  timeStr),
        // نُعيد كتابة بيانات الرصيد حتى لا تختفي عند إعادة الرسم
        HomeWidget.saveWidgetData<String>('balance_val',        balanceVal),
        HomeWidget.saveWidgetData<String>('balance_unit',       balanceUnit),
        HomeWidget.saveWidgetData<String>('balance_text',       balanceText),
        HomeWidget.saveWidgetData<String>('days_remaining',     daysRemaining),
        HomeWidget.saveWidgetData<String>('total_text',         totalText),
        HomeWidget.saveWidgetData<String>('consumed_text',      consumedText),
        HomeWidget.saveWidgetData<int>   ('quota_progress_int', quotaProgress),
        HomeWidget.saveWidgetData<String>('package_name',       packageName),
      ]);

      // ── إعادة رسم الويدجت ────────────────────────────────────────────────────
      await Future.wait([
        HomeWidget.updateWidget(androidName: 'WidgetSmallProvider'),
        HomeWidget.updateWidget(androidName: 'WidgetBannerProvider'),
        HomeWidget.updateWidget(androidName: 'WidgetDetailedProvider'),
      ]);

      debugPrint('[WidgetRefresh] ✅ Done — connected=$isConnected, battery=$batteryLevel%, devices=$devicesCount');
      return true;
    } catch (e) {
      debugPrint('[WidgetRefresh] ❌ Error: $e');
      return false;
    }
  }

  // ── استدعاء API المودم ───────────────────────────────────────────────────

  /// جلب معلومات الراوتر: حالة الاتصال، الإشارة، الأجهزة، السرعة
  static Future<Map<String, dynamic>> _fetchRouterInfo() async {
    try {
      final response = await http.post(
        Uri.parse('$_modemBase/api.cgi?path=router&method=get_status&timeout=5'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
        body: jsonEncode({
          "requests": [
            {"path": "router", "method": "get_status"}
          ]
        }),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final raw = jsonDecode(response.body);
        // يدعم استجابة مباشرة أو مغلّفة في responses[]
        final data = raw['responses'] != null
            ? (raw['responses'] as List).isNotEmpty
                ? raw['responses'][0]['data'] ?? raw['responses'][0]
                : raw
            : raw;

        final signalLevel = int.tryParse(data['signalLevel']?.toString()  ??
                                         data['signal_level']?.toString() ??
                                         data['rsrp']?.toString() ?? '0') ?? 0;

        final clampedSignal = signalLevel.clamp(0, 5);

        final networkType = (data['networkType']?.toString() ??
                             data['network_type']?.toString() ?? '4G').toUpperCase();

        final devCount = int.tryParse(
              data['connectedDeviceCount']?.toString() ??
              data['connected_device_count']?.toString() ??
              data['deviceCount']?.toString() ?? '0') ?? 0;

        // السرعة (bytes/s → KB/s أو MB/s)
        final rxSpeed = int.tryParse(data['rxSpeed']?.toString() ??
                                     data['rx_speed']?.toString() ?? '0') ?? 0;
        final speedStr = _formatSpeed(rxSpeed);

        // حالة الاتصال
        final connStatus = data['connectionStatus']?.toString() ??
                           data['connection_status']?.toString() ??
                           data['wanStatus']?.toString() ?? '';
        final isConn = connStatus.toLowerCase().contains('connect') ||
                       connStatus == '1' ||
                       connStatus == 'true';

        return {
          'isConnected':  isConn,
          'signalBars':   clampedSignal,
          'signalText':   '$networkType • $clampedSignal/5',
          'devicesCount': devCount,
          'networkSpeed': speedStr,
        };
      }
    } catch (_) {}
    // fallback: ping بسيط لمعرفة الاتصال فقط
    return _simplePing();
  }

  /// Ping بسيط فقط للتحقق من الاتصال عند فشل API الرئيسي
  static Future<Map<String, dynamic>> _simplePing() async {
    try {
      final response = await http.post(
        Uri.parse('$_modemBase/api.cgi?path=router&method=get_sys_time&timeout=3'),
        headers: {'X-Requested-With': 'XMLHttpRequest'},
        body: jsonEncode({"requests": [{"path": "router", "method": "get_sys_time"}]}),
      ).timeout(const Duration(seconds: 4));
      final isOk = response.statusCode >= 200 && response.statusCode < 300;
      return {'isConnected': isOk, 'signalBars': 0, 'signalText': isOk ? '4G • ?/5' : 'غير متصل', 'devicesCount': 0, 'networkSpeed': '0 KB/s'};
    } catch (_) {
      return {'isConnected': false, 'signalBars': 0, 'signalText': 'غير متصل', 'devicesCount': 0, 'networkSpeed': '0 KB/s'};
    }
  }

  /// جلب معلومات بطارية المودم
  static Future<Map<String, dynamic>> _fetchBatteryInfo() async {
    try {
      final response = await http.post(
        Uri.parse('$_modemBase/api.cgi?path=aoc&method=get_bat_info&timeout=5'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
        body: jsonEncode({
          "requests": [
            {"path": "aoc", "method": "get_bat_info"}
          ]
        }),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final raw = jsonDecode(response.body);
        final data = raw['responses'] != null
            ? (raw['responses'] as List).isNotEmpty
                ? raw['responses'][0]['data'] ?? {}
                : {}
            : raw;

        final capacity  = int.tryParse(data['capacity']?.toString() ?? '0') ?? 0;
        final status    = int.tryParse(data['status']?.toString()   ?? '0') ?? 0;
        return {
          'capacity':   capacity,
          'isCharging': status == 1,
        };
      }
    } catch (_) {}
    return {'capacity': 0, 'isCharging': false};
  }

  /// تحويل السرعة من bytes/s إلى نص مقروء
  static String _formatSpeed(int bytesPerSec) {
    if (bytesPerSec <= 0)          return '0 KB/s';
    if (bytesPerSec < 1024 * 1024) return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(2)} MB/s';
  }
}
