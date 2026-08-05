import '../entities/device_data_limit.dart';

abstract class DeviceDataLimitRepository {
  Future<bool> getEnableStatus();
  Future<bool> setEnableStatus(bool enable);
  Future<List<DeviceDataLimit>> getLimitList();
  Future<bool> addLimitItem(String mac, int quotaBytes, String comment);
  Future<bool> deleteLimitItem(String mac);
}
