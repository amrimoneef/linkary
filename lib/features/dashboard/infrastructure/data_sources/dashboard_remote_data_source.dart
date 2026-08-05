import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../../../../features/modem_auth/presentation/controllers/auth_controller.dart';
import '../models/dashboard_model.dart';
import '../models/engineering_info_model.dart';

abstract class DashboardRemoteDataSource {
  Future<DashboardModel> fetchDashboardData();
  Future<EngineeringInfoModel> fetchEngineeringInfo();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final http.Client client;
  final String baseUrl = 'http://mobile.router'; // http://192.168.8.1 أو

  DashboardRemoteDataSourceImpl({required this.client});

  Map<String, String> getHeaders(String sessionId) => {
    'Content-Type': 'application/json',
    'Accept': 'application/json, text/javascript, */*; q=0.01',
    'X-Requested-With': 'XMLHttpRequest',
    'Cookie': 'CGISID=$sessionId',
  };

  @override
  Future<DashboardModel> fetchDashboardData() async {
    // 1. جلب Session ID من الـ AuthController
    final authController = Get.find<AuthController>();
    final sessionId = authController.currentUser?.sessionId;

    if (sessionId == null || sessionId.isEmpty) {
      throw Exception('SESSION_EXPIRED');
    }

    // إضافة طابع زمني لكسر الكاش
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = '$baseUrl/api.cgi?multicalls=1&timeout=20&_=$timestamp';

    // 2. تجهيز الـ Payload كما اكتشفناه في الهندسة العكسية
    final payload = {
      "session_id": sessionId,
      "requests": [
        {"path": "cm", "method": "get_link_context", "timeout": "10"},
        {"path": "router", "method": "get_sys_time", "timeout": "10"},
        {"path": "aoc", "method": "get_bat_info", "timeout": "2"},
        {"path": "router", "method": "get_phone_no", "timeout": "10"},
        {"path": "statistics", "method": "stat_get_traffic_transport_status", "timeout": "10"},
        {"path": "statistics", "method": "stat_get_common_data", "timeout": "10"},
        // يمكننا إضافة get_sys_time هنا لاحقاً إذا أردنا عرض وقت المودم
      ]
    };

    try {
      final response = await client.post(
        Uri.parse(url),
        headers: getHeaders(sessionId),
        body: jsonEncode(payload),
      );

      // print("📡 رد المودم الخام: ${response.body}");

      // 🔍 طبقة أمان ثانوية — الفحص المركزي الدقيق يتم في ApiClient
      final bodyStr = response.body.toLowerCase().replaceAll(' ', '');
      if (bodyStr.contains('sessionnoexist') || 
          bodyStr.contains('anotheruser') ||
          bodyStr.contains('login.html')) {
        throw Exception('SESSION_EXPIRED');
      }

      // التأكد من أن الرد ليس فارغاً
      if (response.body.trim().isEmpty) {
        throw Exception('المودم لم يرسل أي بيانات.');
      }

      final data = jsonDecode(response.body);

      // 3. تحويل الـ JSON إلى Model
      return DashboardModel.fromJson(data);

    } catch (e) {
      if (e.toString().contains('SESSION_EXPIRED')) rethrow;
      throw Exception('تعذر جلب بيانات الشبكة: $e');
    }
  }

  @override
  Future<EngineeringInfoModel> fetchEngineeringInfo() async {
    final authController = Get.find<AuthController>();
    final sessionId = authController.currentUser?.sessionId;

    if (sessionId == null || sessionId.isEmpty) {
      throw Exception('SESSION_EXPIRED');
    }

    final headers = {
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
      'Cookie': 'CGISID=$sessionId',
    };

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = '$baseUrl/api.cgi?path=cm&method=query_eng_info&timeout=20&_=$timestamp';

    try {
      final response = await client.get(Uri.parse(url), headers: headers);
      final data = jsonDecode(response.body);

      // 🔍 طبقة أمان ثانوية
      final bodyStr = response.body.toLowerCase().replaceAll(' ', '');
      if (bodyStr.contains('sessionnoexist') ||
          bodyStr.contains('login.html')) {
        throw Exception('SESSION_EXPIRED');
      }

      if (data['result'] != 0 || data['eng_info'] == null) {
        throw Exception('لا يمكن قراءة البيانات الهندسية حالياً.');
      }

      return EngineeringInfoModel.fromJson(data['eng_info']['data']);
    } catch (e) {
      if (e.toString().contains('SESSION_EXPIRED')) rethrow;
      throw Exception('فشل جلب التشخيص المتقدم: $e');
    }
  }
}