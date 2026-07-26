// Hardening tests for `RxList`'s capability probes — the pair of no-op writes
// that decide which of the three backing shapes it is holding:
//
//   `_canChangeLength`  : `list.length = list.length`
//   `_canWriteElements` : `list[0] = list[0]`, or `setRange(0, 0, const [])`
//                         when the list is empty and there is no element to
//                         overwrite
//
//   canChangeLength | canWriteElements | classification | length-op behaviour
//   ----------------|------------------|----------------|--------------------
//        true       |   (not probed)   | growable       | in place
//        false      |      true        | fixed-length   | HEALS to a copy
//        false      |      false       | unmodifiable   | THROWS
//
// `_canWriteElements` is what makes the second and third rows different, so it
// is load-bearing: collapse it away and either `List.empty().obs.add(x)` starts
// throwing again, or `List.unmodifiable([...]).obs.add(x)` silently succeeds.
// Both are pinned below, on `dart:core` types and on `ListBase` subclasses
// that reject mutation only through the abstract primitives.
//
// Note what is NOT here any more: `RxSet` and `RxMap` do not probe at all.
// `dart:core` has no fixed-length-but-writable Set or Map, so "unmodifiable"
// was their only failure mode; under the narrow contract that is an honoured
// opt-in, there is nothing to heal, and the `remove(_mutationProbe)` sentinel
// they used to need is gone. The tests that covered that sentinel went with
// it; what remains for them is the inverse assertion — they throw.
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

// ---------------------------------------------------------------------------
// Collections that reject mutation by overriding ONLY the abstract primitives
// of SetBase/MapBase/ListBase, inheriting every derived member from the mixin.
// ---------------------------------------------------------------------------

class NaiveUnmodifiableSet<E> extends SetBase<E> {
  NaiveUnmodifiableSet(this._inner);

  final Set<E> _inner;

  @override
  bool add(E value) => throw UnsupportedError('unmodifiable');

  @override
  bool remove(Object? value) => throw UnsupportedError('unmodifiable');

  @override
  bool contains(Object? element) => _inner.contains(element);

  @override
  Iterator<E> get iterator => _inner.iterator;

  @override
  int get length => _inner.length;

  @override
  E? lookup(Object? element) => _inner.lookup(element);

  @override
  Set<E> toSet() => _inner.toSet();
}

class NaiveUnmodifiableMap<K, V> extends MapBase<K, V> {
  NaiveUnmodifiableMap(this._inner);

  final Map<K, V> _inner;

  @override
  V? operator [](Object? key) => _inner[key];

  @override
  void operator []=(K key, V value) => throw UnsupportedError('unmodifiable');

  @override
  void clear() => throw UnsupportedError('unmodifiable');

  @override
  V? remove(Object? key) => throw UnsupportedError('unmodifiable');

  @override
  Iterable<K> get keys => _inner.keys;
}

/// A list that rejects BOTH length changes and element writes: unmodifiable.
class NaiveUnmodifiableList<E> extends ListBase<E> {
  NaiveUnmodifiableList(this._inner);

  final List<E> _inner;

  @override
  int get length => _inner.length;

  @override
  set length(int newLength) => throw UnsupportedError('unmodifiable');

  @override
  E operator [](int index) => _inner[index];

  @override
  void operator []=(int index, E value) =>
      throw UnsupportedError('unmodifiable');
}

/// A list that rejects length changes but accepts element writes: the
/// hand-rolled equivalent of `List.filled` / a `Uint8List`. This is the shape
/// [NaiveUnmodifiableList] has to be told apart from, and `_canWriteElements`
/// is the only thing that can do it.
class NaiveFixedLengthList<E> extends ListBase<E> {
  NaiveFixedLengthList(this._inner);

  final List<E> _inner;

  @override
  int get length => _inner.length;

  @override
  set length(int newLength) => throw UnsupportedError('fixed-length');

  @override
  E operator [](int index) => _inner[index];

  @override
  void operator []=(int index, E value) {
    _inner[index] = value;
  }
}

/// A list whose length setter is simply not implemented — it throws something
/// that is NOT an [UnsupportedError] — but whose `add` works perfectly well.
/// The probe must not turn its own no-op write into the caller's crash.
class UnimplementedLengthList<E> extends ListBase<E> {
  UnimplementedLengthList(this._inner);

