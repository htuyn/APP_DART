import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/quiz_local_datasource.dart';
import '../data/datasources/quiz_storage_datasource.dart';
import '../data/models/question_model.dart';
import '../data/models/quiz_result_model.dart';
import '../data/repositories/quiz_repository_impl.dart';
import '../domain/repositories/quiz_repository.dart';
import 'bai_thi_state.dart';
import 'dong_ho_vm.dart';
import 'logic_thi.dart';

class BaiThiVm extends Notifier<BaiThiState> {
  DateTime? _batDauLuc;
  int _maPhien = 0;

  @override
  BaiThiState build() {
    ref.listen<DongHoState>(dongHoProvider, (previous, current) {
      if (current.hetGio &&
          state.cheDo == CheDoBaiThi.thiThu &&
          !state.daNop &&
          state.cauHoi.isNotEmpty) {
        unawaited(nopBai());
      }
    });
    return const BaiThiState();
  }

  /// Báº¯t Ä‘áº§u phiÃªn má»›i. Thi thá»­ trá»™n cÃ¢u; cháº¿ Ä‘á»™ lÃ m láº¡i chá»‰ láº¥y sá»• cÃ¢u sai.
  Future<void> batDau({
    required CheDoBaiThi cheDo,
    int? blockId,
    int soCau = CauHinhThi.soCauMacDinh,
    int? thoiGianGiay,
    Random? random,
  }) async {
    ref.read(dongHoProvider.notifier).dung();
    _batDauLuc = null;
    final maPhien = ++_maPhien;
    state = BaiThiState(
      cheDo: cheDo,
      blockId: blockId,
      dangTai: true,
    );

    try {
      final repository = ref.read(quizRepositoryProvider);
      final allQuestions = await repository.loadQuestions();
      if (maPhien != _maPhien) return;
      final filtered = locTheoKhoi(allQuestions, blockId);
      late final List<QuestionModel> questions;

      if (cheDo == CheDoBaiThi.luyenTap) {
        questions = filtered;
      } else if (cheDo == CheDoBaiThi.thiThu) {
        questions = tronVaLay(filtered, soCau, random: random);
      } else {
        final wrongIds = (await repository.getWrongQuestionIds()).toSet();
        if (maPhien != _maPhien) return;
        questions = locCauSai(filtered, wrongIds);
      }

      _batDauLuc = DateTime.now();
      state = BaiThiState(
        cheDo: cheDo,
        blockId: blockId,
        cauHoi: questions,
      );

      if (cheDo == CheDoBaiThi.thiThu && questions.isNotEmpty) {
        ref.read(dongHoProvider.notifier).batDau(
              thoiGianGiay ?? CauHinhThi.thoiGianThiThuGiay,
            );
      }
    } catch (error) {
      if (maPhien != _maPhien) return;
      state = BaiThiState(
        cheDo: cheDo,
        blockId: blockId,
        loi: error.toString(),
      );
    }
  }

  /// Ghi Ä‘Ã¡p Ã¡n theo ID cÃ¢u; cáº­p nháº­t sá»• sai ngay Ä‘á»ƒ phiÃªn luyá»‡n táº­p cÅ©ng lÆ°u tiáº¿n Ä‘á»™.
  Future<void> chonDapAn(int viTriDapAn) async {
    final question = state.cauHienTai;
    if (question == null || state.daNop) return;
    if (viTriDapAn < 0 || viTriDapAn >= question.optionsVi.length) return;

    state = state.copyWith(
      dapAnDaChon: {
        ...state.dapAnDaChon,
        question.id: viTriDapAn,
      },
    );

    final repository = ref.read(quizRepositoryProvider);
    if (viTriDapAn == question.correctIndex) {
      await repository.removeWrongQuestion(question.id);
    } else {
      await repository.saveWrongQuestion(question.id);
    }
  }

  void cauTiepTheo() {
    if (state.cauHoi.isEmpty || state.laCauCuoi || state.daNop) return;
    state = state.copyWith(viTri: state.viTri + 1);
  }

  void cauTruocDo() {
    if (state.viTri <= 0 || state.daNop) return;
    state = state.copyWith(viTri: state.viTri - 1);
  }

  void denCau(int index) {
    if (index < 0 || index >= state.soCau || state.daNop) return;
    state = state.copyWith(viTri: index);
  }

  /// Cháº¥m Ä‘iá»ƒm, cáº­p nháº­t sá»• sai vÃ  lÆ°u káº¿t quáº£ má»™t láº§n.
  Future<QuizResultModel?> nopBai() async {
    if (state.daNop) return state.ketQua;
    if (state.cauHoi.isEmpty) return null;

    final snapshot = state;
    final grading = chamDiem(snapshot.cauHoi, snapshot.dapAnDaChon);
    final timer = ref.read(dongHoProvider);
    final elapsedSeconds = snapshot.cheDo == CheDoBaiThi.thiThu
        ? timer.daQua
        : DateTime.now()
            .difference(_batDauLuc ?? DateTime.now())
            .inSeconds
            .clamp(0, 1 << 31)
            .toInt();

    ref.read(dongHoProvider.notifier).dung();

    final result = QuizResultModel(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      score: grading.soDung,
      totalQuestions: snapshot.cauHoi.length,
      timeSpentSeconds: elapsedSeconds,
      wrongQuestionIds: grading.idCauSai,
    );

    // ÄÃ¡nh dáº¥u Ä‘Ã£ ná»™p Ä‘á»“ng bá»™ Ä‘á»ƒ trÃ¡nh lÆ°u trÃ¹ng khi Ä‘á»“ng há»“ vÃ  nÃºt cÃ¹ng kÃ­ch hoáº¡t.
    state = snapshot.copyWith(daNop: true, ketQua: result);
    final repository = ref.read(quizRepositoryProvider);

    for (final question in snapshot.cauHoi) {
      if (grading.idCauSai.contains(question.id)) {
        await repository.saveWrongQuestion(question.id);
      } else {
        await repository.removeWrongQuestion(question.id);
      }
    }
    // Lá»‹ch sá»­ thi trong app hiá»‡n táº¡i chá»‰ ghi nháº­n cÃ¡c phiÃªn thi thá»­.
    if (snapshot.cheDo == CheDoBaiThi.thiThu) {
      await repository.saveQuizResult(result);
    }
    return result;
  }

  void thoatPhien() {
    _maPhien++;
    ref.read(dongHoProvider.notifier).dung();
    _batDauLuc = null;
    state = const BaiThiState();
  }
}

/// Repository dÃ¹ng chung cho ViewModels Riverpod, ná»‘i vá»›i datasource hiá»‡n cÃ³.
final quizRepositoryProvider = Provider<IQuizRepository>((ref) {
  return QuizRepositoryImpl(
    localDataSource: QuizLocalDataSource(),
    storageDataSource: QuizStorageDataSource(),
  );
});

final baiThiProvider = NotifierProvider<BaiThiVm, BaiThiState>(
  BaiThiVm.new,
);
