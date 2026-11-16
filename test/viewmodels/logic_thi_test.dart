import 'package:flutter_quiz_bilingual/data/models/question_model.dart';
import 'package:flutter_quiz_bilingual/viewmodels/logic_thi.dart';
import 'package:flutter_test/flutter_test.dart';

QuestionModel _question(String id, int blockId, int correctIndex) {
  return QuestionModel(
    id: id,
    blockId: blockId,
    blockName: LocalizedText(vi: 'Khối $blockId', en: 'Block $blockId'),
    level: 'Nhớ',
    question: LocalizedText(vi: 'Câu $id', en: 'Question $id'),
    optionsVi: const ['A', 'B', 'C', 'D'],
    optionsEn: const ['A', 'B', 'C', 'D'],
    correctIndex: correctIndex,
    explanation: const LocalizedText(vi: 'Giải thích', en: 'Explanation'),
  );
}

void main() {
  final questions = [
    _question('Q1', 1, 0),
    _question('Q2', 1, 2),
    _question('Q3', 2, 1),
  ];

  group('logic thi', () {
    test('lọc theo khối; null hoặc 0 lấy tất cả', () {
      expect(locTheoKhoi(questions, 1).map((q) => q.id), ['Q1', 'Q2']);
      expect(locTheoKhoi(questions, 2).map((q) => q.id), ['Q3']);
      expect(locTheoKhoi(questions, null), hasLength(3));
      expect(locTheoKhoi(questions, 0), hasLength(3));
    });

    test('trộn và lấy tối đa số câu yêu cầu mà không sửa danh sách gốc', () {
      final originalIds = questions.map((q) => q.id).toList();

      final selected = tronVaLay(questions, 2);

      expect(selected, hasLength(2));
      expect(selected.toSet().length, 2);
      expect(questions.map((q) => q.id), originalIds);
      expect(tronVaLay(questions, 0), isEmpty);
      expect(tronVaLay(questions, -1), isEmpty);
    });

    test('lọc câu sai theo ID', () {
      expect(
        locCauSai(questions, {'Q2', 'Q3'}).map((q) => q.id),
        ['Q2', 'Q3'],
      );
    });

    test('chấm đúng, sai và bỏ trống; câu bỏ trống thuộc danh sách ôn lại', () {
      final result = chamDiem(questions, {'Q1': 0, 'Q2': 1});

      expect(result.soDung, 1);
      expect(result.soChuaLam, 1);
      expect(result.idCauSai, ['Q2', 'Q3']);
    });
  });
}
