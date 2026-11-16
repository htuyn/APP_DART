import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Trạng thái đồng hồ đếm ngược cho bài thi thử.
class DongHoState {
  const DongHoState({
    this.tongGiay = 0,
    this.conLai = 0,
    this.dangChay = false,
  });

  final int tongGiay;
  final int conLai;
  final bool dangChay;

  bool get hetGio => tongGiay > 0 && conLai <= 0;
  int get daQua => tongGiay == 0 ? 0 : tongGiay - conLai;

  String get hienThi {
    final giay = conLai < 0 ? 0 : conLai;
    final phutText = (giay ~/ 60).toString().padLeft(2, '0');
    final giayText = (giay % 60).toString().padLeft(2, '0');
    return '$phutText:$giayText';
  }
}

class DongHoVm extends Notifier<DongHoState> {
  Timer? _timer;

  @override
  DongHoState build() {
    ref.onDispose(_huyTimer);
    return const DongHoState();
  }

  void batDau(int tongGiay) {
    _huyTimer();
    if (tongGiay <= 0) {
      state = const DongHoState();
      return;
    }
    state = DongHoState(
      tongGiay: tongGiay,
      conLai: tongGiay,
      dangChay: true,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final conLai = state.conLai - 1;
      if (conLai <= 0) {
        _huyTimer();
        state = DongHoState(
          tongGiay: state.tongGiay,
          conLai: 0,
          dangChay: false,
        );
      } else {
        state = DongHoState(
          tongGiay: state.tongGiay,
          conLai: conLai,
          dangChay: true,
        );
      }
    });
  }

  void tamDung() {
    if (!state.dangChay) return;
    _huyTimer();
    state = DongHoState(
      tongGiay: state.tongGiay,
      conLai: state.conLai,
      dangChay: false,
    );
  }

  void tiepTuc() {
    if (state.dangChay || state.tongGiay <= 0 || state.conLai <= 0) return;
    state = DongHoState(
      tongGiay: state.tongGiay,
      conLai: state.conLai,
      dangChay: true,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final conLai = state.conLai - 1;
      if (conLai <= 0) {
        _huyTimer();
        state = DongHoState(
          tongGiay: state.tongGiay,
          conLai: 0,
          dangChay: false,
        );
      } else {
        state = DongHoState(
          tongGiay: state.tongGiay,
          conLai: conLai,
          dangChay: true,
        );
      }
    });
  }

  void dung() {
    _huyTimer();
    state = const DongHoState();
  }

  void _huyTimer() {
    _timer?.cancel();
    _timer = null;
  }
}

final dongHoProvider = NotifierProvider<DongHoVm, DongHoState>(
  DongHoVm.new,
);
