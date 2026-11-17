import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/question_model.dart';
import 'models/quiz_result_model.dart';
import 'models/thong_ke.dart';

/// Giao diá»‡n truy cáº­p dá»¯ liá»‡u cá»§a á»©ng dá»¥ng.
abstract class KhoDuLieu {
  /// Äá»c cÃ¢u há»i tá»« ngÃ¢n hÃ ng dá»¯ liá»‡u.
  Future<List<QuestionModel>> layTatCaCauHoi();

  // ---- Sá»• cÃ¢u sai ----
  Future<Set<String>> layIdCauSai();
  Future<void> luuCauSai(String idCau);
  Future<void> xoaCauSai(String idCau);

  // ---- Káº¿t quáº£ & Ä‘iá»ƒm ----
  /// LÆ°u káº¿t quáº£ má»™t láº§n thi vÃ o lá»‹ch sá»­.
  Future<void> luuKetQua(QuizResultModel ketQua);

  /// Lá»‹ch sá»­ cÃ¡c láº§n thi, má»›i nháº¥t trÆ°á»›c.
  Future<List<QuizResultModel>> layLichSuThi();

  Future<double> layDiemCaoNhat();
  Future<void> luuDiemCaoNhat(double diem);

  // ---- Thá»‘ng kÃª theo khá»‘i ----
  /// Key lÃ  mÃ£ khá»‘i sá»‘ tá»« QuestionModel.blockId.
  Future<Map<int, BlockStat>> layThongKeKhoi();

  /// Cá»™ng dá»“n sá»‘ cÃ¢u Ä‘Ã£ lÃ m vÃ  sá»‘ cÃ¢u Ä‘Ãºng cho khá»‘i.
  Future<void> capNhatThongKeKhoi(
    int blockId, {
    required int daLam,
    required int dung,
  });

  // ---- NgÃ´n ngá»¯ ----
  /// 'vi' | 'en' | null náº¿u chÆ°a tá»«ng lÆ°u.
  Future<String?> layNgonNgu();
  Future<void> luuNgonNgu(String ma);
}

/// Provider cung cáº¥p kho dá»¯ liá»‡u. Cáº§n Ä‘Æ°á»£c override trong ProviderScope.
final khoDuLieuProvider = Provider<KhoDuLieu>((ref) {
  throw UnimplementedError(
    'HÃ£y override khoDuLieuProvider trong ProviderScope báº±ng má»™t '
    'implementation cá»§a KhoDuLieu.',
  );
});
