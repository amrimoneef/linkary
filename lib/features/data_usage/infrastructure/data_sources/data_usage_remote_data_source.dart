import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../../../features/modem_auth/presentation/controllers/auth_controller.dart';
import '../models/data_usage_model.dart';

abstract class DataUsageRemoteDataSource {
  Future<DataUsageModel> fetchDataUsage();
  Future<bool> savePackageSettings(String type, int bytes);
  Future<bool> calibrateDataUsed(int bytes);
}

class DataUsageRemoteDataSourceImpl implements DataUsageRemoteDataSource {
  final http.Client client;
  final String baseUrl = 'http://mobile.router'; // http://192.168.8.1 أو

  DataUsageRemoteDataSourceImpl({required this.client});

  Map<String, String> _getHeaders(String sessionId) => {
    'Accept': 'application/json', 'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest', 'Cookie': 'CGISID=$sessionId',
    'reset_time': '1',
  };

  @override
  Future<DataUsageModel> fetchDataUsage() async {
    final sessionId = Get.find<AuthController>().currentUser?.sessionId;
    if (sessionId == null) throw Exception('الجلسة منتهية.');

    final url = '$baseUrl/api.cgi?path=package&method=get_package_settings&timeout=20&_=${DateTime.now().millisecondsSinceEpoch}';
    final response = await client.get(Uri.parse(url), headers: _getHeaders(sessionId));

    if (response.body.contains("session no exist")) throw Exception('SESSION_EXPIRED');
    return DataUsageModel.fromJson(jsonDecode(response.body));
  }

  @override
  Future<bool> savePackageSettings(String type, int bytes) async {
    final sessionId = Get.find<AuthController>().currentUser?.sessionId;
    if (sessionId == null) throw Exception('الجلسة منتهية.');

    final url = '$baseUrl/api.cgi?path=package&method=set_package_settings&timeout=20';

    // 🚀 الـ Payload الذي اصطدته أنت
    final payload = {
      "package_type": type,
      "alarm_threshold": 0,
      "package_data_unlimited": {
        "package_data": bytes.toString() // إرسال البايتات كنص
      }
    };

    final response = await client.post(Uri.parse(url), headers: _getHeaders(sessionId), body: jsonEncode(payload));
    return jsonDecode(response.body)['result'] == 0;
  }

  @override
  Future<bool> calibrateDataUsed(int bytes) async {
    final sessionId = Get.find<AuthController>().currentUser?.sessionId;
    if (sessionId == null) throw Exception('الجلسة منتهية.');

    final url = '$baseUrl/api.cgi?path=package&method=set_package_data_used&timeout=20';

    final payload = {
      "data_used": bytes.toString()
    };

    final response = await client.post(Uri.parse(url), headers: _getHeaders(sessionId), body: jsonEncode(payload));
    return jsonDecode(response.body)['result'] == 0;
  }
}