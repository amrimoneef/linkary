import 'device_diagnostic_info.dart';
import 'feedback_category.dart';

enum FeedbackStatus {
  pendingOffline,
  sent;

  String get labelAr {
    switch (this) {
      case FeedbackStatus.pendingOffline:
        return 'محفوظ محلياً (بانتظار الإنترنت)';
      case FeedbackStatus.sent:
        return 'تم الإرسال بنجاح';
    }
  }
}

class FeedbackSubmission {
  final String id;
  final FeedbackCategory category;
  final String title;
  final String description;
  final String? contactInfo;
  final bool includeDiagnostics;
  final DeviceDiagnosticInfo? diagnosticInfo;
  final String? attachmentPath;
  final DateTime createdAt;
  final FeedbackStatus status;
  final String? serverMessage;

  const FeedbackSubmission({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    this.contactInfo,
    this.includeDiagnostics = true,
    this.diagnosticInfo,
    this.attachmentPath,
    required this.createdAt,
    this.status = FeedbackStatus.pendingOffline,
    this.serverMessage,
  });

  FeedbackSubmission copyWith({
    String? id,
    FeedbackCategory? category,
    String? title,
    String? description,
    String? contactInfo,
    bool? includeDiagnostics,
    DeviceDiagnosticInfo? diagnosticInfo,
    String? attachmentPath,
    DateTime? createdAt,
    FeedbackStatus? status,
    String? serverMessage,
  }) {
    return FeedbackSubmission(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      description: description ?? this.description,
      contactInfo: contactInfo ?? this.contactInfo,
      includeDiagnostics: includeDiagnostics ?? this.includeDiagnostics,
      diagnosticInfo: diagnosticInfo ?? this.diagnosticInfo,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      serverMessage: serverMessage ?? this.serverMessage,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category.id,
        'title': title,
        'description': description,
        'contact_info': contactInfo,
        'include_diagnostics': includeDiagnostics,
        'diagnostic_info': diagnosticInfo?.toJson(),
        'attachment_path': attachmentPath,
        'created_at': createdAt.toIso8601String(),
        'status': status.name,
        'server_message': serverMessage,
      };

  factory FeedbackSubmission.fromJson(Map<String, dynamic> json) {
    return FeedbackSubmission(
      id: json['id'] as String,
      category: FeedbackCategory.fromId(json['category'] as String? ?? 'general_feedback'),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      contactInfo: json['contact_info'] as String?,
      includeDiagnostics: json['include_diagnostics'] as bool? ?? true,
      diagnosticInfo: json['diagnostic_info'] != null
          ? DeviceDiagnosticInfo.fromJson(json['diagnostic_info'] as Map<String, dynamic>)
          : null,
      attachmentPath: json['attachment_path'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      status: json['status'] == 'sent'
          ? FeedbackStatus.sent
          : FeedbackStatus.pendingOffline,
      serverMessage: json['server_message'] as String?,
    );
  }
}
