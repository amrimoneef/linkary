import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linkary/features/feedback/domain/entities/feedback_category.dart';
import 'package:linkary/features/feedback/domain/entities/feedback_submission.dart';
import 'package:linkary/features/feedback/infrastructure/datasources/feedback_local_data_source.dart';

void main() {
  late SharedPreferences prefs;
  late FeedbackLocalDataSource localDataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    localDataSource = FeedbackLocalDataSource(sharedPreferences: prefs);
  });

  group('FeedbackLocalDataSource Tests', () {
    test('getSubmissions returns empty list initially', () async {
      final result = await localDataSource.getSubmissions();
      expect(result, isEmpty);
    });

    test('saveSubmission saves new item and retrieves it ordered by newest', () async {
      final sub1 = FeedbackSubmission(
        id: 'sub_1',
        category: FeedbackCategory.featureRequest,
        title: 'أول اقتراح',
        description: 'وصف الاقتراح الأول',
        includeDiagnostics: false,
        createdAt: DateTime(2026, 9, 27, 10, 0),
        status: FeedbackStatus.pendingOffline,
      );

      final sub2 = FeedbackSubmission(
        id: 'sub_2',
        category: FeedbackCategory.bugReport,
        title: 'ثاني اقتراح',
        description: 'وصف الاقتراح الثاني',
        includeDiagnostics: false,
        createdAt: DateTime(2026, 9, 27, 12, 0),
        status: FeedbackStatus.sent,
      );

      await localDataSource.saveSubmission(sub1);
      await localDataSource.saveSubmission(sub2);

      final list = await localDataSource.getSubmissions();
      expect(list.length, 2);
      expect(list.first.id, 'sub_2'); // sub_2 has newer timestamp
      expect(list.last.id, 'sub_1');
    });

    test('saveSubmission updates existing item if id matches', () async {
      final sub = FeedbackSubmission(
        id: 'sub_1',
        category: FeedbackCategory.featureRequest,
        title: 'اقتراح قديم',
        description: 'وصف',
        includeDiagnostics: false,
        createdAt: DateTime(2026, 9, 27, 10, 0),
        status: FeedbackStatus.pendingOffline,
      );
      await localDataSource.saveSubmission(sub);

      final updatedSub = sub.copyWith(
        status: FeedbackStatus.sent,
        serverMessage: 'تم بنجاح',
      );
      await localDataSource.saveSubmission(updatedSub);

      final list = await localDataSource.getSubmissions();
      expect(list.length, 1);
      expect(list.first.status, FeedbackStatus.sent);
      expect(list.first.serverMessage, 'تم بنجاح');
    });

    test('deleteSubmission removes item from cache', () async {
      final sub = FeedbackSubmission(
        id: 'to_delete',
        category: FeedbackCategory.generalFeedback,
        title: 'رأي',
        description: 'تفاصيل',
        includeDiagnostics: false,
        createdAt: DateTime.now(),
        status: FeedbackStatus.sent,
      );
      await localDataSource.saveSubmission(sub);
      expect((await localDataSource.getSubmissions()).length, 1);

      await localDataSource.deleteSubmission('to_delete');
      expect((await localDataSource.getSubmissions()).length, 0);
    });
  });
}
