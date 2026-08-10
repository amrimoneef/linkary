import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../mac_filter/domain/usecases/mac_filter_usecases.dart';
import '../../../modem_auth/presentation/controllers/auth_controller.dart';
import '../../../speed_limit/presentation/controllers/speed_limit_controller.dart';
import '../../domain/entities/connected_device_entity.dart';
import '../../domain/usecases/get_connected_devices_usecase.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../../core/utils/session_helper.dart';
import '../../../../core/services/device_names_service.dart';
import '../../../../core/services/battery_monitor_service.dart';
import '../../../../core/widgets/custom_snackbar.dart';
import '../../../../core/network/session_manager.dart';
import '../../infrastructure/services/background_device_monitor.dart';


class ConnectedDevicesController extends GetxController {
  final GetConnectedDevicesUseCase getConnectedDevicesUseCase;

  ConnectedDevicesController({required this.getConnectedDevicesUseCase});

  // حالة الشاشة التفاعلية
  var isLoading = true.obs;
  var errorMessage = ''.obs;

  // قائمة الأجهزة المتصلة
  var devices = <ConnectedDeviceEntity>[].obs;
  var myDeviceIp = ''.obs;

  // خريطة الأسماء المخصصة { mac: customName }
  var customNames = <String, String>{}.obs;

  // ─── مراقبة الأجهزة والفلترة ───
  var isBgMonitorEnabled = false.obs;
  var pendingMacs = <String>[].obs;       // الأجهزة المعلّقة (بانتظار الموافقة)
  var knownMacs = <String>[].obs;         // الأجهزة الموثوقة
  Timer? _foregroundTimer;                // مؤقت الفحص كل 20 ثانية

  // حالة الفلترة ('all', 'trusted', 'untrusted')
  var selectedFilter = 'all'.obs;

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  List<ConnectedDeviceEntity> get filteredDevices {
    if (!isBgMonitorEnabled.value || selectedFilter.value == 'all') {
      return devices;
    }
    if (selectedFilter.value == 'trusted') {
      return devices.where((d) => knownMacs.contains(d.mac)).toList();
    }
    if (selectedFilter.value == 'untrusted') {
      return devices.where((d) => !knownMacs.contains(d.mac)).toList();
    }
    return devices;
  }

  @override
  void onInit() {
    super.onInit();
    _loadBgMonitorState();
    fetchDevices();
  }

  @override
  void onClose() {
    _foregroundTimer?.cancel();
    super.onClose();
  }

  // ─── تحميل حالة مراقبة الخلفية ───
  Future<void> _loadBgMonitorState() async {
    final authController = Get.find<AuthController>();
    if (authController.currentSN.value == null) {
      await authController.fetchSerialNumber();
    }
    final sn = authController.currentSN.value;

    isBgMonitorEnabled.value = await SessionManager.isBackgroundDeviceMonitorEnabled(sn) ||
        await SessionManager.isBackgroundDeviceMonitorEnabled();
        
    knownMacs.value = await SessionManager.getKnownMacs(sn);
    if (knownMacs.isEmpty) {
      knownMacs.value = await SessionManager.getKnownMacs();
    }

    pendingMacs.value = await SessionManager.getPendingMacs(sn);
    if (pendingMacs.isEmpty) {
      pendingMacs.value = await SessionManager.getPendingMacs();
    }
    
    // إذا كانت الميزة مفعلة، ابدأ الفحص المباشر وسجل مهمة الخلفية
    if (isBgMonitorEnabled.value) {
      await registerBackgroundDeviceMonitor();
      _startForegroundTimer();
    }
  }

