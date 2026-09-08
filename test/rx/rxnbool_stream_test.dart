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
}
