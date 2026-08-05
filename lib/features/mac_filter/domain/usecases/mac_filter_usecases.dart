import '../entities/mac_filter_entity.dart';
import '../repositories/mac_filter_repository.dart';

class GetMacFilterUseCase {
  final MacFilterRepository repository;

  GetMacFilterUseCase(this.repository);

  Future<MacFilterEntity> execute() async {
    return await repository.getMacFilterData();
  }
}

class SaveMacFilterUseCase {
  final MacFilterRepository repository;

  SaveMacFilterUseCase(this.repository);

  Future<bool> execute(String mode, List<String> allowList, List<String> denyList) async {
    return await repository.saveMacFilter(mode, allowList, denyList);
  }
}