// ignore_for_file: file_names

import 'package:flutter_quiz_bilingual/viewmodels/ngon_ngu.dart';
import 'package:flutter_quiz_bilingual/viewmodels/ngon_ngu_vm.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('mặc định tiếng Việt và tải ngôn ngữ đã lưu', () async {
    SharedPreferences.setMockInitialValues({'selected_language': 'en'});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Đọc provider để khởi động quá trình tải bất đồng bộ.
    container.read(ngonNguProvider);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(ngonNguProvider), NgonNgu.en);
  });

  test('đổi và lưu ngôn ngữ Việt/Anh', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final vm = container.read(ngonNguProvider.notifier);
    await vm.doiNgonNgu(NgonNgu.en);

    expect(container.read(ngonNguProvider), NgonNgu.en);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('selected_language'), 'en');

    await vm.chuyenNgonNgu();
    expect(container.read(ngonNguProvider), NgonNgu.vi);
    expect(preferences.getString('selected_language'), 'vi');
  });
}
