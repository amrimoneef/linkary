import '../../domain/entities/parental_control_entity.dart';
import '../../domain/repositories/parental_control_repository.dart';
import '../data_sources/parental_control_remote_data_source.dart';

class ParentalControlRepositoryImpl implements ParentalControlRepository {
  final ParentalControlRemoteDataSource remoteDataSource;

  ParentalControlRepositoryImpl({required this.remoteDataSource});

  @override
  Future<bool> getParentalControlStatus() async {
    return await remoteDataSource.getParentalControlStatus();
  }

  @override
  Future<bool> setParentalControlStatus(bool isEnabled) async {
    return await remoteDataSource.setParentalControlStatus(isEnabled);
  }

  @override
  Future<List<ParentalDevice>> getParentalDevices() async {
    return await remoteDataSource.getParentalDevices();
  }

  @override
  Future<bool> saveParentalRule(String mac, int startTime, int endTime, int repeatMode, int index) async {
    return await remoteDataSource.saveParentalRule(mac, startTime, endTime, repeatMode, index);
  }

  @override
  Future<bool> deleteParentalRule(String mac) async {
    return await remoteDataSource.deleteParentalRule(mac);
  }
}