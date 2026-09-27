import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/feedback_submission.dart';

class FeedbackLocalDataSource {
  static const String _storageKey = 'linkary_feedback_submissions_queue';
  final SharedPreferences sharedPreferences;

  FeedbackLocalDataSource({required this.sharedPreferences});

  /// Retrieves all cached submissions
  Future<List<FeedbackSubmission>> getSubmissions() async {
    final rawList = sharedPreferences.getStringList(_storageKey);
    if (rawList == null || rawList.isEmpty) return [];

    final List<FeedbackSubmission> items = [];
    for (final jsonStr in rawList) {
      try {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        items.add(FeedbackSubmission.fromJson(map));
      } catch (_) {
        // Skip malformed entries
      }
    }
    // Sort newest first
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// Saves or updates a submission in the local list
  Future<void> saveSubmission(FeedbackSubmission submission) async {
    final currentList = await getSubmissions();
    final index = currentList.indexWhere((item) => item.id == submission.id);

    if (index >= 0) {
      currentList[index] = submission;
    } else {
      currentList.insert(0, submission);
    }

    final rawList = currentList.map((e) => jsonEncode(e.toJson())).toList();
    await sharedPreferences.setStringList(_storageKey, rawList);
  }

  /// Deletes a specific submission
  Future<void> deleteSubmission(String id) async {
    final currentList = await getSubmissions();
    currentList.removeWhere((item) => item.id == id);
    final rawList = currentList.map((e) => jsonEncode(e.toJson())).toList();
    await sharedPreferences.setStringList(_storageKey, rawList);
  }

  /// Clears the entire queue
  Future<void> clearAll() async {
    await sharedPreferences.remove(_storageKey);
  }
}
