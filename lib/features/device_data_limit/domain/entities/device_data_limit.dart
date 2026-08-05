class DeviceDataLimit {
  final String index;
  final String hostname;
  final String mac;
  final int quotaBytes;
  final String status;
  final int currentUsageBytes;
  final String comment;
  final String recordData;

  DeviceDataLimit({
    required this.index,
    required this.hostname,
    required this.mac,
    required this.quotaBytes,
    required this.status,
    required this.currentUsageBytes,
    required this.comment,
    required this.recordData,
  });

  DeviceDataLimit copyWith({
    String? index,
    String? hostname,
    String? mac,
    int? quotaBytes,
    String? status,
    int? currentUsageBytes,
    String? comment,
    String? recordData,
  }) {
    return DeviceDataLimit(
      index: index ?? this.index,
      hostname: hostname ?? this.hostname,
      mac: mac ?? this.mac,
      quotaBytes: quotaBytes ?? this.quotaBytes,
      status: status ?? this.status,
      currentUsageBytes: currentUsageBytes ?? this.currentUsageBytes,
      comment: comment ?? this.comment,
      recordData: recordData ?? this.recordData,
    );
  }
}
