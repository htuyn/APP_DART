import '../data/models/question_model.dart';
import '../data/models/thong_ke.dart';
import '../domain/repositories/quiz_repository.dart';

/// Gói dữ liệu tổng hợp cho màn thống kê.
class ThongKeTong {
  const ThongKeTong({
    required this.theoKhoi,
    required this.lichSu,
  });

  final List<BlockStat> theoKhoi;
  final QuizHistorySummary lichSu;
}

/// Tạo thống kê bằng repository và mã ngôn ngữ do Provider truyền vào.
Future<ThongKeTong> tinhThongKe(
  IQuizRepository repository, {
  required String langCode,
}) async {
  final questions = await repository.loadQuestions();
  final wrongIds = (await repository.getWrongQuestionIds()).toSet();
  final history = await repository.getQuizHistory();

  final grouped = <int, List<QuestionModel>>{};
  for (final question in questions) {
    grouped.putIfAbsent(question.blockId, () => []).add(question);
  }

  final blockIds = grouped.keys.toList()..sort();
  final blockStats = [
    for (final blockId in blockIds)
      BlockStat.fromQuestions(
        blockId: blockId,
        questions: grouped[blockId]!,
        wrongIds: wrongIds,
        langCode: langCode,
      ),
  ];

  return ThongKeTong(
    theoKhoi: blockStats,
    lichSu: QuizHistorySummary.fromResults(history),
  );
}
