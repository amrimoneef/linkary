import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../bill/presentation/controllers/bill_controller.dart';
import '../../presentation/widgets/voice_action_dialogs.dart';
import '../entities/voice_intent.dart';
import '../entities/voice_response.dart';
import '../enums/voice_intent_type.dart';
import 'response_builder.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../connected_devices/presentation/controllers/connected_devices_controller.dart';

import '../../../modem_auth/presentation/controllers/auth_controller.dart';
import '../../infrastructure/services/voice_logger.dart';
import '../../../settings/presentation/pages/wifi_settings_page.dart';
import '../../../mac_filter/presentation/pages/mac_filter_page.dart';
import '../../../signal_finder/presentation/pages/signal_finder_page.dart';
import '../../../speed_test/presentation/pages/speed_test_page.dart';
import '../../../parental_control/presentation/pages/parental_control_page.dart';
import '../../../speed_limit/presentation/pages/speed_limit_page.dart';
import '../../../data_usage/presentation/pages/data_usage_page.dart';
import '../../../connected_devices/presentation/pages/connected_devices_page.dart';
import '../../../parental_control/presentation/controllers/parental_control_controller.dart';
import '../../../speed_limit/presentation/controllers/speed_limit_controller.dart';

class VoiceCommandExecutor {
  Future<VoiceResponse> execute(VoiceIntent intent) async {
    if (intent.type == VoiceIntentType.unknown) {
      return ResponseBuilder.notUnderstood();
    }

    if (intent.type == VoiceIntentType.needsMoreInfo || intent.type == VoiceIntentType.ambiguous) {
      return VoiceResponse(
        success: false,
        spokenText: intent.message,
        displayText: intent.message,
      );
    }

    try {
      switch (intent.action) {

        // ═══════════════════════════════════════════════════
        // ─── الاستعلامات ──────────────────────────────────
        // ═══════════════════════════════════════════════════

        // ─── ترحيب سام ───
        case 'query.sam.greeting':
          return ResponseBuilder.success(
            text: 'أهلاً! أنا سام مساعدك الصوتي، كيف أقدر أساعدك اليوم؟',
            displayText: '👋 أهلاً! كيف أقدر أساعدك؟',
          );

        case 'query.devices.count':
        case 'query.devices.list':
          try {
            final controller = Get.find<ConnectedDevicesController>();
            final devices = controller.devices;
            if (devices.isEmpty) {
              return ResponseBuilder.success(text: 'لا توجد أجهزة متصلة حالياً');
            }
            final count = devices.length;
            final names = devices.take(3).map((d) => d.name.isEmpty ? 'جهاز غير معروف' : d.name).join(' و ');
            final more = count > 3 ? ' وغيرها' : '';
            return ResponseBuilder.success(text: 'يوجد $count أجهزة متصلة، منها $names $more');
          } catch (e) {
            VoiceLogger.logError('Failed to get connected devices', e.toString());
            return ResponseBuilder.success(text: 'لا يمكن جلب الأجهزة حالياً');
          }

        case 'query.network.battery':
          try {
            final controller = Get.find<DashboardController>();
            final info = controller.dashboardData.value;
            if (info == null) return ResponseBuilder.error('تعذر جلب بيانات البطارية');
            return ResponseBuilder.success(text: 'نسبة شحن البطارية ${info.batteryCapacity} بالمئة');
          } catch (_) {
            return ResponseBuilder.error();
          }

        case 'query.network.signal':
          try {
            final controller = Get.find<DashboardController>();
            final info = controller.dashboardData.value;
            if (info == null) return ResponseBuilder.error();
            return ResponseBuilder.success(text: 'قوة الإشارة ${info.signalLevel} من 5');
          } catch (_) {
            return ResponseBuilder.error();
          }

        case 'query.network.speed':
          try {
            final controller = Get.find<DashboardController>();
            final info = controller.dashboardData.value;
            if (info == null) return ResponseBuilder.error('تعذر جلب السرعة');
            final rx = controller.formatSpeed(info.rxSpeed);
            final tx = controller.formatSpeed(info.txSpeed);
            return ResponseBuilder.success(text: 'سرعة التنزيل $rx وسرعة الرفع $tx');
          } catch (_) {
            return ResponseBuilder.error();
          }

        case 'query.bill.balance':
          try {
            final billController = Get.find<BillController>();
            final dashController = Get.find<DashboardController>();

            var expectedBytes = billController.expectedBalanceBytes.value;

            if ((expectedBytes == null || expectedBytes == 0) && (billController.billData.value == null)) {
              VoiceLogger.logLifecycle('Balance data missing, fetching automatically...');
              await billController.fetchBill();
              expectedBytes = billController.expectedBalanceBytes.value;
            }

            if (expectedBytes != null && expectedBytes > 0) {
              final formatted = dashController.formatDataUsage(expectedBytes);
              return ResponseBuilder.success(text: 'الرصيد المتاح المتوقع حالياً هو $formatted');
            }

            final data = billController.billData.value?.data;
            if (data == null || data.isEmpty) {
              return ResponseBuilder.success(text: 'عفواً، تعذر جلب بيانات الرصيد من المودم حالياً');
            }

            String balanceStr = '';
            data.forEach((key, value) {
              if (key.contains('رصيد') || key.contains('باقي') || key.contains('المتبقي')) {
                balanceStr += '$key هو $value. ';
              }
            });

            if (balanceStr.isEmpty) {
              return ResponseBuilder.success(text: 'تعذر تحديد الرصيد بدقة من البيانات الحالية');
            }
            return ResponseBuilder.success(text: 'إليك تفاصيل الرصيد: $balanceStr');
          } catch (e) {
            VoiceLogger.logError('Failed to auto-fetch balance', e.toString());
            return ResponseBuilder.error('حدث خطأ أثناء جلب الرصيد');
          }

        case 'query.usage.current':
          try {
            final controller = Get.find<DashboardController>();
            final info = controller.dashboardData.value;
            if (info == null) return ResponseBuilder.error('تعذر جلب الاستهلاك');
            final usage = controller.formatDataUsage(info.currentUsage);
            return ResponseBuilder.success(text: 'حجم الاستهلاك الحالي هو $usage');
          } catch (_) {
            return ResponseBuilder.error();
          }

        case 'query.help':
          Future.microtask(() => VoiceActionDialogs.showHelpDialog());
          return ResponseBuilder.success(
            text: 'سأعرض لك قائمة الأوامر المتاحة',
            displayText: '📋 قائمة الأوامر الصوتية',
          );

        // ═══════════════════════════════════════════════════
        // ─── الإجراءات ────────────────────────────────────
        // ═══════════════════════════════════════════════════

        case 'action.system.reboot':
          if (intent.requiresConfirmation) {
            return VoiceResponse.confirmationRequired(
              message: 'سيتم إعادة تشغيل المودم وهذا سيقطع الإنترنت مؤقتاً. هل أنت متأكد؟',
              onConfirm: () async {
                final auth = Get.find<AuthController>();
                await auth.rebootDirect();
              },
            );
          }
          break;

        case 'action.system.logout':
          if (intent.requiresConfirmation) {
            return VoiceResponse.confirmationRequired(
              message: 'هل أنت متأكد أنك تريد تسجيل الخروج من التطبيق؟',
              onConfirm: () async {
                final auth = Get.find<AuthController>();
                await auth.logoutDirect();
              },
            );
          }
          break;

        case 'action.system.factory_reset':
          return VoiceResponse.confirmationRequired(
            message: 'تحذير! سيتم إعادة ضبط المودم إلى إعدادات المصنع وحذف كافة الإعدادات. هل أنت متأكد تماماً؟',
            onConfirm: () async {
              Get.to(() => WifiSettingsPage());
            },
          );

        case 'action.security.block':
          VoiceLogger.logLifecycle('Triggering Block Device Dialog...');
          Future.microtask(() => VoiceActionDialogs.showBlockDeviceDialog());
          return ResponseBuilder.success(text: 'تفضل، اختر الجهاز الذي تريد حظره من هذه القائمة');

        case 'action.security.unblock':
          Get.to(() => MacFilterPage());
          return ResponseBuilder.success(text: 'جاري فتح شاشة الحظر لتتمكن من إدارتها');

        case 'action.wifi.changePassword':
        case 'action.wifi.changeSsid':
          VoiceLogger.logLifecycle('Triggering WiFi Settings Dialog...');
          Future.microtask(() => VoiceActionDialogs.showWifiSettingsDialog());
          return ResponseBuilder.success(text: 'تفضل، أدخل بيانات الواي فاي الجديدة واضغط حفظ');

        // ─── الرقابة الأبوية ───
        case 'action.parental.enable':
          try {
            final controller = Get.find<ParentalControlController>();
            await controller.toggleParentalControl(true);
            return ResponseBuilder.success(text: 'تم تفعيل الرقابة الأبوية بنجاح');
          } catch (e) {
            VoiceLogger.logError('Failed to enable parental control', e.toString());
            return ResponseBuilder.error('تعذر تفعيل الرقابة الأبوية');
          }

        case 'action.parental.disable':
          return VoiceResponse.confirmationRequired(
            message: 'هل أنت متأكد من تعطيل الرقابة الأبوية؟ سيتمكن الأطفال من الوصول إلى الإنترنت بحرية.',
            onConfirm: () async {
              try {
                final controller = Get.find<ParentalControlController>();
                await controller.toggleParentalControl(false);
              } catch (e) {
                VoiceLogger.logError('Failed to disable parental control', e.toString());
              }
            },
          );

        case 'action.parental.scheduleDevice':
          VoiceLogger.logLifecycle('Opening Parental Control Page for scheduling...');
          Get.to(() => ParentalControlPage());
          return ResponseBuilder.success(
            text: 'جاري فتح شاشة الرقابة الأبوية لتحديد أوقات الأجهزة',
          );

        case 'action.parental.openPage':
          Get.to(() => ParentalControlPage());
          return ResponseBuilder.success(text: 'تم فتح شاشة الرقابة الأبوية');

        // ─── تحديد السرعة ───
        case 'action.speed.setGlobal':
          VoiceLogger.logLifecycle('Triggering Global Speed Limit Dialog...');
          Future.microtask(() {
            final speed = intent.params['speed'] as int?;
            VoiceActionDialogs.showSpeedLimitDialog(presetSpeed: speed, mode: 'global');
          });
          return ResponseBuilder.success(
            text: 'تفضل، اختر السرعة المناسبة للتطبيق على جميع الأجهزة',
          );

        case 'action.speed.setDevice':
          VoiceLogger.logLifecycle('Triggering Device Speed Limit Dialog...');
          Future.microtask(() {
            final speed = intent.params['speed'] as int?;
            final deviceName = intent.params['deviceName'] as String?;
            VoiceActionDialogs.showSpeedLimitDialog(
              presetSpeed: speed,
              mode: 'device',
              deviceName: deviceName,
            );
          });
          return ResponseBuilder.success(
            text: 'تفضل، اختر الجهاز والسرعة المناسبة',
          );

        case 'action.speed.disable':
          try {
            final controller = Get.find<SpeedLimitController>();
            controller.isEnabled.value = false;
            await controller.saveData();
            return ResponseBuilder.success(text: 'تم إلغاء تحديد السرعة لجميع الأجهزة');
          } catch (e) {
            VoiceLogger.logError('Failed to disable speed limit', e.toString());
            return ResponseBuilder.error('تعذر إلغاء تحديد السرعة');
          }

        // ─── استهلاك البيانات ───
        case 'action.usage.setQuota':
          final quota = intent.params['quota'] as int?;
          final unit = intent.params['unit'] as String? ?? 'GB';
          Future.microtask(() => VoiceActionDialogs.showQuotaDialog(
            presetQuota: quota,
            presetUnit: unit,
          ));
          return ResponseBuilder.success(
            text: 'تفضل، حدد حجم الباقة المسموح بها',
          );

        // ─── إعدادات النظام ───
        case 'action.settings.darkMode':
          try {
            final mode = intent.params['mode'] as String? ?? 'toggle';
            if (mode == 'dark') {
              Get.changeThemeMode(ThemeMode.dark);
              return ResponseBuilder.success(text: 'تم تفعيل الوضع الليلي');
            } else if (mode == 'light') {
              Get.changeThemeMode(ThemeMode.light);
              return ResponseBuilder.success(text: 'تم تفعيل الوضع النهاري');
            } else {
              final isDark = Get.isDarkMode;
              Get.changeThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
              return ResponseBuilder.success(
                text: isDark ? 'تم التحويل إلى الوضع النهاري' : 'تم التحويل إلى الوضع الليلي',
              );
            }
          } catch (e) {
            return ResponseBuilder.error('تعذر تغيير وضع العرض');
          }

        case 'action.settings.biometric':
          Get.to(() => WifiSettingsPage());
          return ResponseBuilder.success(text: 'افتح الإعدادات لتفعيل أو تعطيل تسجيل الدخول بالبصمة');

        case 'action.settings.networkMode':
          Get.to(() => WifiSettingsPage());
          return ResponseBuilder.success(text: 'افتح الإعدادات لتغيير نوع شبكة الاتصال');

        // ═══════════════════════════════════════════════════
        // ─── التنقل الشامل ────────────────────────────────
        // ═══════════════════════════════════════════════════
        case 'navigate.page':
          final page = intent.params['page'] as String? ?? '';
          final rawText = (intent.params['rawText'] as String?) ?? '';

          switch (page) {
            case 'settings':
              Get.to(() => WifiSettingsPage());
              return ResponseBuilder.success(text: 'تم فتح إعدادات الواي فاي');
            case 'bill':
              Get.to(() => WifiSettingsPage());
              return ResponseBuilder.success(text: 'تم فتح شاشة الرصيد');
            case 'devices':
              Get.to(() => ConnectedDevicesPage());
              return ResponseBuilder.success(text: 'تم فتح قائمة الأجهزة المتصلة');
            case 'mac_filter':
              Get.to(() => MacFilterPage());
              return ResponseBuilder.success(text: 'تم فتح إعدادات الحظر والأمان');
            case 'signal_finder':
              Get.to(() => SignalFinderPage());
              return ResponseBuilder.success(text: 'تم تشغيل رادار الإشارة');
            case 'speed_test':
              Get.to(() => SpeedTestPage());
              return ResponseBuilder.success(text: 'تم فتح فحص السرعة');
            case 'parental_control':
              Get.to(() => ParentalControlPage());
              return ResponseBuilder.success(text: 'تم فتح شاشة الرقابة الأبوية');
            case 'data_usage':
              Get.to(() => DataUsagePage());
              return ResponseBuilder.success(text: 'تم فتح شاشة استهلاك البيانات');
            case 'speed_limit':
              Get.to(() => SpeedLimitPage());
              return ResponseBuilder.success(text: 'تم فتح شاشة تحديد السرعة');
            default:
              if (rawText.contains('واي فاي') || rawText.contains('اعدادات')) {
                Get.to(() => WifiSettingsPage());
                return ResponseBuilder.success(text: 'تم فتح إعدادات الواي فاي');
              } else if (rawText.contains('حظر') || rawText.contains('فلتر')) {
                Get.to(() => MacFilterPage());
                return ResponseBuilder.success(text: 'تم فتح إعدادات الحظر');
              } else if (rawText.contains('رادار') || rawText.contains('اشاره') || rawText.contains('تغطيه')) {
                Get.to(() => SignalFinderPage());
                return ResponseBuilder.success(text: 'تم تشغيل الرادار');
              } else if (rawText.contains('سرعه') || rawText.contains('فحص')) {
                Get.to(() => SpeedTestPage());
                return ResponseBuilder.success(text: 'تم فتح فحص السرعة');
              }
              return ResponseBuilder.error('عفواً، لم أتعرف على الشاشة المطلوبة');
          }

        default:
          final resp = ResponseBuilder.error('الأمر غير مدعوم حالياً');
          VoiceLogger.logExecution(intent.action, false, resp.displayText);
          return resp;
      }
    } catch (e) {
      VoiceLogger.logError('Execution failed for ${intent.action}', e.toString());
      return ResponseBuilder.error('حدثت مشكلة أثناء التنفيذ');
    }

    VoiceLogger.logExecution(intent.action, false, 'No valid logic matched');
    return ResponseBuilder.error('لم أتمكن من التنفيذ');
  }
}
