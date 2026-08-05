import '../repositories/auth_repository.dart';

class GetRetryTimesUseCase {
  final AuthRepository repository;

  GetRetryTimesUseCase(this.repository);

  Future<int> execute() async {
    return await repository.getRetryTimes();
  }
}