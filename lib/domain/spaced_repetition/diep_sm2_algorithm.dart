import 'dart:math';

import '../../data/models/diep_spaced_repetition_model.dart';

/// Pure implementation of the SM-2 spaced-repetition algorithm.
///
/// Quality scale (0â€“5):
///   >= 3  â†’ correct answer (varying confidence)
///   <  3  â†’ incorrect answer
class SM2Algorithm {
  SM2Algorithm._(); // non-instantiable utility class

  /// Create a brand-new entry for [questionId] with SM-2 defaults.
  static SpacedRepetitionEntry createNew(String questionId) {
    final now = DateTime.now();
    return SpacedRepetitionEntry(
      questionId: questionId,
      wrongCount: 0,
      reviewCount: 0,
      easeFactor: 2.5,
      intervalDays: 1,
      lastReviewed: now,
      nextReviewDate: now.add(const Duration(days: 1)),
      savedAt: now,
    );
  }

  /// Advance [entry] by one review with the given [quality] score (0â€“5).
  ///
  /// SM-2 update rules:
  ///   newEF = max(1.3, EF + 0.1 âˆ’ (5âˆ’q) Ã— (0.08 + (5âˆ’q) Ã— 0.02))
  ///   if quality < 3 : interval = 1, reviewCount stays (not incremented)
  ///   if reviewCount == 0 : interval = 1
  ///   if reviewCount == 1 : interval = 6
  ///   else               : interval = round(prevInterval Ã— newEF)
  static SpacedRepetitionEntry computeNext(
    SpacedRepetitionEntry entry,
    int quality,
  ) {
    assert(quality >= 0 && quality <= 5, 'quality must be in [0, 5]');

    final now = DateTime.now();

    // â”€â”€ 1. Update ease factor â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final double newEF = max(
      1.3,
      entry.easeFactor +
          0.1 -
          (5 - quality) * (0.08 + (5 - quality) * 0.02),
    );

    // â”€â”€ 2. Determine new interval & reviewCount â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    int newInterval;
    int newReviewCount;

    if (quality < 3) {
      // Incorrect: reset interval, do not increment reviewCount
      newInterval = 1;
      newReviewCount = entry.reviewCount; // reset-ish: keep count but restart
    } else {
      newReviewCount = entry.reviewCount + 1;
      if (entry.reviewCount == 0) {
        newInterval = 1;
      } else if (entry.reviewCount == 1) {
        newInterval = 6;
      } else {
        newInterval = (entry.intervalDays * newEF).round();
      }
    }

    // Clamp interval to at least 1 day
    newInterval = max(1, newInterval);

    // â”€â”€ 3. Track wrong count â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    final int newWrongCount =
        quality < 3 ? entry.wrongCount + 1 : entry.wrongCount;

    // â”€â”€ 4. Build updated entry â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    return entry.copyWith(
      wrongCount: newWrongCount,
      reviewCount: newReviewCount,
      easeFactor: newEF,
      intervalDays: newInterval,
      lastReviewed: now,
      nextReviewDate: now.add(Duration(days: newInterval)),
      savedAt: now,
    );
  }
}
