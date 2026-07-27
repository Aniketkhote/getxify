import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/get_rx/get_rx.dart';
import 'package:getxify/getxify.dart';

abstract class PaymentEntity {
  const PaymentEntity(this.id);

  final int id;
}

class PaymentModel extends PaymentEntity {
  const PaymentModel(super.id);
}

void main() {
  test('once', () async {
    final count = 0.obs;
    var result = -1;
    once<int>(count, (int val) {
      result = val;
    });
    count.value++;
    await Future.delayed(Duration.zero);
    expect(1, result);
    count.value++;
    await Future.delayed(Duration.zero);
    expect(1, result);
    count.value++;
    await Future.delayed(Duration.zero);
    expect(1, result);
  });

  test('ever', () async {
    final count = 0.obs;
    var result = -1;
    ever<int>(count, (value) {
      result = value;
    });
    count.value++;
    await Future.delayed(Duration.zero);
    expect(1, result);
    count.value++;
    await Future.delayed(Duration.zero);
    expect(2, result);
    count.value++;
    await Future.delayed(Duration.zero);
    expect(3, result);
  });

  test('debounce', () async {
    final count = 0.obs;
    int? result = -1;
    debounce<int>(count, (int val) {
      result = val;
    }, time: const Duration(milliseconds: 100));

    count.value++;
    count.value++;
    count.value++;
    count.value++;
    await Future.delayed(Duration.zero);
    expect(-1, result);
    await Future.delayed(const Duration(milliseconds: 100));
    expect(4, result);
  });

  test('interval', () async {
    final count = 0.obs;
    int? result = -1;
    interval<int>(count, (v) {
      result = v;
    }, time: const Duration(milliseconds: 100));

    count.value++;
    await Future.delayed(Duration.zero);
    await Future.delayed(const Duration(milliseconds: 100));
    expect(result, 1);
    count.value++;
    count.value++;
    count.value++;
    await Future.delayed(Duration.zero);
    await Future.delayed(const Duration(milliseconds: 100));
    expect(result, 2);
    count.value++;
    await Future.delayed(Duration.zero);
    await Future.delayed(const Duration(milliseconds: 100));
    expect(result, 5);
  });

  test('bindStream test', () async {
    int? count = 0;
    final controller = StreamController<int>();
    final rx = 0.obs;

    rx.listen((value) {
      count = value;
    });
    rx.bindStream(controller.stream);
    expect(count, 0);
    controller.add(555);

    await Future.delayed(Duration.zero);
    expect(count, 555);
    controller.close();
  });

  test('Rx same value will not call the same listener when call', () async {
    var reactiveInteger = RxInt(2);
    var timesCalled = 0;
    reactiveInteger.listen((newInt) {
      timesCalled++;
    });

    // we call 3
    reactiveInteger.call(3);
    // then repeat twice
    reactiveInteger.call(3);
    reactiveInteger.call(3);

    await Future.delayed(const Duration(milliseconds: 100));
    expect(1, timesCalled);
  });

  test('Rx different value will call the listener when trigger', () async {
    var reactiveInteger = RxInt(0);
    var timesCalled = 0;
    reactiveInteger.listen((newInt) {
      timesCalled++;
    });

    // we call 3
    reactiveInteger.trigger(1);
    // then repeat twice
    reactiveInteger.trigger(2);
    reactiveInteger.trigger(3);

    await Future.delayed(const Duration(milliseconds: 100));

    expect(3, timesCalled);
  });

  test('Rx same value will call the listener when trigger', () async {
    var reactiveInteger = RxInt(2);
    var timesCalled = 0;
    reactiveInteger.listen((newInt) {
      timesCalled++;
    });

    // we call 3
    reactiveInteger.trigger(3);
    // then repeat twice
    reactiveInteger.trigger(3);
    reactiveInteger.trigger(3);
    reactiveInteger.trigger(1);

    await Future.delayed(const Duration(milliseconds: 100));
    expect(4, timesCalled);
  });

  test('Rx String with non null values', () async {
    final reactiveString = Rx<String>("abc");
    String? currentString;
    reactiveString.listen((newString) {
      currentString = newString;
    });

    expect(reactiveString.value.endsWith("c"), true);

    // we call 3
    reactiveString("b");

    await Future.delayed(Duration.zero);
    expect(currentString, "b");
  });

  test('Rx String with null values', () async {
    var reactiveString = Rx<String?>(null);
    String? currentString;

    reactiveString.listen((newString) {
      currentString = newString;
    });

    // we call 3
    reactiveString("abc");

    await Future.delayed(Duration.zero);
    expect(reactiveString.value!.endsWith("c"), true);
    expect(currentString, "abc");
  });

  test('Number of times "ever" is called in RxList', () async {
    final list = [1, 2, 3].obs;
    var count = 0;
    ever<List<int>>(list, (value) {
      count++;
    });

    list.add(4);
    await Future.delayed(Duration.zero);
    expect(count, 1);

    count = 0;
    list.addAll([4, 5]);
    await Future.delayed(Duration.zero);
    expect(count, 1);

    count = 0;
    list.remove(2);
    await Future.delayed(Duration.zero);
    expect(count, 1);

    count = 0;
    list.removeWhere((element) => element == 2);
    await Future.delayed(Duration.zero);
    expect(count, 1);

    count = 0;
    list.retainWhere((element) => element == 1);
    await Future.delayed(Duration.zero);
    expect(count, 1);
  });

  group('RxSet assign and assignAll single notification behavior', () {
    // assignAll on an RxSet notified listeners twice: once for the internal
    // clear() (with an empty set) and once for the addAll(). Listeners must
    // receive exactly one event, carrying the final contents.
    test(
      'RxSet.assignAll notifies exactly once with the final contents',
      () async {
        final set = {1, 2, 3}.obs;
        final events = <Set<int>>[];
        set.listen((value) => events.add(Set<int>.of(value)));

        set.assignAll({4, 5});
        await Future.delayed(Duration.zero);

        expect(events.length, 1);
        expect(events.single, {4, 5});
        expect(set, {4, 5});
      },
    );

    test(
      'RxSet.assign notifies exactly once with the final contents',
      () async {
        final set = {1, 2, 3}.obs;
        final events = <Set<int>>[];
        set.listen((value) => events.add(Set<int>.of(value)));

        set.assign(9);
        await Future.delayed(Duration.zero);

        expect(events.length, 1);
        expect(events.single, {9});
        expect(set, {9});
      },
    );

    test('assignAll still replaces contents on a plain (non-reactive) Set', () {
      final set = {1, 2, 3};
      set.assignAll({4, 5});
      expect(set, {4, 5});

      set.assign(9);
      expect(set, {9});
    });
  });

  group('bindStream subscription replacement, cancellation, and lifetime', () {
    // bindStream never cancelled the previous subscription on rebind, and
    // the cancel disposer was silently dropped outside of an observer build,
    // so stale streams kept overwriting the Rx with old data forever.
    test('bindStream with cancelPrevious replaces the previous binding '
        'so the old stream can no longer overwrite the value', () async {
      final oldRoom = StreamController<List<String>>();
      final newRoom = StreamController<List<String>>();
      final messages = RxList<String>();

      messages.bindStream(oldRoom.stream);
      oldRoom.add(['old message']);
      await Future.delayed(Duration.zero);
      expect(messages, ['old message']);

      messages.bindStream(newRoom.stream, cancelPrevious: true);
      newRoom.add(['new message']);
      await Future.delayed(Duration.zero);
      expect(messages, ['new message']);

      oldRoom.add(['stale message']);
      await Future.delayed(Duration.zero);
      expect(messages, ['new message']);

      await oldRoom.close();
      await newRoom.close();
      messages.close();
    });

    test(
      'bindStream with cancelPrevious cancels the old stream subscription',
      () async {
        var oldCancelled = false;
        final oldSource = StreamController<int>(
          onCancel: () {
            oldCancelled = true;
          },
        );
        final newSource = StreamController<int>();
        final rx = 0.obs;

        rx.bindStream(oldSource.stream);
        rx.bindStream(newSource.stream, cancelPrevious: true);
        await Future.delayed(Duration.zero);
        expect(oldCancelled, true);

        await newSource.close();
        rx.close();
        await oldSource.close();
      },
    );

    test('close() cancels subscriptions created by bindStream outside '
        'an observer build', () async {
      var cancelled = false;
      final source = StreamController<int>(
        onCancel: () {
          cancelled = true;
        },
      );
      final rx = 0.obs;

      rx.bindStream(source.stream);
      source.add(1);
      await Future.delayed(Duration.zero);
      expect(rx.value, 1);
      expect(cancelled, false);

      rx.close();
      await Future.delayed(Duration.zero);
      expect(cancelled, true);

      await source.close();
    });

    test(
      'bindStream still supports multiple simultaneous sources by default',
      () async {
        final first = StreamController<int>();
        final second = StreamController<int>();
        final rx = 0.obs;

        rx.bindStream(first.stream);
        rx.bindStream(second.stream);

        first.add(1);
        await Future.delayed(Duration.zero);
        expect(rx.value, 1);

        second.add(2);
        await Future.delayed(Duration.zero);
        expect(rx.value, 2);

        first.add(3);
        await Future.delayed(Duration.zero);
        expect(rx.value, 3);

        await first.close();
        await second.close();
        rx.close();
      },
    );

    test(
      'bindStream returns the subscription so callers can cancel it manually',
      () async {
        final source = StreamController<int>();
        final rx = 0.obs;

        final sub = rx.bindStream(source.stream);
        source.add(10);
        await Future.delayed(Duration.zero);
        expect(rx.value, 10);

        await sub.cancel();
        source.add(20);
        await Future.delayed(Duration.zero);
        expect(rx.value, 10);

        await source.close();
        rx.close();
      },
    );
  });

  group('Rx collections generic subtype element support', () {
    group('issue #3411: default-constructed Rx collections are typed as E', () {
      test('RxList<E>() accepts elements of E and its subtypes', () {
        final RxList<PaymentEntity> payments = RxList<PaymentEntity>();
        expect(() => payments.add(const PaymentModel(1)), returnsNormally);
        payments.add(const PaymentModel(2));
        payments.addAll(const [PaymentModel(3), PaymentModel(4)]);
        expect(payments.length, 4);
        expect(payments.first.id, 1);
      });

      test('RxList created via .obs on empty typed list accepts adds', () {
        final payments = <PaymentEntity>[].obs;
        payments.add(const PaymentModel(1));
        expect(payments.length, 1);
      });

      test('RxSet<E>() accepts elements of E and its subtypes', () {
        final RxSet<PaymentEntity> payments = RxSet<PaymentEntity>();
        expect(() => payments.add(const PaymentModel(1)), returnsNormally);
        payments.add(const PaymentModel(2));
        expect(payments.length, 2);
      });

      test('RxMap<K, V>() accepts entries of K/V and their subtypes', () {
        final RxMap<String, PaymentEntity> payments =
            RxMap<String, PaymentEntity>();
        expect(() => payments['a'] = const PaymentModel(1), returnsNormally);
        payments['b'] = const PaymentModel(2);
        expect(payments.length, 2);
      });

      test('RxList still aliases a caller-supplied backing list', () {
        final backing = <int>[1, 2];
        final rx = RxList<int>(backing);
        rx.add(3);
        expect(backing, [1, 2, 3]);
      });

      test('RxList.unmodifiable remains unmodifiable', () {
        final rx = RxList<int>.unmodifiable([1, 2]);
        expect(() => rx.add(3), throwsUnsupportedError);
      });
    });
  });
}
