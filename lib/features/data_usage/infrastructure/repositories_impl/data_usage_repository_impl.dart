import '../../domain/entities/data_usage_entity.dart';
import '../../domain/repositories/data_usage_repository.dart';
import '../data_sources/data_usage_remote_data_source.dart';

class DataUsageRepositoryImpl implements DataUsageRepository {
  final DataUsageRemoteDataSource remoteDataSource;

  DataUsageRepositoryImpl({required this.remoteDataSource});

  @override
  Future<DataUsageEntity> getDataUsage() async {
    return await remoteDataSource.fetchDataUsage();
  }

  @override
  Future<bool> savePackageSettings(String type, int bytes) async {
    return await remoteDataSource.savePackageSettings(type, bytes);
  }

  @override
  Future<bool> calibrateDataUsed(int bytes) async {
    return await remoteDataSource.calibrateDataUsed(bytes);
  }
}