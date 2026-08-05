import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../features/dashboard/domain/entities/band_config_entity.dart';
import 'package:get/get.dart';
import '../../../../features/modem_auth/presentation/controllers/auth_controller.dart';

class ConnectionManagerDataSource {
  final http.Client client;
  final String baseUrl = 'http://mobile.router'; // http://192.168.8.1 أو

  ConnectionManagerDataSource({http.Client? client}) : client = client ?? http.Client();

  Map<String, String> getHeaders(String sessionId) => {
    'Accept': 'application/json, text/javascript, */*; q=0.01',
    'X-Requested-With': 'XMLHttpRequest',
    'Cookie': 'CGISID=$sessionId',
  };

  // دالة واحدة تدير الاتصال والانقطاع
  Future<bool> toggleDataConnection({required bool connect}) async {
    // 1. جلب Session ID من الـ AuthController
    final authController = Get.find<AuthController>();
    final sessionId = authController.currentUser?.sessionId;

    if (sessionId == null || sessionId.isEmpty) {
      throw Exception('SESSION_EXPIRED');
    }

    // 2. توليد الختم الزمني الديناميكي
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // 3. تحديد الطريقة (connect أو disconnect)
    final method = connect ? 'connect' : 'disconnect';

    // 4. بناء الرابط
    final url = '$baseUrl/api.cgi?path=cm&method=$method&timeout=120&_=$timestamp';

    try {
      final response = await client.get(
        Uri.parse(url),
        headers: getHeaders(sessionId),
      );

      if (response.statusCode == 200) {
        // طبقة أمان ثانوية — الفحص المركزي الدقيق يتم في ApiClient
        final bodyStr = response.body.toLowerCase().replaceAll(' ', '');
        if (bodyStr.contains('sessionnoexist') || 
            bodyStr.contains('anotheruser') ||
            bodyStr.contains('login.html')) {
          throw Exception('SESSION_EXPIRED');
        }

        if (kDebugMode) print('✅ [ConnectionManager] تم تنفيذ أمر $method بنجاح!');
        // السيرفر غالباً يعيد JSON يحتوي على نتيجة العملية، يمكنك فحصه هنا
        return true;
      } else {
        if (kDebugMode) print('❌ [ConnectionManager] فشل الطلب: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      if (e.toString().contains('SESSION_EXPIRED')) rethrow;
      if (kDebugMode) print('💥 [ConnectionManager] خطأ في الاتصال: $e');
      return false;
    }
  }
  Future<BandConfigEntity> getBands() async {
    final authController = Get.find<AuthController>();
    final sessionId = authController.currentUser?.sessionId;

    if (sessionId == null || sessionId.isEmpty) {
      throw Exception('SESSION_EXPIRED');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = '$baseUrl/api.cgi?path=cm&method=eng_get_bands&timeout=20&_=$timestamp';

    try {
      final response = await client.get(
        Uri.parse(url),
        headers: getHeaders(sessionId),
      );

      if (response.statusCode == 200) {
        // طبقة أمان ثانوية
        final bodyStr = response.body.toLowerCase().replaceAll(' ', '');
        if (bodyStr.contains('sessionnoexist') || 
            bodyStr.contains('anotheruser') ||
            bodyStr.contains('login.html')) {
          throw Exception('SESSION_EXPIRED');
        }
        return BandConfigEntity.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('فشل جلب بيانات الباند');
      }
    } catch (e) {
      if (kDebugMode) print('💥 [ConnectionManager] خطأ في جلب الباند: $e');
      rethrow;
    }
  }

  Future<bool> setBands(Map<String, dynamic> payload) async {
    final authController = Get.find<AuthController>();
    final sessionId = authController.currentUser?.sessionId;

    if (sessionId == null || sessionId.isEmpty) {
      throw Exception('SESSION_EXPIRED');
    }

    final url = '$baseUrl/api.cgi?path=cm&method=eng_set_bands&timeout=20';

    try {
      final headers = getHeaders(sessionId);
      headers['Content-Type'] = 'application/json';
      headers['reset_time'] = '1';

      final response = await client.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        // طبقة أمان ثانوية
        final bodyStr = response.body.toLowerCase().replaceAll(' ', '');
        if (bodyStr.contains('sessionnoexist') || 
            bodyStr.contains('anotheruser') ||
            bodyStr.contains('login.html')) {
          throw Exception('SESSION_EXPIRED');
        }
        final Map<String, dynamic> resJson = jsonDecode(response.body);
        return resJson['cm']?['result'] == 0 || resJson['cm']?['setting_response'] == 'OK';
      } else {
        throw Exception('فشل الحفظ');
      }
    } catch (e) {
      if (e.toString().contains('SESSION_EXPIRED')) rethrow;
      if (kDebugMode) print('💥 [ConnectionManager] خطأ في حفظ الباند: $e');
      return false;
    }
  }
}
