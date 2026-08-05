import '../../domain/entities/connected_device_entity.dart';

class ConnectedDeviceModel extends ConnectedDeviceEntity {
  ConnectedDeviceModel({
    required super.mac,
    required super.ip,
    required super.name,
    required super.type,
  });

  factory ConnectedDeviceModel.fromJson(Map<String, dynamic> json) {
    return ConnectedDeviceModel(
      mac: json['mac'] ?? 'غير معروف',
      ip: json['ip'] ?? '0.0.0.0',
      name: json['name'] ?? 'جهاز غير معروف',
      type: json['type'] ?? 'WIFI',
    );
  }
}