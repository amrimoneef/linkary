import '../../domain/entities/connected_device_entity.dart';
import '../../domain/repositories/connected_devices_repository.dart';
import '../data_sources/connected_devices_remote_data_source.dart';

class ConnectedDevicesRepositoryImpl implements ConnectedDevicesRepository {
  final ConnectedDevicesRemoteDataSource remoteDataSource;

  ConnectedDevicesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ConnectedDeviceEntity>> getConnectedDevices() async {
    return await remoteDataSource.fetchConnectedDevices();
  }
}