import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../../../features/modem_auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/speed_limit_entity.dart';
import '../models/speed_limit_model.dart';

abstract class SpeedLimitRemoteDataSource {
  Future<SpeedLimitModel> fetchSpeedLimit();
  Future<bool> saveSpeedLimit(bool isEnabled, int mode, int uploadSpeed, int downloadSpeed, List<SpeedLimitItem> items);
}

class SpeedLimitRemoteDataSourceImpl implements SpeedLimitRemoteDataSource {
  final http.Client client;
  final String baseUrl = 'http://mobile.router'; // http://192.168.8.1 أو

  SpeedLimitRemoteDataSourceImpl({required this.client});

  Map<String, String> _getHeaders(String sessionId) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest',
    'Cookie': 'CGISID=$sessionId',
    'reset_time': '1', // 🚀 الفخ السري الذي اكتشفته!
  };

  @override
  Future<SpeedLimitModel> fetchSpeedLimit() async {
    final sessionId = Get.find<AuthController>().currentUser?.sessionId;
    if (sessionId == null) throw Exception('الجلسة منتهية.');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = '$baseUrl/api.cgi?path=statistics&method=get_speed_limit&timeout=20&_=$timestamp';

    final response = await client.get(Uri.parse(url), headers: _getHeaders(sessionId));
    if (response.body.contains("session no exist")) throw Exception('SESSION_EXPIRED');

    return SpeedLimitModel.fromJson(jsonDecode(response.body));
  }

  @override
  Future<bool> saveSpeedLimit(bool isEnabled, int mode, int uploadSpeed, int downloadSpeed, List<SpeedLimitItem> items) async {
    final sessionId = Get.find<AuthController>().currentUser?.sessionId;
    if (sessionId == null) throw Exception('الجلسة منتهية.');

    final url = '$baseUrl/api.cgi?path=statistics&method=set_speed_limit&timeout=20';

    // 🚀 بناء الـ Payload الذكي بناءً على النمط
    Map<String, dynamic> payload = {
      "enable": isEnabled ? 1 : 0,
      "mode": mode,
    };

    if (mode == 1) {
      payload["all_dl_speed"] = downloadSpeed.toString();
      payload["all_up_speed"] = uploadSpeed.toString();
      payload["items"] = []; // مصفوفة فارغة للنمط العام
    } else if (mode == 2) {
      payload["items"] = items.map((e) => e.toJson()).toList(); // بيانات الأجهزة المحددة
    }

    final response = await client.post(
        Uri.parse(url),
        headers: _getHeaders(sessionId),
        body: jsonEncode(payload)
    );

    final data = jsonDecode(response.body);
    return data['result'] == 0;
  }
}