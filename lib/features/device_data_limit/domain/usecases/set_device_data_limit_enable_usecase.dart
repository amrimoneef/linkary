import '../repositories/device_data_limit_repository.dart';

class SetDeviceDataLimitEnableUseCase {
  final DeviceDataLimitRepository repository;

  SetDeviceDataLimitEnableUseCase(this.repository);

  Future<bool> call(bool enable) async {
    return await repository.setEnableStatus(enable);
  }
}
