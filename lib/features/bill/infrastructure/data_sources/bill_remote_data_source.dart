import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/bill_entity.dart';

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
  // تجاوز التحقق من شهادة SSL
  static http.Client _buildPtcClient() {
    final httpClient = HttpClient();
    httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) => host.contains('ptc.gov.ye');
    httpClient.connectionTimeout = const Duration(seconds: 15);
    return IOClient(httpClient);
  }

  final http.Client _ptcClient = _buildPtcClient();

  // متغير لحفظ جميع الـ Cookies وليس فقط PHPSESSID
  String _savedCookies = '';

  static const _baseUrl = 'https://ptc.gov.ye/?page_id=9017';
  static const _challengeBase = 'https://ptc.gov.ye/wp-admin/admin-ajax.php';

  static const _userAgent =
      'Mozilla/5.0 (Linux; Android 16; SM-S928N Build/BP2A.250605.031.A3; wv) '
      'AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/146.0.7680.177 '
      'Mobile Safari/537.36';

  Map<String, String> get _baseHeaders => {
    'User-Agent': _userAgent,
    'Accept-Language': 'en-US,en;q=0.9,ar-YE;q=0.8,ar;q=0.7',
    'Accept-Encoding': 'gzip, deflate, br, zstd',
    'X-Requested-With': 'com.telecom.yemen4g',
    'sec-ch-ua': '"Chromium";v="146", "Not-A.Brand";v="24", "Android WebView";v="146"',
    'sec-ch-ua-mobile': '?1',
    'sec-ch-ua-platform': '"Android"',
    'Cookie': _savedCookies.isNotEmpty ? _savedCookies : 'pll_language=ar',
  };

  // 🛠️ دالة مساعدة لتحديث الـ Cookies بعد كل طلب
  void _updateCookies(http.Response response) {
    String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null && rawCookie.isNotEmpty) {
      // استخراج الـ Cookies الأساسية ودمجها
      List<String> cookies = rawCookie.split(',');
      for (String cookie in cookies) {
        String cleanCookie = cookie.split(';')[0];
        if (cleanCookie.contains('=')) {
          // إضافة الـ Cookie الجديد أو تحديثه
          if (!_savedCookies.contains(cleanCookie.split('=')[0])) {
            _savedCookies += '${_savedCookies.isEmpty ? '' : '; '}$cleanCookie';
          }
        }
      }
      if (kDebugMode) print('🍪 [BillService] Updated Cookies: $_savedCookies');
    }
  }

  // ============================================================
  // الخطوة 1: جلب session ID من موقع PTC
  // ============================================================
  Future<void> _getSession() async {
    final res = await _ptcClient.get(
      Uri.parse(_baseUrl),
      headers: {
        'User-Agent': _userAgent,
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9,ar-YE;q=0.8,ar;q=0.7',
        'X-Requested-With': 'com.telecom.yemen4g',
        'Upgrade-Insecure-Requests': '1',
      },
    );
    _updateCookies(res);
    if (!_savedCookies.contains('PHPSESSID')) throw Exception('فشل جلب جلسة الموقع');
  }

  // ============================================================
  // الخطوة 2: جلب صفحة الاستعلام
  // ============================================================
  Future<String> _getMainPage() async {
    final res = await _ptcClient.get(
      Uri.parse(_baseUrl),
      headers: {
        ..._baseHeaders,
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
        'Upgrade-Insecure-Requests': '1',
      },
    );
    _updateCookies(res);
    return res.body;
  }

  // ============================================================
  // الخطوة 3: استخراج بيانات النموذج
  // ============================================================
  Map<String, String?> _extractFormData(String html) {
    final nonce = RegExp(r'qb4g_nonce_field"\s+value="([^"]+)').firstMatch(html)?.group(1);
    return {'nonce': nonce};
  }

  // ============================================================
  // الخطوة 4: إرسال طلب الاستعلام
  // ============================================================
  Future<String> _queryBill({
    required String phone,
    required String captchaCode,
    required String nonce,
    required String cookies,
  }) async {
    // 1. تجميع البيانات
    final Map<String, String> formData = {
      'qb4g_nonce_field': nonce,
      '_wp_http_referer': '/?page_id=9017',
      'qb4g_submit': 'YES',
      'phone4gidnew': phone,
      'captcha_code_q4Gbill': captchaCode,
      'qsubmitnew': 'استعلام', // النص العربي
    };

    // 🚀 2. التشفير الصارم لـ URL (يمنع السيرفر من رفض الحروف العربية)
    final String encodedBody = formData.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final res = await _ptcClient.post(
      Uri.parse(_baseUrl),
      headers: {
        ..._baseHeaders,
        'Cookie': cookies,
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Origin': 'https://ptc.gov.ye',
        'Referer': _baseUrl,
        'Upgrade-Insecure-Requests': '1',
      },
      body: encodedBody, // نرسل النص المشفر
    );

    _updateCookies(res);
    return res.body;
  }

  // ============================================================
  // الخطوة 7: تحليل HTML وإرجاع Map (النسخة الذكية)
  // ============================================================
  Map<String, String> _parseHtml(String html) {
    final document = parse(html);
    final Map<String, String> data = {};

    // 1. فحص رسائل الحظر
    if (html.contains('تجاوزت عدد مرات الاستعلام') || html.contains('لايمكنك الاستعلام')) {
      throw Exception('لقد تجاوزت عدد مرات الاستعلام المسموح بها، يرجى المحاولة لاحقاً بعد قليل');
    }

    final errorLabel = document.querySelector('#phoneidrrornew');
    if (errorLabel != null && errorLabel.text.trim().isNotEmpty) {
      throw Exception(errorLabel.text.trim());
    }

    // 🚀 2. البحث عن الجدول الحقيقي للبيانات بدلاً من الـ ID الوهمي
    final table = document.querySelector('table.transdetail');
    if (table == null) {
      if (kDebugMode) print('⚠️ [BillService] لم يتم العثور على جدول transdetail في الـ HTML');
      return data; // فارغ
    }

    // 3. استخراج الصفوف
    final rows = table.querySelectorAll('tr');
    String currentCategory = ''; // لتتبع العناوين الزرقاء (مثل: رصيد البيانات)

    for (final row in rows) {
      // فحص إذا كان الصف عبارة عن عنوان رئيسي (colspan=2)
      final categoryCell = row.querySelector('td[colspan="2"]');
      if (categoryCell != null) {
        currentCategory = categoryCell.text.trim();
        continue;
      }

      // قراءة الخلايا العادية (th للمفتاح، td للقيمة)
      final th = row.querySelector('th');
      final td = row.querySelector('td');

      if (th != null && td != null) {
        String key = th.text.trim().replaceAll('\n', '').trim();
        final value = td.text.trim().replaceAll('\n', '').trim();

        // 💡 حيلة ذكية: تمييز "الرصيد المتاح" للإنترنت عن المكالمات
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

    try {
      await _getSession();
      final page = await _getMainPage();
      final form = _extractFormData(page);

      if (form['nonce'] == null) {
        throw Exception('فشل استخراج بيانات النموذج الأمنية من الموقع');
      }

      // Throw exception to trigger UI dialog
      throw CaptchaRequiredException(
        nonce: form['nonce']!,
        cookies: _savedCookies,
        imageUrl: 'https://ptc.gov.ye/wp-content/plugins/query4g-bill-api/securimage/securimage_show.php',
      );
    } catch (e) {
      if (e is CaptchaRequiredException) rethrow; // Ensure we don't catch it here
      
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

    try {
      final html = await _queryBill(
        phone: cleanPhone,
        captchaCode: captchaCode,
        nonce: nonce,
        cookies: cookies,
      );

      final data = _parseHtml(html);

      if (data.isEmpty) {
        if (kDebugMode) print('⚠️ [BillService] Empty Data after captcha. HTML: ${html.length > 500 ? html.substring(0, 500) : html}');
        throw Exception('رمز التحقق خاطئ أو لم يتم العثور على بيانات.');
      }

      if (kDebugMode) print('✅ [BillService] Data fetched successfully with captcha!');
      return BillEntity(data: data);
    } catch (e) {
      if (kDebugMode) print('❌ [BillService] Error: $e');
      final msg = e.toString();
      if (msg.contains('تجاوزت') || msg.contains('لم يتم العثور') || msg.contains('رمز التحقق خاطئ')) {
        throw Exception(msg.replaceAll('Exception: ', ''));
      }
      throw Exception('حصل خطأ أثناء الاستعلام، يرجى المحاولة لاحقاً');
    }
  }
}