import '../repositories/device_data_limit_repository.dart';

class GetDeviceDataLimitEnableUseCase {
  final DeviceDataLimitRepository repository;

  GetDeviceDataLimitEnableUseCase(this.repository);

  Future<bool> call() async {
    return await repository.getEnableStatus();
  }
}
