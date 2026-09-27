import '../entities/feedback_submission.dart';

abstract class FeedbackRepository {
  /// Submits feedback to the remote endpoint. If offline, caches locally and throws or returns pending status.
  Future<FeedbackSubmission> submitFeedback(FeedbackSubmission submission);

  /// Retrieves all cached and submitted feedbacks from local history
  Future<List<FeedbackSubmission>> getSubmissionHistory();

  /// Saves or updates a submission in the local offline queue
  Future<void> saveToQueue(FeedbackSubmission submission);

  /// Tries to synchronize all pending offline submissions to the server
  Future<int> syncPendingSubmissions();

  /// Deletes a specific submission from history
  Future<void> deleteSubmission(String id);

  /// Clears all history
  Future<void> clearHistory();
}
