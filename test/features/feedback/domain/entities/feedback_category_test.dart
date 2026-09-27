import 'package:flutter_test/flutter_test.dart';
import 'package:linkary/features/feedback/domain/entities/feedback_category.dart';

void main() {
  group('FeedbackCategory Tests', () {
    test('Should have exactly 3 approved categories without modem request', () {
      expect(FeedbackCategory.values.length, 3);
      expect(FeedbackCategory.values, contains(FeedbackCategory.featureRequest));
      expect(FeedbackCategory.values, contains(FeedbackCategory.bugReport));
      expect(FeedbackCategory.values, contains(FeedbackCategory.generalFeedback));
    });

    test('Each category should have appropriate Arabic labels and ids', () {
      expect(FeedbackCategory.featureRequest.id, 'feature_request');
      expect(FeedbackCategory.featureRequest.labelAr, 'اقتراح ميزة');

      expect(FeedbackCategory.bugReport.id, 'bug_report');
      expect(FeedbackCategory.bugReport.labelAr, 'إبلاغ عن مشكلة');

      expect(FeedbackCategory.generalFeedback.id, 'general_feedback');
      expect(FeedbackCategory.generalFeedback.labelAr, 'تقييم ورأي عام');
    });

    test('Each category should have valid icon and non-null color', () {
      for (final cat in FeedbackCategory.values) {
        expect(cat.icon, isNotNull);
        expect(cat.color, isNotNull);
        expect(cat.descriptionAr.isNotEmpty, isTrue);
      }
    });
  });
}
