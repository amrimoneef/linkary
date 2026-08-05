import '../../../modem_auth/domain/usecases/login_usecase.dart';
import '../repositories/settings_repository.dart';

class ChangeAdminPasswordUseCase {
  final SettingsRepository repository;
  final LoginUseCase loginUseCase;

  ChangeAdminPasswordUseCase(this.repository, this.loginUseCase);

  Future<bool> execute(String currentPassword, String newPassword, String confirmPassword) async {
    if (newPassword != confirmPassword) {
      throw Exception('كلمة المرور الجديدة غير متطابقة.');
    }
    if (newPassword.length < 8) {
      throw Exception('كلمة المرور الجديدة يجب أن تكون 8 أحرف على الأقل لمزيد من الأمان.');
    }

    try {
      final auth = await loginUseCase.execute(currentPassword);
      if (!auth.isAuthenticated) {
        throw Exception('كلمة المرور الحالية غير صحيحة.');
      }
    } catch (e) {
      throw Exception('كلمة المرور الحالية غير صحيحة أو فشل الاتصال.');
    }

    return await repository.changeAdminPassword(newPassword);
  }
}
