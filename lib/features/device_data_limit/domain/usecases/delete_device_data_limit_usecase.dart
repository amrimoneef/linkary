import '../repositories/device_data_limit_repository.dart';

class DeleteDeviceDataLimitUseCase {
  final DeviceDataLimitRepository repository;

  DeleteDeviceDataLimitUseCase(this.repository);

  Future<bool> call(String mac) async {
    return await repository.deleteLimitItem(mac);
  }
}
