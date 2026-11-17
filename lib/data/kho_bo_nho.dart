import 'models/question_model.dart';
import 'models/quiz_result_model.dart';
import 'models/thong_ke.dart';
import 'kho_du_lieu.dart';

/// Kho dá»¯ liá»‡u lÆ°u trong RAM, dÃ¹ng Ä‘á»ƒ cháº¡y thá»­ vÃ  viáº¿t test.
/// Táº¯t app lÃ  dá»¯ liá»‡u trong kho nÃ y máº¥t.
class KhoBoNho implements KhoDuLieu {
  KhoBoNho({List<QuestionModel>? cauHoi}) : _cauHoi = cauHoi ?? mau();

  final List<QuestionModel> _cauHoi;
  final Set<String> _cauSai = {};
  final List<QuizResultModel> _lichSu = [];
  final Map<int, BlockStat> _thongKe = {};
  double _diemCaoNhat = 0;
  String? _ngonNgu;

  /// Sinh dá»¯ liá»‡u giáº£: [soKhoi] khá»‘i, má»—i khá»‘i [moiKhoi] cÃ¢u, 4 Ä‘Ã¡p Ã¡n.
  /// ID cÃ¢u vÃ  chá»‰ sá»‘ Ä‘Ã¡p Ã¡n Ä‘Ãºng tiáº¿p tá»¥c theo logic dá»¯ liá»‡u máº«u cÅ©.
  static List<QuestionModel> mau({int soKhoi = 2, int moiKhoi = 5}) {
    final ds = <QuestionModel>[];
    var n = 1;
    for (var k = 1; k <= soKhoi; k++) {
      for (var i = 0; i < moiKhoi; i++, n++) {
        ds.add(
          QuestionModel(
            id: 'Q${n.toString().padLeft(3, '0')}',
            blockId: k,
            blockName: LocalizedText(vi: 'Khá»‘i $k', en: 'Block $k'),
            level: 'Nhá»›',
            question: LocalizedText(
              vi: 'CÃ¢u há»i sá»‘ $n',
              en: 'Question number $n',
            ),
            optionsVi: const ['ÄÃ¡p Ã¡n A', 'ÄÃ¡p Ã¡n B', 'ÄÃ¡p Ã¡n C', 'ÄÃ¡p Ã¡n D'],
            optionsEn: const ['Answer A', 'Answer B', 'Answer C', 'Answer D'],
            correctIndex: n % 4,
            explanation: LocalizedText(
              vi: 'Giáº£i thÃ­ch cho cÃ¢u $n',
              en: 'Explanation for question $n',
            ),
          ),
        );
      }
    }
    return ds;
  }

  @override
  Future<List<QuestionModel>> layTatCaCauHoi() async => List.of(_cauHoi);

  @override
  Future<Set<String>> layIdCauSai() async => Set.of(_cauSai);

  @override
  Future<void> luuCauSai(String idCau) async => _cauSai.add(idCau);

  @override
  Future<void> xoaCauSai(String idCau) async => _cauSai.remove(idCau);

  @override
  Future<void> luuKetQua(QuizResultModel ketQua) async =>
      _lichSu.insert(0, ketQua);

  @override
  Future<List<QuizResultModel>> layLichSuThi() async => List.of(_lichSu);

  @override
  Future<double> layDiemCaoNhat() async => _diemCaoNhat;

  @override
  Future<void> luuDiemCaoNhat(double diem) async => _diemCaoNhat = diem;

  @override
  Future<Map<int, BlockStat>> layThongKeKhoi() async => Map.of(_thongKe);

  @override
  Future<void> capNhatThongKeKhoi(
    int blockId, {
    required int daLam,
    required int dung,
  }) async {
    final cu = _thongKe[blockId];
    var title = cu?.blockTitle ?? 'Block $blockId';

    // Giá»¯ tÃªn khá»‘i theo ngÃ´n ngá»¯ Viá»‡t tá»« dá»¯ liá»‡u cÃ¢u há»i khi táº¡o thá»‘ng kÃª láº§n Ä‘áº§u.
    if (cu == null) {
      for (final question in _cauHoi) {
        if (question.blockId == blockId) {
          title = question.blockName.vi;
          break;
        }
      }
    }

    final daLamMoi = (cu?.totalQuestions ?? 0) + daLam;
    final saiMoi = (cu?.wrongQuestions ?? 0) + daLam - dung;
    _thongKe[blockId] = BlockStat(
      blockId: blockId,
      blockTitle: title,
      totalQuestions: daLamMoi,
      wrongQuestions: saiMoi,
    );
  }

  @override
  Future<String?> layNgonNgu() async => _ngonNgu;

  @override
  Future<void> luuNgonNgu(String ma) async => _ngonNgu = ma;
}
