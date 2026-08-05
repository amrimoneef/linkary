import '../../domain/entities/data_usage_entity.dart';

class DataUsageModel extends DataUsageEntity {
  DataUsageModel({
    required super.packageType,
    required super.packageDataBytes,
    required super.usedDataBytes,
  });

  factory DataUsageModel.fromJson(Map<String, dynamic> json) {
    int parseJsonInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    int packageData = 0;
    if (json['package_data_unlimited'] != null) {
      packageData = parseJsonInt(json['package_data_unlimited']['package_data']);
    } else if (json['package_data_monthly'] != null) {
      packageData = parseJsonInt(json['package_data_monthly']['package_data']);
    }

    return DataUsageModel(
      packageType: json['package_type'] ?? 'not_set',
      packageDataBytes: packageData,
      usedDataBytes: parseJsonInt(json['data_used']),
    );
  }
}