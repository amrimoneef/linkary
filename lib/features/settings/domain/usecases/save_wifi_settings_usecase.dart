import '../repositories/settings_repository.dart';

class SaveWifiSettingsUseCase {
  final SettingsRepository repository;

  SaveWifiSettingsUseCase(this.repository);

  // 🚀 استقبال المتغيرات من الـ Controller وإرسالها للـ Repository
  Future<bool> execute(
      String ssid,
      String password,
      bool isWifiEnabled,
      bool isBroadcastEnabled,
      int maxClients,
      String channel,
      String encryption
      ) async {
    return await repository.saveWifiSettings(
        ssid, password, isWifiEnabled, isBroadcastEnabled, maxClients, channel, encryption
    );
  }
}