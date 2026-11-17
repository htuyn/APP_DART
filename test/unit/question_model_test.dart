import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quiz_bilingual/data/models/question_model.dart';

void main() {
  group('QuestionModel Tests', () {
    final sampleJson = {
      "id": "K01-001",
      "block_id": 1,
      "block_name": {"vi": "Khá»‘i 1. NgÃ´n ngá»¯ Dart", "en": "Block 1. Dart"},
      "level": "Nhá»›",
      "question": {
        "vi": "Tá»« khoÃ¡ nÃ o yÃªu cáº§u háº±ng sá»‘ lÃºc biÃªn dá»‹ch?",
        "en": "Which keyword requires compile-time constant?"
      },
      "options": {
        "vi": ["final", "var", "const", "late"],
        "en": ["final", "var", "const", "late"]
      },
      "correct_index": 2,
      "explanation": {
        "vi": "const táº¡o háº±ng sá»‘ lÃºc biÃªn dá»‹ch.",
        "en": "const creates compile-time constants."
      }
    };

    test('Parses from valid JSON correctly', () {
      final model = QuestionModel.fromJson(sampleJson);

      expect(model.id, 'K01-001');
      expect(model.blockId, 1);
      expect(model.level, 'Nhá»›');
      expect(model.correctIndex, 2);
      expect(model.optionsVi.length, 4);
      expect(model.optionsVi[2], 'const');
    });

    test('Returns correct localized question text', () {
      final model = QuestionModel.fromJson(sampleJson);

      expect(model.question.getText('vi'), 'Tá»« khoÃ¡ nÃ o yÃªu cáº§u háº±ng sá»‘ lÃºc biÃªn dá»‹ch?');
      expect(model.question.getText('en'), 'Which keyword requires compile-time constant?');
    });

    test('Serializes to JSON correctly', () {
      final model = QuestionModel.fromJson(sampleJson);
      final json = model.toJson();

      expect(json['id'], 'K01-001');
      expect(json['correct_index'], 2);
      expect(json['block_id'], 1);
    });
  });
}
