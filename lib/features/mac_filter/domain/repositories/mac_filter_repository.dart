import '../entities/mac_filter_entity.dart';

abstract class MacFilterRepository {
  Future<MacFilterEntity> getMacFilterData();
  Future<bool> saveMacFilter(String mode, List<String> allowList, List<String> denyList);
}