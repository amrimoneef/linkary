import '../entities/device_data_limit.dart';
import '../repositories/device_data_limit_repository.dart';

class GetDeviceDataLimitListUseCase {
  final DeviceDataLimitRepository repository;

  GetDeviceDataLimitListUseCase(this.repository);

  Future<List<DeviceDataLimit>> call() async {
    return await repository.getLimitList();
  }
}
