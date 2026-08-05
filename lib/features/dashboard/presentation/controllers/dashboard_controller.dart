import 'dart:async';
import 'package:get/get.dart';
import '../../../../core/utils/session_helper.dart';
import '../../../settings/domain/usecases/get_wifi_settings_usecase.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/entities/engineering_info_entity.dart';
import '../../domain/entities/band_config_entity.dart';
import 'package:linkary/core/widgets/custom_snackbar.dart';
import '../../domain/usecases/get_dashboard_data_usecase.dart';
import '../../domain/usecases/get_engineering_info_usecase.dart';
import '../../../data_usage/domain/usecases/data_usage_usecases.dart';
import '../../../connected_devices/domain/usecases/get_connected_devices_usecase.dart';
import '../../infrastructure/data_sources/connection_manager_data_source.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class DashboardController extends GetxController with WidgetsBindingObserver {
  final GetDashboardDataUseCase getDashboardDataUseCase;
  final GetEngineeringInfoUseCase getEngineeringInfoUseCase;
  final GetDataUsageUseCase getDataUsageUseCase;
  final GetWifiSettingsUseCase getWifiSettingsUseCase;
  final GetConnectedDevicesUseCase getConnectedDevicesUseCase;

  DashboardController({
    required this.getDashboardDataUseCase,
    required this.getEngineeringInfoUseCase,
    required this.getDataUsageUseCase,
    required this.getWifiSettingsUseCase,
    required this.getConnectedDevicesUseCase,
  });

  // متغيرات الحالة (Reactive State)
  var isLoading = true.obs;
  var errorMessage = ''.obs;
  var isDataConnected = true.obs;
  var isTogglingData = false.obs;

  // الكيان الذي يحمل بيانات المودم
  var dashboardData = Rxn<DashboardEntity>();

  var isEngLoading = false.obs;
  var engErrorMessage = ''.obs;
  var engInfoData = Rxn<EngineeringInfoEntity>();

  // ➕ نسبة استهلاك البيانات (للواجهة التفاعلية)
  var usagePercentage = 0.0.obs;

  // ➕ اسم الواي فاي (SSID)
  var wifiSsid = 'جاري التحميل...'.obs;

  // ➕ عدد الأجهزة المتصلة
  var connectedDevicesCount = 0.obs;

  // ➕ عرض الباقة المختارة
  var selectedPlanDisplay = 'غير محدود'.obs;
  var isPlanSet = false.obs;

  // إعدادات الباند
  var bandConfig = Rxn<BandConfigEntity>();
  var isBandLoading = false.obs;
  var isBandSaving = false.obs;

  // Notification Flags
  bool _hasWarnedBattery = false;
  bool _hasWarnedSignal = false;
  bool _hasWarnedDataLimit = false;

  Timer? _pollingTimer;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    fetchData();
    fetchBandConfig();
    _startPolling();
  }

  @override
  void onClose() {
    _pollingTimer?.cancel(); 
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Return to foreground: Restart polling immediately
      _startPolling();
      fetchData(); 
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Go to background: Stop polling to prevent network timeouts from causing logout
      _pollingTimer?.cancel();
      _pollingTimer = null;
      if (kDebugMode) debugPrint('⏸️ Dashboard Polling paused — preventing background logout.');
    }
  }


  Future<void> fetchData() async {
    isLoading.value = true;
    errorMessage.value = '';



    try {
      final result = await getDashboardDataUseCase.execute();
      dashboardData.value = result;
      isDataConnected.value = result.isDataConnected;
    } catch (e) {
      if (SessionHelper.handleSessionError(e)) {
        _pollingTimer?.cancel();
        return;
      } else {
        errorMessage.value = e.toString().replaceAll('Exception:', '').trim();
        if (kDebugMode) print("❌ خطأ في لوحة التحكم: ${errorMessage.value}");
      }
    } finally {
      isLoading.value = false;
      
      // جلب استهلاك البيانات واسم الواي فاي وعدد المتصلين
      try {
        final wifiSettings = await getWifiSettingsUseCase.execute();
        wifiSsid.value = wifiSettings.ssid;
      } catch (_) {}

      try {
        final devices = await getConnectedDevicesUseCase.execute();
        connectedDevicesCount.value = devices.length;
      } catch (_) {}

      if (dashboardData.value != null) {
        try {
          final dataUsage = await getDataUsageUseCase.execute();
          _checkSmartNotifications(dashboardData.value!, dataUsage);
        } catch (_) {
          _checkSmartNotifications(dashboardData.value!, null);
        }
      }

    }
  }

  Future<void> fetchEngineeringInfo({bool showLoading = true}) async {
    if (showLoading) isEngLoading.value = true;
    engErrorMessage.value = '';

    try {
      final result = await getEngineeringInfoUseCase.execute();
      engInfoData.value = result;
    } catch (e) {
      if (!showLoading) return; // لا تظهر خطأ في الاستعلام الدوري
      engErrorMessage.value = e.toString().replaceAll('Exception:', '').trim();
    } finally {
      if (showLoading) isEngLoading.value = false;
    }
  }

  Future<void> switchDataConnection() async {
    if (isTogglingData.value) return; // منع الضغط المتكرر

    isTogglingData.value = true;
    final dataSource = ConnectionManagerDataSource();

    // إرسال العكس (إذا كان متصلاً، أرسل قطع، والعكس)
    final targetState = !isDataConnected.value;

    final success = await dataSource.toggleDataConnection(connect: targetState);

    if (success) {
      isDataConnected.value = targetState;
      CustomSnackbar.showSuccess(
          targetState ? 'تم الاتصال' : 'تم قطع الاتصال',
          targetState ? 'بيانات الإنترنت تعمل الآن' : 'تم إيقاف استهلاك البيانات'
      );
    } else {
      CustomSnackbar.showError('خطأ', 'لم نتمكن من تغيير حالة الاتصال، حاول مجدداً.');
    }

    isTogglingData.value = false;
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final result = await getDashboardDataUseCase.execute();
        var temp = result;
        dashboardData.value = temp;
        isDataConnected.value = temp.isDataConnected;
        
        // جلب بيانات الرادار (Engineering Info) دورياً
        fetchEngineeringInfo(showLoading: false);

        // جلب استهلاك البيانات للتحقق من الحد الأقصى للباقة
        try {
          final dataUsage = await getDataUsageUseCase.execute();
          _checkSmartNotifications(temp, dataUsage);
        } catch (_) {
          _checkSmartNotifications(temp, null);
        }

        // تحديث البيانات الثانوية في الخلفية
        try {
          final wifiSettings = await getWifiSettingsUseCase.execute();
          wifiSsid.value = wifiSettings.ssid;
        } catch (_) {}

        try {
          final devices = await getConnectedDevicesUseCase.execute();
          connectedDevicesCount.value = devices.length;
        } catch (_) {}
        
        update();
      } catch (e) {
        // ➕ الحماية الذكية: إذا انتهت الجلسة، نوقف العداد ونطرد المستخدم لشاشة الدخول
        if (SessionHelper.handleSessionError(e)) {
          _pollingTimer?.cancel(); // إيقاف الاستعلام
        }
      }
    });
  }

  // ➕ دالة مساعدة هندسية لتحويل السرعة (Bytes -> KB/MB)
  String formatSpeed(int bytes) {
    if (bytes < 1024) return '$bytes B/s';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB/s';
  }

  // دالة تحويل البايتات إلى مساحة مقروءة
  String formatDataUsage(int bytes) {
    if (bytes == 0) return '0 MB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  // دالة تحويل الثواني إلى صيغة وقت (ساعات:دقائق:ثواني)
  String formatDuration(int seconds) {
    Duration duration = Duration(seconds: seconds);
    return duration.toString().split('.').first.padLeft(8, "0");
  }

    // دالة تحويل الثواني إلى صيغة ايام وقت (ايام ساعات00:دقائق00:ثواني00)
    String formatTotalDuration(int seconds) {
      Duration duration = Duration(seconds: seconds);
      int days = duration.inDays;
      String hours = duration.inHours.remainder(24).toString().padLeft(2, "0");
      String minutes = duration.inMinutes.remainder(60).toString().padLeft(2, "0");
      String secs = duration.inSeconds.remainder(60).toString().padLeft(2, "0");
      return "$hours:$minutes:$secs ${days > 0 ? '$days يوم' : ''}";
    }

  // 🔔 إشعارات ذكية
  void _checkSmartNotifications(DashboardEntity data, dynamic dataUsage) {
    // 1. Battery Notification
    if (data.batteryCapacity <= 20 && !data.isCharging && !_hasWarnedBattery) {
      CustomSnackbar.showWarning('تنبيه البطارية', 'البطارية منخفضة (${data.batteryCapacity}%). يرجى توصيل الشاحن.');
      _hasWarnedBattery = true;
    } else if (data.isCharging || data.batteryCapacity > 20) {
      _hasWarnedBattery = false;
    }

    // 2. Signal Notification
    if (data.signalLevel <= 2 && !_hasWarnedSignal) {
      CustomSnackbar.showWarning('تنبيه الإشارة', 'إشارة الشبكة ضعيفة. حاول تغيير مكان المودم لتحسين الأداء.');
      _hasWarnedSignal = true;
    } else if (data.signalLevel > 2) {
      _hasWarnedSignal = false;
    }
    
    // 3. Data Limit Notification (90%+)
    if (dataUsage != null && dataUsage.packageType == 'unlimited' && dataUsage.packageDataBytes > 0) {
      isPlanSet.value = true;
      // تحديث مسمى الباقة
      selectedPlanDisplay.value = '${(dataUsage.packageDataBytes / (1024 * 1024 * 1024)).toStringAsFixed(0)} GB';

      double percentage = dataUsage.usedDataBytes / dataUsage.packageDataBytes;
      usagePercentage.value = percentage.clamp(0.0, 1.0); // تعيين النسبة للواجهة
      
      if (percentage >= 0.9 && !_hasWarnedDataLimit) {
        CustomSnackbar.showWarning('تنبيه الباقة', 'لقد استهلكت ${(percentage * 100).toInt()}% من باقة البيانات الخاصة بك.');
        _hasWarnedDataLimit = true;
      } else if (percentage < 0.9) {
        _hasWarnedDataLimit = false;
      }
    } else {
      isPlanSet.value = false;
      // إذا لم يكن هناك باقة محددة، نعرض نسبة بسيطة كشكل تفاعلي أو 0
      selectedPlanDisplay.value = 'غير محدود';
      usagePercentage.value = 0.0;
    }
  }

  Future<void> fetchBandConfig() async {
    isBandLoading.value = true;
    try {
      final dataSource = ConnectionManagerDataSource();
      bandConfig.value = await dataSource.getBands();
    } catch (e) {
      if (!SessionHelper.handleSessionError(e)) {
        CustomSnackbar.showError('خطأ', 'تعذر جلب إعدادات الباند');
      }
    } finally {
      isBandLoading.value = false;
    }
  }

  Future<void> saveBandConfig(bool isAuto, List<int> selectedBands) async {
    isBandSaving.value = true;
    try {
      final dataSource = ConnectionManagerDataSource();
      final payload = {
        "band_select": isAuto ? "off" : "on",
        "bands": {
          "lte": isAuto ? (bandConfig.value?.supportedBands ?? [3, 28, 41]) : selectedBands,
        }
      };
      
      final success = await dataSource.setBands(payload);
      if (success) {
        CustomSnackbar.showSuccess('نجاح', 'تم تطبيق الباند بنجاح.');
        await fetchBandConfig();
      } else {
        CustomSnackbar.showError('خطأ', 'تعذر حفظ إعدادات الباند');
      }
    } catch (e) {
      if (!SessionHelper.handleSessionError(e)) {
        CustomSnackbar.showError('خطأ', 'تعذر حفظ إعدادات الباند');
      }
    } finally {
      isBandSaving.value = false;
    }
  }
}
