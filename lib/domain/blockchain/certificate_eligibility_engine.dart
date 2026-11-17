import '../../data/models/course_progress_model.dart';
import '../../data/models/gamification_model.dart';
import '../../data/models/quiz_result_model.dart';
import '../../data/models/achievement_certificate_model.dart';

enum AchievementCode {
  perfectScore,
  sevenDayStreak,
  flutterMaster,
  knowledgeExplorer,
}

class CertificateEligibility {
  const CertificateEligibility({
    required this.type,
    required this.code,
    required this.eligible,
    required this.criteria,
  });

  final CertificateType type;
  final String code;
  final bool eligible;
  final Map<String, dynamic> criteria;
}

/// Pure Dart eligibility rules. This class never accesses storage or the network.
class CertificateEligibilityEngine {
  const CertificateEligibilityEngine();

  List<CertificateEligibility> evaluateAchievements({
    required GamificationModel gamification,
    required int currentStreak,
    required int currentLevel,
    required List<QuizResultModel> quizHistory,
    required CourseProgressModel courseProgress,
  }) {
    final perfectScore = gamification.perfectCount > 0 ||
        quizHistory.any(
          (result) =>
              result.totalQuestions > 0 &&
              result.score == result.totalQuestions,
        );
    final achievements = <(AchievementCode, bool, Map<String, dynamic>)>[
      (
        AchievementCode.perfectScore,
        perfectScore,
        {
          'perfect_exam_count': gamification.perfectCount,
          'has_perfect_quiz': perfectScore,
          'required_percent': 100,
        },
      ),
      (
        AchievementCode.sevenDayStreak,
        currentStreak >= 7,
        {'current_streak': currentStreak, 'required_days': 7},
      ),
      (
        AchievementCode.flutterMaster,
        currentLevel >= 5 && gamification.examCount >= 10,
        {
          'current_level': currentLevel,
          'exam_count': gamification.examCount,
          'required_level': 5,
          'required_exams': 10,
        },
      ),
      (
        AchievementCode.knowledgeExplorer,
        courseProgress.allBlocksCompleted,
        {
          'completed_block_ids': courseProgress.completedBlockIds.toList()..sort(),
          'all_block_ids': courseProgress.allBlockIds.toList()..sort(),
          'required_completion_percent': 100,
        },
      ),
    ];

    return achievements
        .map(
          (item) => CertificateEligibility(
            type: CertificateType.achievement,
            code: item.$1.name,
            eligible: item.$2,
            criteria: Map.unmodifiable(item.$3),
          ),
        )
        .toList(growable: false);
  }

  CertificateEligibility evaluateCourseCompletion({
    required CourseProgressModel progress,
  }) {
    final courseComplete =
        progress.allBlocksCompleted &&
        progress.practiceQuestionsAnswered >=
            progress.requiredPracticeQuestions &&
        progress.totalQuestionsAnswered > 0 &&
        progress.totalCorrectAnswers * 100 >=
            progress.totalQuestionsAnswered * 80 &&
        progress.capstoneExamScore != null &&
        progress.capstoneExamTotal != null &&
        progress.capstoneExamTotal! > 0 &&
        progress.capstoneExamScore! * 100 >= progress.capstoneExamTotal! * 80;

    return CertificateEligibility(
      type: CertificateType.courseCompletion,
      code: 'course_completion',
      eligible: courseComplete,
      criteria: Map.unmodifiable({
        ...progress.toJson(),
        'required_block_completion_percent': 100,
        'required_practice_questions': progress.requiredPracticeQuestions,
        'required_accuracy_percent': 80,
        'required_capstone_percent': 80,
      }),
    );
  }
}
