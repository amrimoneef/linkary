import '../../domain/entities/device_data_limit.dart';

class DeviceDataLimitModel extends DeviceDataLimit {
  DeviceDataLimitModel({
    required super.index,
    required super.hostname,
    required super.mac,
    required super.quotaBytes,
    required super.status,
    required super.currentUsageBytes,
    required super.comment,
    required super.recordData,
  });

  factory DeviceDataLimitModel.fromJson(Map<String, dynamic> json) {
    return DeviceDataLimitModel(
      index: json['index'] ?? '',
      hostname: json['hostname'] ?? '',
      mac: json['mac'] ?? '',
      quotaBytes: int.tryParse(json['quota'] ?? '0') ?? 0,
      status: json['status'] ?? '',
      currentUsageBytes: int.tryParse(json['current_usage'] ?? '0') ?? 0,
      comment: json['comment'] ?? '',
      recordData: json['record_data'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'hostname': hostname,
      'mac': mac,
      'quota': quotaBytes.toString(),
      'status': status,
      'current_usage': currentUsageBytes.toString(),
      'comment': comment,
      'record_data': recordData,
    };
  }
}
