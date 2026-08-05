import 'package:linkary/features/settings/domain/repositories/admin_settings_repository.dart';
import 'package:linkary/features/settings/infrastructure/models/admin_settings_model.dart';

class GetAdminSettingsUseCase {
  final AdminSettingsRepository repository;

  GetAdminSettingsUseCase(this.repository);

  Future<AdminSettingsModel> execute() async {
    return await repository.getAdminSettings();
  }
}
