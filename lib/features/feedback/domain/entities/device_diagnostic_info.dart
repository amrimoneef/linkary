class DeviceDiagnosticInfo {
  final String appVersion;
  final String deviceModel;
  final String osVersion;
  final String modemModel;
  final String modemFirmware;
  final String networkType;
  final String batteryLevel;
  final String signalStrength;

  const DeviceDiagnosticInfo({
    required this.appVersion,
    required this.deviceModel,
    required this.osVersion,
    this.modemModel = 'غير متوفر',
    this.modemFirmware = 'غير متوفر',
    this.networkType = 'غير متوفر',
    this.batteryLevel = 'غير متوفر',
    this.signalStrength = 'غير متوفر',
  });

  Map<String, dynamic> toJson() => {
        'app_version': appVersion,
        'device_model': deviceModel,
        'os_version': osVersion,
        'modem_model': modemModel,
        'modem_firmware': modemFirmware,
        'network_type': networkType,
        'battery_level': batteryLevel,
        'signal_strength': signalStrength,
      };

  factory DeviceDiagnosticInfo.fromJson(Map<String, dynamic> json) {
    return DeviceDiagnosticInfo(
      appVersion: json['app_version'] as String? ?? '1.0.0',
      deviceModel: json['device_model'] as String? ?? 'هاتف محمول',
      osVersion: json['os_version'] as String? ?? 'Android',
      modemModel: json['modem_model'] as String? ?? 'غير متوفر',
      modemFirmware: json['modem_firmware'] as String? ?? 'غير متوفر',
      networkType: json['network_type'] as String? ?? 'غير متوفر',
      batteryLevel: json['battery_level'] as String? ?? 'غير متوفر',
      signalStrength: json['signal_strength'] as String? ?? 'غير متوفر',
    );
  }
}
