import '../../domain/entities/wifi_settings_entity.dart';

class WifiSettingsModel extends WifiSettingsEntity {
  WifiSettingsModel({
    required super.ssid,
    required super.password,
    required super.isWifiEnabled,
    required super.isBroadcastEnabled,
    required super.maxClients,
    required super.maxClientsLimit,
    required super.channel,
    required super.encryption,
  });

  factory WifiSettingsModel.fromJson(Map<String, dynamic> json) {
    try {
      final wifiIf = json['wireless']['AP0']['wifi_if_24G'];
      final ssidData = wifiIf['ssid0'];

      return WifiSettingsModel(
        ssid: ssidData['ssid'] ?? '',
        password: ssidData['key'] ?? '',
        isWifiEnabled: wifiIf['switch'] == 'on', // on = تمكين
        isBroadcastEnabled: ssidData['hidden'] == '0', // 0 = تمكين البث (غير مخفية)
        maxClients: int.tryParse(ssidData['maxassoc']?.toString() ?? '2') ?? 2,
        maxClientsLimit: int.tryParse(ssidData['maxassoc_limit']?.toString() ?? '10') ?? 10,
        channel: wifiIf['channel'] ?? '0',
        encryption: ssidData['encryption'] ?? 'psk-mixed+tkip+ccmp',
      );
    } catch (e) {
      throw Exception('فشل في قراءة إعدادات الواي فاي: $e');
    }
  }
}