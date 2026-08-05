import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../../../features/modem_auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/parental_control_entity.dart';

abstract class ParentalControlRemoteDataSource {
  Future<bool> getParentalControlStatus();
  Future<bool> setParentalControlStatus(bool isEnabled);
  Future<List<ParentalDevice>> getParentalDevices();
  Future<bool> saveParentalRule(String mac, int startTime, int endTime, int repeatMode, int index);
  Future<bool> deleteParentalRule(String mac);
}

class ParentalControlRemoteDataSourceImpl implements ParentalControlRemoteDataSource {
  final http.Client client;
  final String baseUrl = 'http://mobile.router'; // http://192.168.8.1 أو

  ParentalControlRemoteDataSourceImpl({required this.client});

  Map<String, String> _getHeaders(String sessionId) => {
    'Accept': 'application/json', 'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest', 'Cookie': 'CGISID=$sessionId',
    'reset_time': '1',
  };

  @override
  Future<bool> getParentalControlStatus() async {
    final sessionId = Get.find<AuthController>().currentUser?.sessionId;
    if (sessionId == null) throw Exception('الجلسة منتهية');

    final res = await client.get(Uri.parse('$baseUrl/api.cgi?path=firewall&method=get_parental_control_enable&timeout=20&_=${DateTime.now().millisecondsSinceEpoch}'), headers: _getHeaders(sessionId));
    return jsonDecode(res.body)['pctrl_enable'] == 1;
  }

  @override
  Future<bool> setParentalControlStatus(bool isEnabled) async {
    final sessionId = Get.find<AuthController>().currentUser?.sessionId;
    if (sessionId == null) throw Exception('الجلسة منتهية');

    final payload = {"pctrl_enable": isEnabled ? 1 : 0};
    final res = await client.post(Uri.parse('$baseUrl/api.cgi?path=firewall&method=set_parental_control_enable&timeout=20'), headers: _getHeaders(sessionId), body: jsonEncode(payload));
    return jsonDecode(res.body)['result'] == 0;
  }

  @override
  Future<List<ParentalDevice>> getParentalDevices() async {
    final sessionId = Get.find<AuthController>().currentUser?.sessionId;
    if (sessionId == null) throw Exception('الجلسة منتهية');

    final res = await client.get(Uri.parse('$baseUrl/api.cgi?path=firewall&method=get_parental_control_list&timeout=20&_=${DateTime.now().millisecondsSinceEpoch}'), headers: _getHeaders(sessionId));
    final data = jsonDecode(res.body);

    if (data['pctrl_list'] == null) return [];

    return (data['pctrl_list'] as List).map((dev) {
      List<TimeSlot> slots = (dev['items'] as List).map((s) => TimeSlot(
          index: s['index'], startTime: s['start_time'], endTime: s['end_time'], repeatMode: s['repeat_mode']
      )).toList();
      return ParentalDevice(mac: dev['mac'], name: dev['name'], timeSlots: slots);
    }).toList();
  }

  // 🚀 ضربتك القاضية (Multicalls)
  @override
  Future<bool> saveParentalRule(String mac, int startTime, int endTime, int repeatMode, int index) async {
    final sessionId = Get.find<AuthController>().currentUser?.sessionId;
    if (sessionId == null) throw Exception('الجلسة منتهية');

    final url = '$baseUrl/api.cgi?multicalls=1&timeout=20';
    final payload = {
      "requests": [
        {
          "path": "firewall",
          "method": "update_parental_user_item", // الدالة التي اصطدتها
          "data": {
            "mac": mac,
            "start_time": startTime,
            "end_time": endTime,
            "repeat_mode": repeatMode,
            "index": index
          }
        }
      ]
    };

    final res = await client.post(Uri.parse(url), headers: _getHeaders(sessionId), body: jsonEncode(payload));
    final data = jsonDecode(res.body);
    return data['responses']?[0]?['data']?['result'] == 0;
  }

  @override
  Future<bool> deleteParentalRule(String mac) async {
    final sessionId = Get.find<AuthController>().currentUser?.sessionId;
    if (sessionId == null) throw Exception('الجلسة منتهية');

    final url = '$baseUrl/api.cgi?multicalls=1&timeout=20';
    final payload = {
      "requests": [
        {
          "path": "firewall",
          "method": "clear_parental_user_items",
          "data": {"mac": mac}
        }
      ]
    };

    final res = await client.post(Uri.parse(url), headers: _getHeaders(sessionId), body: jsonEncode(payload));
    final data = jsonDecode(res.body);
    return data['responses']?[0]?['data']?['result'] == 0;
  }
}