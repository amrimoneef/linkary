import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../../../features/modem_auth/presentation/controllers/auth_controller.dart';
import '../models/connected_device_model.dart';

abstract class ConnectedDevicesRemoteDataSource {
  Future<List<ConnectedDeviceModel>> fetchConnectedDevices();
}

class ConnectedDevicesRemoteDataSourceImpl implements ConnectedDevicesRemoteDataSource {
  final http.Client client;
  final String baseUrl = 'http://mobile.router'; // http://192.168.8.1 أو

  ConnectedDevicesRemoteDataSourceImpl({required this.client});

  @override
  Future<List<ConnectedDeviceModel>> fetchConnectedDevices() async {
    // 1. جلب الجلسة الحالية
    final authController = Get.find<AuthController>();
    final sessionId = authController.currentUser?.sessionId;

    if (sessionId == null || sessionId.isEmpty) {
      throw Exception('SESSION_EXPIRED');
    }

    // تجهيز الترويسات مع إضافة الـ Cookie الإجباري
    final headers = {
      'Accept': 'application/json, text/javascript, */*; q=0.01',
      'X-Requested-With': 'XMLHttpRequest',
      'Cookie': 'CGISID=$sessionId', // السحر يكمن هنا!
    };

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = '$baseUrl/api.cgi?path=statistics&method=get_conn_clients_info&timeout=20&_=$timestamp';

    try {
      // استخدمنا GET كما ظهر في الـ cURL
      final response = await client.get(Uri.parse(url), headers: headers);

      if (response.statusCode != 200 || response.body.isEmpty) {
        throw Exception('فشل في الاتصال بالمودم.');
      }

      final data = jsonDecode(response.body);

      // التأكد من وجود المصفوفة
      if (data['clients_info'] != null) {
        final List clients = data['clients_info'];
        // تحويل المصفوفة إلى قائمة من النماذج
        return clients.map((json) => ConnectedDeviceModel.fromJson(json)).toList();
      }

      return []; // إرجاع قائمة فارغة إذا لم يكن هناك أجهزة
    } catch (e) {
      throw Exception('تعذر جلب قائمة الأجهزة: $e');
    }
  }
}