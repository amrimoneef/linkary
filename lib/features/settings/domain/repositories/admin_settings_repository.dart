import 'package:linkary/features/settings/infrastructure/models/admin_settings_model.dart';

abstract class AdminSettingsRepository {
  Future<AdminSettingsModel> getAdminSettings();
  Future<void> updateAdminSettings({
    required String username,
    required String password,
    required String totalTime,
    required String lcdPw,
    required int sleepTime,
  });
}
