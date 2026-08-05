class WifiSettingsEntity {
  final String ssid;
  final String password;
  final bool isWifiEnabled; // موديول الواي فاي (switch)
  final bool isBroadcastEnabled; // بث الشبكة (hidden)
  final int maxClients; // أقصى عدد للمستخدمين الحالي (maxassoc)
  final int maxClientsLimit; // الحد الأقصى للقائمة (maxassoc_limit)
  final String channel; // القناة
  final String encryption; // نمط الأمان

  WifiSettingsEntity({
    required this.ssid,
    required this.password,
    required this.isWifiEnabled,
    required this.isBroadcastEnabled,
    required this.maxClients,
    required this.maxClientsLimit,
    required this.channel,
    required this.encryption,
  });
}