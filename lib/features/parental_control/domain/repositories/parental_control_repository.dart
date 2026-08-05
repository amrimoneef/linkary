import '../entities/parental_control_entity.dart';

abstract class ParentalControlRepository {
  Future<bool> getParentalControlStatus();
  Future<bool> setParentalControlStatus(bool isEnabled);
  Future<List<ParentalDevice>> getParentalDevices();
  Future<bool> saveParentalRule(String mac, int startTime, int endTime, int repeatMode, int index);
  Future<bool> deleteParentalRule(String mac);
}