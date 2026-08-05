import '../entities/wifi_settings_entity.dart';

abstract class SettingsRepository {
  Future<WifiSettingsEntity> getWifiSettings();

  Future<bool> saveWifiSettings(
      String ssid,
      String password,
      bool isWifiEnabled,
      bool isBroadcastEnabled,
      int maxClients,
      String channel,
      String encryption
      );

  Future<bool> changeAdminPassword(String newPassword);
}