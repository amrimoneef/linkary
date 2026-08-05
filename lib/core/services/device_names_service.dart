import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// خدمة مركزية لحفظ وجلب الأسماء المخصصة للأجهزة محلياً.
/// تُستخدم عنوان MAC كمعرّف فريد.
class DeviceNamesService {
  static const _storage = FlutterSecureStorage();
  static const _storageKey = 'device_custom_names';

  /// جلب خريطة الأسماء المحفوظة { mac: customName }
  static Future<Map<String, String>> getAllNames() async {
    try {
      final raw = await _storage.read(key: _storageKey);
      if (raw == null || raw.isEmpty) return {};
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  /// جلب الاسم المخصص لجهاز معين بواسطة MAC
  static Future<String?> getName(String mac) async {
    final all = await getAllNames();
    return all[mac.toUpperCase()];
  }

  /// حفظ أو تحديث اسم جهاز معين
  static Future<void> saveName(String mac, String name) async {
    final all = await getAllNames();
    all[mac.toUpperCase()] = name.trim();
    await _storage.write(key: _storageKey, value: jsonEncode(all));
  }

  /// حذف الاسم المخصص لجهاز (الرجوع للاسم الافتراضي)
  static Future<void> removeName(String mac) async {
    final all = await getAllNames();
    all.remove(mac.toUpperCase());
    await _storage.write(key: _storageKey, value: jsonEncode(all));
  }
}
