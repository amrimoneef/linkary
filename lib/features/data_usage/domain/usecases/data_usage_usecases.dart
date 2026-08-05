import '../entities/data_usage_entity.dart';
import '../repositories/data_usage_repository.dart';

class GetDataUsageUseCase {
  final DataUsageRepository repository;

  GetDataUsageUseCase(this.repository);

  Future<DataUsageEntity> execute() async {
    return await repository.getDataUsage();
  }
}

class SaveDataUsageUseCase {
  final DataUsageRepository repository;

  SaveDataUsageUseCase(this.repository);

  Future<bool> execute(String type, int bytes) async {
    return await repository.savePackageSettings(type, bytes);
  }
}