  final List<E> _inner;

  @override
  int get length => _inner.length;

  @override
  set length(int newLength) => throw StateError('length setter unsupported');

  @override
  E operator [](int index) => _inner[index];

  @override
  void operator []=(int index, E value) {
    _inner[index] = value;
  }

  @override
  void add(E element) {
    _inner.add(element);
  }
}

/// Fixed-length, and its `[]=` rejects writes with something that is NOT an
/// [UnsupportedError]. The element probe must swallow that rather than let it
/// escape ahead of the real mutation.
class HostileElementWriteList<E> extends ListBase<E> {
  HostileElementWriteList(this._inner);

  final List<E> _inner;

  @override
  int get length => _inner.length;

  @override
  set length(int newLength) => throw UnsupportedError('fixed-length');

  @override
  E operator [](int index) => _inner[index];

  @override
  void operator []=(int index, E value) => throw StateError('no writes here');
}

/// Fixed-length, and its `==` claims equality with any other list. Assigning a
/// growable copy over it must not be mistaken for "nothing changed".
class LyingEqualityList extends ListBase<int> {
  LyingEqualityList(this._inner);

  final List<int> _inner;

  @override
  int get length => _inner.length;

  @override
  set length(int newLength) => throw UnsupportedError('fixed-length');

  @override
  int operator [](int index) => _inner[index];

  @override
  void operator []=(int index, int value) {
    _inner[index] = value;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object other) => other is List<int>;

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => 0;
}

/// A growable list that counts every element write it is asked to perform,
/// so the probes' cost is observable.
class WriteCountingList<E> extends ListBase<E> {
  WriteCountingList(this._inner);

  final List<E> _inner;
  int writes = 0;
  int lengthWrites = 0;

  @override
  int get length => _inner.length;

  @override
  set length(int newLength) {
    lengthWrites++;
    _inner.length = newLength;
  }

  @override
  E operator [](int index) => _inner[index];

  @override
  void operator []=(int index, E value) {
    writes++;
    _inner[index] = value;
  }
}

