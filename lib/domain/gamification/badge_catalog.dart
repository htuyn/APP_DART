import '../../data/models/gamification_model.dart';

enum BadgeMetric { answers, streak, exams, perfectExams }

/// Domain badge metadata. Localized copy is resolved by AppStrings in the UI.
class BadgeDefinition {
  const BadgeDefinition({
    required this.id,
    required this.icon,
    required this.titleKey,
    required this.descriptionKey,
    required this.metric,
    required this.threshold,
  });

  final String id;
  final String icon;
  final String titleKey;
  final String descriptionKey;
  final BadgeMetric metric;
  final int threshold;

  bool isEarned(GamificationModel progress) {
    final value = switch (metric) {
      BadgeMetric.answers => progress.totalAnswered,
      BadgeMetric.streak => progress.streak,
      BadgeMetric.exams => progress.examCount,
      BadgeMetric.perfectExams => progress.perfectCount,
    };
    return value >= threshold;
  }
}

abstract final class BadgeCatalog {
  static const List<BadgeDefinition> all = [
    BadgeDefinition(
      id: 'first_answer',
      icon: '🌱',
      titleKey: 'badge_first_answer_title',
      descriptionKey: 'badge_first_answer_description',
      metric: BadgeMetric.answers,
      threshold: 1,
    ),
    BadgeDefinition(
      id: 'answers_10',
      icon: '📚',
      titleKey: 'badge_answers_10_title',
      descriptionKey: 'badge_answers_10_description',
      metric: BadgeMetric.answers,
      threshold: 10,
    ),
    BadgeDefinition(
      id: 'answers_50',
      icon: '🧠',
      titleKey: 'badge_answers_50_title',
      descriptionKey: 'badge_answers_50_description',
      metric: BadgeMetric.answers,
      threshold: 50,
    ),
    BadgeDefinition(
      id: 'answers_100',
      icon: '🏅',
      titleKey: 'badge_answers_100_title',
      descriptionKey: 'badge_answers_100_description',
      metric: BadgeMetric.answers,
      threshold: 100,
    ),
    BadgeDefinition(
      id: 'streak_3',
      icon: '🔥',
      titleKey: 'badge_streak_3_title',
      descriptionKey: 'badge_streak_3_description',
      metric: BadgeMetric.streak,
      threshold: 3,
    ),
    BadgeDefinition(
      id: 'streak_7',
      icon: '⚡',
      titleKey: 'badge_streak_7_title',
      descriptionKey: 'badge_streak_7_description',
      metric: BadgeMetric.streak,
      threshold: 7,
    ),
    BadgeDefinition(
      id: 'streak_30',
      icon: '👑',
      titleKey: 'badge_streak_30_title',
      descriptionKey: 'badge_streak_30_description',
      metric: BadgeMetric.streak,
      threshold: 30,
    ),
    BadgeDefinition(
      id: 'first_exam',
      icon: '🎯',
      titleKey: 'badge_first_exam_title',
      descriptionKey: 'badge_first_exam_description',
      metric: BadgeMetric.exams,
      threshold: 1,
    ),
    BadgeDefinition(
      id: 'perfect_exam',
      icon: '💯',
      titleKey: 'badge_perfect_exam_title',
      descriptionKey: 'badge_perfect_exam_description',
      metric: BadgeMetric.perfectExams,
      threshold: 1,
    ),
  ];
}
