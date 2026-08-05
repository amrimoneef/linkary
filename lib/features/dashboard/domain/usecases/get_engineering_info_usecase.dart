import '../entities/engineering_info_entity.dart';
import '../repositories/dashboard_repository.dart';

class GetEngineeringInfoUseCase {
  final DashboardRepository repository;

  GetEngineeringInfoUseCase(this.repository);

  Future<EngineeringInfoEntity> execute() async {
    return await repository.getEngineeringInfo();
  }
}