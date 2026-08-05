import '../entities/dashboard_entity.dart';
import '../entities/engineering_info_entity.dart';

abstract class DashboardRepository {
  // دالة لجلب بيانات لوحة التحكم.
  // ملاحظة: لا نمرر الـ Session ID هنا لأن الـ Domain لا يجب أن يعرف تفاصيل الـ HTTP!
  // سيتم التعامل مع الجلسة في طبقة الـ Infrastructure.
  Future<DashboardEntity> getDashboardData();
  Future<EngineeringInfoEntity> getEngineeringInfo();
}