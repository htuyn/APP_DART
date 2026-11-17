import 'package:flutter/foundation.dart';
import '../../data/models/question_model.dart';
import '../../data/models/spaced_repetition_model.dart';
import '../../data/datasources/spaced_repetition_datasource.dart';
import '../../domain/spaced_repetition/sm2_algorithm.dart';

class SpacedRepetitionProvider with ChangeNotifier {
  final SpacedRepetitionDataSource _dataSource = SpacedRepetitionDataSource();

  Map<String, SpacedRepetitionEntry> _entries = {};
  List<QuestionModel> _allQuestions = [];

  /// All questions sorted by urgencyScore descending (most urgent first).
  /// Only questions that have a bookmark entry are returned.
  List<QuestionModel> get sortedReviewQuestions {
    final bookmarked = _allQuestions
        .where((q) => _entries.containsKey(q.id))
        .toList();

    bookmarked.sort((a, b) {
      final scoreA = _entries[a.id]?.urgencyScore ?? 0.0;
      final scoreB = _entries[b.id]?.urgencyScore ?? 0.0;
      return scoreB.compareTo(scoreA);
    });

    return bookmarked;
  }

  /// Number of questions whose nextReviewDate is today or in the past.
  int get dueTodayCount {
    final now = DateTime.now();
    return _entries.values
        .where((e) => !e.nextReviewDate.isAfter(now))
        .length;
  }

  SpacedRepetitionEntry? entryFor(String questionId) => _entries[questionId];

  bool isBookmarked(String questionId) => _entries.containsKey(questionId);

  Future<void> initialize(List<QuestionModel> allQuestions) async {
    _allQuestions = allQuestions;
    _entries = await _dataSource.loadAll();
    notifyListeners();
  }

  Future<void> bookmarkQuestion(String questionId) async {
    if (_entries.containsKey(questionId)) return;
    final entry = SM2Algorithm.createNew(questionId);
    _entries[questionId] = entry;
    await _dataSource.upsertEntry(entry);
    notifyListeners();
  }

  Future<void> removeBookmark(String questionId) async {
    if (!_entries.containsKey(questionId)) return;
    _entries.remove(questionId);
    await _dataSource.removeEntry(questionId);
    notifyListeners();
  }

  Future<void> recordAnswer(String questionId, bool isCorrect) async {
    final existing = _entries[questionId];
    if (existing == null) return;

    final quality = isCorrect ? 4 : 1;
    final updated = SM2Algorithm.computeNext(existing, quality);
    _entries[questionId] = updated;
    await _dataSource.upsertEntry(updated);
    notifyListeners();
  }
}
