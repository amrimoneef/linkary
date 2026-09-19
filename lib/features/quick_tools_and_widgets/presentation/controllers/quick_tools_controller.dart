import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../bill/presentation/controllers/bill_controller.dart';
import '../../../main_layout/presentation/controllers/main_layout_controller.dart';
import '../../../modem_auth/presentation/controllers/auth_controller.dart';
import '../../../bill/presentation/pages/bill_page.dart';
import '../../../../core/services/balance_tracking_service.dart';
import '../../domain/entities/quick_tools_state_entity.dart';
import '../../domain/entities/widget_config_entity.dart';
import '../../domain/repositories/quick_tools_repository.dart';
import '../../infrastructure/services/home_widget_sync_service.dart';
import '../../infrastructure/services/quick_notification_service.dart';

class QuickToolsController extends GetxController {
  final QuickToolsRepository repository;
  final HomeWidgetSyncService homeWidgetSyncService;
  final QuickNotificationService quickNotificationService;

  QuickToolsController({
    required this.repository,
    required this.homeWidgetSyncService,
    required this.quickNotificationService,
  });

  final RxBool isNotificationEnabled = false.obs;
  final Rx<WidgetConfigEntity> widgetConfig = const WidgetConfigEntity().obs;
  final Rx<QuickToolsStateEntity> state = QuickToolsStateEntity(
    lastUpdated: DateTime.now(),
  ).obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedSettings();
    _setupReactiveListeners();
  }

  Future<void> _loadSavedSettings() async {
    isNotificationEnabled.value = await repository.isNotificationEnabled();
    widgetConfig.value = await repository.getWidgetConfig();
    updateLiveState();
  }

  void _setupReactiveListeners() {
    // الاستماع لأي تحديث في شاشة لوحة التحكم
    if (Get.isRegistered<DashboardController>()) {
      final dashController = Get.find<DashboardController>();
      ever(dashController.dashboardData, (_) => updateLiveState());
    }

    // الاستماع لأي تحديث في شاشة الرصيد (البيانات والرصيد المتوقع)
    if (Get.isRegistered<BillController>()) {
      final billController = Get.find<BillController>();
      ever(billController.billData, (_) => updateLiveState());
      ever(billController.expectedBalanceBytes, (_) => updateLiveState());
    }
  }

  /// تفعيل أو تعطيل الإشعار التفاعلي الدائم
  Future<void> toggleNotification(bool value) async {
    isNotificationEnabled.value = value;
    await repository.setNotificationEnabled(value);

    if (value) {
      await quickNotificationService.showOrUpdate(state.value);
      Get.snackbar(
        'شريط الإشعارات',
        'تم تفعيل الإشعار التفاعلي الدائم بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.teal.shade800,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } else {
      await quickNotificationService.cancel();
      Get.snackbar(
        'شريط الإشعارات',
        'تم إيقاف الإشعار التفاعلي الدائم',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.grey.shade900,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// تغيير مظهر الويدجت الزجاجي
  Future<void> changeTheme(GlassTheme theme) async {
    widgetConfig.value = widgetConfig.value.copyWith(theme: theme);
    await repository.saveWidgetConfig(widgetConfig.value);
    await homeWidgetSyncService.syncData(
      state: state.value,
      config: widgetConfig.value,
    );
  }

  /// طلب إضافة وتثبيت الويدجت على الشاشة الرئيسية مباشرة
  Future<void> pinWidget(String providerName) async {
    final success = await homeWidgetSyncService.pinWidget(providerName);
    if (success) {
      Get.snackbar(
        'الويدجت الزجاجية',
        'تم إرسال طلب إضافة الويدجت إلى الشاشة الرئيسية بنجاح 📌',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0F172A),
        colorText: const Color(0xFF38BDF8),
        icon: const Icon(Icons.check_circle, color: Color(0xFF38BDF8)),
        duration: const Duration(seconds: 3),
      );
    } else {
      Get.snackbar(
        'الويدجت الزجاجية',
        'يرجى إضافة الويدجت يدوياً بالضغط المطول على شاشتك الرئيسية واختيار Linkary',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.amber.shade900,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    }
  }

  /// تحديث الحالة الحية ومزامنتها مع الإشعار والويدجت
  Future<void> updateLiveState() async {
    bool isConnected = false;
    int batteryLevel = 0;
    bool isCharging = false;
    int signalBars = 0;
    String signalText = 'غير متصل';
    int devicesCount = 0;
    String balanceText = '-- GB';
    String daysRemaining = '-- يوم متبقي';
    String networkSpeed = '0 KB/s';
    int currentSessionUsageBytes = 0;
    int totalAccumulatedUsageBytes = 0;
    int totalPlanBytes = 0;

    if (Get.isRegistered<DashboardController>()) {
      final dash = Get.find<DashboardController>();
      final data = dash.dashboardData.value;
      if (data != null) {
        isConnected = true;
        batteryLevel = data.batteryCapacity;
        isCharging = data.isCharging;
        signalBars = data.signalLevel;
        signalText = '${data.networkType.toUpperCase()} • ${data.signalLevel}/5';
        devicesCount = dash.connectedDevicesCount.value;
        networkSpeed = dash.formatSpeed(data.rxSpeed);
        currentSessionUsageBytes = data.currentUsage;
        totalAccumulatedUsageBytes = data.totalUsage;
      }
    }

    // جلب الرصيد المتوقع والأيام المتبقية
    int? expectedBytes;
    String? rawExpiryDate;

    String packageName = 'باقة نشطة';

    if (Get.isRegistered<BillController>()) {
      final bill = Get.find<BillController>();
      expectedBytes = bill.expectedBalanceBytes.value;
      rawExpiryDate = bill.balanceTrackingData?.expiryDate;
      if (bill.packageName.value.isNotEmpty) {
        packageName = bill.packageName.value;
      } else if (bill.balanceTrackingData?.packageName != null && bill.balanceTrackingData!.packageName!.isNotEmpty) {
        packageName = bill.balanceTrackingData!.packageName!;
      }

      final billData = bill.billData.value?.data;
      if (billData != null) {
        for (final entry in billData.entries) {
          final k = entry.key;
          final v = entry.value;
          if (expectedBytes == null && (k.contains('الرصيد المتاح') || k.contains('الرصيد المتبقي') || k.contains('البيانات'))) {
            if (v.toLowerCase().contains('gb') || v.toLowerCase().contains('mb') || v.contains('جيجا') || v.contains('ميجا')) {
              balanceText = v;
            }
          }
          if (rawExpiryDate == null && (k.contains('تاريخ') || k.contains('انتهاء') || k.contains('صلاحية'))) {
            rawExpiryDate = v;
          }
          if (k == 'الباقة' || k == 'اسم الباقة' || k.contains('باقة')) {
            if (v.trim().isNotEmpty) {
              packageName = v.trim();
            }
          }
        }
      }
    }

    // قراءة بيانات التتبع المحفوظة إذا لم تتوفر في الذاكرة الحالية
    if (expectedBytes == null || rawExpiryDate == null || packageName == 'باقة نشطة') {
      try {
        final tracking = await BalanceTrackingService.getData();
        if (tracking != null) {
          rawExpiryDate ??= tracking.expiryDate;
          if (packageName == 'باقة نشطة' && tracking.packageName != null && tracking.packageName!.isNotEmpty) {
            packageName = tracking.packageName!;
          }
          if (expectedBytes == null && tracking.lastFetchedBalanceBytes > 0) {
            int currentUsage = 0;
            if (Get.isRegistered<DashboardController>()) {
              currentUsage = Get.find<DashboardController>().dashboardData.value?.totalUsage ?? 0;
            }
            final initialUsage = tracking.initialRouterUsageBytes;
            final consumed = currentUsage >= initialUsage ? (currentUsage - initialUsage) : 0;
            final remaining = tracking.lastFetchedBalanceBytes - consumed;
            if (remaining > 0) {
              expectedBytes = remaining;
            }
          }
        }
      } catch (_) {}
    }

    // بديل من إعدادات لوحة التحكم إذا لم تتحدد من الفاتورة
    if (packageName == 'باقة نشطة' && Get.isRegistered<DashboardController>()) {
      final dash = Get.find<DashboardController>();
      if (dash.isPlanSet.value && dash.selectedPlanDisplay.value.isNotEmpty && dash.selectedPlanDisplay.value != 'غير محدود') {
        packageName = 'باقة ${dash.selectedPlanDisplay.value}';
      }
    }

    // تنظيف اسم الباقة بحذف DATA_ONLY
    packageName = _cleanPackageName(packageName);

    // حساب الحجم الكلي للباقة بالبايت
    final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(packageName);
    if (match != null) {
      final gb = double.tryParse(match.group(1)!) ?? 0.0;
      if (gb > 0) {
        totalPlanBytes = (gb * 1024 * 1024 * 1024).toInt();
      }
    }
    if (totalPlanBytes == 0 && expectedBytes != null && expectedBytes > 0) {
      final gb = expectedBytes / (1024 * 1024 * 1024);
      totalPlanBytes = (gb > 40 ? 80 : 40) * 1024 * 1024 * 1024;
    }

    if (expectedBytes != null && expectedBytes > 0) {
      final gb = expectedBytes / (1024 * 1024 * 1024);
      if (gb >= 1.0) {
        balanceText = '${gb.toStringAsFixed(2)} GB';
      } else {
        final mb = expectedBytes / (1024 * 1024);
        balanceText = '${mb.toStringAsFixed(0)} MB';
      }
    }

    if (rawExpiryDate != null && rawExpiryDate.trim().isNotEmpty) {
      daysRemaining = _calculateDaysRemaining(rawExpiryDate);
    }

    state.value = QuickToolsStateEntity(
      isNotificationEnabled: isNotificationEnabled.value,
      isConnected: isConnected,
      balanceText: balanceText,
      daysRemaining: daysRemaining,
      batteryLevel: batteryLevel,
      isCharging: isCharging,
      signalBars: signalBars,
      signalText: signalText,
      connectedDevicesCount: devicesCount,
      lastUpdated: DateTime.now(),
      networkSpeed: networkSpeed,
      packageName: packageName,
      currentSessionUsageBytes: currentSessionUsageBytes,
      totalAccumulatedUsageBytes: totalAccumulatedUsageBytes,
      expectedBalanceBytes: expectedBytes,
      totalPlanBytes: totalPlanBytes,
    );

    // مزامنة الويدجت
    await homeWidgetSyncService.syncData(
      state: state.value,
      config: widgetConfig.value,
    );

    // تحديث الإشعار إذا كان مفعلاً
    if (isNotificationEnabled.value) {
      await quickNotificationService.showOrUpdate(state.value);
    }
  }

  /// تنظيف اسم الباقة بحذف DATA_ONLY وأي زوائد غير مرغوبة
  String _cleanPackageName(String raw) {
    var cleaned = raw
        .replaceAll(RegExp(r'[_-\s]*DATA_ONLY[_-\s]*', caseSensitive: false), ' ')
        .trim();
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.isNotEmpty ? cleaned : raw;
  }

  /// حساب عدد الأيام المتبقية حتى تاريخ الانتهاء
  String _calculateDaysRemaining(String rawDate) {
    try {
      final clean = rawDate.trim().split(' ').first;
      DateTime? expiryDate;
      if (RegExp(r'^\d{2}[-/]\d{2}[-/]\d{4}$').hasMatch(clean)) {
        final sep = clean.contains('-') ? '-' : '/';
        final parts = clean.split(sep);
        expiryDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      } else if (RegExp(r'^\d{4}[-/]\d{2}[-/]\d{2}$').hasMatch(clean)) {
        final sep = clean.contains('-') ? '-' : '/';
        final parts = clean.split(sep);
        expiryDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      } else {
        expiryDate = DateTime.tryParse(clean);
      }

      if (expiryDate != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final target = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
        final diff = target.difference(today).inDays;
        if (diff > 0) {
          return 'متبقي $diff يوم';
        } else if (diff == 0) {
          return 'ينتهي اليوم';
        } else {
          return 'منتهي الصلاحية';
        }
      }
    } catch (_) {}
    return rawDate;
  }

  /// تحديث شامل لكافة مؤشرات المودم والرصيد
  Future<void> refreshAll() async {
    try {
      if (Get.isRegistered<DashboardController>()) {
        await Get.find<DashboardController>().fetchData();
      }
      if (Get.isRegistered<BillController>()) {
        await Get.find<BillController>().fetchBill();
      }
      await updateLiveState();
      Get.snackbar(
        'تحديث البيانات',
        'تم تحديث بيانات ومؤشرات المودم بنجاح ⚡',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF0F172A),
        colorText: const Color(0xFF38BDF8),
        icon: const Icon(Icons.check_circle_outline, color: Color(0xFF38BDF8)),
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      await updateLiveState();
    }
  }

  /// فتح شاشة الرصيد والاستعلام
  void openBalancePage() {
    if (Get.isRegistered<MainLayoutController>()) {
      Get.find<MainLayoutController>().changePage(3);
      Get.until((route) => route.isFirst);
    } else {
      Get.to(() => BillPage());
    }
  }

  /// إعادة تشغيل المودم
  Future<void> rebootModem() async {
    if (Get.isRegistered<AuthController>()) {
      await Get.find<AuthController>().reboot();
    } else {
      Get.snackbar(
        'إعادة التشغيل',
        'يرجى تسجيل الدخول إلى المودم أولاً',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade900,
        colorText: Colors.white,
      );
    }
  }
}
