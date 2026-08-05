import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../models/auth_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthModel> loginToModem(String password);
  Future<int> fetchRetryTimes();
  Future<void> logout(String sessionId);
  Future<void> reboot(String sessionId);
  Future<void> powerOff(String sessionId);
  Future<void> factoryReset(String sessionId);
  Future<bool> checkIfSetupRequired();
  Future<void> markSetupComplete();
  Future<String?> getSerialNumber();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;
  final String baseUrl = 'http://mobile.router'; // http://192.168.8.1 أو

  AuthRemoteDataSourceImpl({required this.client});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json, text/javascript, */*; q=0.01',
    'X-Requested-With': 'XMLHttpRequest',
  };

  @override
  Future<AuthModel> loginToModem(String password) async {
    final userId = _generateRandomString(8);



    // 1. جلب التحدي (rand)
    final randResponse = await client.post(
      Uri.parse('$baseUrl/api.cgi?path=account&method=get_rand&timeout=20'),
      headers: _headers,
      body: jsonEncode({"type": "admin", "user_id": userId}),
    );



    // التحقق من أن الاستجابة ليست فارغة قبل فك التشفير
    if (randResponse.body.trim().isEmpty) {
      throw Exception('المودم أعاد استجابة فارغة! تأكد من الـ IP ومن اتصالك بالشبكة.');
    }

    final randData = jsonDecode(randResponse.body);
    if (randData['result'] != 0) {
      throw Exception('فشل في جلب التحدي من المودم');
    }

    final String rand = randData['rand'];

    // 2. التشفير (MD5(rand + password.toLowerCase()))
    final rawString = rand + password.toLowerCase();
    final hashedPassword = md5.convert(utf8.encode(rawString)).toString();

    // 3. إرسال طلب الدخول
    final loginResponse = await client.post(
      Uri.parse('$baseUrl/api.cgi?path=account&method=login&timeout=20'),
      headers: _headers,
      body: jsonEncode({
        "type": "admin",
        "username": "admin",
        "password": hashedPassword,
        "user_id": userId
      }),
    );

    final loginData = jsonDecode(loginResponse.body);

    // 0 و 3 تعني نجاح الدخول
    if (loginData['result'] == 0 || loginData['result'] == 3) {
      final sessionId = _extractCookies(loginResponse.headers);
      
      // التحقق مما إذا كان المودم جديداً ويحتاج إعداد أولي
      final isSetupRequired = await checkIfSetupRequired();

      return AuthModel(
        isAuthenticated: true, 
        sessionId: sessionId,
        isSetupRequired: isSetupRequired,
      );
    } else {
      throw Exception('فشل تسجيل الدخول. تأكد من كلمة المرور.');
    }
  }

  @override
  Future<int> fetchRetryTimes() async {
    try {
      // 1. توليد طابع زمني دقيق لمنع المودم من إرجاع نسخة مخبأة (Cache-Busting)
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 2. إضافة الطابع الزمني للرابط
      final url = '$baseUrl/api.cgi?path=account&method=get_retrytimes_and_time&timeout=20&_=$timestamp';

      final response = await client.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({"type": "admin"}),
      );

      final data = jsonDecode(response.body);



      if (data['result'] == 0) {
        return data['retry_times'] as int;
      }
      return 5; // قيمة افتراضية
    } catch (e) {
      return 5;
    }
  }

  @override
  Future<void> logout(String sessionId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await client.post(
        Uri.parse('$baseUrl/api.cgi?path=account&method=logout&timeout=20&_=$timestamp'),
        headers: {
          ..._headers,
          'Cookie': 'CGISID=$sessionId',
        },
        body: jsonEncode({}),
      );
    } catch (_) {
      // نغض الطرف عن أخطاء تسجيل الخروج من المودم لضمان استمرار العملية محلياً
    }
  }

  @override
  Future<void> reboot(String sessionId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await client.get(
        Uri.parse('$baseUrl/api.cgi?path=router&method=router_call_reboot&timeout=20&_=$timestamp'),
        headers: {
          ..._headers,
          'Cookie': 'CGISID=$sessionId',
          'reset_time': '1',
        },
      );
    } catch (_) {
      // نغض الطرف عن أخطاء إعادة التشغيل لضمان استمرار واجهة المستخدم
    }
  }

  @override
  Future<void> powerOff(String sessionId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final methods = [
      'router_call_poweroff',
      'router_poweroff',
      'router_call_power_off',
      'router_shutdown',
    ];

    for (final method in methods) {
      try {
        final uri = Uri.parse('$baseUrl/api.cgi?path=router&method=$method&timeout=20&_=$timestamp');
        await client.get(
          uri,
          headers: {
            ..._headers,
            'Cookie': 'CGISID=$sessionId',
            'reset_time': '1',
            'shutdown': '1',
          },
        ).timeout(const Duration(seconds: 3));
      } catch (_) {}
    }
  }

  @override
  Future<void> factoryReset(String sessionId) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await client.get(
        Uri.parse('$baseUrl/api.cgi?path=router&method=router_call_rst_factory&timeout=20&_=$timestamp'),
        headers: {
          ..._headers,
          'Cookie': 'CGISID=$sessionId',
        },
      );
    } catch (_) {
      // نغض الطرف عن الأخطاء لضمان استمرار واجهة المستخدم
    }
  }


  @override
  Future<bool> checkIfSetupRequired() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await client.get(
        Uri.parse('$baseUrl/api.cgi?path=router&method=get_guide_config&timeout=20&_=$timestamp'),
        headers: _headers,
      ).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['result'] == 0 && data['data'] != null) {
          // إذا كانت `guide_step1_pass` تساوي 0 فهذا يعني أنه لم يكمل الإعداد السريع
          return data['data']['guide_step1_pass'] == 0;
        }
      }
      return false; // إذا لم نستطع التحقق، نفترض أنه لا يحتاج
    } catch (_) {
      return false; 
    }
  }

  @override
  Future<void> markSetupComplete() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await client.post(
        Uri.parse('$baseUrl/api.cgi?path=router&method=set_guide_config&timeout=20&_=$timestamp'),
        headers: _headers,
        body: jsonEncode({
          'guide_step1_pass': 1,
        }),
      );
    } catch (_) {
      // لا نوقف العملية إذا فشل — الأهم هو أن الإعدادات حُفظت بنجاح
    }
  }

  @override
  Future<String?> getSerialNumber() async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final response = await client.get(
        Uri.parse('$baseUrl/api.cgi?path=router&method=get_device_info&timeout=20&_=$timestamp'),
        headers: _headers,
      ).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data['result'] == 0 && data['sn'] != null) {
          return data['sn'].toString();
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }


  // --- دوال مساعدة ---
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  String? _extractCookies(Map<String, String> headers) {
    final rawCookie = headers['set-cookie'];
    if (rawCookie != null) {
      final regExp = RegExp(r'CGISID=([^;]+)');
      final match = regExp.firstMatch(rawCookie);
      if (match != null) return match.group(1);
    }
    return null;
  }
}