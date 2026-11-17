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

  test('máº·c Ä‘á»‹nh tiáº¿ng Viá»‡t vÃ  táº£i ngÃ´n ngá»¯ Ä‘Ã£ lÆ°u', () async {
    SharedPreferences.setMockInitialValues({'selected_language': 'en'});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Äá»c provider Ä‘á»ƒ khá»Ÿi Ä‘á»™ng quÃ¡ trÃ¬nh táº£i báº¥t Ä‘á»“ng bá»™.
    container.read(ngonNguProvider);
    await Future<void>.delayed(Duration.zero);

    expect(container.read(ngonNguProvider), NgonNgu.en);
  });

  test('Ä‘á»•i vÃ  lÆ°u ngÃ´n ngá»¯ Viá»‡t/Anh', () async {
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
