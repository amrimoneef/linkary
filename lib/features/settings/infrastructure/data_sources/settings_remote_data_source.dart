import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../../../features/modem_auth/presentation/controllers/auth_controller.dart';
import '../models/wifi_settings_model.dart';

abstract class SettingsRemoteDataSource {
  Future<WifiSettingsModel> fetchWifiSettings();
  Future<bool> saveWifiSettings(String ssid, String password, bool isWifiEnabled, bool isBroadcastEnabled,
      int maxClients, String channel, String encryption);
  Future<bool> changeAdminPassword(String newPassword);
}

class SettingsRemoteDataSourceImpl implements SettingsRemoteDataSource {
  final http.Client client;
  final String baseUrl = 'http://mobile.router'; // http://192.168.8.1 أو

  SettingsRemoteDataSourceImpl({required this.client});

  @override
  Future<WifiSettingsModel> fetchWifiSettings() async {
    final sessionId = Get.find<AuthController>().currentUser?.sessionId;
    if (sessionId == null || sessionId.isEmpty) throw Exception('الجلسة منتهية.');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // مسار الـ GET الذي التقطته تماماً
    final url = '$baseUrl/api.cgi?path=wireless&method=wifi_get_detail&timeout=20&_=$timestamp';

    final response = await client.get(
      Uri.parse(url),
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'Cookie': 'CGISID=$sessionId',
      },
    );

    if (response.statusCode != 200 || response.body.isEmpty) {
      throw Exception('فشل الاتصال بالمودم.');
    }

    // حماية الجلسة
    if (response.body.contains("session no exist")) {
      throw Exception('SESSION_EXPIRED');
    }

    return WifiSettingsModel.fromJson(jsonDecode(response.body));
  }

  @override
  Future<bool> saveWifiSettings(
      String ssid, String password, bool isWifiEnabled, bool isBroadcastEnabled,
      int maxClients, String channel, String encryption) async {

    final sessionId = Get.find<AuthController>().currentUser?.sessionId;
    if (sessionId == null) throw Exception('الجلسة منتهية.');

    final url = '$baseUrl/api.cgi?path=wireless&method=wifi_set_2.4g&timeout=20';

    final payload = {
      "wifi_device": "0",
      "wifi_if_24G": {
        "switch": isWifiEnabled ? "on" : "off",
        "channel": channel,
        "ssid": ssid,
        "encryption": encryption,
        "key": password,
        "hidden": isBroadcastEnabled ? "0" : "1",
        "maxassoc": maxClients.toString(),
      }
    };

    final response = await client.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'Cookie': 'CGISID=$sessionId',
      },
      body: jsonEncode(payload),
    );

    final data = jsonDecode(response.body);
    return data['wireless']?['setting_response'] == 'OK';
  }

  // ➕ دالة تغيير كلمة مرور المودم (الإدمن)
  @override
  Future<bool> changeAdminPassword(String newPassword) async {
    final sessionId = Get.find<AuthController>().currentUser?.sessionId;
    if (sessionId == null) throw Exception('الجلسة منتهية.');

    final url = '$baseUrl/api.cgi?path=account&method=set_info&timeout=20';

    final payload = {
      "type": "admin",
      "password": newPassword
    };

    final response = await client.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'Cookie': 'CGISID=$sessionId',
        'reset_time': '1',
      },
      body: jsonEncode(payload),
    );

    final data = jsonDecode(response.body);
    return data['result'] == 0;
  }
}