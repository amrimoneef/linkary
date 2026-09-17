import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/bill_entity.dart';
import '../models/bill_config_model.dart';
import '../services/bill_config_service.dart';

abstract class BillRemoteDataSource {
  Future<BillEntity> fetchBill(String phoneNumber);
  Future<BillEntity> submitBillWithCaptcha({
    required String phone,
    required String captchaCode,
    required String nonce,
    required String cookies,
  });
}

class BillRemoteDataSourceImpl implements BillRemoteDataSource {
  final BillConfigService configService;

  BillRemoteDataSourceImpl({required this.configService});

  // تجاوز التحقق من شهادة SSL
  static http.Client _buildPtcClient() {
    final httpClient = HttpClient();
    httpClient.badCertificateCallback =
        (X509Certificate cert, String host, int port) => host.contains('ptc.gov.ye');
    httpClient.connectionTimeout = const Duration(seconds: 15);
    return IOClient(httpClient);
  }

  final http.Client _ptcClient = _buildPtcClient();

  final Map<String, String> _cookieJar = {};

  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 16; SM-S928N Build/BP2A.250605.031.A3; wv) '
      'AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/146.0.7680.177 '
      'Mobile Safari/537.36';

  void _clearCookies() {
    _cookieJar.clear();
    _cookieJar['pll_language'] = 'ar';
  }

  void _updateCookiesFromHeaders(Map<String, String> headers) {
    final rawCookie = headers['set-cookie'];
    if (rawCookie == null || rawCookie.isEmpty) return;

    final regex = RegExp(r'([a-zA-Z0-9_\-]+)=([^;,\s]+)');
    for (final match in regex.allMatches(rawCookie)) {
      final name = match.group(1);
      final value = match.group(2);
      if (name != null && value != null) {
        final lower = name.toLowerCase();
        if (lower != 'path' &&
            lower != 'domain' &&
            lower != 'expires' &&
            lower != 'samesite' &&
            lower != 'max-age' &&
            lower != 'httponly' &&
            lower != 'secure') {
          _cookieJar[name] = value;
        }
      }
    }
    if (kDebugMode) print('🍪 [BillService] Cookies: $cookieHeaderString');
  }

  String get cookieHeaderString {
    return _cookieJar.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  Map<String, String> get _baseHeaders => {
    'User-Agent': _userAgent,
    'Accept-Language': 'en-US,en;q=0.9,ar-YE;q=0.8,ar;q=0.7',
    'Accept-Encoding': 'gzip, deflate, br, zstd',
    'X-Requested-With': 'com.telecom.yemen4g',
    'sec-ch-ua': '"Chromium";v="146", "Not-A.Brand";v="24", "Android WebView";v="146"',
    'sec-ch-ua-mobile': '?1',
    'sec-ch-ua-platform': '"Android"',
    'Cookie': cookieHeaderString,
  };

  // ============================================================
  // استخراج بيانات النموذج
  // ============================================================
  Map<String, String?> _extractFormData(String html, BillConfigModel config) {
    final nonceRegex = RegExp('${config.nonceField}"\\s+value="([^"]+)');
    final nonce = nonceRegex.firstMatch(html)?.group(1);
    return {'nonce': nonce};
  }

  // ============================================================
  // إرسال طلب الاستعلام
  // ============================================================
  Future<String> _queryBill({
    required String phone,
    required String captchaCode,
    required String nonce,
    required String cookies,
    required BillConfigModel config,
  }) async {
    // 1. تجميع البيانات ديناميكياً من الإعدادات
    final Map<String, String> formData = {
      config.nonceField: nonce,
      '_wp_http_referer': config.referer,
      config.submitField: config.submitValue,
      config.phoneField: phone,
      config.captchaField: captchaCode,
      config.queryBtnField: config.queryBtnValue,
    };

    // 🚀 2. التشفير الصارم لـ URL (يمنع السيرفر من رفض الحروف العربية)
    final String encodedBody = formData.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final res = await _ptcClient.post(
      Uri.parse(config.submitUrl),
      headers: {
        ..._baseHeaders,
        'Cookie': cookies.isNotEmpty ? cookies : cookieHeaderString,
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Origin': config.origin,
        'Referer': config.baseUrl,
        'Upgrade-Insecure-Requests': '1',
      },
      body: encodedBody,
    );

    _updateCookiesFromHeaders(res.headers);
    return res.body;
  }

  // ============================================================
  // تحليل HTML وإرجاع Map (النسخة الذكية)
  // ============================================================
  Map<String, String> _parseHtml(String html, BillConfigModel config) {
    final document = parse(html);
    final Map<String, String> data = {};

    // 1. فحص رسائل الحظر
    if (html.contains(config.rateLimitKeyword) || html.contains('لايمكنك الاستعلام')) {
      throw Exception('لقد تجاوزت عدد مرات الاستعلام المسموح بها، يرجى المحاولة لاحقاً بعد قليل');
    }

    final errorLabel = document.querySelector(config.phoneErrorSelector);
    if (errorLabel != null && errorLabel.text.trim().isNotEmpty) {
      throw Exception(errorLabel.text.trim());
    }

    // 🚀 2. البحث عن جدول البيانات المحدد ديناميكياً
    final table = document.querySelector(config.tableSelector);
    if (table == null) {
      if (kDebugMode) print('⚠️ [BillService] لم يتم العثور على جدول البيانات (${config.tableSelector})');
      return data;
    }

    // 3. استخراج الصفوف
    final rows = table.querySelectorAll('tr');
    String currentCategory = '';

    for (final row in rows) {
      final categoryCell = row.querySelector('td[colspan="2"]') ??
          row.querySelector('td[colspan]') ??
          (row.querySelector('td')?.attributes.containsKey('colspan') == true
              ? row.querySelector('td')
              : null);
      if (categoryCell != null) {
        currentCategory = categoryCell.text.trim();
        continue;
      }

      final th = row.querySelector('th');
      final td = row.querySelector('td');

      if (th != null && td != null) {
        String key = th.text.trim().replaceAll('\n', '').trim();
        final value = td.text.trim().replaceAll('\n', '').trim();

        if (currentCategory.isNotEmpty && (key == 'الرصيد المتاح' || key == 'الرصيد الإجمالي')) {
          key = '$currentCategory - $key';
        }

        if (key.isNotEmpty && value.isNotEmpty) {
          data[key] = value;
        }
      }
    }

    return data;
  }

  // ============================================================
  // الدالة الرئيسية
  // ============================================================
  @override
  Future<BillEntity> fetchBill(String phoneNumber) async {
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'(\+967|00967|\s)'), '').trim();

    if (!RegExp(r'^10\d{7}$').hasMatch(cleanPhone)) {
      throw Exception('صيغة الرقم غير صحيحة. يجب أن يكون بصيغة: 10XXXXXXX');
    }

    if (kDebugMode) print('📞 [BillService] Querying bill for: $cleanPhone');

    // 1. تنظيف الكوكيز لجلسة استعلام جديدة
    _clearCookies();

    // 2. جلب أحدث إعدادات خوارزمية الاستعلام من السيرفر
    final config = await configService.getConfig();

    try {
      // 3. جلب الصفحة الرئيسية للحصول على الـ Nonce والجلسة في طلب واحد
      final pageRes = await _ptcClient.get(
        Uri.parse(config.baseUrl),
        headers: {
          ..._baseHeaders,
          'Cookie': cookieHeaderString,
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Upgrade-Insecure-Requests': '1',
        },
      );
      _updateCookiesFromHeaders(pageRes.headers);

      final form = _extractFormData(pageRes.body, config);
      final nonce = form['nonce'];

      if (nonce == null || nonce.isEmpty) {
        throw Exception('فشل استخراج بيانات النموذج الأمنية من الموقع');
      }

      // 4. تحميل صورة الكابتشا مباشرة عبر نفس الجلسة للتأكد من ربطها بالـ Session
      final sep = config.captchaUrl.contains('?') ? '&' : '?';
      final captchaUri = Uri.parse(
        '${config.captchaUrl}${sep}t=${DateTime.now().millisecondsSinceEpoch}',
      );

      Uint8List? imageBytes;
      try {
        final captchaRes = await _ptcClient.get(
          captchaUri,
          headers: {
            ..._baseHeaders,
            'Cookie': cookieHeaderString,
            'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
            'Referer': config.baseUrl,
          },
        );
        _updateCookiesFromHeaders(captchaRes.headers);

        if (captchaRes.statusCode == 200 && captchaRes.bodyBytes.length > 100) {
          imageBytes = captchaRes.bodyBytes;
          if (kDebugMode) {
            print('🖼️ [BillService] Captcha pre-fetched successfully (${imageBytes.length} bytes)');
          }
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ [BillService] Captcha pre-fetch error: $e');
      }

      throw CaptchaRequiredException(
        nonce: nonce,
        cookies: cookieHeaderString,
        imageUrl: config.captchaUrl,
        imageBytes: imageBytes,
      );
    } catch (e) {
      if (e is CaptchaRequiredException) rethrow;

      if (kDebugMode) print('❌ [BillService] Error: $e');
      final msg = e.toString();
      if (msg.contains('تجاوزت') || msg.contains('لم يتم العثور') || msg.contains('صيغة الرقم غير صحيحة')) {
        throw Exception(msg.replaceAll('Exception: ', ''));
      }
      throw Exception('حصل خطأ، تأكد من اتصالك بالإنترنت وحاول مرة أخرى');
    }
  }

  @override
  Future<BillEntity> submitBillWithCaptcha({
    required String phone,
    required String captchaCode,
    required String nonce,
    required String cookies,
  }) async {
    String cleanPhone = phone.replaceAll(RegExp(r'(\+967|00967|\s)'), '').trim();
    final config = await configService.getConfig();

    try {
      final html = await _queryBill(
        phone: cleanPhone,
        captchaCode: captchaCode,
        nonce: nonce,
        cookies: cookies.isNotEmpty ? cookies : cookieHeaderString,
        config: config,
      );

      final data = _parseHtml(html, config);

      if (data.isEmpty) {
        if (kDebugMode) print('⚠️ [BillService] Empty Data after captcha.');
        throw Exception('رمز التحقق خاطئ أو لم يتم العثور على بيانات.');
      }

      if (kDebugMode) print('✅ [BillService] Data fetched successfully with captcha!');
      return BillEntity(data: data);
    } catch (e) {
      if (kDebugMode) print('❌ [BillService] Error: $e');
      final msg = e.toString();
      if (msg.contains('تجاوزت') || msg.contains('لم يتم العثور') || msg.contains('رمز التحقق خاطئ') || msg.contains('لايمكنك')) {
        throw Exception(msg.replaceAll('Exception: ', ''));
      }
      throw Exception('حصل خطأ أثناء الاستعلام، يرجى المحاولة لاحقاً');
    }
  }
}