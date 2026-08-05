import '../../domain/entities/speed_limit_entity.dart';
import '../../domain/repositories/speed_limit_repository.dart';
import '../data_sources/speed_limit_remote_data_source.dart';

class SpeedLimitRepositoryImpl implements SpeedLimitRepository {
  final SpeedLimitRemoteDataSource remoteDataSource;

  SpeedLimitRepositoryImpl({required this.remoteDataSource});

  @override
  Future<SpeedLimitEntity> getSpeedLimit() async =>
      await remoteDataSource.fetchSpeedLimit();

  @override
  Future<bool> saveSpeedLimit(
      bool isEnabled,
      int mode,
      int uploadSpeed,
      int downloadSpeed,
      List<SpeedLimitItem> items
      ) async {
    return await remoteDataSource.saveSpeedLimit(
        isEnabled,
        mode,
        uploadSpeed,
        downloadSpeed,
        items
    );
  }
}