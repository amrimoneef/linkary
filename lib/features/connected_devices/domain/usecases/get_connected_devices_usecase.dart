import '../entities/connected_device_entity.dart';
import '../repositories/connected_devices_repository.dart';

class GetConnectedDevicesUseCase {
  final ConnectedDevicesRepository repository;

  GetConnectedDevicesUseCase(this.repository);

  Future<List<ConnectedDeviceEntity>> execute() async {
    return await repository.getConnectedDevices();
  }
}