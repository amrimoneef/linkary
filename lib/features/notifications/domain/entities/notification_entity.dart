import 'dart:convert';

class NotificationEntity {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  bool isRead;
  final Map<String, dynamic> payload;

  NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.payload = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'payload': payload,
    };
  }

  factory NotificationEntity.fromMap(Map<String, dynamic> map) {
    return NotificationEntity(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      payload: Map<String, dynamic>.from(map['payload'] ?? {}),
    );
  }

  String toJson() => json.encode(toMap());

  factory NotificationEntity.fromJson(String source) => NotificationEntity.fromMap(json.decode(source));
}
