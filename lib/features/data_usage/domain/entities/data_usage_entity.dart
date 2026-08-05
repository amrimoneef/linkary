import '../repositories/data_usage_repository.dart';

class DataUsageEntity {
  final String packageType; // 'unlimited', 'not_set', 'monthly'
  final int packageDataBytes; // الحد المسموح بالبايت
  final int usedDataBytes; // البيانات المستهلكة حالياً بالبايت

  DataUsageEntity({
    required this.packageType,
    required this.packageDataBytes,
    required this.usedDataBytes,
  });
}

class CalibrateDataUsageUseCase {
  final DataUsageRepository repository;

  CalibrateDataUsageUseCase(this.repository);

  Future<bool> execute(int bytes) async {
    return await repository.calibrateDataUsed(bytes);
  }
}