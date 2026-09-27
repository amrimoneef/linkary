import 'dart:io';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:linkary/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:linkary/features/feedback/domain/entities/device_diagnostic_info.dart';

class SystemDiagnosticCollector {
  Future<DeviceDiagnosticInfo> collectDiagnostics() async {
    String appVer = '1.0.3';
    try {
      final pkg = await PackageInfo.fromPlatform();
      appVer = '${pkg.version}+${pkg.buildNumber}';
    } catch (_) {
      // Fallback
    }

    final osVersion = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
    String deviceModel = Platform.isAndroid ? 'جهاز أندرويد' : (Platform.isIOS ? 'iPhone' : Platform.operatingSystem);

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
}
