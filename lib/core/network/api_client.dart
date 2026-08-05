import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/constants.dart';
import '../utils/session_helper.dart';

class ApiClient extends http.BaseClient {
  final http.Client _inner;

  ApiClient({required http.Client inner}) : _inner = inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // 🛡️ Bypass modem-specific logic for external URLs (like speed tests)
    if (!request.url.toString().contains('mobile.router') && !request.url.toString().contains('192.168.')) {
       return _inner.send(request);
    }

    final startTime = DateTime.now();
    if (kDebugMode) {
      debugPrint('🌐 [API REQUEST] ${request.method} ${request.url}');
    }
    
    try {
      final response = await _inner.send(request).timeout(
        const Duration(seconds: AppConstants.requestTimeoutSeconds),
        onTimeout: () {
          throw Exception('انتهى وقت الطلب (Timeout). يرجى التحقق من اتصالك بالمودم.');
        },
      );
      
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      if (kDebugMode) {
        if (response.statusCode >= 400) {
          debugPrint('🔴 [API ERROR] [${response.statusCode}] ${request.method} ${request.url} in ${duration}ms');
        } else {
          debugPrint('🟢 [API SUCCESS] [${response.statusCode}] ${request.method} ${request.url} in ${duration}ms');
        }
      }

      // 🔍 المراقبة المركزية لانتهاء الجلسة (Session Expiration)
      final responseBytes = await response.stream.toBytes();
      final bodyString = utf8.decode(responseBytes, allowMalformed: true);
      
      if (_isSessionExpired(response.statusCode, bodyString)) {
        if (kDebugMode) {
          debugPrint('⚠️ [SESSION EXPIRED DETECTED] ${request.url}');
        }
        // نمرر الخطأ لـ SessionHelper ليتعامل معه (محاولة تجديد أو طرد)
        SessionHelper.handleSessionError('SESSION_EXPIRED');
        throw Exception('SESSION_EXPIRED');
      }

      // إعادة تجمع StreamedResponse بما أننا استهلكنا الـ Stream
      final newStream = http.ByteStream(Stream.fromIterable([responseBytes]));
      return http.StreamedResponse(
        newStream,
        response.statusCode,
        contentLength: responseBytes.length,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        final duration = DateTime.now().difference(startTime).inMilliseconds;
        debugPrint('❌ [API EXCEPTION] ${request.method} ${request.url} in ${duration}ms');
        debugPrint('Details: $e');
      }
      
      // التوجيه الذكي إذا كان الخطأ بسبب الجلسة (من مكان آخر)
      if (e.toString().contains('SESSION_EXPIRED')) {
        SessionHelper.handleSessionError(e);
      }
      
      rethrow;
    }
  }

  /// فحص دقيق لانتهاء الجلسة — يتجنب الإيجابيات الكاذبة (False Positives)
  ///
  /// المنهج: نحلل الرد كـ JSON أولاً للتحقق من الحقول المحددة.
  /// نلجأ للفحص النصي فقط للأنماط الواضحة التي لا تتواجد في بيانات عادية.
  bool _isSessionExpired(int statusCode, String body) {
    if (statusCode == 401) return true;
    
    final bodyLower = body.toLowerCase().replaceAll(' ', '');
    
    // 1. أنماط واضحة لا لبس فيها — آمن للفحص النصي
    if (bodyLower.contains('sessionnoexist') ||
        bodyLower.contains('sessionfail') ||
        bodyLower.contains('authorizationisnotok') ||
        bodyLower.contains('anotheruser') ||
        bodyLower.contains('login.html') ||
        bodyLower.contains('window.location')) {
      return true;
    }

    // 2. فحص JSON دقيق للأكواد الرقمية — لتجنب False Positives
    // أكواد مثل 100002, 100003, 125002 قد تظهر في بيانات عادية (أرقام هواتف، حسابات)
    // لذلك نتحقق فقط من أنها قيمة حقل "result"
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return _checkResultCode(decoded);
      } else if (decoded is List) {
        // multicall response — نتحقق من كل عنصر
        for (final item in decoded) {
          if (item is Map<String, dynamic> && _checkResultCode(item)) {
            return true;
          }
        }
      }
    } catch (_) {
      // إذا لم يكن JSON صالحاً، نتحقق هل هو HTML (صفحة إعادة تسجيل الدخول)
      if (bodyLower.contains('<html') && bodyLower.contains('login')) {
        return true;
      }
    }
    
    return false;
  }

  /// التحقق من أكواد النتيجة في حقل "result" من JSON المودم
  bool _checkResultCode(Map<String, dynamic> json) {
    final result = json['result'];
    if (result == null) return false;
    
    // أكواد انتهاء الجلسة المعروفة:
    // 100003 = session expired
    // 125002 = session invalid
    // 11 = login required
    // -32000 = unauthorized
    const sessionExpiredCodes = {100003, 125002, 11, -32000};
    
    if (result is int) {
      return sessionExpiredCodes.contains(result);
    }
    if (result is String) {
      final parsed = int.tryParse(result);
      if (parsed != null) return sessionExpiredCodes.contains(parsed);
    }
    
    return false;
  }
}
