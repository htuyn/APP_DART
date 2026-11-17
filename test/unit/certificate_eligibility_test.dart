import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quiz_bilingual/data/models/achievement_certificate_model.dart';
import 'package:flutter_quiz_bilingual/data/models/course_progress_model.dart';
import 'package:flutter_quiz_bilingual/data/models/gamification_model.dart';
import 'package:flutter_quiz_bilingual/data/models/quiz_result_model.dart';
import 'package:flutter_quiz_bilingual/domain/blockchain/certificate_eligibility_engine.dart';

void main() {
  const engine = CertificateEligibilityEngine();

  CourseProgressModel progress({
    int bank = 30,
    int practice = 27,
    int answered = 100,
    int correct = 80,
    int? capstoneScore = 80,
    int? capstoneTotal = 100,
    Set<int> completed = const {1, 2},
  }) =>
      CourseProgressModel(
        allBlockIds: const {1, 2},
        completedBlockIds: completed,
        totalQuestionsInBank: bank,
        practiceQuestionsAnswered: practice,
        totalQuestionsAnswered: answered,
        totalCorrectAnswers: correct,
        capstoneExamScore: capstoneScore,
        capstoneExamTotal: capstoneTotal,
      );

  test('opens all four achievement certificates at their thresholds', () {
    final result = engine.evaluateAchievements(
      gamification: GamificationModel(examCount: 10, perfectCount: 1),
      currentStreak: 7,
      currentLevel: 5,
      quizHistory: const [],
      courseProgress: progress(),
    );

    expect(result, hasLength(4));
    expect(
      result.every((item) => item.type == CertificateType.achievement),
      isTrue,
    );
    expect(result.map((item) => item.code).toSet(), hasLength(4));
    expect(result.every((item) => item.eligible), isTrue);
    expect(
      result.map((item) => item.code),
      containsAll([
        'perfectScore',
        'sevenDayStreak',
        'flutterMaster',
        'knowledgeExplorer',
      ]),
    );
  });

  test('perfect score can come from quiz history, but not an incomplete test', () {
    final noPerfect = engine.evaluateAchievements(
      gamification: GamificationModel(),
      currentStreak: 0,
      currentLevel: 1,
      quizHistory: [
        QuizResultModel(
          id: 'attempt',
          timestamp: DateTime.utc(2026),
          score: 9,
          totalQuestions: 10,
          timeSpentSeconds: 20,
          wrongQuestionIds: [],
        ),
      ],
      courseProgress: progress(),
    );
    expect(
      noPerfect.firstWhere((item) => item.code == 'perfectScore').eligible,
      isFalse,
    );

    final perfect = engine.evaluateAchievements(
      gamification: GamificationModel(),
      currentStreak: 0,
      currentLevel: 1,
      quizHistory: [
        QuizResultModel(
          id: 'perfect',
          timestamp: DateTime.utc(2026),
          score: 10,
          totalQuestions: 10,
          timeSpentSeconds: 20,
          wrongQuestionIds: [],
        ),
      ],
      courseProgress: progress(),
    );
    expect(
      perfect.firstWhere((item) => item.code == 'perfectScore').eligible,
      isTrue,
    );
  });

  test('course certificate uses ceil of 90 percent for a 30-question bank', () {
    final belowThreshold = engine.evaluateCourseCompletion(
      progress: progress(practice: 26),
    );
    final atThreshold = engine.evaluateCourseCompletion(
      progress: progress(practice: 27),
    );

    expect(belowThreshold.eligible, isFalse);
    expect(atThreshold.eligible, isTrue);
    expect(atThreshold.criteria['required_practice_questions'], 27);
    expect(progress().requiredPracticeQuestions, 27);
  });

  test('course certificate uses ceil of 90 percent for a 100-question bank', () {
    expect(
      engine.evaluateCourseCompletion(
        progress: progress(bank: 100, practice: 89),
      ).eligible,
      isFalse,
    );
    final result = engine.evaluateCourseCompletion(
      progress: progress(bank: 100, practice: 90),
    );
    expect(result.eligible, isTrue);
    expect(result.criteria['required_practice_questions'], 90);
  });

  test('an empty question bank still requires at least one practice answer', () {
    expect(progress(bank: 0, practice: 0).requiredPracticeQuestions, 1);
    expect(
      engine.evaluateCourseCompletion(
        progress: progress(bank: 0, practice: 0),
      ).eligible,
      isFalse,
    );
    expect(
      engine.evaluateCourseCompletion(
        progress: progress(bank: 0, practice: 1),
      ).eligible,
      isTrue,
    );
  });

  test('course certificate enforces 79/80 accuracy boundaries', () {
    expect(
      engine.evaluateCourseCompletion(
        progress: progress(practice: 27, answered: 100, correct: 79),
      ).eligible,
      isFalse,
    );
    expect(
      engine.evaluateCourseCompletion(
        progress: progress(practice: 27, answered: 100, correct: 80),
      ).eligible,
      isTrue,
    );
  });

  test('course certificate requires all blocks and an 80 percent capstone', () {
    expect(
      engine.evaluateCourseCompletion(
        progress: progress(completed: const {1}),
      ).eligible,
      isFalse,
    );
    expect(
      engine.evaluateCourseCompletion(
        progress: progress(capstoneScore: 79),
      ).eligible,
      isFalse,
    );
    expect(
      engine.evaluateCourseCompletion(
        progress: progress(capstoneScore: 80),
      ).eligible,
      isTrue,
    );
  });

  test('eligibility returns one record for each achievement code', () {
    final result = engine.evaluateAchievements(
      gamification: GamificationModel(examCount: 10, perfectCount: 1),
      currentStreak: 7,
      currentLevel: 5,
      quizHistory: const [],
      courseProgress: progress(),
    );
    expect(result.map((item) => item.code).toSet(), hasLength(result.length));
  });
}
