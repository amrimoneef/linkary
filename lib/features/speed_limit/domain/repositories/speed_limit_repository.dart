import '../entities/speed_limit_entity.dart';

abstract class SpeedLimitRepository {
  Future<SpeedLimitEntity> getSpeedLimit();

  // 🚀 أضفنا List<SpeedLimitItem> items ليتطابق مع الـ Impl تماماً
  Future<bool> saveSpeedLimit(
      bool isEnabled,
      int mode,
      int uploadSpeed,
      int downloadSpeed,
      List<SpeedLimitItem> items
      );
}