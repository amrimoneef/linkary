import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../../../features/modem_auth/presentation/controllers/auth_controller.dart';
import '../models/device_data_limit_model.dart';

abstract class DeviceDataLimitRemoteDataSource {
  Future<bool> getEnableStatus();
  Future<bool> setEnableStatus(bool enable);
  Future<List<DeviceDataLimitModel>> getLimitList();
  Future<bool> addLimitItem(String mac, int quotaBytes, String comment);
  Future<bool> updateLimitItem(int index, String mac, int quotaBytes, String comment);
  Future<bool> deleteLimitItem(String mac);
}

class DeviceDataLimitRemoteDataSourceImpl implements DeviceDataLimitRemoteDataSource {
  final http.Client client;
  final String baseUrl = 'http://mobile.router';

  DeviceDataLimitRemoteDataSourceImpl({required this.client});

  Map<String, String> _getHeaders(String sessionId) => {
    'Accept': 'application/json, text/javascript, */*; q=0.01',
    'Cache-Control': 'no-store, no-cache, must-revalidate',
    'Content-Type': 'application/json',
    'Expires': '-1',
    'Pragma': 'no-cache',
    'Referer': '$baseUrl/index.html',
    'X-Requested-With': 'XMLHttpRequest',
    'Cookie': 'CGISID=$sessionId', // Or sessionid based on how auth controller works, but mac filter uses CGISID=$sessionId. Let's use the standard from AuthController if possible, else stick to standard headers.
    'reset_time': '1',
  };
  
  String get _sessionId {
    final sessionId = Get.find<AuthController>().currentUser?.sessionId;
    if (sessionId == null) throw Exception('الجلسة منتهية.');
    return sessionId;
  }

  @override
  Future<bool> getEnableStatus() async {
    final time = DateTime.now().millisecondsSinceEpoch;
    final url = '$baseUrl/api.cgi?path=statistics&method=get_user_data_limit_enable&timeout=20&_=$time';
    
    final response = await client.get(Uri.parse(url), headers: _getHeaders(_sessionId));
    final data = jsonDecode(response.body);
    return data['enable'] == 1;
  }

  @override
  Future<bool> setEnableStatus(bool enable) async {
    final url = '$baseUrl/api.cgi?path=statistics&method=set_user_data_limit_enable&timeout=20';
    
    Map<String, dynamic> payload = {
      "enable": enable ? 1 : 0,
    };

    final response = await client.post(
      Uri.parse(url), 
      headers: _getHeaders(_sessionId), 
      body: jsonEncode(payload)
    );
    final data = jsonDecode(response.body);
    return data['result'] == 0;
  }

  @override
  Future<List<DeviceDataLimitModel>> getLimitList() async {
    final time = DateTime.now().millisecondsSinceEpoch;
    final url = '$baseUrl/api.cgi?path=statistics&method=get_user_data_limit_list&timeout=20&_=$time';
    
    final response = await client.get(Uri.parse(url), headers: _getHeaders(_sessionId));
    final data = jsonDecode(response.body);
    
    if (data['user_list'] != null) {
      return (data['user_list'] as List)
          .map((item) => DeviceDataLimitModel.fromJson(item))
          .toList();
    }
    return [];
  }

  @override
  Future<bool> addLimitItem(String mac, int quotaBytes, String comment) async {
    final url = '$baseUrl/api.cgi?path=statistics&method=add_user_data_limit_item&timeout=20';
    
    Map<String, dynamic> payload = {
      "mac": mac,
      "quota": quotaBytes.toString(),
      "comment": comment,
    };

    final response = await client.post(
      Uri.parse(url), 
      headers: _getHeaders(_sessionId), 
      body: jsonEncode(payload)
    );
    final data = jsonDecode(response.body);
    return data['result'] == 0;
  }

  @override
  Future<bool> updateLimitItem(int index, String mac, int quotaBytes, String comment) async {
    final url = '$baseUrl/api.cgi?path=statistics&method=update_user_data_limit_item&timeout=20';
    
    Map<String, dynamic> payload = {
      "index": index,
      "mac": mac,
      "quota": quotaBytes.toString(),
      "comment": comment,
    };

    final response = await client.post(
      Uri.parse(url), 
      headers: _getHeaders(_sessionId), 
      body: jsonEncode(payload)
    );
    final data = jsonDecode(response.body);
    return data['result'] == 0;
  }

  @override
  Future<bool> deleteLimitItem(String mac) async {
    final url = '$baseUrl/api.cgi?path=statistics&method=delete_user_data_limit_item&timeout=20';
    
    Map<String, dynamic> payload = {
      "mac": mac,
    };

    final response = await client.post(
      Uri.parse(url), 
      headers: _getHeaders(_sessionId), 
      body: jsonEncode(payload)
    );
    final data = jsonDecode(response.body);
    return data['result'] == 0;
  }
}
