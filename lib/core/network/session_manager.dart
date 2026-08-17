import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  static const _storage = FlutterSecureStorage();
  static const _sessionIdKey = 'session_id';
  static const _passwordKey = 'modem_password';
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _onboardingVisitedKey = 'onboarding_visited';
  static const _speedTestWarningDismissedKey = 'speed_test_warning_dismissed';
  static const _lockEndTimeKey = 'lock_end_time';
  static const _targetBssidKey = 'target_bssid';
  static const _permissionsRequestedKey = 'permissions_requested';
  static const _lastHeartbeatKey = 'last_heartbeat';
  static const _sessionTimeoutKey = 'session_timeout_minutes';
  static const _lastLoginPasswordKey = 'last_login_password';
  static const _knownMacsKey = 'known_devices_macs';
  static const _bgDeviceMonitorEnabledKey = 'bg_device_monitor_enabled';
  static const _pendingMacsKey = 'pending_devices_macs';
  static const _lastSnKey = 'last_sn';

  /// حفظ الرقم التسلسلي الأخير لاستخدامه في مهام الخلفية
  static Future<void> saveLastSN(String sn) async {
    await _storage.write(key: _lastSnKey, value: sn);
  }

  /// استرجاع الرقم التسلسلي الأخير
  static Future<String?> getLastSN() async {
    return await _storage.read(key: _lastSnKey);
  }

  /// حفظ قائمة الأجهزة المعروفة (MAC Addresses) للمودم الحالي
  static Future<void> saveKnownMacs(List<String> macs, [String? sn]) async {
    await _storage.write(
      key: _getKey(_knownMacsKey, sn),
      value: macs.join(','),
    );
  }

  /// استرجاع قائمة الأجهزة المعروفة
  static Future<List<String>> getKnownMacs([String? sn]) async {
    final val = await _storage.read(key: _getKey(_knownMacsKey, sn));
    if (val == null || val.isEmpty) return [];
    return val.split(',');
  }

  /// حفظ قائمة الأجهزة المعلّقة (بانتظار موافقة المستخدم)
  static Future<void> savePendingMacs(List<String> macs, [String? sn]) async {
    await _storage.write(
      key: _getKey(_pendingMacsKey, sn),
      value: macs.join(','),
    );
  }

  /// استرجاع قائمة الأجهزة المعلّقة
  static Future<List<String>> getPendingMacs([String? sn]) async {
    final val = await _storage.read(key: _getKey(_pendingMacsKey, sn));
    if (val == null || val.isEmpty) return [];
    return val.split(',');
  }

  /// إضافة MAC واحد للقائمة المعلّقة (بدون تكرار)
  static Future<void> addPendingMac(String mac, [String? sn]) async {
    final current = await getPendingMacs(sn);
    if (!current.contains(mac)) {
      current.add(mac);
      await savePendingMacs(current, sn);
    }
  }

  /// إزالة MAC من القائمة المعلّقة
  static Future<void> removePendingMac(String mac, [String? sn]) async {
    final current = await getPendingMacs(sn);
    current.remove(mac);
    await savePendingMacs(current, sn);
  }

  /// نقل MAC من المعلّقة إلى المعروفة (توثيق الجهاز)
  static Future<void> trustDevice(String mac, [String? sn]) async {
    await removePendingMac(mac, sn);
    final known = await getKnownMacs(sn);
    if (!known.contains(mac)) {
      known.add(mac);
      await saveKnownMacs(known, sn);
    }
  }

  /// إزالة MAC من القائمة المعروفة (إلغاء الثقة)
  static Future<void> untrustDevice(String mac, [String? sn]) async {
    final known = await getKnownMacs(sn);
    known.remove(mac);
    await saveKnownMacs(known, sn);
  }

  /// تفعيل/تعطيل إشعارات الأجهزة في الخلفية
  static Future<void> setBackgroundDeviceMonitorEnabled(bool enabled, [String? sn]) async {
    await _storage.write(
      key: _getKey(_bgDeviceMonitorEnabledKey, sn),
      value: enabled.toString(),
    );
  }

  /// هل إشعارات الأجهزة في الخلفية مفعلة؟ (الافتراضي: مفعل)
  static Future<bool> isBackgroundDeviceMonitorEnabled([String? sn]) async {
    final val = await _storage.read(key: _getKey(_bgDeviceMonitorEnabledKey, sn));
    if (val == null) return true; // تفعيل تلقائي عند التثبيت الجديد
    return val == 'true';
  }

  /// توليد مفتاح ديناميكي بناءً على الرقم التسلسلي للمودم (SN) لضمان تعدد السجلات
  static String _getKey(String baseKey, String? sn) {
    if (sn == null || sn.isEmpty) return baseKey;
    return '${baseKey}_$sn';
  }

  /// حفظ وقت انتهاء القفل (مرتبط بالـ SN لتجنب حظر المستخدم في مودم آخر)
  static Future<void> setLockEndTime(DateTime? endTime, [String? sn]) async {
    final key = _getKey(_lockEndTimeKey, sn);
    if (endTime == null) {
      await _storage.delete(key: key);
    } else {
      await _storage.write(key: key, value: endTime.toIso8601String());
    }
  }

  /// استرجاع وقت انتهاء القفل
  static Future<DateTime?> getLockEndTime([String? sn]) async {
    final key = _getKey(_lockEndTimeKey, sn);
    final val = await _storage.read(key: key);
    if (val == null) return null;
    return DateTime.tryParse(val);
  }

  /// حفظ الجلسة
  static Future<void> saveSessionId(String sessionId, [String? sn]) async {
    await _storage.write(key: _getKey(_sessionIdKey, sn), value: sessionId);
    // تسجيل وقت الحفظ كأول heartbeat
    await setLastHeartbeat(DateTime.now(), sn);
  }

  /// استرجاع الجلسة
  static Future<String?> getSessionId([String? sn]) async {
    return await _storage.read(key: _getKey(_sessionIdKey, sn));
  }

  /// حفظ كلمة المرور بشكل آمن (للبصمة)
  static Future<void> savePassword(String password, [String? sn]) async {
    await _storage.write(key: _getKey(_passwordKey, sn), value: password);
  }

  /// استرجاع كلمة المرور
  static Future<String?> getPassword([String? sn]) async {
    return await _storage.read(key: _getKey(_passwordKey, sn));
  }

  /// مسح كلمة المرور
  static Future<void> clearPassword([String? sn]) async {
    await _storage.delete(key: _getKey(_passwordKey, sn));
  }

  // ─── Session Heartbeat & Validity ───

  /// حفظ وقت آخر heartbeat ناجح
  static Future<void> setLastHeartbeat(DateTime time, [String? sn]) async {
    await _storage.write(
      key: _getKey(_lastHeartbeatKey, sn),
      value: time.toIso8601String(),
    );
  }

  /// استرجاع وقت آخر heartbeat ناجح
  static Future<DateTime?> getLastHeartbeat([String? sn]) async {
    final val = await _storage.read(key: _getKey(_lastHeartbeatKey, sn));
    if (val == null) return null;
    return DateTime.tryParse(val);
  }

  /// حفظ مهلة انتهاء الجلسة (بالدقائق) — تُجلب من إعدادات المودم
  static Future<void> setSessionTimeout(int minutes, [String? sn]) async {
    await _storage.write(
      key: _getKey(_sessionTimeoutKey, sn),
      value: minutes.toString(),
    );
  }

  /// استرجاع مهلة انتهاء الجلسة (بالدقائق) — القيمة الافتراضية 30 دقيقة
  static Future<int> getSessionTimeout([String? sn]) async {
    final val = await _storage.read(key: _getKey(_sessionTimeoutKey, sn));
    if (val == null) return 30;
    return int.tryParse(val) ?? 30;
  }

  /// التحقق المحلي السريع: هل الجلسة من المرجح أنها صالحة؟
  /// يعتمد على آخر heartbeat ناجح + timeout المودم
  static Future<bool> isSessionLikelyValid([String? sn]) async {
    final sessionId = await getSessionId(sn);
    if (sessionId == null || sessionId.isEmpty) return false;

    final lastHb = await getLastHeartbeat(sn);
    if (lastHb == null) return false; // لم يتم التحقق أبداً

    final timeoutMinutes = await getSessionTimeout(sn);
    final expiryTime = lastHb.add(Duration(minutes: timeoutMinutes));

    // نعطي هامش أمان 2 دقيقة
    return DateTime.now().isBefore(expiryTime.subtract(const Duration(minutes: 2)));
  }

  // ─── Password for Auto-Renewal ───

  /// حفظ كلمة المرور الأخيرة المستخدمة للدخول (للتجديد التلقائي)
  static Future<void> saveLastLoginPassword(String password, [String? sn]) async {
    await _storage.write(key: _getKey(_lastLoginPasswordKey, sn), value: password);
  }

  /// استرجاع كلمة المرور الأخيرة للتجديد التلقائي
  static Future<String?> getLastLoginPassword([String? sn]) async {
    return await _storage.read(key: _getKey(_lastLoginPasswordKey, sn));
  }

  /// تفعيل أو تعطيل خيار البصمة
  static Future<void> setBiometricEnabled(bool enabled, [String? sn]) async {
    await _storage.write(key: _getKey(_biometricEnabledKey, sn), value: enabled.toString());
  }

  /// هل خيار البصمة مفعل؟
  static Future<bool> isBiometricEnabled([String? sn]) async {
    final val = await _storage.read(key: _getKey(_biometricEnabledKey, sn));
    return val == 'true';
  }

  /// حفظ BSSID الخاص بالمودم المرتبط بالبصمة
  static Future<void> saveTargetBssid(String bssid, [String? sn]) async {
    await _storage.write(key: _getKey(_targetBssidKey, sn), value: bssid);
  }

  /// استرجاع BSSID
  static Future<String?> getTargetBssid([String? sn]) async {
    return await _storage.read(key: _getKey(_targetBssidKey, sn));
  }

  /// حفظ حالة زيارة شاشة الترحيب (عالمي للتطبيق)
  static Future<void> setOnboardingVisited() async {
    await _storage.write(key: _onboardingVisitedKey, value: 'true');
  }

  /// هل تمت زيارة شاشة الترحيب؟
  static Future<bool> isOnboardingVisited() async {
    final val = await _storage.read(key: _onboardingVisitedKey);
    return val == 'true';
  }

  /// حفظ حالة طلب الصلاحيات
  static Future<void> setPermissionsRequested() async {
    await _storage.write(key: _permissionsRequestedKey, value: 'true');
  }

  /// هل تم طلب الصلاحيات مسبقاً؟
  static Future<bool> hasRequestedPermissions() async {
    final val = await _storage.read(key: _permissionsRequestedKey);
    return val == 'true';
  }

  /// حفظ حالة تجاهل تحذير فحص السرعة
  static Future<void> setSpeedTestWarningDismissed() async {
    await _storage.write(key: _speedTestWarningDismissedKey, value: 'true');
  }

  /// هل تم تجاهل تحذير فحص السرعة؟
  static Future<bool> isSpeedTestWarningDismissed() async {
    final val = await _storage.read(key: _speedTestWarningDismissedKey);
    return val == 'true';
  }

  /// حذف الجلسة (عند تسجيل الخروج)
  static Future<void> clearSession([String? sn]) async {
    await _storage.delete(key: _getKey(_sessionIdKey, sn));
    await _storage.delete(key: _getKey(_lastHeartbeatKey, sn));
  }
}
