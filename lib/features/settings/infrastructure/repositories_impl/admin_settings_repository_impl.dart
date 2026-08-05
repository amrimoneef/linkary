import 'package:get/get.dart';
import 'package:linkary/features/modem_auth/presentation/controllers/auth_controller.dart';
import 'package:linkary/features/settings/infrastructure/data_sources/admin_remote_data_source.dart';
import 'package:linkary/features/settings/infrastructure/models/admin_settings_model.dart';
import 'package:linkary/features/settings/domain/repositories/admin_settings_repository.dart';

class AdminSettingsRepositoryImpl implements AdminSettingsRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminSettingsRepositoryImpl({required this.remoteDataSource});

  String? _getSessionId() {
    return Get.find<AuthController>().currentUser?.sessionId;
  }

  @override
  Future<AdminSettingsModel> getAdminSettings() async {
    final sessionId = _getSessionId();
    if (sessionId == null) throw Exception('SESSION_EXPIRED');
    return await remoteDataSource.getAdminSettings(sessionId);
  }

  @override
  Future<void> updateAdminSettings({
    required String username,
    required String password,
    required String totalTime,
    required String lcdPw,
    required int sleepTime,
  }) async {
    final sessionId = _getSessionId();
    if (sessionId == null) throw Exception('SESSION_EXPIRED');
    return await remoteDataSource.setAdminSettings(
      sessionId: sessionId,
      username: username,
      password: password,
      totalTime: totalTime,
      lcdPw: lcdPw,
      sleepTime: sleepTime,
    );
  }
}
