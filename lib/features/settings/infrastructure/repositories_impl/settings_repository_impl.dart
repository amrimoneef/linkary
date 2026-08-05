import '../../domain/entities/wifi_settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../data_sources/settings_remote_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDataSource remoteDataSource;

  SettingsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<WifiSettingsEntity> getWifiSettings() async {
    return await remoteDataSource.fetchWifiSettings();
  }

  // 🚀 تمرير المتغيرات الشاملة
  @override
  Future<bool> saveWifiSettings(
      String ssid,
      String password,
      bool isWifiEnabled,
      bool isBroadcastEnabled,
      int maxClients,
      String channel,
      String encryption
      ) async {
    return await remoteDataSource.saveWifiSettings(
        ssid, password, isWifiEnabled, isBroadcastEnabled, maxClients, channel, encryption
    );
  }

  @override
  Future<bool> changeAdminPassword(String newPassword) async {
    return await remoteDataSource.changeAdminPassword(newPassword);
  }
}