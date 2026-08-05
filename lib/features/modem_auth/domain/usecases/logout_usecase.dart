import '../repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  Future<void> execute(String sessionId) async {
    return await repository.logout(sessionId);
  }
}
