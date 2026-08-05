import '../../domain/entities/mac_filter_entity.dart';

class MacFilterModel extends MacFilterEntity {
  MacFilterModel({
    required super.filterMode,
    required super.allowList,
    required super.denyList,
    required super.routerMac,
  });

  factory MacFilterModel.fromJson(Map<String, dynamic> jsonFilter, Map<String, dynamic> jsonMac) {
    final ap0 = jsonFilter['wireless']?['AP0'] ?? {};

    // 🚀 دالة ذكية لتنظيف الفراغات الغريبة التي يرسلها المودم
    List<String> parseMacs(String? raw) {
      if (raw == null || raw.trim().isEmpty) return [];
      return raw.split(RegExp(r'[\s;,]+')).where((m) => m.isNotEmpty && m.contains(':')).toList();
    }

    return MacFilterModel(
      filterMode: ap0['macfilter'] ?? 'disable',
      allowList: parseMacs(ap0['maclist_allow']),
      denyList: parseMacs(ap0['maclist_deny']),
      routerMac: jsonMac['wifi_mac'] ?? '',
    );
  }
}