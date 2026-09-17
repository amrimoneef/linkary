import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/bill_entity.dart';

class BillApiDataSource {
  final http.Client client;
  static const String _baseUrl = 'https://www.sam4g.com/api/agent/bill';

  BillApiDataSource({required this.client});

  /// 1. إرسال طلب استعلام إلى الـ API الخارجي
  Future<BillEntity> fetchBill(String phoneNumber) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'(\+967|00967|\s)'), '').trim();

    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/query'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({'phone': cleanPhone}),
      ).timeout(const Duration(seconds: 15));

      final bodyString = response.body.trim();

      // التحقق مما إذا كانت الاستجابة صفحة HTML (Captive Portal أو 404 HTML)
      if (bodyString.startsWith('<')) {
        throw Exception('استجابة غير متوقعة من الخادم');
      }

      final Map<String, dynamic> jsonResponse = json.decode(bodyString);

      // الحالة A: تم الاستعلام بنجاح وإرجاع البيانات مباشرة
      if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
        final Map<String, dynamic> rawData = jsonResponse['data'];
        final Map<String, String> stringData = rawData.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
        return BillEntity(data: stringData);
      }

      // الحالة B: الخادم يتطلب حل الكابتشا من المستخدم
      if (jsonResponse['requires_captcha'] == true) {
        throw CaptchaRequiredException(
          nonce: jsonResponse['nonce']?.toString() ?? '',
          cookies: jsonResponse['cookies']?.toString() ?? '',
          imageUrl: jsonResponse['captcha_url']?.toString() ??
              'https://svc.ptc.gov.ye/wp-content/plugins/query4g-bill-api/securimage/securimage_show.php?namespace=q4g_one_captcha',
        );
      }

      // الحالة C: رسالة خطأ من الخادم
      final message = jsonResponse['message']?.toString() ?? 'فشل الاستعلام من الخادم';
      throw Exception(message);
    } on CaptchaRequiredException {
      rethrow;
    } catch (e) {
      if (kDebugMode) print('❌ [BillApiDataSource] fetchBill error: $e');
      rethrow;
    }
  }

  /// 2. إرسال حل الكابتشا إلى الـ API الخارجي
  Future<BillEntity> submitBillWithCaptcha({
    required String phone,
    required String captchaCode,
    required String nonce,
    required String cookies,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'(\+967|00967|\s)'), '').trim();

    try {
      final response = await client.post(
        Uri.parse('$_baseUrl/submit-captcha'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'phone': cleanPhone,
          'captcha_code': captchaCode,
          'nonce': nonce,
          'cookies': cookies,
        }),
      ).timeout(const Duration(seconds: 20));

      final bodyString = response.body.trim();
      if (bodyString.startsWith('<')) {
        throw Exception('استجابة غير متوقعة من الخادم');
      }

      final Map<String, dynamic> jsonResponse = json.decode(bodyString);

      if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
        final Map<String, dynamic> rawData = jsonResponse['data'];
        final Map<String, String> stringData = rawData.map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
        return BillEntity(data: stringData);
      }

      final message = jsonResponse['message']?.toString() ?? 'رمز التحقق غير صحيح';
      throw Exception(message);
    } catch (e) {
      if (kDebugMode) print('❌ [BillApiDataSource] submitBillWithCaptcha error: $e');
      rethrow;
    }
  }
}
