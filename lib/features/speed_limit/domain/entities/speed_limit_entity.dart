// 1. كلاس يمثل قاعدة الجهاز الواحد
class SpeedLimitItem {
  int index;
  String ip;
  int upSpeed;
  int dlSpeed;
  String comment;

  SpeedLimitItem({
    required this.index,
    required this.ip,
    required this.upSpeed,
    required this.dlSpeed,
    required this.comment,
  });

  // للتحويل من وإلى JSON
  factory SpeedLimitItem.fromJson(Map<String, dynamic> json) => SpeedLimitItem(
    index: json['index'] ?? 0,
    ip: json['ip'] ?? '',
    upSpeed: int.tryParse(json['up_speed']?.toString() ?? '0') ?? 0,
    dlSpeed: int.tryParse(json['dl_speed']?.toString() ?? '0') ?? 0,
    comment: json['comment'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    "index": index,
    "ip": ip,
    "up_speed": upSpeed,
    "dl_speed": dlSpeed,
    "comment": comment,
  };
}

// 2. تحديث الكيان الأساسي
class SpeedLimitEntity {
  final bool isEnabled;
  final int mode;
  final int uploadSpeed;
  final int downloadSpeed;
  final List<SpeedLimitItem> items; // 🚀 إضافة مصفوفة الأجهزة

  SpeedLimitEntity({
    required this.isEnabled,
    required this.mode,
    required this.uploadSpeed,
    required this.downloadSpeed,
    required this.items, // 🚀
  });
}