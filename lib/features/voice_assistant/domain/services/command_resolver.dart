import 'package:get/get.dart';
import '../entities/voice_intent.dart';
import '../../../connected_devices/presentation/controllers/connected_devices_controller.dart';
import '../../../connected_devices/domain/entities/connected_device_entity.dart';
import '../enums/voice_intent_type.dart';
import 'entity_extractor.dart';

class CommandResolver {
  /// إكمال النية بالمعاملات (Parameters) واستخراج الكيانات اللازمة
  static VoiceIntent resolve(VoiceIntent intent, String normalizedText) {
    // 1. إذا كان يحتاج معلومات أو تعارض، نرجعه كما هو
    if (intent.type == VoiceIntentType.ambiguous || intent.type == VoiceIntentType.needsMoreInfo) {
      return intent;
    }

    final Map<String, dynamic> params = {};
    params['rawText'] = normalizedText;

    // 2. حل المعاملات بناءً على نوع الأمر
    switch (intent.action) {

      // ─── حظر جهاز ───
      case 'action.security.block':
        List<ConnectedDeviceEntity> devices = [];
        try {
          devices = Get.find<ConnectedDevicesController>().devices;
        } catch (_) {}

        final mac = EntityExtractor.extractDeviceMac(normalizedText, devices);
        if (mac != null) {
          params['mac'] = mac;
          final deviceName = devices.firstWhere((d) => d.mac == mac).name;
          params['deviceName'] = deviceName.isEmpty ? 'الجهاز' : deviceName;
        }
        break;

      // ─── فك الحظر ───
      case 'action.security.unblock':
        params['rawName'] = normalizedText.replaceAll(
            RegExp(r'(ارفع|فك|اسمح|عن|جهاز|حظر|منع|افتح|حل)'), '').trim();
        break;

      // ─── تغيير كلمة مرور الواي فاي ───
      case 'action.wifi.changePassword':
        final password = EntityExtractor.extractPassword(normalizedText);
        if (password != null && password.length >= 8) {
          params['password'] = password;
        }
        break;

      // ─── تحديد السرعة العامة ───
      case 'action.speed.setGlobal':
        final speed = EntityExtractor.extractNumber(normalizedText);
        if (speed != null) {
          params['speed'] = speed;
        }
        break;

      // ─── تحديد سرعة جهاز معين ───
      case 'action.speed.setDevice':
        final speed = EntityExtractor.extractNumber(normalizedText);
        if (speed != null) params['speed'] = speed;

        List<ConnectedDeviceEntity> devices = [];
        try {
          devices = Get.find<ConnectedDevicesController>().devices;
        } catch (_) {}

        final mac = EntityExtractor.extractDeviceMac(normalizedText, devices);
        if (mac != null) {
          params['mac'] = mac;
          final deviceName = devices.firstWhere((d) => d.mac == mac).name;
          params['deviceName'] = deviceName.isEmpty ? 'الجهاز' : deviceName;
        }
        break;

      // ─── ضبط حجم الباقة ───
      case 'action.usage.setQuota':
        final quota = EntityExtractor.extractNumber(normalizedText);
        if (quota != null) {
          params['quota'] = quota;
          // تحديد الوحدة
          if (normalizedText.contains('جيجا') || normalizedText.contains('gb')) {
            params['unit'] = 'GB';
          } else if (normalizedText.contains('ميجا') || normalizedText.contains('mb')) {
            params['unit'] = 'MB';
          } else {
            params['unit'] = 'GB';
          }
        }
        break;

      // ─── الوضع الليلي/النهاري ───
      case 'action.settings.darkMode':
        if (normalizedText.contains('ليلي') || normalizedText.contains('مظلم') ||
            normalizedText.contains('داكن') || normalizedText.contains('دارك')) {
          params['mode'] = 'dark';
        } else if (normalizedText.contains('فاتح') || normalizedText.contains('نهاري') ||
            normalizedText.contains('لايت')) {
          params['mode'] = 'light';
        } else {
          params['mode'] = 'toggle';
        }
        break;

      // ─── التنقل ───
      case 'navigate.page':
        final text = normalizedText;
        if (text.contains('واي فاي') || text.contains('اعدادات') || text.contains('ضبط')) {
          params['page'] = 'settings';
        } else if (text.contains('رصيد') || text.contains('فاتوره') || text.contains('حساب')) {
          params['page'] = 'bill';
        } else if (text.contains('اجهزه') || text.contains('متصل') || text.contains('اجهزة')) {
          params['page'] = 'devices';
        } else if (text.contains('حظر') || text.contains('فلتر') || text.contains('امنع')) {
          params['page'] = 'mac_filter';
        } else if (text.contains('رادار') || text.contains('اشاره') || text.contains('تغطيه')) {
          params['page'] = 'signal_finder';
        } else if (text.contains('سرعه') || text.contains('فحص') || text.contains('تست')) {
          params['page'] = 'speed_test';
        } else if (text.contains('رقابه') || text.contains('اطفال') || text.contains('مراقبه')) {
          params['page'] = 'parental_control';
        } else if (text.contains('استهلاك') || text.contains('بيانات') || text.contains('باقه')) {
          params['page'] = 'data_usage';
        } else if (text.contains('تحديد سرعه') || text.contains('حد سرعه')) {
          params['page'] = 'speed_limit';
        } else if (text.contains('رئيسيه') || text.contains('داشبورد') || text.contains('الرئيسي') || text.contains('الرئيسية') || text.contains('لوحه')) {
          params['page'] = 'dashboard';
        } else if (text.contains('شبكه') || text.contains('مودم') || text.contains('معلومات')) {
          params['page'] = 'network_info';
        }
        break;
    }

    // إرجاع النية المستكملة
    return VoiceIntent(
      type: intent.type,
      category: intent.category,
      action: intent.action,
      requiresConfirmation: intent.requiresConfirmation,
      matchScore: intent.matchScore,
      params: params,
    );
  }
}
