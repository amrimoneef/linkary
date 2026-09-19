import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import '../../../../core/services/balance_tracking_service.dart';
import '../../domain/entities/quick_tools_state_entity.dart';
import '../../../modem_auth/presentation/controllers/auth_controller.dart';

class QuickNotificationService {
  static const int notificationId = 8888;
  static const String channelId = 'quick_tools_persistent_channel';
  static const String channelName = 'مراقبة المودم المستمرة';
  static const String channelDesc = 'عرض حي ودائم لحالة الرصيد والبطارية والاتصال';

  static const MethodChannel _nativeChannel =
      MethodChannel('com.linkary/quick_notification');

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationAction,
    );
    _isInitialized = true;
  }

  void _onNotificationAction(NotificationResponse response) {
    if (kDebugMode) {
      debugPrint('🔔 [QuickNotificationService] Action clicked: ${response.actionId}');
    }
  }

  /// إظهار أو تحديث الإشعار التفاعلي الدائم
  /// يحاول أولاً تشغيل الواجهة الأصلية المخصصة (RemoteViews Custom View) المستوحاة من مشروع Stitch
  /// مع الرجوع للإشعار القياسي المنظم في حال عدم توفرها.
  Future<void> showOrUpdate(QuickToolsStateEntity state) async {
    final updateTime = state.lastUpdated12h;
    final quotaProgress = state.quotaProgressPercent;

    final cleanPackage = state.cleanPackageName
        .replaceAll(RegExp(r'[_-\s]*DATA_ONLY[_-\s]*', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\b4G\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\bGB\b', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final totalPlan = cleanPackage.startsWith('من أصل')
        ? cleanPackage
        : (cleanPackage == 'باقة نشطة'
            ? 'من أصل باقة نشطة'
            : (cleanPackage.startsWith('باقة')
                ? 'من أصل $cleanPackage GB'
                : 'من أصل $cleanPackage GB'));

    // 💾 جلب session_id لإرساله للكود الأصلي حتى يتمكن WidgetActionReceiver من إعادة التشغيل بلا فتح التطبيق
    String? sessionId;
    try {
      sessionId = Get.find<AuthController>().currentUser?.sessionId;
    } catch (_) {}

    try {
      await _nativeChannel.invokeMethod('showCustomNotification', {
        'is_connected': state.isConnected,
        'balance_text': state.balanceText,
        'days_remaining': state.daysRemaining,
        'battery_level': state.batteryLevel,
        'is_charging': state.isCharging,
        'signal_bars': state.signalBars,
        'signal_text': state.signalText,
        'devices_count': state.connectedDevicesCount,
        'last_updated_time': updateTime,
        'quota_progress': quotaProgress,
        'total_plan': totalPlan,
        'session_id': sessionId, // 🔑 مفتاح إعادة التشغيل من الويدجت
      });
      return;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ [QuickNotificationService] Native RemoteViews notification fallback: $e');
      }
    }

    // Standard Fallback Notification via flutter_local_notifications
    await _ensureInitialized();

    final connectionStatus = state.isConnected ? 'متصل بالشبكة' : 'غير متصل';
    final title = 'مودم SAM4G • $connectionStatus';
    final chargingStatus = state.isCharging ? ' (جارٍ الشحن)' : '';
    final collapsedSummary =
        'الرصيد: ${state.balanceText}  •  البطارية: ${state.batteryLevel}%$chargingStatus  •  الأجهزة: ${state.connectedDevicesCount}';

    final batteryStateText = state.isCharging
        ? '${state.batteryLevel}% — جارٍ الشحن'
        : '${state.batteryLevel}% — على البطارية';

    final detailedBody =
        '• الرصيد المتبقي: ${state.balanceText} (${state.daysRemaining})\n'
        '• حالة الطاقة: $batteryStateText\n'
        '• تغطية الشبكة: ${state.signalText}\n'
        '• الأجهزة المتصلة: ${state.connectedDevicesCount} جهاز نشط\n'
        '• سرعة النقل الحالية: ${state.networkSpeed}\n'
        '• آخر تحديث: $updateTime';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      showWhen: true,
      color: const Color(0xFF4A90E2),
      subText: 'مراقبة حية',
      styleInformation: BigTextStyleInformation(
        detailedBody,
        contentTitle: title,
        summaryText: collapsedSummary,
      ),
      actions: const [
        AndroidNotificationAction(
          'action_refresh',
          'تحديث البيانات',
          showsUserInterface: false,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          'action_open_bill',
          'عرض الرصيد',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'action_reboot',
          'إعادة التشغيل',
          showsUserInterface: false,
        ),
      ],
    );

    final details = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.show(
        id: notificationId,
        title: title,
        body: collapsedSummary,
        notificationDetails: details,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ [QuickNotificationService] showOrUpdate error: $e');
    }
  }

  /// إخفاء وإلغاء الإشعار عند إيقاف الميزة
  Future<void> cancel() async {
    // إلغاء الإشعار الأصلي (RemoteViews) أولاً
    try {
      await _nativeChannel.invokeMethod('cancelCustomNotification');
      if (kDebugMode) debugPrint('🔕 [QuickNotificationService] Native notification canceled.');
      return; // نجح - لا حاجة لإلغاء Flutter
    } catch (_) {}

    // fallback: إلغاء إشعار Flutter القياسي إن وجد
    if (_isInitialized) {
      try {
        await _notificationsPlugin.cancel(id: notificationId);
        if (kDebugMode) debugPrint('🔕 [QuickNotificationService] Flutter notification canceled.');
      } catch (e) {
        if (kDebugMode) debugPrint('❌ [QuickNotificationService] cancel error: $e');
      }
    }
  }

  /// فحص الإجراء القادم من ضغطات الويدجت أو الإشعار أثناء بدء التشغيل
  Future<String?> getPendingAction() async {
    try {
      return await _nativeChannel.invokeMethod<String>('getPendingAction');
    } catch (_) {
      return null;
    }
  }

  /// الاستماع للإجراءات القادمة من أزرار الويدجت أو الإشعار أثناء عمل التطبيق
  void setActionListener(void Function(String action) listener) {
    _nativeChannel.setMethodCallHandler((call) async {
      if (call.method == 'onActionReceived' && call.arguments is String) {
        listener(call.arguments as String);
      }
    });
  }
}
