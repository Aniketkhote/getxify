import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/get_rx/get_rx.dart';

void main() {
  test('RxnBool stream should emit when value changes', () async {
    final foo = RxnBool(null);
    final emissions = <bool?>[];

    foo.stream.listen((value) {
      emissions.add(value);
    });

    // Change value to true
    foo.value = true;
    await Future.delayed(Duration.zero);
    expect(emissions, [true]);

    // Change value to false
    foo.value = false;
    await Future.delayed(Duration.zero);
    expect(emissions, [true, false]);

    // Change value back to null
    foo.value = null;
    await Future.delayed(Duration.zero);
    expect(emissions, [true, false, null]);
  });

  test('RxnBool stream should emit when using call()', () async {
    final foo = RxnBool(null);
    final emissions = <bool?>[];

    foo.stream.listen((value) {
      emissions.add(value);
    });

    await Future.delayed(Duration.zero);

    foo(true);
    await Future.delayed(Duration.zero);
    expect(emissions, [true]);

    foo(false);
    await Future.delayed(Duration.zero);
    expect(emissions, [true, false]);
  });

  test('RxnBool stream should emit when using toggle()', () async {
    final foo = RxnBool(true);
    final emissions = <bool?>[];

    foo.stream.listen((value) {
      emissions.add(value);
    });

    await Future.delayed(Duration.zero);

    foo.toggle();
    await Future.delayed(Duration.zero);
    expect(emissions, [false]);

    foo.toggle();
    await Future.delayed(Duration.zero);
    expect(emissions, [false, true]);
  });

  test(
    'GetListenable stream should reconnect after listener cancellation',
    () async {
      final count = 0.obs;
      final emissions = <int>[];

      // 1. First subscription that cancels quickly
      final sub1 = count.stream.listen((val) {});
      await Future.delayed(Duration.zero);
      await sub1.cancel(); // Listener count drops to 0

      // 2. Second subscription created later
      final sub2 = count.stream.listen((val) {
        emissions.add(val);
      });

      // 3. Update the value
      count.value = 42;
      await Future.delayed(Duration.zero);

      // Should receive the value even after previous cancellation
      // With onListen fix, the stream reconnects and receives value changes
      expect(emissions, [42]);

      await sub2.cancel();
    },
  );
}
