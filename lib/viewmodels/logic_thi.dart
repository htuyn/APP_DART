import 'dart:math';

import '../data/models/question_model.dart';

/// CÃ¡c cháº¿ Ä‘á»™ lÃ m bÃ i Ä‘Æ°á»£c ViewModel há»— trá»£.
enum CheDoBaiThi { luyenTap, thiThu, lamLaiCauSai }

/// Cáº¥u hÃ¬nh máº·c Ä‘á»‹nh, giá»¯ tÆ°Æ¡ng á»©ng vá»›i tráº£i nghiá»‡m thi thá»­ Ä‘ang cÃ³.
class CauHinhThi {
  const CauHinhThi._();

  static const int soCauMacDinh = 20;
  static const int thoiGianThiThuGiay = 15 * 60;
}

/// Káº¿t quáº£ cháº¥m má»™t phiÃªn.
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

/// Lá»c theo khá»‘i; null hoáº·c 0 cÃ³ nghÄ©a lÃ  láº¥y táº¥t cáº£.
List<QuestionModel> locTheoKhoi(List<QuestionModel> ds, int? blockId) {
  if (blockId == null || blockId == 0) return List.of(ds);
  return ds.where((question) => question.blockId == blockId).toList();
}

/// Trá»™n danh sÃ¡ch vÃ  láº¥y tá»‘i Ä‘a [soCau] cÃ¢u; khÃ´ng sá»­a danh sÃ¡ch nguá»“n.
List<QuestionModel> tronVaLay(
  List<QuestionModel> ds,
  int soCau, {
  Random? random,
}) {
  if (soCau <= 0 || ds.isEmpty) return const [];
  final ban = List<QuestionModel>.of(ds)..shuffle(random);
  return ban.take(soCau).toList();
}

/// Lá»c cÃ¡c cÃ¢u cÃ³ ID náº±m trong sá»• cÃ¢u sai.
List<QuestionModel> locCauSai(
  List<QuestionModel> ds,
  Set<String> idCauSai,
) =>
    ds.where((question) => idCauSai.contains(question.id)).toList();

/// Cháº¥m toÃ n bá»™ cÃ¢u trong phiÃªn; cÃ¢u bá» trá»‘ng Ä‘Æ°á»£c tÃ­nh chÆ°a lÃ m vÃ  váº«n náº±m
/// trong danh sÃ¡ch cáº§n Ã´n láº¡i, giá»‘ng hÃ nh vi cháº¥m bÃ i hiá»‡n táº¡i.
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
