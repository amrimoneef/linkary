import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';
import '../../../modem_auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/quick_tools_state_entity.dart';
import '../../domain/entities/widget_config_entity.dart';

class HomeWidgetSyncService {
  static const String appGroupId = 'group.com.sam4g.app_settings';
  static const String smallWidgetProvider = 'WidgetSmallProvider';
  static const String bannerWidgetProvider = 'WidgetBannerProvider';
  static const String detailedWidgetProvider = 'WidgetDetailedProvider';

  HomeWidgetSyncService() {
    _init();
  }

  void _init() {
    try {
      HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      if (kDebugMode) print('⚠️ [HomeWidgetSyncService] init error: $e');
    }
  }

  /// مزامنة أحدث بيانات المودم والباقة مع جميع الويدجت النشطة على الشاشة الرئيسية
  Future<void> syncData({
    required QuickToolsStateEntity state,
    required WidgetConfigEntity config,
  }) async {
    try {
      // 1. حفظ البيانات الأساسية المشتركة
      await HomeWidget.saveWidgetData<bool>('is_connected', state.isConnected);
      await HomeWidget.saveWidgetData<String>('balance_text', state.balanceText);
      await HomeWidget.saveWidgetData<String>('days_remaining', state.daysRemaining);
      await HomeWidget.saveWidgetData<int>(
        'battery_level',
        state.batteryLevel,
      );
      await HomeWidget.saveWidgetData<bool>('is_charging', state.isCharging);
      await HomeWidget.saveWidgetData<int>('signal_bars', state.signalBars);
      await HomeWidget.saveWidgetData<String>('signal_text', state.signalText);
      await HomeWidget.saveWidgetData<int>(
        'devices_count',
        state.connectedDevicesCount,
      );
      await HomeWidget.saveWidgetData<String>(
        'network_speed',
        state.networkSpeed,
      );
      await HomeWidget.saveWidgetData<String>(
        'last_updated_time',
        state.lastUpdated12h,
      );
      await HomeWidget.saveWidgetData<String>(
        'package_name',
        state.cleanPackageName,
      );
      await HomeWidget.saveWidgetData<String>(
        'balance_val',
        state.balanceNumericValue,
      );
      await HomeWidget.saveWidgetData<String>(
        'balance_unit',
        state.balanceUnit,
      );
      await HomeWidget.saveWidgetData<String>(
        'total_text',
        state.accumulatedUsageText,
      );
      await HomeWidget.saveWidgetData<String>(
        'consumed_text',
        state.currentSessionUsageText,
      );
      await HomeWidget.saveWidgetData<int>(
        'quota_progress_int',
        state.quotaProgressPercent,
      );
      await HomeWidget.saveWidgetData<String>('theme_mode', config.theme.name);

      // حفظ session_id لاستخدامه في إعادة تشغيل المودم من الويدجت بلا فتح التطبيق
      try {
        if (Get.isRegistered<AuthController>()) {
          final sid = Get.find<AuthController>().currentUser?.sessionId;
          if (sid != null && sid.isNotEmpty) {
            await HomeWidget.saveWidgetData<String>('modem_session_id', sid);
          }
        }
      } catch (_) {}

      // 2. طلب تحديث كافة قوالب الويدجت النشطة
      await HomeWidget.updateWidget(
        name: smallWidgetProvider,
        androidName: smallWidgetProvider,
      );
      await HomeWidget.updateWidget(
        name: bannerWidgetProvider,
        androidName: bannerWidgetProvider,
      );
      await HomeWidget.updateWidget(
        name: detailedWidgetProvider,
        androidName: detailedWidgetProvider,
      );

      if (kDebugMode) {
        print('✨ [HomeWidgetSyncService] Synced data to Android Home Widgets.');
      }
    } catch (e) {
      if (kDebugMode) print('❌ [HomeWidgetSyncService] syncData error: $e');
    }
  }

  /// طلب إضافة وتثبيت الويدجت على الشاشة الرئيسية مباشرة عبر نظام أندرويد
  Future<bool> pinWidget(String providerName) async {
    try {
      final isRequestPinSupported = await HomeWidget.isRequestPinWidgetSupported();
      if (isRequestPinSupported == true) {
        await HomeWidget.requestPinWidget(androidName: providerName);
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('❌ [HomeWidgetSyncService] pinWidget error: $e');
      return false;
    }
  }
}
