import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bill_config_model.dart';

class BillConfigService {
  final http.Client client;
  final SharedPreferences sharedPreferences;

  static const String _configUrl = 'https://www.sam4g.com/api/agent/bill/config';
  static const String _prefsKey = 'cached_bill_config_json';

  BillConfigModel? _memoryConfig;

  BillConfigService({
    required this.client,
    required this.sharedPreferences,
  });

  /// جلب الإعدادات (يحاول التحديث من السيرفر ثم يرجع للـ Cache أو القيم الافتراضية)
  Future<BillConfigModel> getConfig({bool forceRefresh = false}) async {
    if (!forceRefresh && _memoryConfig != null) {
      return _memoryConfig!;
    }

    // 1. محاولة جلب الإعدادات المحدثة من سيرفر sam4g.com
    try {
      final response = await client.get(
        Uri.parse(_configUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (!body.startsWith('<')) {
          final Map<String, dynamic> jsonResponse = json.decode(body);
          if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
            final configMap = jsonResponse['data'] as Map<String, dynamic>;
            final newConfig = BillConfigModel.fromJson(configMap);
            _memoryConfig = newConfig;

            // حفظ النسخة المحدثة محلياً لاستخدامها بدون إنترنت
            await sharedPreferences.setString(_prefsKey, json.encode(newConfig.toJson()));
            if (kDebugMode) {
              print('🚀 [BillConfigService] Successfully synced bill config from sam4g.com');
            }
            return newConfig;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ℹ️ [BillConfigService] Could not reach remote config ($e). Using local fallback.');
      }
    }

    // 2. الرجوع للنسخة المخزنة محلياً في الهاتف إن وجدت
    final cachedJsonStr = sharedPreferences.getString(_prefsKey);
    if (cachedJsonStr != null && cachedJsonStr.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = json.decode(cachedJsonStr);
        _memoryConfig = BillConfigModel.fromJson(decoded);
        return _memoryConfig!;
      } catch (_) {}
    }

    // 3. الرجوع للقيم الافتراضية المدمجة
    _memoryConfig = BillConfigModel.defaultValues();
    return _memoryConfig!;
  }
}
