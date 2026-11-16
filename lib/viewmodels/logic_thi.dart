import 'dart:math';

import '../data/models/question_model.dart';

/// Các chế độ làm bài được ViewModel hỗ trợ.
enum CheDoBaiThi { luyenTap, thiThu, lamLaiCauSai }

/// Cấu hình mặc định, giữ tương ứng với trải nghiệm thi thử đang có.
class CauHinhThi {
  const CauHinhThi._();

  static const int soCauMacDinh = 20;
  static const int thoiGianThiThuGiay = 15 * 60;
}

/// Kết quả chấm một phiên.
class KetQuaCham {
  const KetQuaCham({
    required this.soDung,
    required this.idCauSai,
    required this.soChuaLam,
  });

  final int soDung;
  final List<String> idCauSai;
  final int soChuaLam;
}

/// Lọc theo khối; null hoặc 0 có nghĩa là lấy tất cả.
List<QuestionModel> locTheoKhoi(List<QuestionModel> ds, int? blockId) {
  if (blockId == null || blockId == 0) return List.of(ds);
  return ds.where((question) => question.blockId == blockId).toList();
}

/// Trộn danh sách và lấy tối đa [soCau] câu; không sửa danh sách nguồn.
List<QuestionModel> tronVaLay(
  List<QuestionModel> ds,
  int soCau, {
  Random? random,
}) {
  if (soCau <= 0 || ds.isEmpty) return const [];
  final ban = List<QuestionModel>.of(ds)..shuffle(random);
  return ban.take(soCau).toList();
}

/// Lọc các câu có ID nằm trong sổ câu sai.
List<QuestionModel> locCauSai(
  List<QuestionModel> ds,
  Set<String> idCauSai,
) =>
    ds.where((question) => idCauSai.contains(question.id)).toList();

/// Chấm toàn bộ câu trong phiên; câu bỏ trống được tính chưa làm và vẫn nằm
/// trong danh sách cần ôn lại, giống hành vi chấm bài hiện tại.
KetQuaCham chamDiem(
  List<QuestionModel> ds,
  Map<String, int> dapAnDaChon,
) {
  var dung = 0;
  var chuaLam = 0;
  final idSai = <String>[];

  for (final question in ds) {
    final selected = dapAnDaChon[question.id];
    if (selected == null) {
      chuaLam++;
      idSai.add(question.id);
    } else if (selected == question.correctIndex) {
      dung++;
    } else {
      idSai.add(question.id);
    }
  }

  return KetQuaCham(
    soDung: dung,
    idCauSai: idSai,
    soChuaLam: chuaLam,
  );
}
