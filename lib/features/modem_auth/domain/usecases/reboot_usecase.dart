import '../repositories/auth_repository.dart';

class RebootUseCase {
  final AuthRepository repository;

  RebootUseCase(this.repository);

  Future<void> execute(String sessionId) async {
    return await repository.reboot(sessionId);
  }
}
