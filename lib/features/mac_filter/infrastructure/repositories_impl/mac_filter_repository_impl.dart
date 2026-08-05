import '../../domain/entities/mac_filter_entity.dart';
import '../../domain/repositories/mac_filter_repository.dart';
import '../data_sources/mac_filter_remote_data_source.dart';

class MacFilterRepositoryImpl implements MacFilterRepository {
  final MacFilterRemoteDataSource remoteDataSource;

  MacFilterRepositoryImpl({required this.remoteDataSource});

  @override
  Future<MacFilterEntity> getMacFilterData() async {
    return await remoteDataSource.fetchMacFilterData();
  }

  @override
  Future<bool> saveMacFilter(String mode, List<String> allowList, List<String> denyList) async {
    return await remoteDataSource.saveMacFilter(mode, allowList, denyList);
  }
}