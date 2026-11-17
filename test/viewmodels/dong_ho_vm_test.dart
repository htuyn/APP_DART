import 'package:fake_async/fake_async.dart';
import 'package:flutter_quiz_bilingual/viewmodels/dong_ho_vm.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Ä‘áº¿m ngÆ°á»£c vá» 0 rá»“i dá»«ng', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final vm = container.read(dongHoProvider.notifier);

      vm.batDau(2);
      expect(container.read(dongHoProvider).conLai, 2);
      expect(container.read(dongHoProvider).dangChay, isTrue);

      async.elapse(const Duration(seconds: 1));
      expect(container.read(dongHoProvider).conLai, 1);

      async.elapse(const Duration(seconds: 1));
      final state = container.read(dongHoProvider);
      expect(state.conLai, 0);
      expect(state.hetGio, isTrue);
      expect(state.dangChay, isFalse);
      expect(state.hienThi, '00:00');
    });
  });

  test('táº¡m dá»«ng giá»¯ thá»i gian, tiáº¿p tá»¥c Ä‘áº¿m vÃ  dá»«ng Ä‘áº·t láº¡i tráº¡ng thÃ¡i', () {
    fakeAsync((async) {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final vm = container.read(dongHoProvider.notifier);

      vm.batDau(5);
      async.elapse(const Duration(seconds: 1));
      vm.tamDung();
      expect(container.read(dongHoProvider).conLai, 4);

      async.elapse(const Duration(seconds: 3));
      expect(container.read(dongHoProvider).conLai, 4);

      vm.tiepTuc();
      async.elapse(const Duration(seconds: 1));
      expect(container.read(dongHoProvider).conLai, 3);

      vm.dung();
      expect(container.read(dongHoProvider).tongGiay, 0);
      expect(container.read(dongHoProvider).dangChay, isFalse);
    });
  });

  test('thá»i lÆ°á»£ng khÃ´ng dÆ°Æ¡ng khÃ´ng khá»Ÿi cháº¡y timer', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(dongHoProvider.notifier).batDau(0);

    expect(container.read(dongHoProvider).tongGiay, 0);
    expect(container.read(dongHoProvider).dangChay, isFalse);
  });
}
