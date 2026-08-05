import '../entities/speed_limit_entity.dart';
import '../repositories/speed_limit_repository.dart';

class GetSpeedLimitUseCase {
  final SpeedLimitRepository repository;
  GetSpeedLimitUseCase(this.repository);

  Future<SpeedLimitEntity> execute() async => await repository.getSpeedLimit();
}

class SaveSpeedLimitUseCase {
  final SpeedLimitRepository repository;
  SaveSpeedLimitUseCase(this.repository);

  // 🚀 استقبال المصفوفة (items) من المتحكم وتمريرها للمستودع
  Future<bool> execute(
      bool isEnabled,
      int mode,
      int uploadSpeed,
      int downloadSpeed,
      List<SpeedLimitItem> items // <--- المعطى الخامس هنا
      ) async {
    return await repository.saveSpeedLimit(
        isEnabled,
        mode,
        uploadSpeed,
        downloadSpeed,
        items // <--- وتمريره هنا
    );
  }
}