void main() {
  group('_canWriteElements discriminates fixed-length from unmodifiable', () {
    test('dart:core fixed-length backings heal on a length change', () {
      for (final backing in <List<int>>[
        List<int>.filled(2, 0)..setAll(0, [1, 2]),
        Uint8List.fromList([1, 2]),
      ]) {
        final rx = RxList<int>(backing);

        expect(() => rx.add(3), returnsNormally);
        expect(rx, [1, 2, 3]);
        expect(
          identical(rx.value, backing),
          isFalse,
          reason: 'the heal detaches from the caller\'s buffer',
        );
        expect(backing, [1, 2], reason: 'which is left untouched');
      }
    });

    test('dart:core unmodifiable backings throw on a length change', () {
      for (final backing in <List<int>>[
        List<int>.unmodifiable([1, 2]),
        const <int>[1, 2],
        UnmodifiableListView<int>(<int>[1, 2]),
      ]) {
        final rx = RxList<int>(backing);

        expect(() => rx.add(3), throwsUnsupportedError);
        expect(rx, [1, 2]);
        expect(identical(rx.value, backing), isTrue);
      }
    });

    test('ListBase subclass that only rejects length= heals', () {
      final inner = <int>[1, 2];
      final rx = RxList<int>(NaiveFixedLengthList<int>(inner));

      expect(() => rx.add(3), returnsNormally);
      expect(rx, [1, 2, 3]);
      expect(inner, [1, 2], reason: 'the heal copied instead of mutating');

      // Element writes on such a backing still land in place, before any
      // length change detaches it.
      final other = NaiveFixedLengthList<int>(<int>[3, 1, 2]);
      final rxOther = RxList<int>(other);
      expect(() => rxOther.sort(), returnsNormally);
      expect(identical(rxOther.value, other), isTrue);
      expect(other, [1, 2, 3]);
    });

    test('ListBase subclass that rejects length= AND []= throws', () {
      // The probe has to reach the member that decides mutability: `add` is a
      // *derived* member (`ListBase.add` grows through `length=`), so nothing
      // but a real capability probe can tell this apart from the fixed-length
      // class above.
      final rx = RxList<int>(NaiveUnmodifiableList<int>([1, 2]));

      expect(() => rx.add(3), throwsUnsupportedError);
      expect(rx, [1, 2]);

      final other = RxList<int>(NaiveUnmodifiableList<int>([3, 1, 2]));
      expect(() => other.sort(), throwsUnsupportedError);
      expect(other, [3, 1, 2]);
    });

    test('the empty-list branch decides List.empty().obs', () {
      // With no element to overwrite, `_canWriteElements` probes
      // `setRange(0, 0, const [])` instead. Falling back to the *length* probe
      // here would answer `false` for a fixed-length list too, and
      // `List.empty().obs.add(x)` — the reported crash — would still throw.
      final healed = List<int>.empty().obs;
      expect(() => healed.add(1), returnsNormally);
      expect(healed, [1]);

      final emptyUint8 = RxList<int>(Uint8List(0));
      expect(() => emptyUint8.add(1), returnsNormally);
      expect(emptyUint8, [1]);

      // And it must not answer `true` for an empty *unmodifiable* list: every
      // dart:core unmodifiable list rejects even a vacuous setRange.
      for (final backing in <List<int>>[
        const <int>[],
        List<int>.unmodifiable(const <int>[]),
        UnmodifiableListView<int>(<int>[]),
      ]) {
        final frozen = RxList<int>(backing);
        expect(() => frozen.add(1), throwsUnsupportedError);
        expect(frozen, isEmpty);
        expect(identical(frozen.value, backing), isTrue);
      }
    });

    test('an empty unmodifiable typed-data view is not healed', () {
      // `setRange` alone cannot see this one: an unmodifiable typed-data view
      // only rejects writes that actually touch an element, so it accepts a
      // vacuous range just like a plain fixed-length list does. The probe
      // therefore looks at the underlying buffer instead — which is where the
      // immutability actually lives — whenever there is a byte in it to probe.
      final source = Uint8List.fromList(<int>[1, 2, 3, 4]);
      for (final backing in <List<int>>[
        Uint8List.sublistView(source, 2, 2).asUnmodifiableView(),
        Int32List.sublistView(Int32List(4), 2, 2).asUnmodifiableView(),
      ]) {
        expect(backing, isEmpty, reason: 'the empty branch is what is probed');
        final frozen = RxList<int>(backing);
        expect(() => frozen.add(1), throwsUnsupportedError);
        expect(frozen, isEmpty);
        expect(identical(frozen.value, backing), isTrue);
      }
      expect(source, [1, 2, 3, 4], reason: 'the probe writes nothing');

      // The mutable controls over the very same shape still heal.
      for (final backing in <List<int>>[
        Uint8List.sublistView(Uint8List(4), 2, 2),
        Int32List.sublistView(Int32List(4), 2, 2),
      ]) {
        final healed = RxList<int>(backing);
        expect(() => healed.add(1), returnsNormally);
        expect(healed, [1]);
      }
    });

    test('an unmodifiable typed-data view over a ZERO-length buffer heals', () {
      // Documented limit. `Uint8List(0)` owns a zero-byte buffer, so there
      // is no byte anywhere — in the list or behind it — to attempt a write
      // against, and the view is indistinguishable from the plain
      // `Uint8List(0)` pinned above, which must heal. Nothing can be stored
      // in either, so nothing is at risk of being overwritten; the answer is
      // the same on the VM and on the web, which the `setRange` probe alone
      // could not manage.
      final rx = RxList<int>(Uint8List(0).asUnmodifiableView());

      expect(() => rx.add(7), returnsNormally);
      expect(rx, [7]);
    });

    test(
      'an EMPTY naive unmodifiable list is indistinguishable, and heals',
      () {
        // Documented limit of probing rather than type-checking.
        // `ListMixin.setRange` returns early when the range is empty, without
        // ever touching `[]=`, so a `ListBase` subclass that rejects mutation
        // *only* through `length=`/`[]=` looks exactly like an empty
        // fixed-length list — there is no observable difference to probe for.
        // It heals.
        //
        // Scope of the limitation, precisely: every `dart:core` unmodifiable
        // list (`List.unmodifiable`, `const []`, `UnmodifiableListView`)
        // overrides `setRange` to throw unconditionally and so is classified
        // correctly even when empty, as the test above pins. Unmodifiable
        // *typed-data* views do NOT — they accept a vacuous range — which is
        // why the probe falls back to their underlying buffer; only a
        // zero-length buffer is beyond it. This branch is the residue: a
        // hand-rolled `ListBase` that is empty and inherits `setRange`.
        final rx = RxList<int>(NaiveUnmodifiableList<int>(<int>[]));

        expect(() => rx.add(1), returnsNormally);
        expect(rx, [1]);
      },
    );

    test('a growable backing costs exactly one extra length write', () {
      // `_canChangeLength` answers first and short-circuits, so the second
      // probe's no-op `[]=` never happens on the common path. Calibrated
      // against the same mutation performed without an RxList in the picture,
      // because `ListBase.add` does its own `length=` and `[]=`.
      // The element type is nullable because `ListBase.add` grows through
      // `length = length + 1`, which pads with nulls before writing.
      final baseline = WriteCountingList<int?>(<int?>[1, 2])..add(3);

      final counting = WriteCountingList<int?>(<int?>[1, 2]);
      RxList<int?>(counting).add(3);

      expect(counting, [1, 2, 3]);
      expect(
        counting.writes,
        baseline.writes,
        reason: 'no element probe on a growable list',
      );
      expect(
        counting.lengthWrites,
        baseline.lengthWrites + 1,
        reason: 'the single `length = length` probe, and nothing else',
      );
    });

    test('element operations do not probe at all', () {
      // Under the narrow contract element writes are plain in-place
      // mutations, so a write-observing backing sees exactly the writes the
      // caller asked for.
      final counting = WriteCountingList<int>(<int>[1, 2, 3]);
      final rx = RxList<int>(counting);

      rx[0] = 9;

      expect(counting.writes, 1);
      expect(counting.lengthWrites, 0);
      expect(rx, [9, 2, 3]);
    });

    test('probing leaves the backing\'s contents untouched', () {
      final backing = List<int>.filled(3, 0)..setAll(0, [1, 2, 3]);
      final rx = RxList<int>(backing);

      // Probes, then heals. Neither probe may perturb the values.
      rx.add(4);

      expect(backing, [1, 2, 3]);
      expect(rx, [1, 2, 3, 4]);
    });
  });

  group('the probes are total: they never become the caller\'s error', () {
    test('a length setter that throws a StateError still routes in place', () {
      // The probe asks a question the caller never asked; if the backing
      // answers with something other than UnsupportedError the probe cannot
      // classify it, and the only safe answer is "behave as if there were no
      // probe at all" — i.e. run the mutation straight against the backing.
      // Here `add` is implemented and works, so it must keep working.
      final rx = RxList<int>(UnimplementedLengthList<int>(<int>[1, 2]));

      expect(() => rx.add(9), returnsNormally);
      expect(rx, [1, 2, 9]);
    });

    test('an element setter that throws a StateError still routes in '
        'place', () {
      // Same rule on the second probe, except that "no probe at all" means
      // the *unmodifiable* branch: the action runs against the backing and
      // whatever the backing throws is what the caller sees. `ListBase.add`
      // grows through `length=`, so that is UnsupportedError here — exactly
      // what this call did before healing existed.
      final rx = RxList<int>(HostileElementWriteList<int>(<int>[1, 2]));

      expect(() => rx.add(9), throwsUnsupportedError);
      expect(rx, [1, 2]);
    });
  });

  group('the heal path is a backing swap, not a value change', () {
    test('a backing whose == lies cannot silently swallow the heal', () async {
      // `value = copy` short-circuits when the old value reports itself `==`
      // to the new one. That is right for a value change and catastrophic for
      // a backing swap: the mutation already applied to the copy would be
      // discarded while a notification still claimed something happened.
      final backing = LyingEqualityList(<int>[1, 2]);
      expect(backing == <int>[9, 9, 9], isTrue, reason: 'the premise');

      final rx = RxList<int>(backing);
      var notifications = 0;
      rx.listen((_) => notifications++);

      rx.add(9);
      await Future.delayed(Duration.zero);

      expect(rx.toList(), [1, 2, 9], reason: 'the mutation must not be lost');
      expect(rx.length, 3);
      expect(identical(rx.value, backing), isFalse);
      expect(backing, [1, 2], reason: 'the caller\'s list is left alone');
      expect(notifications, 1);
    });
  });

  group('RxSet/RxMap no longer probe, and no longer heal', () {
    test('SetBase subclass that only overrides add/remove throws', () {
      final rx = RxSet<int>(NaiveUnmodifiableSet<int>({1, 2}));

      expect(() => rx.add(3), throwsUnsupportedError);
      expect(rx, unorderedEquals(<int>[1, 2]));

      expect(
        () => RxSet<int>(NaiveUnmodifiableSet<int>({1, 2})).clear(),
        throwsUnsupportedError,
      );
      expect(
        () => RxSet<int>(NaiveUnmodifiableSet<int>({1, 2})).remove(1),
        throwsUnsupportedError,
      );
      expect(
        () => RxSet<int>(NaiveUnmodifiableSet<int>({1, 2})).addAll({3, 4}),
        throwsUnsupportedError,
      );
    });

    test('MapBase subclass that only overrides []=/remove/clear throws', () {
      final rx = RxMap<String, int>(
        NaiveUnmodifiableMap<String, int>({'a': 1}),
      );

      expect(() => rx['b'] = 2, throwsUnsupportedError);
      expect(rx, {'a': 1});

      expect(
        () => RxMap<String, int>(
          NaiveUnmodifiableMap<String, int>({'a': 1}),
        ).clear(),
        throwsUnsupportedError,
      );
      expect(
        () => RxMap<String, int>(
          NaiveUnmodifiableMap<String, int>({'a': 1}),
        ).remove('a'),
        throwsUnsupportedError,
      );
    });

    test('a mutable set/map with custom equals and hashCode still works', () {
      // Nothing hands these callbacks a foreign sentinel value any more, so
      // they only ever see the caller's own elements.
      final set = LinkedHashSet<Object>(
        equals: (a, b) => (a as String) == (b as String),
        hashCode: (a) => (a as String).length,
      )..add('ab');
      final rxSet = RxSet<Object>(set);
      expect(() => rxSet.add('cd'), returnsNormally);
      expect(rxSet.length, 2);

      final map = LinkedHashMap<Object, int>(
        equals: (a, b) => (a as String) == (b as String),
        hashCode: (a) => (a as String).length,
      )..['ab'] = 1;
      final rxMap = RxMap<Object, int>(map);
      expect(() => rxMap['cde'] = 2, returnsNormally);
      expect(rxMap.length, 2);

      final sorted = SplayTreeSet<Object>(
        (a, b) => (a as String).compareTo(b as String),
      )..add('ab');
      final rxSorted = RxSet<Object>(sorted);
      expect(() => rxSorted.add('cd'), returnsNormally);
      expect(rxSorted, ['ab', 'cd']);
    });
  });

  group('exactly one notification even with a re-entrant listener', () {
    /// Mutates [rx] with a listener attached that reassigns `value` the first
    /// time it runs, and reports how many notifications the mutation produced.
    int notificationsFor(
      dynamic rx,
      void Function() mutate,
      void Function() reassign,
    ) {
      var count = 0;
      var reassigned = false;
      rx.addListener(() {
        count++;
        if (!reassigned) {
          reassigned = true;
          reassign();
        }
      });
      mutate();
      return count;
    }

    test('RxList heal path matches the in-place path', () {
      final growable = RxList<int>(<int>[]);
      final inPlace = notificationsFor(
        growable,
        () => growable.add(1),
        () => growable.value = <int>[99],
      );

      final fixed = RxList<int>(List<int>.empty());
      final healPath = notificationsFor(
        fixed,
        () => fixed.add(1),
        () => fixed.value = <int>[99],
      );

      expect(healPath, inPlace);
    });

    test('RxList: an unmodifiable backing notifies zero times', () {
      final frozen = RxList<int>(List<int>.unmodifiable(<int>[]));
      var count = 0;
      frozen.addListener(() => count++);

      expect(() => frozen.add(1), throwsUnsupportedError);
      expect(count, 0);
      expect(frozen, isEmpty);
    });

    test('RxSet: an unmodifiable backing notifies zero times', () {
      final frozen = RxSet<int>(Set<int>.unmodifiable(<int>{}));
      var count = 0;
      frozen.addListener(() => count++);

      expect(() => frozen.add(1), throwsUnsupportedError);
      expect(count, 0);
      expect(frozen, isEmpty);
    });

    test('RxMap: an unmodifiable backing notifies zero times', () {
      final frozen = RxMap<String, int>(
        Map<String, int>.unmodifiable(<String, int>{}),
      );
      var count = 0;
      frozen.addListener(() => count++);

      expect(() => frozen['a'] = 1, throwsUnsupportedError);
      expect(count, 0);
      expect(frozen, isEmpty);
    });
  });

  group('element writes on an EMPTY backing follow the aliasing contract', () {
    test('an empty fixed-length backing is kept, exactly as a seeded one', () {
      final list = RxList<int>(List<int>.empty());
      final backing = list.value;

      list.sort();
      list.shuffle();
      list.fillRange(0, 0, 0);
      list.setAll(0, const <int>[]);
      list.setRange(0, 0, const <int>[]);

      expect(
        identical(list.value, backing),
        isTrue,
        reason:
            'dart:core performs all of these in place on List.empty(), so '
            'they must not detach the backing any more than sort() does on a '
            'non-empty fixed-length list',
      );
    });

    test('an empty unmodifiable backing throws instead of being replaced', () {
      for (final backing in <List<int>>[
        const <int>[],
        List<int>.unmodifiable(const <int>[]),
        UnmodifiableListView<int>(<int>[]),
      ]) {
        final list = RxList<int>(backing);
        var notifications = 0;
        list.addListener(() => notifications++);

        expect(() => list.sort(), throwsUnsupportedError);
        expect(
          () => list.setRange(0, 0, const <int>[]),
          throwsUnsupportedError,
        );
        expect(identical(list.value, backing), isTrue);
        expect(notifications, 0);

        // `shuffle` is the exception, and deliberately so: with fewer than
        // two elements it has nothing to swap, so it returns without asking
        // the backing to write — which is what the inherited
        // `ListMixin.shuffle` did before RxList overrode it. It still emits
        // this override's single notification.
        expect(() => list.shuffle(), returnsNormally);
        expect(identical(list.value, backing), isTrue);
        expect(notifications, 1);
      }
    });

    test('a length change on an empty fixed-length backing still detaches', () {
      final list = RxList<int>(List<int>.empty());
      final backing = list.value;

      list.add(1);

      expect(identical(list.value, backing), isFalse);
      expect(list, [1]);
    });
  });

  group('the aliasing contract is path dependent, and documented as such', () {
    test('element writes reach a fixed-length backing until it detaches', () {
      final backing = List<int>.filled(4, 0)..setAll(0, [3, 1, 2, 0]);
      final list = RxList<int>(backing);

      list[0] = 9;
      expect(backing, [9, 1, 2, 0], reason: 'element writes go through');

      list.sort();
      expect(backing, [0, 1, 2, 9], reason: 'so does sort');

      // The documented cliff edge: a length change cannot be done in place, so
      // from here on the RxList owns a growable copy.
      list.add(7);
      expect(identical(list.value, backing), isFalse);
      expect(backing, [0, 1, 2, 9], reason: 'the caller keeps its buffer');
      expect(list, [0, 1, 2, 9, 7]);

      list[0] = 42;
      expect(backing, [0, 1, 2, 9], reason: 'later writes no longer land');
      expect(list, [42, 1, 2, 9, 7]);
    });

    test('an unmodifiable backing never detaches, because nothing heals', () {
      final backing = List<int>.unmodifiable([3, 1, 2]);
      final list = RxList<int>(backing);

      expect(() => list[0] = 9, throwsUnsupportedError);
      expect(() => list.sort(), throwsUnsupportedError);
      expect(() => list.add(7), throwsUnsupportedError);

      expect(identical(list.value, backing), isTrue);
      expect(list, [3, 1, 2]);
    });
  });
}
