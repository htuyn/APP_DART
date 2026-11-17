import 'dart:math';

import '../../data/models/spaced_repetition_model.dart';

/// Pure implementation of the SM-2 spaced-repetition algorithm.
///
/// Quality scale (0–5):
///   >= 3  → correct answer (varying confidence)
///   <  3  → incorrect answer
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

  /// Advance [entry] by one review with the given [quality] score (0–5).
  ///
  /// SM-2 update rules:
  ///   newEF = max(1.3, EF + 0.1 − (5−q) × (0.08 + (5−q) × 0.02))
  ///   if quality < 3 : interval = 1, reviewCount stays (not incremented)
  ///   if reviewCount == 0 : interval = 1
  ///   if reviewCount == 1 : interval = 6
  ///   else               : interval = round(prevInterval × newEF)
  static SpacedRepetitionEntry computeNext(
    SpacedRepetitionEntry entry,
    int quality,
  ) {
    assert(quality >= 0 && quality <= 5, 'quality must be in [0, 5]');

    final now = DateTime.now();

    // ── 1. Update ease factor ───────────────────────────────────────────────
    final double newEF = max(
      1.3,
      entry.easeFactor +
          0.1 -
          (5 - quality) * (0.08 + (5 - quality) * 0.02),
    );

    // ── 2. Determine new interval & reviewCount ─────────────────────────────
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

    // ── 3. Track wrong count ────────────────────────────────────────────────
    final int newWrongCount =
        quality < 3 ? entry.wrongCount + 1 : entry.wrongCount;

    // ── 4. Build updated entry ──────────────────────────────────────────────
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
