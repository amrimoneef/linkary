import '../repositories/device_data_limit_repository.dart';

class AddDeviceDataLimitUseCase {
  final DeviceDataLimitRepository repository;

  AddDeviceDataLimitUseCase(this.repository);

  Future<bool> call(String mac, int quotaBytes, String comment) async {
    return await repository.addLimitItem(mac, quotaBytes, comment);
  }
}
