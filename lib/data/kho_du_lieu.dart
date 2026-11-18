import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/question_model.dart';
import 'models/quiz_result_model.dart';
import 'models/thong_ke.dart';

/// Giao diện truy cập dữ liệu của ứng dụng.
abstract class KhoDuLieu {
  /// Đọc câu hỏi từ ngân hàng dữ liệu.
  Future<List<QuestionModel>> layTatCaCauHoi();

  // ---- Sổ câu sai ----
  Future<Set<String>> layIdCauSai();
  Future<void> luuCauSai(String idCau);
  Future<void> xoaCauSai(String idCau);

  // ---- Kết quả & điểm ----
  /// Lưu kết quả một lần thi vào lịch sử.
  Future<void> luuKetQua(QuizResultModel ketQua);

  /// Lịch sử các lần thi, mới nhất trước.
  Future<List<QuizResultModel>> layLichSuThi();

  Future<double> layDiemCaoNhat();
  Future<void> luuDiemCaoNhat(double diem);

  // ---- Thống kê theo khối ----
  /// Key là mã khối số từ QuestionModel.blockId.
  Future<Map<int, BlockStat>> layThongKeKhoi();

  /// Cộng dồn số câu đã làm và số câu đúng cho khối.
  Future<void> capNhatThongKeKhoi(
    int blockId, {
    required int daLam,
    required int dung,
  });

  // ---- Ngôn ngữ ----
  /// 'vi' | 'en' | null nếu chưa từng lưu.
  Future<String?> layNgonNgu();
  Future<void> luuNgonNgu(String ma);
}

/// Provider cung cấp kho dữ liệu. Cần được override trong ProviderScope.
final khoDuLieuProvider = Provider<KhoDuLieu>((ref) {
  throw UnimplementedError(
    'Hãy override khoDuLieuProvider trong ProviderScope bằng một '
    'implementation của KhoDuLieu.',
  );
});
