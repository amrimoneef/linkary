import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/admin_settings_model.dart';

abstract class AdminRemoteDataSource {
  Future<AdminSettingsModel> getAdminSettings(String sessionId);
  Future<void> setAdminSettings({
    required String sessionId,
    required String username,
    required String password,
    required String totalTime,
    required String lcdPw,
    required int sleepTime,
  });
}

class AdminRemoteDataSourceImpl implements AdminRemoteDataSource {
  final http.Client client;
  final String baseUrl = 'http://mobile.router';

  AdminRemoteDataSourceImpl({required this.client});

  Map<String, String> _headers(String sessionId) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json, text/javascript, */*; q=0.01',
    'X-Requested-With': 'XMLHttpRequest',
    'Cookie': 'CGISID=$sessionId',
  };

  @override
  Future<AdminSettingsModel> getAdminSettings(String sessionId) async {
    final url = '$baseUrl/api.cgi?multicalls=1&timeout=20';
    final payload = {
      "requests": [
        {"path": "account", "method": "get_info", "data": {"type": "admin", "session_id": sessionId}},
        {"path": "aoc", "method": "sleep_wait_time"},
        {"path": "router", "method": "get_simcard_type"},
        {"path": "router", "method": "get_lcd_pw"}
      ]
    };

    final response = await client.post(
      Uri.parse(url),
      headers: _headers(sessionId),
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return AdminSettingsModel.fromJson(json);
    } else {
      throw Exception('Failed to load admin settings');
    }
  }

  @override
  Future<void> setAdminSettings({
    required String sessionId,
    required String username,
    required String password,
    required String totalTime,
    required String lcdPw,
    required int sleepTime,
  }) async {
    final url = '$baseUrl/api.cgi?multicalls=1&timeout=20&_=setAdmin';
    final payload = {
      "requests": [
        {
          "path": "account",
          "method": "set_info",
          "data": {
            "type": "admin",
            "username": username,
            "password": password,
            "total_time": totalTime
          }
        },
        {
          "path": "router",
          "method": "set_lcd_pw",
          "data": {"lcd_pw": lcdPw}
        },
        {
          "path": "aoc",
          "method": "set_sleep_wait_time",
          "data": {"time": sleepTime}
        }
      ]
    };

    final response = await client.post(
      Uri.parse(url),
      headers: {
        ..._headers(sessionId),
        'reset_time': '1',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update admin settings');
    }
    
    final data = jsonDecode(response.body);
    if (data['responses'] == null || data['responses'].any((r) => r['data']['result'] != 0)) {
       // Note: set_lcd_pw or others might return result 0 for success.
       // Based on user response: {"responses":[{"data":{"result":0}},{"data":{"result":0}},{"data":{"result":0}}]}
    }
  }
}
