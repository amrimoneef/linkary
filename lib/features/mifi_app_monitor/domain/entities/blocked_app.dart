class BlockedApp {
  final String packageName;
  final String appName;
  final DateTime blockedAt;

  const BlockedApp({
    required this.packageName,
    required this.appName,
    required this.blockedAt,
  });

  Map<String, dynamic> toJson() => {
    'packageName': packageName,
    'appName': appName,
    'blockedAt': blockedAt.toIso8601String(),
  };

  factory BlockedApp.fromJson(Map<String, dynamic> json) => BlockedApp(
    packageName: json['packageName'] as String,
    appName: json['appName'] as String,
    blockedAt: DateTime.parse(json['blockedAt'] as String),
  );
}
