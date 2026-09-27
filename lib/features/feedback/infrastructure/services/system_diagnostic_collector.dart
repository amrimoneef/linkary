import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:linkary/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:linkary/features/feedback/domain/entities/device_diagnostic_info.dart';

class SystemDiagnosticCollector {
  final DeviceInfoPlugin _deviceInfo;

  SystemDiagnosticCollector({DeviceInfoPlugin? deviceInfo})
      : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  Future<DeviceDiagnosticInfo> collectDiagnostics() async {
    String appVer = '1.0.3';
    try {
      final pkg = await PackageInfo.fromPlatform();
      appVer = '${pkg.version}+${pkg.buildNumber}';
    } catch (_) {
      // Fallback
    }

    String osVersion = 'Android';
    String deviceModel = 'هاتف ذكي';

    try {
      if (Platform.isAndroid) {
        final android = await _deviceInfo.androidInfo;
        osVersion = 'Android ${android.version.release}'.trim();
        deviceModel = _resolveAndroidDeviceName(
          brand: android.brand,
          model: android.model,
          manufacturer: android.manufacturer,
        );
      } else if (Platform.isIOS) {
        final ios = await _deviceInfo.iosInfo;
        osVersion = 'iOS ${ios.systemVersion}'.trim();
        deviceModel = _resolveIosDeviceName(
          machine: ios.utsname.machine,
          name: ios.name,
        );
      } else if (Platform.isWindows) {
        osVersion = 'Windows';
        deviceModel = 'حاسوب شخصي (Windows PC)';
      } else {
        osVersion = Platform.operatingSystem;
        deviceModel = Platform.operatingSystem;
      }
    } catch (_) {
      osVersion = Platform.isAndroid ? 'Android' : (Platform.isIOS ? 'iOS' : Platform.operatingSystem);
      deviceModel = Platform.isAndroid ? 'جهاز أندرويد' : (Platform.isIOS ? 'iPhone' : 'جهاز غير معروف');
    }

    String modemModel = 'غير متوفر';
    String modemFirmware = 'غير متوفر';
    String networkType = 'غير متوفر';
    String batteryLevel = 'غير متوفر';
    String signalStrength = 'غير متوفر';

    // Extract live modem data from DashboardController if active
    if (Get.isRegistered<DashboardController>()) {
      try {
        final dash = Get.find<DashboardController>();
        final data = dash.dashboardData.value;
        if (data != null) {
          if (data.batteryCapacity > 0) {
            batteryLevel = '${data.batteryCapacity}%';
          }
          if (data.networkType.isNotEmpty) {
            networkType = '${data.networkType.toUpperCase()} (${data.networkName})';
          }
          if (data.signalLevel >= 0) {
            signalStrength = '${data.signalLevel} / 5 (${data.rssi} dBm)';
          }
          modemModel = 'Sam4G MiFi';
        }
        final eng = dash.engInfoData.value;
        if (eng != null && eng.band.isNotEmpty) {
          modemFirmware = 'Band: ${eng.band} (PCI: ${eng.pci})';
        }
      } catch (_) {}
    }

    return DeviceDiagnosticInfo(
      appVersion: appVer,
      deviceModel: deviceModel,
      osVersion: osVersion,
      modemModel: modemModel,
      modemFirmware: modemFirmware,
      networkType: networkType,
      batteryLevel: batteryLevel,
      signalStrength: signalStrength,
    );
  }

  static String _resolveAndroidDeviceName({
    required String brand,
    required String model,
    required String manufacturer,
  }) {
    final m = model.trim().toUpperCase();
    final b = brand.trim();
    final capitalBrand = b.isNotEmpty ? (b[0].toUpperCase() + b.substring(1)) : '';

    // Samsung Galaxy flagship & popular models mapping
    if (m.startsWith('SM-S928')) return 'Samsung Galaxy S24 Ultra';
    if (m.startsWith('SM-S926')) return 'Samsung Galaxy S24+';
    if (m.startsWith('SM-S921')) return 'Samsung Galaxy S24';
    if (m.startsWith('SM-S918')) return 'Samsung Galaxy S23 Ultra';
    if (m.startsWith('SM-S916')) return 'Samsung Galaxy S23+';
    if (m.startsWith('SM-S911')) return 'Samsung Galaxy S23';
    if (m.startsWith('SM-S908')) return 'Samsung Galaxy S22 Ultra';
    if (m.startsWith('SM-S906')) return 'Samsung Galaxy S22+';
    if (m.startsWith('SM-S901')) return 'Samsung Galaxy S22';
    if (m.startsWith('SM-G998')) return 'Samsung Galaxy S21 Ultra';
    if (m.startsWith('SM-G996')) return 'Samsung Galaxy S21+';
    if (m.startsWith('SM-G991')) return 'Samsung Galaxy S21';
    if (m.startsWith('SM-F946')) return 'Samsung Galaxy Z Fold 5';
    if (m.startsWith('SM-F731')) return 'Samsung Galaxy Z Flip 5';
    if (m.startsWith('SM-F956')) return 'Samsung Galaxy Z Fold 6';
    if (m.startsWith('SM-F741')) return 'Samsung Galaxy Z Flip 6';
    if (m.startsWith('SM-A556')) return 'Samsung Galaxy A55';
    if (m.startsWith('SM-A546')) return 'Samsung Galaxy A54';
    if (m.startsWith('SM-A356')) return 'Samsung Galaxy A35';
    if (m.startsWith('SM-A346')) return 'Samsung Galaxy A34';
    if (m.startsWith('SM-A155') || m.startsWith('SM-A156')) return 'Samsung Galaxy A15';

    // If model already contains brand name (e.g. "Pixel 8 Pro", "Xiaomi 14")
    if (model.toLowerCase().contains(b.toLowerCase())) {
      return model;
    }

    if (capitalBrand.isNotEmpty) {
      return '$capitalBrand $model';
    }

    return model.isNotEmpty ? model : 'جهاز أندرويد';
  }

  static String _resolveIosDeviceName({
    required String machine,
    required String name,
  }) {
    final m = machine.trim();
    const map = {
      'iPhone16,2': 'iPhone 15 Pro Max',
      'iPhone16,1': 'iPhone 15 Pro',
      'iPhone15,5': 'iPhone 15 Plus',
      'iPhone15,4': 'iPhone 15',
      'iPhone15,3': 'iPhone 14 Pro Max',
      'iPhone15,2': 'iPhone 14 Pro',
      'iPhone14,8': 'iPhone 14 Plus',
      'iPhone14,7': 'iPhone 14',
      'iPhone14,3': 'iPhone 13 Pro Max',
      'iPhone14,2': 'iPhone 13 Pro',
      'iPhone14,5': 'iPhone 13',
      'iPhone14,4': 'iPhone 13 mini',
      'iPhone13,4': 'iPhone 12 Pro Max',
      'iPhone13,3': 'iPhone 12 Pro',
      'iPhone13,2': 'iPhone 12',
      'iPhone13,1': 'iPhone 12 mini',
      'iPhone12,5': 'iPhone 11 Pro Max',
      'iPhone12,3': 'iPhone 11 Pro',
      'iPhone12,1': 'iPhone 11',
    };

    if (map.containsKey(m)) return map[m]!;
    if (name.isNotEmpty && name != 'iPhone') return name;
    if (m.isNotEmpty) return 'iPhone ($m)';
    return 'iPhone';
  }
}