  // ─── تفعيل/تعطيل مراقبة الأجهزة ───
  Future<void> toggleBgMonitor(bool value) async {
    isBgMonitorEnabled.value = value;
    final sn = Get.find<AuthController>().currentSN.value;
    await SessionManager.setBackgroundDeviceMonitorEnabled(value, sn);
    await SessionManager.setBackgroundDeviceMonitorEnabled(value);
    
    if (value) {
      // طلب صلاحيات الإشعارات
      await BatteryMonitorService.requestPermissions();
      
      // جلب الأجهزة الموثوقة والمحفوظة مسبقاً لدى المستخدم
      knownMacs.value = await SessionManager.getKnownMacs(sn);
      pendingMacs.value = await SessionManager.getPendingMacs(sn);

      // توثيق جهاز الهاتف الحالي تلقائياً فقط إذا كانت القائمة فارغة كلياً
      if (knownMacs.isEmpty && myDeviceIp.value.isNotEmpty) {
        final myDevice = devices.firstWhereOrNull((d) => d.ip == myDeviceIp.value);
        if (myDevice != null) {
          await SessionManager.trustDevice(myDevice.mac, sn);
          await SessionManager.trustDevice(myDevice.mac);
          knownMacs.value = await SessionManager.getKnownMacs(sn);
        }
      }

      // تسجيل مهمة الخلفية + بدء المؤقت المباشر
      await registerBackgroundDeviceMonitor();
      _startForegroundTimer();
      
      // ⚡ فحص فوري لاكتشاف الأجهزة الموجودة مسبقاً
      await _checkForNewDevices();
      
      CustomSnackbar.showSuccess('إشعارات التطبيق', 'تم تفعيل اكتشاف الأجهزة الجديدة بنجاح.');
    } else {
      // إلغاء مهمة الخلفية والمؤقت المباشر مع الحفاظ على القوائم المحفوظة
      await cancelBackgroundDeviceMonitor();
      _foregroundTimer?.cancel();
      _foregroundTimer = null;
      
      CustomSnackbar.showWarning('إشعارات التطبيق', 'تم إيقاف إشعارات الأجهزة الجديدة.');
    }
  }

