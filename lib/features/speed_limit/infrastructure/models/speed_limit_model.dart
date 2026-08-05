import '../../domain/entities/speed_limit_entity.dart';

class SpeedLimitModel extends SpeedLimitEntity {
  SpeedLimitModel({
    required super.isEnabled,
    required super.mode,
    required super.uploadSpeed,
    required super.downloadSpeed,
    required super.items,
  });

  factory SpeedLimitModel.fromJson(Map<String, dynamic> json) {
    return SpeedLimitModel(
      isEnabled: json['enable'] == 1,
      mode: json['mode'] ?? 1,
      uploadSpeed: int.tryParse(json['all_up_speed']?.toString() ?? '0') ?? 0,
      downloadSpeed: int.tryParse(json['all_dl_speed']?.toString() ?? '0') ?? 0,
      items: json['items'] != null
          ? (json['items'] as List).map((i) => SpeedLimitItem.fromJson(i)).toList()
          : [],
    );
  }
}