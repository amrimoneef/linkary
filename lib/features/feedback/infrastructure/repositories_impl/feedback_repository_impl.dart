import '../../domain/entities/feedback_submission.dart';
import '../../domain/repositories/feedback_repository.dart';
import '../datasources/feedback_local_data_source.dart';
import '../datasources/feedback_remote_data_source.dart';

class FeedbackRepositoryImpl implements FeedbackRepository {
  final FeedbackRemoteDataSource remoteDataSource;
  final FeedbackLocalDataSource localDataSource;

  FeedbackRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<FeedbackSubmission> submitFeedback(FeedbackSubmission submission) async {
    // 1. Save initially to local storage as pendingOffline to guarantee zero data loss
    var current = submission.copyWith(status: FeedbackStatus.pendingOffline);
    await localDataSource.saveSubmission(current);

    // 2. Try remote transmission
    try {
      final msg = await remoteDataSource.sendFeedback(current);
      current = current.copyWith(
        status: FeedbackStatus.sent,
        serverMessage: msg,
      );
      await localDataSource.saveSubmission(current);
      return current;
    } catch (e) {
      // Keep as pendingOffline and persist error explanation
      current = current.copyWith(
        status: FeedbackStatus.pendingOffline,
        serverMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      await localDataSource.saveSubmission(current);
      rethrow;
    }
  }

  @override
  Future<List<FeedbackSubmission>> getSubmissionHistory() async {
    return await localDataSource.getSubmissions();
  }

  @override
  Future<void> saveToQueue(FeedbackSubmission submission) async {
    await localDataSource.saveSubmission(submission);
  }

  @override
  Future<int> syncPendingSubmissions() async {
    final history = await localDataSource.getSubmissions();
    final pending = history.where((s) => s.status == FeedbackStatus.pendingOffline).toList();

    int successCount = 0;
    for (final item in pending) {
      try {
        final msg = await remoteDataSource.sendFeedback(item);
        final updated = item.copyWith(
          status: FeedbackStatus.sent,
          serverMessage: msg,
        );
        await localDataSource.saveSubmission(updated);
        successCount++;
      } catch (_) {
        // If still offline, continue to next
      }
    }
    return successCount;
  }

  @override
  Future<void> deleteSubmission(String id) async {
    await localDataSource.deleteSubmission(id);
  }

  @override
  Future<void> clearHistory() async {
    await localDataSource.clearAll();
  }
}
