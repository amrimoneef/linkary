import '../entities/wifi_settings_entity.dart';
import '../repositories/settings_repository.dart';

class GetWifiSettingsUseCase {
  final SettingsRepository repository;
  GetWifiSettingsUseCase(this.repository);

  Future<WifiSettingsEntity> execute() async {
    return await repository.getWifiSettings();
  }
}