

import '../../../device_data_limit/domain/entities/device_data_limit.dart';
import '../../../parental_control/domain/entities/parental_control_entity.dart';
import '../../../speed_limit/domain/entities/speed_limit_entity.dart';

class ManagedDevice {
  final String mac;
  final String name;
  final String? ip;
  final String? type;

  // بيانات التحكم الأبوي (من parental_control)
  final List<TimeSlot>? timeSlots;

  // بيانات تحديد السرعة (من speed_limit)
  final SpeedLimitItem? speedRule;

  // بيانات تحديد الباقة (من device_data_limit)
  final DeviceDataLimit? dataLimit;

  ManagedDevice({
    required this.mac,
    required this.name,
    this.ip,
    this.type,
    this.timeSlots,
    this.speedRule,
    this.dataLimit,
  });

  bool get hasParentalRule => timeSlots != null && timeSlots!.isNotEmpty;
  bool get hasSpeedRule => speedRule != null;
  bool get hasDataLimit => dataLimit != null;
  
  int get activeRulesCount => [hasParentalRule, hasSpeedRule, hasDataLimit]
      .where((e) => e).length;
}
