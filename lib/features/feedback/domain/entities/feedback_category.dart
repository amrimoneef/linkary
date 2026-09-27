import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

enum FeedbackCategory {
  featureRequest,
  bugReport,
  generalFeedback;

  String get id {
    switch (this) {
      case FeedbackCategory.featureRequest:
        return 'feature_suggestion';
      case FeedbackCategory.bugReport:
        return 'technical_issue';
      case FeedbackCategory.generalFeedback:
        return 'general_inquiry';
    }
  }

  String get labelAr {
    switch (this) {
      case FeedbackCategory.featureRequest:
        return 'اقتراح ميزة';
      case FeedbackCategory.bugReport:
        return 'إبلاغ عن مشكلة';
      case FeedbackCategory.generalFeedback:
        return 'تقييم ورأي عام';
    }
  }

  String get descriptionAr {
    switch (this) {
      case FeedbackCategory.featureRequest:
        return 'فكرة أو خاصية ترغب برؤيتها في التطبيق';
      case FeedbackCategory.bugReport:
        return 'خلل فني، توقف مفاجئ، أو سلوك غير سليم';
      case FeedbackCategory.generalFeedback:
        return 'انطباعك العام، إشادة، أو نصيحة لتطوير التجربة';
    }
  }

  IconData get icon {
    switch (this) {
      case FeedbackCategory.featureRequest:
        return Iconsax.lamp_on;
      case FeedbackCategory.bugReport:
        return Iconsax.danger;
      case FeedbackCategory.generalFeedback:
        return Iconsax.star_1;
    }
  }

  Color get color {
    switch (this) {
      case FeedbackCategory.featureRequest:
        return const Color(0xFFF59E0B); // Amber
      case FeedbackCategory.bugReport:
        return const Color(0xFFEF4444); // Red
      case FeedbackCategory.generalFeedback:
        return const Color(0xFF8B5CF6); // Royal Violet
    }
  }

  static FeedbackCategory fromId(String id) {
    switch (id) {
      case 'feature_suggestion':
      case 'feature_request':
        return FeedbackCategory.featureRequest;
      case 'technical_issue':
      case 'bug_report':
        return FeedbackCategory.bugReport;
      case 'general_inquiry':
      case 'general_feedback':
      default:
        return FeedbackCategory.generalFeedback;
    }
  }
}
