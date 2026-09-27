import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linkary/features/feedback/domain/entities/feedback_category.dart';
import 'package:linkary/features/feedback/domain/entities/feedback_submission.dart';
import 'package:linkary/features/feedback/infrastructure/datasources/feedback_local_data_source.dart';
import 'package:linkary/features/feedback/infrastructure/datasources/feedback_remote_data_source.dart';
import 'package:linkary/features/feedback/infrastructure/repositories_impl/feedback_repository_impl.dart';

class FakeFeedbackRemoteDataSource extends Fake implements FeedbackRemoteDataSource {
  bool shouldFail = false;
  String successMessage = 'تم استلام اقتراحك بنجاح';
  int sendCount = 0;

  @override
  Future<String> sendFeedback(FeedbackSubmission submission) async {
    sendCount++;
    if (shouldFail) {
      throw Exception('Network error');
    }
    return successMessage;
  }
}

void main() {
  late SharedPreferences prefs;
  late FeedbackLocalDataSource localDataSource;
  late FakeFeedbackRemoteDataSource fakeRemoteDataSource;
  late FeedbackRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    localDataSource = FeedbackLocalDataSource(sharedPreferences: prefs);
    fakeRemoteDataSource = FakeFeedbackRemoteDataSource();
    repository = FeedbackRepositoryImpl(
      remoteDataSource: fakeRemoteDataSource,
      localDataSource: localDataSource,
    );
  });

  group('FeedbackRepositoryImpl Tests', () {
    final testSubmission = FeedbackSubmission(
      id: 'sub_test',
      category: FeedbackCategory.featureRequest,
      title: 'ميزة جديدة',
      description: 'شرح تفصيلي للميزة المطلوبة',
      includeDiagnostics: false,
      createdAt: DateTime.now(),
      status: FeedbackStatus.pendingOffline,
    );

    test('submitFeedback updates status to sent when remote succeeds', () async {
      fakeRemoteDataSource.shouldFail = false;

      final result = await repository.submitFeedback(testSubmission);

      expect(result.status, FeedbackStatus.sent);
      expect(result.serverMessage, 'تم استلام اقتراحك بنجاح');
      expect(fakeRemoteDataSource.sendCount, 1);

      // Verify stored locally as sent
      final history = await repository.getSubmissionHistory();
      expect(history.length, 1);
      expect(history.first.status, FeedbackStatus.sent);
    });

    test('submitFeedback retains pendingOffline and rethrows when remote fails', () async {
      fakeRemoteDataSource.shouldFail = true;

      await expectLater(
        repository.submitFeedback(testSubmission),
        throwsA(isA<Exception>()),
      );

      // Verify stored locally as pendingOffline despite network error
      final history = await repository.getSubmissionHistory();
      expect(history.length, 1);
      expect(history.first.status, FeedbackStatus.pendingOffline);
      expect(history.first.serverMessage, contains('Network error'));
    });

    test('syncPendingSubmissions transmits all pending offline items', () async {
      // 1. Setup 2 pending items
      final item1 = testSubmission.copyWith(id: 'item_1', status: FeedbackStatus.pendingOffline);
      final item2 = testSubmission.copyWith(id: 'item_2', status: FeedbackStatus.pendingOffline);
      await localDataSource.saveSubmission(item1);
      await localDataSource.saveSubmission(item2);

      // 2. Sync online
      fakeRemoteDataSource.shouldFail = false;
      final syncedCount = await repository.syncPendingSubmissions();

      expect(syncedCount, 2);
      final history = await repository.getSubmissionHistory();
      expect(history.every((e) => e.status == FeedbackStatus.sent), isTrue);
    });
  });
}
