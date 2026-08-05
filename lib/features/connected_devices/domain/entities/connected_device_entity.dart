class ConnectedDeviceEntity {
  final String mac;
  final String ip;
  final String name;
  final String type; // WIFI أو USB

  ConnectedDeviceEntity({
    required this.mac,
    required this.ip,
    required this.name,
    required this.type,
  });
}