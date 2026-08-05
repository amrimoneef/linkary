import '../repositories/auth_repository.dart';

class PowerOffUseCase {
  final AuthRepository repository;

  PowerOffUseCase(this.repository);

  Future<void> execute(String sessionId) async {
    return await repository.powerOff(sessionId);
  }
}
