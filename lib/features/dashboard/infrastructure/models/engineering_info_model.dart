import '../../domain/entities/engineering_info_entity.dart';

class EngineeringInfoModel extends EngineeringInfoEntity {
  EngineeringInfoModel({
    required super.band,
    required super.rsrp,
    required super.rsrq,
    required super.sinr,
    required super.pci,
    required super.bandwidth,
  });

  factory EngineeringInfoModel.fromJson(Map<String, dynamic> json) {
    return EngineeringInfoModel(
      // استخدام toString() يحمينا من أي تغيير مفاجئ في نوع البيانات من المودم
      band: json['band']?.toString() ?? 'N/A',
      rsrp: json['rsrp']?.toString() ?? 'N/A',
      rsrq: json['rsrq']?.toString() ?? 'N/A',
      sinr: json['sinr']?.toString() ?? 'N/A',
      pci: json['pci']?.toString() ?? 'N/A',
      bandwidth: json['dl_bandwidth']?.toString() ?? 'N/A',
    );
  }
}