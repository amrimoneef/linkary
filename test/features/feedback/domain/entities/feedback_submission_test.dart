import 'package:flutter_test/flutter_test.dart';
import 'package:linkary/features/feedback/domain/entities/device_diagnostic_info.dart';
import 'package:linkary/features/feedback/domain/entities/feedback_category.dart';
import 'package:linkary/features/feedback/domain/entities/feedback_submission.dart';

void main() {
  group('FeedbackSubmission Tests', () {
    test('toJson and fromJson should serialize and deserialize correctly', () {
      final diag = DeviceDiagnosticInfo(
        appVersion: '1.0.3+10',
        deviceModel: 'Android Test',
        osVersion: 'Android 14',
        modemModel: 'Sam4G MiFi',
        modemFirmware: 'v1.0',
        networkType: '4G',
        batteryLevel: '85%',
        signalStrength: '4/5',
      );

      final original = FeedbackSubmission(
        id: 'test_123',
        category: FeedbackCategory.featureRequest,
        title: 'إضافة ودجت جديد',
        description: 'نرجو إضافة ودجت سرعة الشبكة للشاشة الرئيسية',
        contactInfo: 'test@example.com',
        includeDiagnostics: true,
        diagnosticInfo: diag,
        attachmentPath: '/path/to/image.png',
        createdAt: DateTime(2026, 9, 27, 20, 30),
        status: FeedbackStatus.pendingOffline,
        serverMessage: 'في الانتظار',
      );

      final json = original.toJson();
      final recreated = FeedbackSubmission.fromJson(json);

      expect(recreated.id, original.id);
      expect(recreated.category, original.category);
      expect(recreated.title, original.title);
      expect(recreated.description, original.description);
      expect(recreated.contactInfo, original.contactInfo);
      expect(recreated.includeDiagnostics, original.includeDiagnostics);
      expect(recreated.diagnosticInfo?.deviceModel, 'Android Test');
      expect(recreated.attachmentPath, original.attachmentPath);
      expect(recreated.status, FeedbackStatus.pendingOffline);
      expect(recreated.serverMessage, original.serverMessage);
    });

    test('copyWith should properly update specified fields', () {
      final submission = FeedbackSubmission(
        id: 'test_1',
        category: FeedbackCategory.bugReport,
        title: 'عطل في الاتصال',
        description: 'تفاصيل العطل',
        includeDiagnostics: false,
        createdAt: DateTime.now(),
        status: FeedbackStatus.pendingOffline,
      );

      final updated = submission.copyWith(
        status: FeedbackStatus.sent,
        serverMessage: 'تم الاستلام بنجاح',
      );

      expect(updated.id, submission.id);
      expect(updated.status, FeedbackStatus.sent);
      expect(updated.serverMessage, 'تم الاستلام بنجاح');
      expect(updated.category, FeedbackCategory.bugReport);
    });

    test('FeedbackStatus labels should be localized in Arabic', () {
      expect(FeedbackStatus.pendingOffline.labelAr, contains('محفوظ محلياً'));
      expect(FeedbackStatus.sent.labelAr, contains('تم الإرسال'));
    });
  });
}
