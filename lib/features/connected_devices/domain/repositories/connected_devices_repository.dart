import '../entities/connected_device_entity.dart';

abstract class ConnectedDevicesRepository {
  Future<List<ConnectedDeviceEntity>> getConnectedDevices();
}