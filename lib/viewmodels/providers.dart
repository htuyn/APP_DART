import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/question_model.dart';
import '../data/models/quiz_result_model.dart';
import 'bai_thi_vm.dart';
import 'ngon_ngu_vm.dart';
import 'thong_ke_vm.dart';

export 'bai_thi_state.dart';
export 'bai_thi_vm.dart';
export 'dong_ho_vm.dart';
export 'logic_thi.dart';
export 'ngon_ngu.dart';
export 'ngon_ngu_vm.dart';
export 'thong_ke_vm.dart';

/// Danh sách câu hỏi từ assets.
final questionBankProvider = FutureProvider<List<QuestionModel>>((ref) {
  return ref.watch(quizRepositoryProvider).loadQuestions();
});

/// ID các câu đang có trong sổ câu sai.
final wrongQuestionIdsProvider = FutureProvider<Set<String>>((ref) async {
  final ids = await ref.watch(quizRepositoryProvider).getWrongQuestionIds();
  return ids.toSet();
});

/// Lịch sử thi đã lưu.
final quizHistoryProvider = FutureProvider<List<QuizResultModel>>((ref) {
  return ref.watch(quizRepositoryProvider).getQuizHistory();
});

/// Thống kê theo khối và lịch sử; theo dõi đổi ngôn ngữ để cập nhật tiêu đề khối.
final thongKeProvider = FutureProvider.autoDispose<ThongKeTong>((ref) {
  final repository = ref.watch(quizRepositoryProvider);
  final language = ref.watch(ngonNguProvider).ma;
  return tinhThongKe(repository, langCode: language);
});

/// Mã ngôn ngữ hiện tại cho MaterialApp.locale hoặc hàm dịch.
final localeCodeProvider = Provider<String>(
  (ref) => ref.watch(ngonNguProvider).ma,
);
