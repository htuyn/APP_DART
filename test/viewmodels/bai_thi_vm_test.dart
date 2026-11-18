import 'dart:math';

import 'package:flutter_quiz_bilingual/data/models/question_model.dart';
import 'package:flutter_quiz_bilingual/data/models/quiz_result_model.dart';
import 'package:flutter_quiz_bilingual/domain/repositories/quiz_repository.dart';
import 'package:flutter_quiz_bilingual/viewmodels/bai_thi_vm.dart';
import 'package:flutter_quiz_bilingual/viewmodels/logic_thi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeQuizRepository implements IQuizRepository {
  _FakeQuizRepository(this.questions);

  final List<QuestionModel> questions;
  final Set<String> wrongIds = {};
  final List<QuizResultModel> history = [];

  @override
  Future<List<QuestionModel>> loadQuestions() async => questions;

  @override
  Future<List<String>> getWrongQuestionIds() async => wrongIds.toList();

  @override
  Future<void> saveWrongQuestion(String questionId) async {
    wrongIds.add(questionId);
  }

  @override
  Future<void> removeWrongQuestion(String questionId) async {
    wrongIds.remove(questionId);
  }

  @override
  Future<List<String>> getBookmarkedQuestionIds() async => [];

  @override
  Future<void> saveBookmarkedQuestion(String questionId) async {}

  @override
  Future<void> removeBookmarkedQuestion(String questionId) async {}

  @override
  Future<List<QuizResultModel>> getQuizHistory() async => List.of(history);

  @override
  Future<void> saveQuizResult(QuizResultModel result) async {
    history.add(result);
  }
}

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
  late _FakeQuizRepository repository;
  late ProviderContainer container;

  final questions = [
    _question('Q1', 1, 0),
    _question('Q2', 1, 1),
    _question('Q3', 2, 2),
  ];

  setUp(() {
    repository = _FakeQuizRepository(questions);
    container = ProviderContainer(
      overrides: [
        quizRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('luyện tập lọc theo khối và lưu đáp án sai vào sổ câu sai', () async {
    final vm = container.read(baiThiProvider.notifier);

    await vm.batDau(cheDo: CheDoBaiThi.luyenTap, blockId: 1);
    expect(container.read(baiThiProvider).cauHoi.map((q) => q.id), ['Q1', 'Q2']);

    await vm.chonDapAn(3);
    expect(container.read(baiThiProvider).dapAnHienTai, 3);
    expect(repository.wrongIds, contains('Q1'));

    await vm.chonDapAn(0);
    expect(repository.wrongIds, isNot(contains('Q1')));
  });

  test('làm lại câu sai chỉ nạp ID có trong sổ sai', () async {
    repository.wrongIds.add('Q2');
    final vm = container.read(baiThiProvider.notifier);

    await vm.batDau(cheDo: CheDoBaiThi.lamLaiCauSai);

    expect(container.read(baiThiProvider).cauHoi.map((q) => q.id), ['Q2']);
  });

  test('thi thử lấy tối đa số câu, chấm điểm và lưu lịch sử', () async {
    final vm = container.read(baiThiProvider.notifier);

    await vm.batDau(
      cheDo: CheDoBaiThi.thiThu,
      soCau: 2,
      thoiGianGiay: 120,
      random: Random(1),
    );
    final state = container.read(baiThiProvider);
    expect(state.cauHoi, hasLength(2));

    for (var index = 0; index < state.cauHoi.length; index++) {
      vm.denCau(index);
      await vm.chonDapAn(state.cauHoi[index].correctIndex);
    }

    final result = await vm.nopBai();

    expect(result, isNotNull);
    expect(result!.score, 2);
    expect(result.totalQuestions, 2);
    expect(container.read(baiThiProvider).daNop, isTrue);
    expect(repository.history, hasLength(1));
    expect(repository.wrongIds, isEmpty);
  });

  test('không lưu luyện tập vào lịch sử thi thử', () async {
    final vm = container.read(baiThiProvider.notifier);
    await vm.batDau(cheDo: CheDoBaiThi.luyenTap);
    await vm.nopBai();

    expect(repository.history, isEmpty);
  });
}
