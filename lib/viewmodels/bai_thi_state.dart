import '../data/models/question_model.dart';
import '../data/models/quiz_result_model.dart';
import 'logic_thi.dart';

/// Tráº¡ng thÃ¡i cá»§a má»™t phiÃªn luyá»‡n táº­p, thi thá»­ hoáº·c lÃ m láº¡i cÃ¢u sai.
class BaiThiState {
  const BaiThiState({
    this.cheDo = CheDoBaiThi.luyenTap,
    this.blockId,
    this.cauHoi = const [],
    this.viTri = 0,
    this.dapAnDaChon = const {},
    this.dangTai = false,
    this.daNop = false,
    this.loi,
    this.ketQua,
  });

  final CheDoBaiThi cheDo;
  final int? blockId;
  final List<QuestionModel> cauHoi;
  final int viTri;

  /// LÆ°u lá»±a chá»n theo ID cÃ¢u há»i Ä‘á»ƒ thá»© tá»± cÃ¢u khÃ´ng áº£nh hÆ°á»Ÿng Ä‘Ã¡p Ã¡n.
  final Map<String, int> dapAnDaChon;
  final bool dangTai;
  final bool daNop;
  final String? loi;
  final QuizResultModel? ketQua;

  int get soCau => cauHoi.length;

  QuestionModel? get cauHienTai =>
      viTri >= 0 && viTri < cauHoi.length ? cauHoi[viTri] : null;

  int? get dapAnHienTai {
    final cau = cauHienTai;
    return cau == null ? null : dapAnDaChon[cau.id];
  }

  int get soDaTraLoi => dapAnDaChon.length;
  int get soChuaTraLoi => soCau - soDaTraLoi;
  double get tienDo => soCau == 0 ? 0 : soDaTraLoi / soCau;
  bool get laCauCuoi => soCau == 0 || viTri >= soCau - 1;

  BaiThiState copyWith({
    CheDoBaiThi? cheDo,
    int? blockId,
    bool xoaBlockId = false,
    List<QuestionModel>? cauHoi,
    int? viTri,
    Map<String, int>? dapAnDaChon,
    bool? dangTai,
    bool? daNop,
    String? loi,
    bool xoaLoi = false,
    QuizResultModel? ketQua,
    bool xoaKetQua = false,
  }) {
    return BaiThiState(
      cheDo: cheDo ?? this.cheDo,
      blockId: xoaBlockId ? null : blockId ?? this.blockId,
      cauHoi: cauHoi ?? this.cauHoi,
      viTri: viTri ?? this.viTri,
      dapAnDaChon: dapAnDaChon ?? this.dapAnDaChon,
      dangTai: dangTai ?? this.dangTai,
      daNop: daNop ?? this.daNop,
      loi: xoaLoi ? null : loi ?? this.loi,
      ketQua: xoaKetQua ? null : ketQua ?? this.ketQua,
    );
  }
}
