import 'package:linkary/features/settings/domain/repositories/admin_settings_repository.dart';

class UpdateAdminSettingsUseCase {
  final AdminSettingsRepository repository;

  UpdateAdminSettingsUseCase(this.repository);

  Future<void> execute({
    required String username,
    required String password,
    required String totalTime,
    required String lcdPw,
    required int sleepTime,
  }) async {
    return await repository.updateAdminSettings(
      username: username,
      password: password,
      totalTime: totalTime,
      lcdPw: lcdPw,
      sleepTime: sleepTime,
    );
  }
}
