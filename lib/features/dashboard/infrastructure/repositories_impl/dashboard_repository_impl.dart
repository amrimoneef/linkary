import '../../domain/entities/dashboard_entity.dart';
import '../../domain/entities/engineering_info_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../data_sources/dashboard_remote_data_source.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource remoteDataSource;

  DashboardRepositoryImpl({required this.remoteDataSource});

  @override
  Future<DashboardEntity> getDashboardData() async {
    // استدعاء مصدر البيانات وإرجاع النتيجة
    return await remoteDataSource.fetchDashboardData();
  }

  @override
  Future<EngineeringInfoEntity> getEngineeringInfo() async {
    return await remoteDataSource.fetchEngineeringInfo();
  }
}