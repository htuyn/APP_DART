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

/// Danh sÃ¡ch cÃ¢u há»i tá»« assets.
final questionBankProvider = FutureProvider<List<QuestionModel>>((ref) {
  return ref.watch(quizRepositoryProvider).loadQuestions();
});

/// ID cÃ¡c cÃ¢u Ä‘ang cÃ³ trong sá»• cÃ¢u sai.
final wrongQuestionIdsProvider = FutureProvider<Set<String>>((ref) async {
  final ids = await ref.watch(quizRepositoryProvider).getWrongQuestionIds();
  return ids.toSet();
});

/// Lá»‹ch sá»­ thi Ä‘Ã£ lÆ°u.
final quizHistoryProvider = FutureProvider<List<QuizResultModel>>((ref) {
  return ref.watch(quizRepositoryProvider).getQuizHistory();
});

/// Thá»‘ng kÃª theo khá»‘i vÃ  lá»‹ch sá»­; theo dÃµi Ä‘á»•i ngÃ´n ngá»¯ Ä‘á»ƒ cáº­p nháº­t tiÃªu Ä‘á» khá»‘i.
final thongKeProvider = FutureProvider.autoDispose<ThongKeTong>((ref) {
  final repository = ref.watch(quizRepositoryProvider);
  final language = ref.watch(ngonNguProvider).ma;
  return tinhThongKe(repository, langCode: language);
});

/// MÃ£ ngÃ´n ngá»¯ hiá»‡n táº¡i cho MaterialApp.locale hoáº·c hÃ m dá»‹ch.
final localeCodeProvider = Provider<String>(
  (ref) => ref.watch(ngonNguProvider).ma,
);
