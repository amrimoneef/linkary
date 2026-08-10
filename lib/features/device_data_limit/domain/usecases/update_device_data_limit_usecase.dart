import '../repositories/device_data_limit_repository.dart';

class UpdateDeviceDataLimitUseCase {
  final DeviceDataLimitRepository repository;

  UpdateDeviceDataLimitUseCase(this.repository);

  Future<bool> call(int index, String mac, int quotaBytes, String comment) async {
    return await repository.updateLimitItem(index, mac, quotaBytes, comment);
  }
}
