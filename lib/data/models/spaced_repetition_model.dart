import 'dart:math';

class SpacedRepetitionEntry {
  final String questionId;
  final int wrongCount;
  final int reviewCount;
  final double easeFactor;
  final int intervalDays;
  final DateTime lastReviewed;
  final DateTime nextReviewDate;
  final DateTime savedAt;

  const SpacedRepetitionEntry({
    required this.questionId,
    required this.wrongCount,
    required this.reviewCount,
    required this.easeFactor,
    required this.intervalDays,
    required this.lastReviewed,
    required this.nextReviewDate,
    required this.savedAt,
  });

  /// urgencyScore = wrongCount * 2.0 + max(0, daysPastDue)
  double get urgencyScore {
    final daysPastDue = DateTime.now().difference(nextReviewDate).inDays;
    return wrongCount * 2.0 + max(0, daysPastDue).toDouble();
  }

  SpacedRepetitionEntry copyWith({
    String? questionId,
    int? wrongCount,
    int? reviewCount,
    double? easeFactor,
    int? intervalDays,
    DateTime? lastReviewed,
    DateTime? nextReviewDate,
    DateTime? savedAt,
  }) {
    return SpacedRepetitionEntry(
      questionId: questionId ?? this.questionId,
      wrongCount: wrongCount ?? this.wrongCount,
      reviewCount: reviewCount ?? this.reviewCount,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'questionId': questionId,
      'wrongCount': wrongCount,
      'reviewCount': reviewCount,
      'easeFactor': easeFactor,
      'intervalDays': intervalDays,
      'lastReviewed': lastReviewed.toIso8601String(),
      'nextReviewDate': nextReviewDate.toIso8601String(),
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory SpacedRepetitionEntry.fromJson(Map<String, dynamic> json) {
    return SpacedRepetitionEntry(
      questionId: json['questionId'] as String,
      wrongCount: json['wrongCount'] as int,
      reviewCount: json['reviewCount'] as int,
      easeFactor: (json['easeFactor'] as num).toDouble(),
      intervalDays: json['intervalDays'] as int,
      lastReviewed: DateTime.parse(json['lastReviewed'] as String),
      nextReviewDate: DateTime.parse(json['nextReviewDate'] as String),
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpacedRepetitionEntry &&
          runtimeType == other.runtimeType &&
          questionId == other.questionId;

  @override
  int get hashCode => questionId.hashCode;

  @override
  String toString() =>
      'SpacedRepetitionEntry(questionId: $questionId, wrongCount: $wrongCount, '
      'reviewCount: $reviewCount, easeFactor: $easeFactor, '
      'intervalDays: $intervalDays, nextReviewDate: $nextReviewDate)';
}
