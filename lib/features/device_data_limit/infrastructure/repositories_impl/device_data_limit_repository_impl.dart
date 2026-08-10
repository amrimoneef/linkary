import '../../domain/entities/device_data_limit.dart';
import '../../domain/repositories/device_data_limit_repository.dart';
import '../data_sources/device_data_limit_remote_data_source.dart';

class DeviceDataLimitRepositoryImpl implements DeviceDataLimitRepository {
  final DeviceDataLimitRemoteDataSource remoteDataSource;

  DeviceDataLimitRepositoryImpl({required this.remoteDataSource});

  @override
  Future<bool> getEnableStatus() async {
    return await remoteDataSource.getEnableStatus();
  }

  @override
  Future<bool> setEnableStatus(bool enable) async {
    return await remoteDataSource.setEnableStatus(enable);
  }

  @override
  Future<List<DeviceDataLimit>> getLimitList() async {
    return await remoteDataSource.getLimitList();
  }

  @override
  Future<bool> addLimitItem(String mac, int quotaBytes, String comment) async {
    return await remoteDataSource.addLimitItem(mac, quotaBytes, comment);
  }

  @override
  Future<bool> updateLimitItem(int index, String mac, int quotaBytes, String comment) async {
    return await remoteDataSource.updateLimitItem(index, mac, quotaBytes, comment);
  }

  @override
  Future<bool> deleteLimitItem(String mac) async {
    return await remoteDataSource.deleteLimitItem(mac);
  }
}
