import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../../../features/modem_auth/presentation/controllers/auth_controller.dart';
import '../models/mac_filter_model.dart';

abstract class MacFilterRemoteDataSource {
  Future<MacFilterModel> fetchMacFilterData();
  Future<bool> saveMacFilter(String mode, List<String> allowList, List<String> denyList);
}

class MacFilterRemoteDataSourceImpl implements MacFilterRemoteDataSource {
  final http.Client client;
  final String baseUrl = 'http://mobile.router'; // http://192.168.8.1 أو

  MacFilterRemoteDataSourceImpl({required this.client});

  Map<String, String> _getHeaders(String sessionId) => {
    'Accept': 'application/json', 'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest', 'Cookie': 'CGISID=$sessionId',
    'reset_time': '1',
  };

  @override
  Future<MacFilterModel> fetchMacFilterData() async {
    final sessionId = Get.find<AuthController>().currentUser?.sessionId;
    if (sessionId == null) throw Exception('الجلسة منتهية.');

    final time = DateTime.now().millisecondsSinceEpoch;

    // 1. جلب بيانات المرشح
    final filterUrl = '$baseUrl/api.cgi?path=wireless&method=wifi_get_mac_filter&timeout=20&_=$time';
    final filterRes = await client.get(Uri.parse(filterUrl), headers: _getHeaders(sessionId));

    // 2. جلب الـ MAC الخاص بالمودم
    final macUrl = '$baseUrl/api.cgi?path=router&method=get_mac_info&timeout=20&_=${time + 1}';
    final macRes = await client.get(Uri.parse(macUrl), headers: _getHeaders(sessionId));

    return MacFilterModel.fromJson(jsonDecode(filterRes.body), jsonDecode(macRes.body));
  }

  @override
  Future<bool> saveMacFilter(String mode, List<String> allowList, List<String> denyList) async {
    final sessionId = Get.find<AuthController>().currentUser?.sessionId;
    if (sessionId == null) throw Exception('الجلسة منتهية.');

    final url = '$baseUrl/api.cgi?path=wireless&method=wifi_set_mac_filter&timeout=20';

    // 🚀 بناء الـ Payload السري
    Map<String, dynamic> payload = {
      "wifi_device": "0",
      "macfilter": mode,
    };

    if (mode == 'deny') {
      payload["maclist_deny"] = denyList.join(' ');
    } else if (mode == 'allow') {
      payload["maclist_allow"] = allowList.join(' ');
    }

    final response = await client.post(Uri.parse(url), headers: _getHeaders(sessionId), body: jsonEncode(payload));
    return jsonDecode(response.body)['wireless']?['setting_response'] == 'OK';
  }
}