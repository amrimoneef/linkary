import '../../domain/entities/auth_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../data_sources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AuthEntity> login(String password) async {
    try {
      // هنا نقوم باستدعاء مصدر البيانات
      final authModel = await remoteDataSource.loginToModem(password);
      return authModel; // نعيد النموذج لأنه في النهاية هو AuthEntity
    } catch (e) {
      // في تطبيق حقيقي نستخدم dartz/Either لإرجاع الأخطاء، لكن للتبسيط حالياً:
      rethrow;
    }
  }

  @override
  Future<int> getRetryTimes() async {
    return await remoteDataSource.fetchRetryTimes();
  }

  @override
  Future<void> logout(String sessionId) async {
    await remoteDataSource.logout(sessionId);
  }

  @override
  Future<void> reboot(String sessionId) async {
    await remoteDataSource.reboot(sessionId);
  }

  @override
  Future<void> powerOff(String sessionId) async {
    await remoteDataSource.powerOff(sessionId);
  }

  @override
  Future<void> factoryReset(String sessionId) async {
    await remoteDataSource.factoryReset(sessionId);
  }

  @override
  Future<bool> checkIfSetupRequired() async {
    return await remoteDataSource.checkIfSetupRequired();
  }

  @override
  Future<void> markSetupComplete() async {
    await remoteDataSource.markSetupComplete();
  }

  @override
  Future<String?> getSerialNumber() async {
    return await remoteDataSource.getSerialNumber();
  }
}