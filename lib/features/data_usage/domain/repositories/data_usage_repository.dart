import '../entities/data_usage_entity.dart';

abstract class DataUsageRepository {
  Future<DataUsageEntity> getDataUsage();
  Future<bool> savePackageSettings(String type, int bytes);
  Future<bool> calibrateDataUsed(int bytes);
}