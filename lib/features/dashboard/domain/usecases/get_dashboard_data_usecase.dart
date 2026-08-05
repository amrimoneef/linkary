import '../entities/dashboard_entity.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardDataUseCase {
  final DashboardRepository repository;

  GetDashboardDataUseCase(this.repository);

  Future<DashboardEntity> execute() async {
    // يمكننا هنا إضافة منطق أعمال مستقبلياً إذا احتجنا
    // مثلاً: التحقق إذا كانت الإشارة ضعيفة جداً وإطلاق تحذير
    return await repository.getDashboardData();
  }
}