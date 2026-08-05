import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../../../features/modem_auth/presentation/controllers/auth_controller.dart';
import '../models/url_filter_model.dart';

abstract class UrlFilterRemoteDataSource {
  Future<UrlFilterModel> fetchUrlFilterData();
  Future<bool> saveUrlFilter(String mode, List<String> blackItems);
}

class UrlFilterRemoteDataSourceImpl implements UrlFilterRemoteDataSource {
  final http.Client client;
  final String baseUrl = 'http://mobile.router';

  UrlFilterRemoteDataSourceImpl({required this.client});

  Map<String, String> _getHeaders(String sessionId) => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'X-Requested-With': 'XMLHttpRequest',
    'Cookie': 'CGISID=$sessionId',
    'reset_time': '1',
  };

  @override
  Future<UrlFilterModel> fetchUrlFilterData() async {
    final sessionId = Get.find<AuthController>().currentUser?.sessionId;
    if (sessionId == null) throw Exception('الجلسة منتهية.');

    final time = DateTime.now().millisecondsSinceEpoch;
    final url = '$baseUrl/api.cgi?path=firewall&method=get_url_filter&timeout=20&_=$time';
    
    final response = await client.get(Uri.parse(url), headers: _getHeaders(sessionId));
    
    if (response.statusCode == 200) {
      return UrlFilterModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('فشل في جلب إعدادات حظر المواقع');
    }
  }

  @override
  Future<bool> saveUrlFilter(String mode, List<String> blackItems) async {
    final sessionId = Get.find<AuthController>().currentUser?.sessionId;
    if (sessionId == null) throw Exception('الجلسة منتهية.');

    final url = '$baseUrl/api.cgi?path=firewall&method=set_url_filter&timeout=20';

    // The API requires exactly 10 items in the array, formatted with index and value.
    List<Map<String, dynamic>> blackItemsList = [];
    for (int i = 0; i < 10; i++) {
      blackItemsList.add({
        "value": i < blackItems.length ? blackItems[i] : "",
        "index": i
      });
    }

    Map<String, dynamic> payload = {
      "mode": mode,
      "black_items": blackItemsList
    };

    final response = await client.post(
      Uri.parse(url),
      headers: _getHeaders(sessionId),
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['result'] == 0;
    }
    return false;
  }
}
