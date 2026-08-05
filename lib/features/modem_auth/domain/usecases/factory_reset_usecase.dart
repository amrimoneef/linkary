import '../repositories/auth_repository.dart';

class FactoryResetUseCase {
  final AuthRepository repository;

  FactoryResetUseCase({required this.repository});

  Future<void> execute(String sessionId) async {
    return await repository.factoryReset(sessionId);
  }
}
