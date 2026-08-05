class BandConfigEntity {
  final bool isAuto;
  final List<int> supportedBands;
  final List<int> configuredBands;

  BandConfigEntity({
    required this.isAuto,
    required this.supportedBands,
    required this.configuredBands,
  });

  factory BandConfigEntity.fromJson(Map<String, dynamic> json) {
    // Example: {"band_select":"on","bands":{"lte":{"support":[3,28,41],"config":[28,41]}}}
    final isAuto = (json['band_select'] as String?) == 'off'; // off means Auto, on means Manual
    
    final lteJson = json['bands']?['lte'] as Map<String, dynamic>?;
    
    final support = lteJson?['support'] as List<dynamic>? ?? [];
    final config = lteJson?['config'] as List<dynamic>? ?? [];

    return BandConfigEntity(
      isAuto: isAuto,
      supportedBands: support.map((e) => int.tryParse(e.toString()) ?? 0).toList()..removeWhere((e) => e == 0),
      configuredBands: config.map((e) => int.tryParse(e.toString()) ?? 0).toList()..removeWhere((e) => e == 0),
    );
  }
}
