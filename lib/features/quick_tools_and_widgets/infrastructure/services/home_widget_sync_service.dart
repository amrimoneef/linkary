import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:home_widget/home_widget.dart';
import '../../../modem_auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/quick_tools_state_entity.dart';
import '../../domain/entities/widget_config_entity.dart';
import '../../../../core/services/balance_tracking_service.dart';

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
      // 1. تجميع وحفظ البيانات الأساسية المشتركة دفعة واحدة (Batch writes)
      final saveTasks = <Future<dynamic>>[
        HomeWidget.saveWidgetData<bool>('is_connected', state.isConnected),
        HomeWidget.saveWidgetData<String>('balance_text', state.balanceText),
        HomeWidget.saveWidgetData<String>('days_remaining', state.daysRemaining),
        HomeWidget.saveWidgetData<int>('battery_level', state.batteryLevel),
        HomeWidget.saveWidgetData<bool>('is_charging', state.isCharging),
        HomeWidget.saveWidgetData<int>('signal_bars', state.signalBars),
        HomeWidget.saveWidgetData<String>('signal_text', state.signalText),
        HomeWidget.saveWidgetData<int>('devices_count', state.connectedDevicesCount),
        HomeWidget.saveWidgetData<String>('network_speed', state.networkSpeed),
        HomeWidget.saveWidgetData<String>('last_updated_time', state.lastUpdated12h),
        HomeWidget.saveWidgetData<String>('package_name', state.cleanPackageName),
        HomeWidget.saveWidgetData<String>('balance_val', state.balanceNumericValue),
        HomeWidget.saveWidgetData<String>('balance_unit', state.balanceUnit),
        HomeWidget.saveWidgetData<String>('total_text', state.accumulatedUsageText),
        HomeWidget.saveWidgetData<String>('consumed_text', state.currentSessionUsageText),
        HomeWidget.saveWidgetData<int>('quota_progress_int', state.quotaProgressPercent),
        HomeWidget.saveWidgetData<String>('theme_mode', config.theme.name),
        HomeWidget.saveWidgetData<int>('total_plan_bytes', state.totalPlanBytes),
      ];

      // حفظ session_id لاستخدامه في إعادة تشغيل المودم من الويدجت بلا فتح التطبيق
      try {
        if (Get.isRegistered<AuthController>()) {
          final sid = Get.find<AuthController>().currentUser?.sessionId;
          if (sid != null && sid.isNotEmpty) {
            saveTasks.add(HomeWidget.saveWidgetData<String>('modem_session_id', sid));
          }
        }
      } catch (_) {}

      // حفظ بيانات تتبع الرصيد حتى يتمكن كود Kotlin في الويدجت من إعادة حساب الرصيد فوراً
      try {
        final tracking = await BalanceTrackingService.getData();
        if (tracking != null) {
          saveTasks.add(HomeWidget.saveWidgetData<int>('tracking_balance_bytes', tracking.lastFetchedBalanceBytes));
          saveTasks.add(HomeWidget.saveWidgetData<int>('tracking_initial_usage', tracking.initialRouterUsageBytes));
        }
      } catch (_) {}

      // تنفيذ كافة عمليات الحفظ بالتوازي دفعة واحدة
      await Future.wait(saveTasks);

      // 2. طلب تحديث كافة قوالب الويدجت النشطة بالتوازي
      await Future.wait([
        HomeWidget.updateWidget(
          name: smallWidgetProvider,
          androidName: smallWidgetProvider,
        ),
        HomeWidget.updateWidget(
          name: bannerWidgetProvider,
          androidName: bannerWidgetProvider,
        ),
        HomeWidget.updateWidget(
          name: detailedWidgetProvider,
          androidName: detailedWidgetProvider,
        ),
      ]);

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

  static const MethodChannel _tileChannel = MethodChannel('com.linkary/quick_settings_tile');

  /// طلب إضافة الـ Quick Settings Tile إلى ستارة الإشعارات العلوية
  Future<bool> requestAddQuickSettingsTile() async {
    try {
      final res = await _tileChannel.invokeMethod<bool>('requestAddTile');
      return res ?? false;
    } catch (e) {
      if (kDebugMode) print('❌ [HomeWidgetSyncService] requestAddTile error: $e');
      return false;
    }
  }

  /// فحص هل إضافة الـ Tile مدعومة برمجياً بنظام أندرويد (Android 13+)
  Future<bool> isTileAddSupported() async {
    try {
      final res = await _tileChannel.invokeMethod<bool>('isTileAddSupported');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// طلب تحديث الـ Quick Settings Tile فوراً
  Future<void> updateQuickSettingsTile() async {
    try {
      await _tileChannel.invokeMethod<void>('updateTile');
    } catch (_) {}
  }
}
