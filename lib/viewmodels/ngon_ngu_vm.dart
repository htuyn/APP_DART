import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ngon_ngu.dart';

/// LÆ°u vÃ  cung cáº¥p ngÃ´n ngá»¯ dÃ¹ng chung; dÃ¹ng cÃ¹ng khÃ³a vá»›i LanguageProvider cÅ©.
class NgonNguVm extends Notifier<NgonNgu> {
  static const String _khoaNgonNgu = 'selected_language';

  bool _nguoiDungDaDoi = false;
  bool _daHuy = false;

  @override
  NgonNgu build() {
    ref.onDispose(() => _daHuy = true);
    unawaited(_napNgonNguDaLuu());
    return NgonNgu.vi;
  }

  Future<void> _napNgonNguDaLuu() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final ma = preferences.getString(_khoaNgonNgu);
      if (_daHuy || _nguoiDungDaDoi || ma == null) return;
      state = NgonNgu.tuMa(ma);
    } catch (_) {
      // Náº¿u khÃ´ng Ä‘á»c Ä‘Æ°á»£c cÃ i Ä‘áº·t, giá»¯ máº·c Ä‘á»‹nh tiáº¿ng Viá»‡t.
    }
  }

  Future<void> doiNgonNgu(NgonNgu ngonNgu) async {
    _nguoiDungDaDoi = true;
    state = ngonNgu;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_khoaNgonNgu, ngonNgu.ma);
  }

  Future<void> chuyenNgonNgu() => doiNgonNgu(state.nguoc);
}

final ngonNguProvider = NotifierProvider<NgonNguVm, NgonNgu>(
  NgonNguVm.new,
);