  // ─── مؤقت الفحص المباشر ───
  void _startForegroundTimer() {
    _foregroundTimer?.cancel();
    _foregroundTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      _checkForNewDevices();
    });
  }

  /// فحص الأجهزة المتصلة ومقارنتها بالقائمة المعروفة
  Future<void> _checkForNewDevices() async {
    if (!isBgMonitorEnabled.value) return;
    
    try {
      final result = await getConnectedDevicesUseCase.execute();
      final sn = Get.find<AuthController>().currentSN.value;
      
      final currentKnown = await SessionManager.getKnownMacs(sn);
      final currentPending = await SessionManager.getPendingMacs(sn);
      
      // الأجهزة غير الموثوقة
      final untrustedDevices = result.where((d) => 
        !currentKnown.contains(d.mac)
      ).toList();

      if (untrustedDevices.isNotEmpty) {
        bool hasNewDevices = false;

        for (var device in untrustedDevices) {
          // إضافة للمعلّقة إذا لم يكن موجوداً بالفعل (للتتبع في الواجهة)
          if (!currentPending.contains(device.mac)) {
            await SessionManager.addPendingMac(device.mac, sn);
            await SessionManager.addPendingMac(device.mac);
            hasNewDevices = true;
          }
        }
        
        // إظهار تنبيه داخل التطبيق فقط للأجهزة الجديدة
        if (hasNewDevices) {
          CustomSnackbar.showWarning(
            'أجهزة غير موثقة متصلة',
            'يوجد ${untrustedDevices.length} جهاز غير موثق متصل بالشبكة.',
          );
        }
        
        // تحديث القوائم التفاعلية
        pendingMacs.value = await SessionManager.getPendingMacs(sn);
      }
      
      // تنظيف الأجهزة المعلقة التي لم تعد متصلة
      final currentMacsSet = result.map((d) => d.mac).toSet();
      final stalePending = currentPending.where((mac) => !currentMacsSet.contains(mac)).toList();
      for (var mac in stalePending) {
        await SessionManager.removePendingMac(mac, sn);
      }
      if (stalePending.isNotEmpty) {
        pendingMacs.value = await SessionManager.getPendingMacs(sn);
      }
      
      // تحديث قائمة الأجهزة لإظهار حالة الأجهزة
      await fetchDevices();
    } catch (e) {
      debugPrint('Foreground device check error: $e');
    }
  }

  // ─── إدارة الأجهزة: توثيق / تجاهل / إلغاء ثقة ───

  /// توثيق جهاز (نقله من المعلّقة للمعروفة)
  Future<void> trustDevice(String mac) async {
    final sn = Get.find<AuthController>().currentSN.value;
    await SessionManager.trustDevice(mac, sn);
    pendingMacs.value = await SessionManager.getPendingMacs(sn);
    knownMacs.value = await SessionManager.getKnownMacs(sn);
    CustomSnackbar.showSuccess('تم التوثيق', 'تمت إضافة الجهاز للأجهزة الموثوقة.');
  }

  /// توثيق كافة الأجهزة المتصلة حالياً بنقرة واحدة
  Future<void> trustAllCurrentDevices() async {
    final sn = Get.find<AuthController>().currentSN.value;
    final allCurrentMacs = devices.map((d) => d.mac).toList();
    
    for (var mac in allCurrentMacs) {
      await SessionManager.trustDevice(mac, sn);
    }
    
    pendingMacs.value = await SessionManager.getPendingMacs(sn);
    knownMacs.value = await SessionManager.getKnownMacs(sn);
    
    CustomSnackbar.showSuccess('تم التوثيق', 'تم توثيق جميع الأجهزة المتصلة حالياً بنجاح.');
  }

  /// تجاهل جهاز (إزالته من المعلّقة — سيظهر مجدداً إذا لا يزال متصلاً)
  Future<void> dismissDevice(String mac) async {
    final sn = Get.find<AuthController>().currentSN.value;
    await SessionManager.removePendingMac(mac, sn);
    pendingMacs.value = await SessionManager.getPendingMacs(sn);
  }

  /// إزالة جهاز من الموثوقة (إلغاء الثقة)
  Future<void> removeTrustedDevice(String mac) async {
    final sn = Get.find<AuthController>().currentSN.value;
    await SessionManager.untrustDevice(mac, sn);
    knownMacs.value = await SessionManager.getKnownMacs(sn);
    CustomSnackbar.showWarning('إلغاء التوثيق', 'تمت إزالة الجهاز من الأجهزة الموثوقة.');
  }

  /// التحقق مما إذا كان الجهاز معلّقاً (جديداً)
  bool isDevicePending(String mac) => pendingMacs.contains(mac);

  // ─── جلب الأجهزة المتصلة ───
  Future<void> fetchDevices() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      myDeviceIp.value = await _getCurrentDeviceIp() ?? '';

      // تحميل الأسماء المحفوظة أولاً
      customNames.value = await DeviceNamesService.getAllNames();

      final result = await getConnectedDevicesUseCase.execute();

      // دمج الأسماء المخصصة مع نتائج API
      final enriched = result.map((d) {
        final saved = customNames[d.mac.toUpperCase()];
        if (saved != null && saved.isNotEmpty) {
          return ConnectedDeviceEntity(
            mac: d.mac,
            ip: d.ip,
            name: saved,
            type: d.type,
          );
        }
        return d;
      }).toList();

      devices.assignAll(enriched);
      
      // تحديث القوائم التفاعلية إذا كانت الميزة مفعلة
      if (isBgMonitorEnabled.value) {
        final sn = Get.find<AuthController>().currentSN.value;
        pendingMacs.value = await SessionManager.getPendingMacs(sn);
        knownMacs.value = await SessionManager.getKnownMacs(sn);
      }
    } catch (e) {
      if (SessionHelper.handleSessionError(e)) return;
      errorMessage.value = e.toString().replaceAll('Exception:', '').trim();
    } finally {
      isLoading.value = false;
    }
  }

  /// تغيير أو إعادة تسمية جهاز معين بواسطة MAC
  Future<void> renameDevice(String mac, String newName) async {
    if (newName.trim().isEmpty) {
      await DeviceNamesService.removeName(mac);
    } else {
      await DeviceNamesService.saveName(mac, newName.trim());
    }

    // تحديث القائمة المحلية فوراً بدون إعادة جلب من API
    customNames.value = await DeviceNamesService.getAllNames();

    final updated = devices.map((d) {
      if (d.mac.toUpperCase() == mac.toUpperCase()) {
        final savedName = customNames[mac.toUpperCase()];
        return ConnectedDeviceEntity(
          mac: d.mac,
          ip: d.ip,
          name: savedName != null && savedName.isNotEmpty ? savedName : d.name,
          type: d.type,
        );
      }
      return d;
    }).toList();

    devices.assignAll(updated);
  }

  /// استرجاع الاسم المعروض للجهاز (المخصص أولاً، ثم الافتراضي)
  String getDisplayName(ConnectedDeviceEntity device) {
    final saved = customNames[device.mac.toUpperCase()];
    if (saved != null && saved.isNotEmpty) return saved;
    return device.name.isEmpty ? 'جهاز غير معروف' : device.name;
  }

  Future<String?> _getCurrentDeviceIp() async {
    try {
      final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4,
          includeLoopback: false
      );

      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.address.startsWith('192.168.')) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print("لم نتمكن من قراءة IP الهاتف: $e");
    }
    return null;
  }

  /// 🚫 حظر جهاز معين
  Future<void> blockDevice(ConnectedDeviceEntity device) async {
    try {
      final getMacUseCase = Get.find<GetMacFilterUseCase>();
      final saveMacUseCase = Get.find<SaveMacFilterUseCase>();
      
      final currentFilter = await getMacUseCase.execute();
      final newDenyList = List<String>.from(currentFilter.denyList);
      final mac = device.mac.toUpperCase();
      
      if (!newDenyList.contains(mac)) {
        newDenyList.add(mac);
      }

      final success = await saveMacUseCase.execute('deny', currentFilter.allowList, newDenyList);
      
      if (success) {
        CustomSnackbar.showSuccess('تم الحظر', 'تم حظر الجهاز وتطبيق القواعد بنجاح.');
        fetchDevices(); // تحديث القائمة فوراً
      } else {
        CustomSnackbar.showError('خطأ', 'فشل حفظ الإعدادات في المودم.');
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('socketexception') || errorStr.contains('timeout') || errorStr.contains('network is unreachable')) {
        Get.find<AuthController>().forceLogout(
          'تم الحظر',
          'تم حظر الجهاز. المودم يقوم الآن بإعادة تشغيل شبكة الـ Wi-Fi لتطبيق التعديلات.'
        );
        return;
      }
      
      if (SessionHelper.handleSessionError(e)) return;
      if (kDebugMode) print("خطأ في حظر الجهاز: $e");
      CustomSnackbar.showError('خطأ', 'حدث خطأ أثناء محاولة حظر الجهاز.');
    }
  }

  /// ⚡ تحديد سرعة جهاز معين
  Future<void> limitDeviceSpeed(ConnectedDeviceEntity device, int upload, int download) async {
    try {
      final speedCtrl = Get.find<SpeedLimitController>();
      await speedCtrl.fetchData();
      
      speedCtrl.addDeviceRule(device.ip, upload, download, getDisplayName(device));
      speedCtrl.isEnabled.value = true;
      
      await speedCtrl.saveData();
      CustomSnackbar.showSuccess('تم بنجاح', 'تم تطبيق السرعة المحددة على ${getDisplayName(device)}');
    } catch (e) {
      if (kDebugMode) print("خطأ في تحديد السرعة: $e");
      CustomSnackbar.showError('خطأ', 'حدث خطأ أثناء حفظ إعدادات السرعة.');
    }
  }
}