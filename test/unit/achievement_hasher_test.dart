import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quiz_bilingual/core/utils/achievement_hasher.dart';

void main() {
  const hasher = AchievementHasher();

  test('canonicalizes map key order for a deterministic hash', () {
    final first = hasher.hash(
      subjectId: 'learner-1',
      certificateType: 1,
      achievementCode: 'perfectScore',
      criteria: const {'score': 100, 'exam': {'total': 10, 'correct': 10}},
    );
    final reordered = hasher.hash(
      subjectId: 'learner-1',
      certificateType: 1,
      achievementCode: 'perfectScore',
      criteria: const {'exam': {'correct': 10, 'total': 10}, 'score': 100},
    );

    expect(first, startsWith('0x'));
    expect(first, hasLength(66));
    expect(reordered, first);
  });

  test('different identity or achievement criteria produce different hashes', () {
    final base = hasher.hash(
      subjectId: 'learner-1',
      certificateType: 1,
      achievementCode: 'perfectScore',
      criteria: const {'score': 100},
    );
    final variants = [
      hasher.hash(
        subjectId: 'learner-2',
        certificateType: 1,
        achievementCode: 'perfectScore',
        criteria: const {'score': 100},
      ),
      hasher.hash(
        subjectId: 'learner-1',
        certificateType: 2,
        achievementCode: 'perfectScore',
        criteria: const {'score': 100},
      ),
      hasher.hash(
        subjectId: 'learner-1',
        certificateType: 1,
        achievementCode: 'sevenDayStreak',
        criteria: const {'score': 100},
      ),
      hasher.hash(
        subjectId: 'learner-1',
        certificateType: 1,
        achievementCode: 'perfectScore',
        criteria: const {'score': 99},
      ),
    ];

    expect(variants.toSet(), hasLength(variants.length));
    expect(variants, everyElement(isNot(base)));
  });
}
