enum GlassTheme {
  darkAcrylic,
  frostedGlass,
  deepCyan,
}

class WidgetConfigEntity {
  final GlassTheme theme;
  final bool showConnectedDevices;
  final bool showBattery;
  final bool showSignal;
  final bool showQuickActions;

  const WidgetConfigEntity({
    this.theme = GlassTheme.darkAcrylic,
    this.showConnectedDevices = true,
    this.showBattery = true,
    this.showSignal = true,
    this.showQuickActions = true,
  });

  WidgetConfigEntity copyWith({
    GlassTheme? theme,
    bool? showConnectedDevices,
    bool? showBattery,
    bool? showSignal,
    bool? showQuickActions,
  }) {
    return WidgetConfigEntity(
      theme: theme ?? this.theme,
      showConnectedDevices: showConnectedDevices ?? this.showConnectedDevices,
      showBattery: showBattery ?? this.showBattery,
      showSignal: showSignal ?? this.showSignal,
      showQuickActions: showQuickActions ?? this.showQuickActions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'theme': theme.name,
      'showConnectedDevices': showConnectedDevices,
      'showBattery': showBattery,
      'showSignal': showSignal,
      'showQuickActions': showQuickActions,
    };
  }

  factory WidgetConfigEntity.fromJson(Map<String, dynamic> json) {
    return WidgetConfigEntity(
      theme: GlassTheme.values.firstWhere(
        (e) => e.name == json['theme'],
        orElse: () => GlassTheme.darkAcrylic,
      ),
      showConnectedDevices: json['showConnectedDevices'] ?? true,
      showBattery: json['showBattery'] ?? true,
      showSignal: json['showSignal'] ?? true,
      showQuickActions: json['showQuickActions'] ?? true,
    );
  }
}
