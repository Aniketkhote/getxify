// Regression tests for the NARROW self-healing contract on RxList/RxSet/RxMap.
//
// Real-world trigger (production app, reported crash):
//
//     RxList<SaleRecDetail> mycartList = List<SaleRecDetail>.empty().obs;
//     // ... on a button tap:
//     mycartList.insert(0, newItem);
//     // Unsupported operation: Cannot add to a fixed-length list
//     //   #0 FixedLengthListMixin.insert (dart:_internal/list.dart:25:5)
//     //   #1 RxList.insert (package:getxify/.../rx_iterables/rx_list.dart)
//
// `List.empty()` defaults to `growable: false`, so the RxList aliased a
// fixed-length backing. The same app called `mycartList.clear()` elsewhere —
// a second latent crash of the same family.
//
// The fix heals ONLY backings that carry no immutability intent:
//
//   * FIXED-LENGTH (`List.empty()`, `List.filled()`, a `Uint8List`, ...) — the
//     length is fixed by accident of the `dart:core` API, not by a decision
//     the caller made. A length-changing mutator transparently swaps in a
//     growable copy, applies the mutation there and notifies EXACTLY ONCE.
//     Element writes (`[]=`, `sort`, `setAll`, ...) need no help at all: a
//     fixed-length list already accepts them in place, so the backing stays
//     aliased.
//
//   * UNMODIFIABLE (`List.unmodifiable`, `const []`, `UnmodifiableListView`,
//     `Set.unmodifiable`, `Map.unmodifiable`, `const {}`) — an EXPLICIT opt-in
//     to immutability. Never healed. Every mutator still throws the backing's
//     own `UnsupportedError`, the collection keeps its previous contents and
//     no listener is notified. Silently swallowing that opt-in would delete a
//     guard the caller deliberately put in place, with no compile error.
//
// RxSet and RxMap therefore have no healing whatsoever: `dart:core` has no
// fixed-length-but-writable Set or Map, so "unmodifiable" was their only
// failure mode and it is now an honoured opt-in again.
//
// The ONE documented exception is `assign`/`assignAll` (pinned by
// fixed_length_backing_assign_test.dart, and by the "intended seam" group at
// the bottom of this file): they replace the contents wholesale by publishing
// a fresh mutable collection, so they work over any backing.
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

/// Stand-in for the model class from the crash report.
class SaleRecDetail {
  const SaleRecDetail(this.id);
  final int id;
}

// ---------------------------------------------------------------------------
// Backing shapes
// ---------------------------------------------------------------------------

/// Builds a backing collection holding exactly `seed`, or returns `null` when
/// that shape cannot hold that seed (`List.empty()` is always empty, and a
/// const literal cannot be built from a runtime value).
typedef _ListBacking = List<int>? Function(List<int> seed);
typedef _SetBacking = Set<int>? Function(Set<int> seed);
typedef _MapBacking = Map<String, int>? Function(Map<String, int> seed);

/// Const collections have to be written out, so they are looked up by seed.
/// Every seed used in the matrices below has an entry here.
const _constLists = <String, List<int>>{
  '': <int>[],
  '1,2,3': <int>[1, 2, 3],
  '3,1,2': <int>[3, 1, 2],
};
const _constSets = <String, Set<int>>{
  '': <int>{},
  '1,2,3': <int>{1, 2, 3},
};
const _constMaps = <String, Map<String, int>>{
  '': <String, int>{},
  'a:1,b:2': <String, int>{'a': 1, 'b': 2},
};

String _key(Iterable<int> seed) => seed.join(',');
String _mapKey(Map<String, int> seed) =>
    seed.entries.map((e) => '${e.key}:${e.value}').join(',');

/// Backings with no immutability intent. Length changes heal, element writes
/// land in place.
final Map<String, _ListBacking> _healingListBackings = <String, _ListBacking>{
  // Control: the ordinary case, which must keep behaving exactly as before.
  'a growable <int>[]': (seed) => <int>[...seed],
  // The backing from the crash report.
  'List.empty() (fixed-length)': (seed) =>
      seed.isEmpty ? List<int>.empty() : null,
  'List.filled (fixed-length)': (seed) =>
      List<int>.filled(seed.length, 0)..setAll(0, seed),
  // A fixed-length list that is not a `dart:core` growable list in disguise.
  'a Uint8List (fixed-length)': (seed) => Uint8List.fromList(seed),
};

/// Backings that are an explicit opt-in to immutability. Nothing heals them.
final Map<String, _ListBacking> _frozenListBackings = <String, _ListBacking>{
  'List.unmodifiable': (seed) => List<int>.unmodifiable(seed),
  'a const list literal': (seed) => _constLists[_key(seed)],
  'UnmodifiableListView': (seed) => UnmodifiableListView<int>(<int>[...seed]),
};

final Map<String, _SetBacking> _mutableSetBackings = <String, _SetBacking>{
  'a mutable <int>{}': (seed) => <int>{...seed},
};

final Map<String, _SetBacking> _frozenSetBackings = <String, _SetBacking>{
  'Set.unmodifiable': (seed) => Set<int>.unmodifiable(seed),
  'a const set literal': (seed) => _constSets[_key(seed)],
  'UnmodifiableSetView': (seed) => UnmodifiableSetView<int>(<int>{...seed}),
};

final Map<String, _MapBacking> _mutableMapBackings = <String, _MapBacking>{
  'a mutable <String, int>{}': (seed) => <String, int>{...seed},
};

final Map<String, _MapBacking> _frozenMapBackings = <String, _MapBacking>{
  'Map.unmodifiable': (seed) => Map<String, int>.unmodifiable(seed),
  'a const map literal': (seed) => _constMaps[_mapKey(seed)],
  'UnmodifiableMapView': (seed) =>
      UnmodifiableMapView<String, int>(<String, int>{...seed}),
};

// ---------------------------------------------------------------------------
// Mutator cases
// ---------------------------------------------------------------------------

class _ListCase {
  const _ListCase(
    this.name,
    this.seed,
    this.apply,
    this.expected, {
    this.throwsOnFrozen = true,
  });
  final String name;
  final List<int> seed;
  final void Function(RxList<int> list) apply;
  final Matcher expected;

  /// Whether this mutator throws when the backing is unmodifiable.
  ///
  /// True for every mutator but one: `shuffle` on a list of fewer than two
  /// elements has nothing to swap, so it returns without ever asking the
  /// backing to write anything — exactly as the inherited `ListMixin.shuffle`
  /// did before `RxList` overrode it to collapse the notifications. Making it
  /// throw would be a regression against an unmodifiable backing, which the
  /// narrow contract promises to leave behaving as it always has.
  final bool throwsOnFrozen;
}

class _SetCase {
  const _SetCase(
    this.name,
    this.seed,
    this.apply,
    this.expected, [
    this.notifications = 1,
  ]);
  final String name;
  final Set<int> seed;
  final void Function(RxSet<int> set) apply;
  final Matcher expected;
  final int notifications;
}

class _MapCase {
  const _MapCase(
    this.name,
    this.seed,
    this.apply,
    this.expected, [
    this.notifications = 1,
  ]);
  final String name;
  final Map<String, int> seed;
  final void Function(RxMap<String, int> map) apply;
  final Matcher expected;
  final int notifications;
}

const _seed = <int>[1, 2, 3];
const _sortSeed = <int>[3, 1, 2];
const _noSeed = <int>[];

/// Every `RxList` mutator, over a non-empty backing.
final List<_ListCase> _seededListCases = <_ListCase>[
  _ListCase('add', _seed, (l) => l.add(4), equals([1, 2, 3, 4])),
  _ListCase('addAll', _seed, (l) => l.addAll([4, 5]), equals([1, 2, 3, 4, 5])),
  _ListCase('insert', _seed, (l) => l.insert(0, 0), equals([0, 1, 2, 3])),
  _ListCase(
    'insertAll',
    _seed,
    (l) => l.insertAll(1, [8, 9]),
    equals([1, 8, 9, 2, 3]),
  ),
  _ListCase('remove', _seed, (l) {
    expect(l.remove(2), isTrue);
  }, equals([1, 3])),
  _ListCase('removeAt', _seed, (l) {
    expect(l.removeAt(0), 1);
  }, equals([2, 3])),
  _ListCase('removeLast', _seed, (l) {
    expect(l.removeLast(), 3);
  }, equals([1, 2])),
  _ListCase('removeRange', _seed, (l) => l.removeRange(0, 2), equals([3])),
  _ListCase(
    'removeWhere',
    _seed,
    (l) => l.removeWhere((e) => e.isEven),
    equals([1, 3]),
  ),
  _ListCase(
    'retainWhere',
    _seed,
    (l) => l.retainWhere((e) => e.isOdd),
    equals([1, 3]),
  ),
  _ListCase('clear', _seed, (l) => l.clear(), isEmpty),
  _ListCase('length= (shrink)', _seed, (l) => l.length = 1, equals([1])),
  _ListCase('operator []=', _seed, (l) => l[1] = 9, equals([1, 9, 3])),
  _ListCase('operator +', _seed, (l) {
    // Unlike List.+, RxList.+ mutates in place and returns itself.
    expect(identical(l + <int>[4], l), isTrue);
  }, equals([1, 2, 3, 4])),
  _ListCase('setAll', _seed, (l) => l.setAll(1, [8, 9]), equals([1, 8, 9])),
  _ListCase(
    'setRange',
    _seed,
    (l) => l.setRange(0, 2, [7, 8]),
    equals([7, 8, 3]),
  ),
  _ListCase('fillRange', _seed, (l) => l.fillRange(0, 2, 0), equals([0, 0, 3])),
  _ListCase(
    'replaceRange',
    _seed,
    (l) => l.replaceRange(1, 3, [9]),
    equals([1, 9]),
  ),
  _ListCase('sort', _sortSeed, (l) => l.sort(), equals([1, 2, 3])),
  _ListCase(
    'sort (custom comparator)',
    _sortSeed,
    (l) => l.sort((a, b) => b.compareTo(a)),
    equals([3, 2, 1]),
  ),
  _ListCase(
    'shuffle',
    _seed,
    (l) => l.shuffle(),
    unorderedEquals(<int>[1, 2, 3]),
  ),
  _ListCase('first=', _seed, (l) => l.first = 9, equals([9, 2, 3])),
  _ListCase('last=', _seed, (l) => l.last = 9, equals([1, 2, 9])),
  _ListCase('addIf', _seed, (l) => l.addIf(true, 4), equals([1, 2, 3, 4])),
  _ListCase(
    'addAllIf',
    _seed,
    (l) => l.addAllIf(true, [4, 5]),
    equals([1, 2, 3, 4, 5]),
  ),
  _ListCase('addNonNull', _seed, (l) => l.addNonNull(4), equals([1, 2, 3, 4])),
];

/// The same surface over an EMPTY backing — the only way `List.empty()`, the
/// backing from the crash report, can be exercised. Mutators that need an
/// existing element (`removeAt`, `removeLast`, `[]=`, `first=`, `last=`) are
/// covered by [_seededListCases] instead.
final List<_ListCase> _emptyListCases = <_ListCase>[
  _ListCase('add', _noSeed, (l) => l.add(1), equals([1])),
  _ListCase('addAll', _noSeed, (l) => l.addAll([1, 2]), equals([1, 2])),
  _ListCase('insert', _noSeed, (l) => l.insert(0, 1), equals([1])),
  _ListCase(
    'insertAll',
    _noSeed,
    (l) => l.insertAll(0, [1, 2]),
    equals([1, 2]),
  ),
  _ListCase('remove (absent)', _noSeed, (l) {
    expect(l.remove(9), isFalse);
  }, isEmpty),
  _ListCase('removeWhere', _noSeed, (l) => l.removeWhere((e) => true), isEmpty),
  _ListCase('retainWhere', _noSeed, (l) => l.retainWhere((e) => true), isEmpty),
  _ListCase('clear', _noSeed, (l) => l.clear(), isEmpty),
  _ListCase('length= (0)', _noSeed, (l) => l.length = 0, isEmpty),
  _ListCase('operator +', _noSeed, (l) {
    expect(identical(l + <int>[1], l), isTrue);
  }, equals([1])),
  _ListCase(
    'setAll (vacuous)',
    _noSeed,
    (l) => l.setAll(0, const <int>[]),
    isEmpty,
  ),
  _ListCase(
    'setRange (vacuous)',
    _noSeed,
    (l) => l.setRange(0, 0, const <int>[]),
    isEmpty,
  ),
  // A fill value is required even for an empty range: dart:core casts it to E
  // before looking at the range, so `fillRange(0, 0)` on a List<int> is a
  // TypeError with or without an RxList in the picture.
  _ListCase(
    'fillRange (vacuous)',
    _noSeed,
    (l) => l.fillRange(0, 0, 0),
    isEmpty,
  ),
  _ListCase(
    'removeRange (vacuous)',
    _noSeed,
    (l) => l.removeRange(0, 0),
    isEmpty,
  ),
  _ListCase(
    'replaceRange',
    _noSeed,
    (l) => l.replaceRange(0, 0, [9]),
    equals([9]),
  ),
  _ListCase('sort', _noSeed, (l) => l.sort(), isEmpty),
  // Nothing to swap, so it never reaches the backing — see [throwsOnFrozen].
  _ListCase(
    'shuffle',
    _noSeed,
    (l) => l.shuffle(),
    isEmpty,
    throwsOnFrozen: false,
  ),
  _ListCase('addIf', _noSeed, (l) => l.addIf(true, 1), equals([1])),
  _ListCase(
    'addAllIf',
    _noSeed,
    (l) => l.addAllIf(true, [1, 2]),
    equals([1, 2]),
  ),
  _ListCase('addNonNull', _noSeed, (l) => l.addNonNull(1), equals([1])),
];

const _setSeed = <int>{1, 2, 3};
const _noSetSeed = <int>{};

final List<_SetCase> _setCases = <_SetCase>[
  _SetCase('add', _setSeed, (s) {
    expect(s.add(4), isTrue);
  }, unorderedEquals(<int>[1, 2, 3, 4])),
  // add/remove only notify when the set really changed.
  _SetCase(
    'add (already present)',
    _setSeed,
    (s) {
      expect(s.add(2), isFalse);
    },
    unorderedEquals(<int>[1, 2, 3]),
    0,
  ),
  _SetCase(
    'addAll',
    _setSeed,
    (s) => s.addAll({4, 5}),
    unorderedEquals(<int>[1, 2, 3, 4, 5]),
  ),
  _SetCase(
    'addAll (vacuous)',
    _setSeed,
    (s) => s.addAll(const <int>[]),
    unorderedEquals(<int>[1, 2, 3]),
  ),
  _SetCase('remove', _setSeed, (s) {
    expect(s.remove(2), isTrue);
  }, unorderedEquals(<int>[1, 3])),
  _SetCase(
    'remove (absent)',
    _setSeed,
    (s) {
      expect(s.remove(9), isFalse);
    },
    unorderedEquals(<int>[1, 2, 3]),
    0,
  ),
  _SetCase(
    'removeAll',
    _setSeed,
    (s) => s.removeAll([1, 2]),
    unorderedEquals(<int>[3]),
  ),
  _SetCase(
    'retainAll',
    _setSeed,
    (s) => s.retainAll([2]),
    unorderedEquals(<int>[2]),
  ),
  _SetCase(
    'removeWhere',
    _setSeed,
    (s) => s.removeWhere((e) => e.isEven),
    unorderedEquals(<int>[1, 3]),
  ),
  _SetCase(
    'retainWhere',
    _setSeed,
    (s) => s.retainWhere((e) => e.isOdd),
    unorderedEquals(<int>[1, 3]),
  ),
  _SetCase('clear', _setSeed, (s) => s.clear(), isEmpty),
  // `update` hands `fn` the REAL backing set, so an unmodifiable backing
  // throws from inside the callback (see the frozen matrix below).
  _SetCase(
    'update',
    _setSeed,
    (s) => s.update((v) => (v! as Set<int>).add(4)),
    unorderedEquals(<int>[1, 2, 3, 4]),
  ),
  _SetCase('operator +', _setSeed, (s) {
    expect(identical(s + {4}, s), isTrue);
  }, unorderedEquals(<int>[1, 2, 3, 4])),
  _SetCase(
    'addIf',
    _setSeed,
    (s) => s.addIf(true, 4),
    unorderedEquals(<int>[1, 2, 3, 4]),
  ),
  _SetCase(
    'addAllIf',
    _setSeed,
    (s) => s.addAllIf(true, {4, 5}),
    unorderedEquals(<int>[1, 2, 3, 4, 5]),
  ),
  _SetCase('add (empty backing)', _noSetSeed, (s) {
    expect(s.add(1), isTrue);
  }, unorderedEquals(<int>[1])),
  _SetCase(
    'addAll (empty backing)',
    _noSetSeed,
    (s) => s.addAll({1, 2}),
    unorderedEquals(<int>[1, 2]),
  ),
  _SetCase('clear (empty backing)', _noSetSeed, (s) => s.clear(), isEmpty),
];

const _mapSeed = <String, int>{'a': 1, 'b': 2};
const _noMapSeed = <String, int>{};

final List<_MapCase> _mapCases = <_MapCase>[
  _MapCase(
    'operator []= (new key)',
    _mapSeed,
    (m) => m['c'] = 3,
    equals({'a': 1, 'b': 2, 'c': 3}),
  ),
  _MapCase(
    'operator []= (existing key)',
    _mapSeed,
    (m) => m['a'] = 9,
    equals({'a': 9, 'b': 2}),
  ),
  _MapCase(
    'addAll',
    _mapSeed,
    (m) => m.addAll({'c': 3}),
    equals({'a': 1, 'b': 2, 'c': 3}),
  ),
  _MapCase(
    'addAll (vacuous)',
    _mapSeed,
    (m) => m.addAll(const <String, int>{}),
    equals({'a': 1, 'b': 2}),
  ),
  _MapCase(
    'addEntries',
    _mapSeed,
    (m) => m.addEntries([const MapEntry('c', 3)]),
    equals({'a': 1, 'b': 2, 'c': 3}),
  ),
  _MapCase('putIfAbsent (absent)', _mapSeed, (m) {
    expect(m.putIfAbsent('c', () => 3), 3);
  }, equals({'a': 1, 'b': 2, 'c': 3})),
  // The only Map mutator that can leave the map untouched, so the only one
  // that must skip the notification.
  _MapCase(
    'putIfAbsent (present)',
    _mapSeed,
    (m) {
      expect(m.putIfAbsent('a', () => 99), 1);
    },
    equals({'a': 1, 'b': 2}),
    0,
  ),
  _MapCase('update', _mapSeed, (m) {
    expect(m.update('a', (v) => v + 10), 11);
  }, equals({'a': 11, 'b': 2})),
  _MapCase('update (ifAbsent)', _mapSeed, (m) {
    expect(m.update('z', (v) => v, ifAbsent: () => 7), 7);
  }, equals({'a': 1, 'b': 2, 'z': 7})),
  _MapCase(
    'updateAll',
    _mapSeed,
    (m) => m.updateAll((k, v) => v * 10),
    equals({'a': 10, 'b': 20}),
  ),
  _MapCase('remove', _mapSeed, (m) {
    expect(m.remove('a'), 1);
  }, equals({'b': 2})),
  // Unlike Set.remove, Map.remove notifies even when nothing was removed —
  // long-standing behaviour that none of this work changes.
  _MapCase('remove (absent)', _mapSeed, (m) {
    expect(m.remove('z'), isNull);
  }, equals({'a': 1, 'b': 2})),
  _MapCase(
    'removeWhere',
    _mapSeed,
    (m) => m.removeWhere((k, v) => v.isEven),
    equals({'a': 1}),
  ),
  _MapCase('clear', _mapSeed, (m) => m.clear(), isEmpty),
  _MapCase(
    'addIf',
    _mapSeed,
    (m) => m.addIf(true, 'c', 3),
    equals({'a': 1, 'b': 2, 'c': 3}),
  ),
  _MapCase(
    'addAllIf',
    _mapSeed,
    (m) => m.addAllIf(true, {'c': 3}),
    equals({'a': 1, 'b': 2, 'c': 3}),
  ),
  _MapCase(
    'operator []= (empty backing)',
    _noMapSeed,
    (m) => m['a'] = 1,
    equals({'a': 1}),
  ),
  _MapCase(
    'addAll (empty backing)',
    _noMapSeed,
    (m) => m.addAll({'a': 1}),
    equals({'a': 1}),
  ),
  _MapCase('clear (empty backing)', _noMapSeed, (m) => m.clear(), isEmpty),
];

void main() {
  // -------------------------------------------------------------------------
  group('the reported crash', () {
    test('insert into List.empty().obs, then clear, then add again', () async {
      // Verbatim shape of the production code that crashed.
      final RxList<SaleRecDetail> mycartList = List<SaleRecDetail>.empty().obs;
      var notifications = 0;
      mycartList.listen((_) => notifications++);

      // Used to throw: Unsupported operation: Cannot add to a fixed-length
      // list.
      mycartList.insert(0, const SaleRecDetail(1));
      mycartList.insert(0, const SaleRecDetail(2));
      expect(mycartList.map((e) => e.id), [2, 1]);

      // The second latent crash in the same app.
      mycartList.clear();
      expect(mycartList, isEmpty);

      mycartList.add(const SaleRecDetail(3));
      expect(mycartList.map((e) => e.id), [3]);

      await Future.delayed(Duration.zero);
      expect(notifications, 4);
    });

    test('a const list literal .obs is NOT healed', () {
      // ListExtension.obs adopts the receiver, so this really does wrap a
      // const (unmodifiable) list. Unlike `List.empty()`, a const literal is
      // an explicit statement that the contents must not change, so it keeps
      // throwing instead of quietly detaching.
      final RxList<int> list = const <int>[1].obs;

      expect(() => list.add(2), throwsUnsupportedError);
      expect(list, [1]);
    });

    test('a const map literal .obs is NOT healed', () {
      // MapExtension.obs adopts the receiver too, so this wraps a const
      // (unmodifiable) map. Same reasoning as above.
      final RxMap<String, int> map = const <String, int>{'a': 1}.obs;

      expect(() => map['b'] = 2, throwsUnsupportedError);
      expect(map, {'a': 1});
    });
  });

  // -------------------------------------------------------------------------
  // RxList over a backing with NO immutability intent: every mutator works,
  // notifying exactly once.
  // -------------------------------------------------------------------------
  for (final backing in _healingListBackings.entries) {
    for (final cases in <List<_ListCase>>[_seededListCases, _emptyListCases]) {
      final label = identical(cases, _emptyListCases) ? ', empty' : '';
      group('RxList over ${backing.key}$label', () {
        for (final c in cases) {
          if (backing.value(c.seed) == null) continue;
          test('${c.name} works and notifies exactly once', () async {
            final list = RxList<int>(backing.value(c.seed)!);
            var notifications = 0;
            list.listen((_) => notifications++);

            c.apply(list);
            await Future.delayed(Duration.zero);

            expect(list, c.expected);
            expect(notifications, 1);
          });
        }
      });
    }
  }

  // -------------------------------------------------------------------------
  // RxList over an UNMODIFIABLE backing: every mutator throws, nothing is
  // healed, no listener is notified. This is the inverse of the matrix above
  // and is the whole point of the narrow contract.
  // -------------------------------------------------------------------------
  for (final backing in _frozenListBackings.entries) {
    for (final cases in <List<_ListCase>>[_seededListCases, _emptyListCases]) {
      final label = identical(cases, _emptyListCases) ? ', empty' : '';
      group('RxList over ${backing.key}$label', () {
        for (final c in cases) {
          if (backing.value(c.seed) == null) continue;
          if (!c.throwsOnFrozen) {
            test('${c.name} is a no-op, exactly as it always was', () async {
              final source = backing.value(c.seed)!;
              final list = RxList<int>(source);
              var notifications = 0;
              list.listen((_) => notifications++);

              // It never asks the backing to write, so there is nothing for
              // the backing to refuse — and it must not start refusing now.
              expect(() => c.apply(list), returnsNormally);
              await Future.delayed(Duration.zero);

              expect(list, equals(c.seed));
              expect(
                identical(list.value, source),
                isTrue,
                reason: 'an unmodifiable backing is never swapped out',
              );
              expect(
                notifications,
                1,
                reason: 'every mutator call notifies exactly once',
              );
            });
            continue;
          }
          test(
            '${c.name} throws UnsupportedError and changes nothing',
            () async {
              final source = backing.value(c.seed)!;
              final list = RxList<int>(source);
              var notifications = 0;
              list.listen((_) => notifications++);

              expect(() => c.apply(list), throwsUnsupportedError);
              await Future.delayed(Duration.zero);

              expect(list, equals(c.seed));
              expect(
                identical(list.value, source),
                isTrue,
                reason: 'an unmodifiable backing is never swapped out',
              );
              expect(notifications, 0);
            },
          );
        }
      });
    }
  }

  // -------------------------------------------------------------------------
  group('RxList backing-swap behaviour', () {
    test('a rejected mutation replaces the backing exactly once', () {
      final list = RxList<int>(List<int>.empty());

      list.add(1);
      final healed = list.value;
      expect(healed, isNot(isEmpty));

      // Every later mutation must reuse the growable copy, not build another.
      list.add(2);
      list.insert(0, 0);
      list.removeAt(1);

      expect(identical(list.value, healed), isTrue);
      expect(list, [0, 2]);
    });

    test('the heal path never mutates the original fixed-length buffer', () {
      final backing = List<int>.filled(3, 0)..setAll(0, [1, 2, 3]);
      final list = RxList<int>(backing);

      list.add(4);

      expect(backing, [1, 2, 3]);
      expect(list, [1, 2, 3, 4]);
      expect(identical(list.value, backing), isFalse);
    });

    test('a growable backing is still mutated in place (aliasing kept)', () {
      final backing = <int>[1, 2];
      final list = RxList<int>(backing);

      list.add(3);
      list.insert(0, 0);

      expect(backing, [0, 1, 2, 3]);
      expect(identical(list.value, backing), isTrue);
    });

    test('element writes go straight through a fixed-length backing', () {
      final backing = List<int>.filled(3, 0)..setAll(0, [1, 2, 3]);
      final list = RxList<int>(backing);

      list[1] = 9;
      list.first = 8;
      list.last = 7;
      list.fillRange(1, 2, 5);
      list.setAll(0, [4]);
      list.setRange(1, 3, [5, 6]);

      expect(identical(list.value, backing), isTrue);
      expect(backing, [4, 5, 6]);
    });

    test('element writes reach a Uint8List backing in place', () {
      // The case the aliasing contract exists for: a typed buffer the caller
      // still holds a reference to.
      final backing = Uint8List.fromList([1, 2, 3]);
      final list = RxList<int>(backing);

      list[0] = 9;
      list.sort();
      list.setRange(0, 2, [4, 5]);

      expect(identical(list.value, backing), isTrue);
      expect(backing, [4, 5, 9]);
    });

    test('sort mutates a fixed-length backing in place (no copy path)', () {
      final backing = List<int>.filled(3, 0)..setAll(0, [3, 1, 2]);
      final list = RxList<int>(backing);

      list.sort();

      expect(
        identical(list.value, backing),
        isTrue,
        reason:
            'a fixed-length list accepts element writes, so sorting it '
            'must not detach the backing',
      );
      expect(backing, [1, 2, 3]);
    });

    test('sort on an unmodifiable backing throws and changes nothing', () {
      final backing = List<int>.unmodifiable([3, 1, 2]);
      final list = RxList<int>(backing);

      expect(() => list.sort(), throwsUnsupportedError);

      expect(identical(list.value, backing), isTrue);
      expect(backing, [3, 1, 2], reason: 'the original is left alone');
      expect(list, [3, 1, 2]);
    });

    test('shuffle on a fixed-length backing shuffles it in place', () {
      final backing = List<int>.filled(5, 0)..setAll(0, [1, 2, 3, 4, 5]);
      final list = RxList<int>(backing);

      list.shuffle();

      expect(identical(list.value, backing), isTrue);
      expect(list, unorderedEquals(<int>[1, 2, 3, 4, 5]));
    });

    test('the growable copy keeps the runtime element type of the backing', () {
      final RxList<num> list = RxList<num>(
        List<int>.filled(2, 0)..setAll(0, [1, 2]),
      );

      // The copy is built with toList(), so it is still a List<int> and keeps
      // rejecting incompatible elements — same contract as assignAll.
      list.add(3);
      expect(list, [1, 2, 3]);
      expect(() => list.add(0.5), throwsA(isA<TypeError>()));
    });

    test('RxList.filled/empty with growable: false are healed on add', () {
      final filled = RxList<int>.filled(2, 7);
      final empty = RxList<int>.empty();

      filled.add(8);
      empty.add(1);

      expect(filled, [7, 7, 8]);
      expect(empty, [1]);
    });

    test('length= can grow a fixed-length backing of a nullable type', () {
      final list = RxList<int?>(List<int?>.filled(2, 0));

      list.length = 4;

      expect(list, [0, 0, null, null]);
    });

    test('growing a non-nullable list still throws, on every backing', () {
      // Unchanged pre-existing behaviour: filling with nulls is a type error,
      // which is orthogonal to whether the backing accepts length changes.
      expect(() => RxList<int>(<int>[1]).length = 3, throwsA(isA<TypeError>()));
      expect(
        () => RxList<int>(List<int>.filled(1, 0)).length = 3,
        throwsA(isA<TypeError>()),
      );
    });

    test('probing does not notify a nested RxList backing', () async {
      final inner = RxList<int>(<int>[1, 2]);
      final outer = RxList<int>(inner);
      var innerNotifications = 0;
      var outerNotifications = 0;
      inner.listen((_) => innerNotifications++);
      outer.listen((_) => outerNotifications++);

      outer.add(3);
      await Future.delayed(Duration.zero);

      expect(outer, [1, 2, 3]);
      expect(outerNotifications, 1);
      expect(
        innerNotifications,
        1,
        reason: 'only the real mutation, never the capability probe',
      );
    });

    test('a nested RxList backing applies its OWN policy', () {
      // The outer list short-circuits the probes and runs the action against
      // the inner RxList, which then heals or throws exactly as it would
      // standalone.
      final healing = RxList<int>(RxList<int>(List<int>.empty()));
      healing.add(1);
      expect(healing, [1]);

      final frozen = RxList<int>(RxList<int>(List<int>.unmodifiable([1, 2])));
      expect(() => frozen.add(3), throwsUnsupportedError);
      expect(frozen, [1, 2]);
    });
  });

  // -------------------------------------------------------------------------
  group('RxList.unmodifiable is genuinely unmodifiable', () {
    test('every length-changing mutator throws', () {
      for (final mutate in <void Function(RxList<int>)>[
        (l) => l.add(3),
        (l) => l.addAll([3]),
        (l) => l.insert(0, 3),
        (l) => l.insertAll(0, [3]),
        (l) => l.remove(1),
        (l) => l.removeAt(0),
        (l) => l.removeLast(),
        (l) => l.removeRange(0, 1),
        (l) => l.removeWhere((e) => true),
        (l) => l.retainWhere((e) => false),
        (l) => l.replaceRange(0, 1, [9]),
        (l) => l.clear(),
        (l) => l.length = 0,
        (l) => l + <int>[3],
      ]) {
        final list = RxList<int>.unmodifiable([1, 2]);
        expect(() => mutate(list), throwsUnsupportedError);
        expect(list, [1, 2]);
      }
    });

    test('every element-writing mutator throws', () {
      for (final mutate in <void Function(RxList<int>)>[
        (l) => l[0] = 9,
        (l) => l.first = 9,
        (l) => l.last = 9,
        (l) => l.setAll(0, [9]),
        (l) => l.setRange(0, 1, [9]),
        (l) => l.fillRange(0, 1, 9),
        (l) => l.sort(),
        (l) => l.shuffle(),
      ]) {
        final list = RxList<int>.unmodifiable([1, 2]);
        expect(() => mutate(list), throwsUnsupportedError);
        expect(list, [1, 2]);
      }
    });
  });

  // -------------------------------------------------------------------------
  group('RxList errors still propagate', () {
    test('insert past the end throws RangeError and changes nothing', () async {
      final backing = List<int>.filled(3, 0)..setAll(0, [1, 2, 3]);
      final list = RxList<int>(backing);
      var notifications = 0;
      list.listen((_) => notifications++);

      expect(() => list.insert(999, 4), throwsRangeError);
      await Future.delayed(Duration.zero);

      expect(list, [1, 2, 3]);
      expect(identical(list.value, backing), isTrue);
      expect(notifications, 0);
    });

    test('removeAt past the end throws RangeError on the heal path', () async {
      final backing = List<int>.filled(3, 0)..setAll(0, [1, 2, 3]);
      final list = RxList<int>(backing);
      var notifications = 0;
      list.listen((_) => notifications++);

      expect(() => list.removeAt(99), throwsRangeError);
      await Future.delayed(Duration.zero);

      expect(list, [1, 2, 3]);
      expect(
        identical(list.value, backing),
        isTrue,
        reason: 'a copy that failed mid-flight is never published',
      );
      expect(notifications, 0);
    });

    test('removeAt past the end on an unmodifiable backing throws '
        'UnsupportedError, not RangeError', () async {
      // The backing rejects the whole operation before it ever gets as far
      // as validating the index, and that error is passed through untouched.
      final list = RxList<int>(List<int>.unmodifiable([1, 2, 3]));
      var notifications = 0;
      list.listen((_) => notifications++);

      expect(() => list.removeAt(99), throwsUnsupportedError);
      await Future.delayed(Duration.zero);

      expect(list, [1, 2, 3]);
      expect(notifications, 0);
    });

    test('an exception from a sort comparator propagates', () {
      final backing = List<int>.filled(3, 0)..setAll(0, [3, 1, 2]);
      final list = RxList<int>(backing);

      expect(
        () => list.sort((a, b) => throw StateError('boom')),
        throwsStateError,
      );
      expect(list, [3, 1, 2]);
    });

    test(
      'an UnsupportedError from user code is NOT swallowed by the probes',
      () {
        // Only the capability probes may catch UnsupportedError; the real
        // mutation must never be wrapped in a catch. Both paths are checked:
        // `sort` runs in place, `removeWhere` runs through the heal path,
        // which is where the probes actually fire.
        final inPlace = RxList<int>(
          List<int>.filled(3, 0)..setAll(0, [3, 1, 2]),
        );
        expect(
          () => inPlace.sort((a, b) => throw UnsupportedError('from user')),
          throwsUnsupportedError,
        );
        expect(inPlace, [3, 1, 2]);

        final backing = List<int>.filled(3, 0)..setAll(0, [3, 1, 2]);
        final healPath = RxList<int>(backing);
        expect(
          () =>
              healPath.removeWhere((e) => throw UnsupportedError('from user')),
          throwsUnsupportedError,
        );
        expect(healPath, [3, 1, 2]);
        expect(identical(healPath.value, backing), isTrue);
      },
    );

    test('a throwing predicate leaves the backing untouched', () {
      final backing = List<int>.filled(3, 0)..setAll(0, [1, 2, 3]);
      final list = RxList<int>(backing);

      expect(
        () => list.removeWhere((e) => throw StateError('boom')),
        throwsStateError,
      );
      expect(list, [1, 2, 3]);
      expect(
        identical(list.value, backing),
        isTrue,
        reason: 'a failed copy must not be published',
      );
    });
  });

  // -------------------------------------------------------------------------
  // RxSet — mutable backings behave as always; unmodifiable ones throw. There
  // is no fixed-length-but-writable Set in dart:core, so RxSet has no heal
  // path at all.
  // -------------------------------------------------------------------------
  for (final backing in _mutableSetBackings.entries) {
    group('RxSet over ${backing.key}', () {
      for (final c in _setCases) {
        if (backing.value(c.seed) == null) continue;
        test(
          '${c.name} works and notifies ${c.notifications} time(s)',
          () async {
            final set = RxSet<int>(backing.value(c.seed)!);
            var notifications = 0;
            set.listen((_) => notifications++);

            c.apply(set);
            await Future.delayed(Duration.zero);

            expect(set, c.expected);
            expect(notifications, c.notifications);
          },
        );
      }
    });
  }

  for (final backing in _frozenSetBackings.entries) {
    group('RxSet over ${backing.key}', () {
      for (final c in _setCases) {
        if (backing.value(c.seed) == null) continue;
        test('${c.name} throws UnsupportedError and changes nothing', () async {
          final source = backing.value(c.seed)!;
          final set = RxSet<int>(source);
          var notifications = 0;
          set.listen((_) => notifications++);

          expect(() => c.apply(set), throwsUnsupportedError);
          await Future.delayed(Duration.zero);

          expect(set, unorderedEquals(c.seed));
          expect(identical(set.value, source), isTrue);
          expect(notifications, 0);
        });
      }
    });
  }

  group('RxSet backing behaviour', () {
    test('an unmodifiable backing is never swapped out', () {
      final backing = Set<int>.unmodifiable({1, 2});
      final set = RxSet<int>(backing);

      expect(() => set.add(3), throwsUnsupportedError);

      expect(backing, {1, 2});
      expect(set, unorderedEquals(<int>[1, 2]));
      expect(identical(set.value, backing), isTrue);
    });

    test('a mutable backing is still mutated in place (aliasing kept)', () {
      final backing = <int>{1};
      final set = RxSet<int>(backing);

      set.add(2);

      expect(backing, {1, 2});
      expect(identical(set.value, backing), isTrue);
    });

    test('RxSet.unmodifiable is genuinely unmodifiable', () {
      for (final mutate in <void Function(RxSet<int>)>[
        (s) => s.add(3),
        (s) => s.addAll({3}),
        (s) => s.remove(1),
        (s) => s.removeAll([1]),
        (s) => s.retainAll([1]),
        (s) => s.removeWhere((e) => true),
        (s) => s.retainWhere((e) => false),
        (s) => s.clear(),
        (s) => s.update((v) => (v! as Set<int>).add(3)),
        (s) => s + <int>{3},
      ]) {
        final set = RxSet<int>.unmodifiable([1, 2]);
        expect(() => mutate(set), throwsUnsupportedError);
        expect(set, unorderedEquals(<int>[1, 2]));
      }
    });

    test('update hands the callback the real backing set', () {
      // Not a defensive copy: if the caller declared the set unmodifiable, a
      // mutation inside the callback must be rejected like any other.
      final set = RxSet<int>(Set<int>.unmodifiable({1}));

      expect(
        () => set.update((v) => (v! as Set<int>).add(2)),
        throwsUnsupportedError,
      );
      expect(set, unorderedEquals(<int>[1]));
    });

    test('a throwing callback leaves a mutable backing untouched', () {
      final backing = <int>{1, 2};
      final set = RxSet<int>(backing);

      expect(
        () => set.removeWhere((e) => throw StateError('boom')),
        throwsStateError,
      );
      expect(set, unorderedEquals(<int>[1, 2]));
      expect(identical(set.value, backing), isTrue);
    });

    test(
      'a nested RxSet backing is notified once, by the real mutation',
      () async {
        final inner = RxSet<int>(<int>{1});
        final outer = RxSet<int>(inner);
        var innerNotifications = 0;
        var outerNotifications = 0;
        inner.listen((_) => innerNotifications++);
        outer.listen((_) => outerNotifications++);

        outer.add(2);
        await Future.delayed(Duration.zero);

        expect(outer, unorderedEquals(<int>[1, 2]));
        expect(outerNotifications, 1);
        expect(innerNotifications, 1);
      },
    );
  });

  // -------------------------------------------------------------------------
  // RxMap
  // -------------------------------------------------------------------------
  for (final backing in _mutableMapBackings.entries) {
    group('RxMap over ${backing.key}', () {
      for (final c in _mapCases) {
        if (backing.value(c.seed) == null) continue;
        test(
          '${c.name} works and notifies ${c.notifications} time(s)',
          () async {
            final map = RxMap<String, int>(backing.value(c.seed)!);
            var notifications = 0;
            map.listen((_) => notifications++);

            c.apply(map);
            await Future.delayed(Duration.zero);

            expect(map, c.expected);
            expect(notifications, c.notifications);
          },
        );
      }
    });
  }

  for (final backing in _frozenMapBackings.entries) {
    group('RxMap over ${backing.key}', () {
      for (final c in _mapCases) {
        if (backing.value(c.seed) == null) continue;
        test('${c.name} throws UnsupportedError and changes nothing', () async {
          final source = backing.value(c.seed)!;
          final map = RxMap<String, int>(source);
          var notifications = 0;
          map.listen((_) => notifications++);

          expect(() => c.apply(map), throwsUnsupportedError);
          await Future.delayed(Duration.zero);

          expect(map, equals(c.seed));
          expect(identical(map.value, source), isTrue);
          expect(notifications, 0);
        });
      }
    });
  }

  group('RxMap backing behaviour', () {
    test('an unmodifiable backing is never swapped out', () {
      final backing = Map<String, int>.unmodifiable({'a': 1});
      final map = RxMap<String, int>(backing);

      expect(() => map['b'] = 2, throwsUnsupportedError);

      expect(backing, {'a': 1});
      expect(map, {'a': 1});
      expect(identical(map.value, backing), isTrue);
    });

    test('a mutable backing is still mutated in place (aliasing kept)', () {
      final backing = <String, int>{'a': 1};
      final map = RxMap<String, int>(backing);

      map['b'] = 2;

      expect(backing, {'a': 1, 'b': 2});
      expect(identical(map.value, backing), isTrue);
    });

    test('RxMap.unmodifiable is genuinely unmodifiable', () {
      for (final mutate in <void Function(RxMap<String, int>)>[
        (m) => m['b'] = 2,
        (m) => m.addAll({'b': 2}),
        (m) => m.addEntries([const MapEntry('b', 2)]),
        (m) => m.putIfAbsent('b', () => 2),
        (m) => m.update('a', (v) => v + 1),
        (m) => m.updateAll((k, v) => v),
        (m) => m.remove('a'),
        (m) => m.removeWhere((k, v) => true),
        (m) => m.clear(),
      ]) {
        final map = RxMap<String, int>.unmodifiable({'a': 1});
        expect(() => mutate(map), throwsUnsupportedError);
        expect(map, {'a': 1});
      }
    });

    test('update on a missing key of an unmodifiable backing throws '
        'UnsupportedError, not ArgumentError', () async {
      // The backing rejects the write before `Map.update` gets far enough to
      // complain about the missing key.
      final backing = Map<String, int>.unmodifiable({'a': 1});
      final map = RxMap<String, int>(backing);
      var notifications = 0;
      map.listen((_) => notifications++);

      expect(() => map.update('z', (v) => v), throwsUnsupportedError);
      await Future.delayed(Duration.zero);

      expect(map, {'a': 1});
      expect(identical(map.value, backing), isTrue);
      expect(notifications, 0);
    });

    test('update on a missing key of a mutable backing still throws', () async {
      final backing = <String, int>{'a': 1};
      final map = RxMap<String, int>(backing);
      var notifications = 0;
      map.listen((_) => notifications++);

      expect(() => map.update('z', (v) => v), throwsArgumentError);
      await Future.delayed(Duration.zero);

      expect(map, {'a': 1});
      expect(identical(map.value, backing), isTrue);
      expect(notifications, 0);
    });

    test('a throwing callback leaves a mutable backing untouched', () {
      final backing = <String, int>{'a': 1};
      final map = RxMap<String, int>(backing);

      expect(
        () => map.removeWhere((k, v) => throw StateError('boom')),
        throwsStateError,
      );
      expect(map, {'a': 1});
      expect(identical(map.value, backing), isTrue);
    });

    test(
      'a nested RxMap backing is notified once, by the real mutation',
      () async {
        final inner = RxMap<String, int>(<String, int>{'a': 1});
        final outer = RxMap<String, int>(inner);
        var innerNotifications = 0;
        var outerNotifications = 0;
        inner.listen((_) => innerNotifications++);
        outer.listen((_) => outerNotifications++);

        outer['b'] = 2;
        await Future.delayed(Duration.zero);

        expect(outer, {'a': 1, 'b': 2});
        expect(outerNotifications, 1);
        expect(innerNotifications, 1);
      },
    );
  });

  // -------------------------------------------------------------------------
  // The intended seam.
  // -------------------------------------------------------------------------
  group('the intended seam: assign/assignAll heal, add/insert throw', () {
    // This asymmetry is a DECISION, not an oversight, and must not be
    // "fixed" in either direction:
    //
    //   * `assignAll` REPLACES the contents wholesale. Nothing of the old
    //     collection survives, so which object happened to be holding those
    //     contents is an implementation detail with nothing left to protect —
    //     it publishes a fresh mutable collection and succeeds.
    //   * `add`/`insert`/`[]=` MUTATE a collection the caller explicitly
    //     declared unmodifiable. Letting them through would silently delete a
    //     guard, with no compile error to warn anyone.
    //
    // fixed_length_backing_assign_test.dart pins the assign/assignAll half in
    // detail; these tests pin the two halves side by side so the seam itself
    // is visible.

    test('RxList: assignAll succeeds where add throws', () async {
      final list = RxList<int>(List<int>.unmodifiable([1, 2]));
      var notifications = 0;
      list.listen((_) => notifications++);

      expect(() => list.add(3), throwsUnsupportedError);
      expect(list, [1, 2]);

      list.assignAll([7, 8]);
      expect(list, [7, 8]);

      // ...and the RxList is plainly mutable afterwards: the unmodifiable
      // backing is gone, replaced by the fresh growable list assignAll built.
      list.add(9);
      expect(list, [7, 8, 9]);

      await Future.delayed(Duration.zero);
      expect(notifications, 2, reason: 'assignAll, then add. Never the throw.');
    });

    test('RxList: assign succeeds where insert throws', () {
      final list = RxList<int>(const <int>[1, 2]);

      expect(() => list.insert(0, 0), throwsUnsupportedError);
      expect(list, [1, 2]);

      list.assign(7);
      expect(list, [7]);
    });

    test('RxSet: assignAll succeeds where add throws', () async {
      final set = RxSet<int>(Set<int>.unmodifiable({1, 2}));
      var notifications = 0;
      set.listen((_) => notifications++);

      expect(() => set.add(3), throwsUnsupportedError);
      expect(set, unorderedEquals(<int>[1, 2]));

      set.assignAll([7, 8]);
      expect(set, unorderedEquals(<int>[7, 8]));

      set.add(9);
      expect(set, unorderedEquals(<int>[7, 8, 9]));

      await Future.delayed(Duration.zero);
      expect(notifications, 2);
    });

    test('RxSet: the assignAll copy keeps the runtime element type', () {
      // toSet() reifies the BACKING's element type, not the RxSet's type
      // argument, so the fresh set is a Set<int> and keeps rejecting
      // incompatible elements exactly as the backing did.
      final RxSet<num> set = RxSet<num>(Set<int>.unmodifiable({1, 2}));

      set.assignAll(<int>[3, 4]);
      expect(set, unorderedEquals(<num>[3, 4]));
      expect(() => set.add(0.5), throwsA(isA<TypeError>()));

      // Strict enough that even a compatible-looking `Iterable<num>` is
      // rejected, because `Set<int>.addAll` will not accept one.
      expect(
        () => set.assignAll(<num>[5, 6]),
        throwsA(isA<TypeError>()),
        reason: 'the copy is a Set<int>, so addAll wants an Iterable<int>',
      );
    });

    test('RxMap: assignAll succeeds where []= throws', () async {
      final map = RxMap<String, int>(Map<String, int>.unmodifiable({'a': 1}));
      var notifications = 0;
      map.listen((_) => notifications++);

      expect(() => map['b'] = 2, throwsUnsupportedError);
      expect(map, {'a': 1});

      map.assignAll(<String, int>{'z': 9});
      expect(map, {'z': 9});

      map['y'] = 8;
      expect(map, {'z': 9, 'y': 8});

      await Future.delayed(Duration.zero);
      expect(notifications, 2);
    });

    test('RxMap: the assign copy is parameterised by K and V', () {
      // Documented trade-off: Map has no runtime-type-preserving copy the way
      // List.toList()/Set.toSet() do, so assign publishes a plain Map<K, V>.
      final RxMap<Object, Object> map = RxMap<Object, Object>(
        Map<String, int>.unmodifiable({'a': 1}),
      );

      map.assign('b', 2);
      map[1] = 'accepted after the swap';

      expect(map, {'b': 2, 1: 'accepted after the swap'});
    });
  });

  // -------------------------------------------------------------------------
  group('worker and Obx integration', () {
    test(
      'ever() fires exactly once per mutation of a fixed-backing RxList',
      () async {
        final list = RxList<int>(List<int>.empty());
        final seen = <List<int>>[];
        final worker = ever<List<int>>(
          list,
          (value) => seen.add(List<int>.of(value)),
        );

        list.add(1);
        await Future.delayed(Duration.zero);
        list.insert(0, 0);
        await Future.delayed(Duration.zero);
        list.clear();
        await Future.delayed(Duration.zero);

        expect(seen, [
          [1],
          [0, 1],
          <int>[],
        ]);
        worker.dispose();
      },
    );

    test('ever() never fires for a rejected mutation', () async {
      final map = RxMap<String, int>(Map<String, int>.unmodifiable({'a': 1}));
      var calls = 0;
      final worker = ever<Map<String, int>>(map, (_) => calls++);

      expect(() => map['b'] = 2, throwsUnsupportedError);
      await Future.delayed(Duration.zero);
      expect(calls, 0);

      // The surviving seam still reaches the worker.
      map.assignAll(<String, int>{'z': 9});
      await Future.delayed(Duration.zero);

      expect(calls, 1);
      expect(map, {'z': 9});
      worker.dispose();
    });

    testWidgets('Obx rebuilds once per mutation of a fixed-backing RxList', (
      tester,
    ) async {
      final list = RxList<int>(List<int>.empty());
      var builds = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Obx(() {
            builds++;
            return Text('items: ${list.length}');
          }),
        ),
      );
      expect(builds, 1);
      expect(find.text('items: 0'), findsOneWidget);

      // Obx schedules its rebuild in a microtask, so drain those (idle())
      // before asking for a frame.
      list.insert(0, 1);
      await tester.idle();
      await tester.pump();
      expect(builds, 2);
      expect(find.text('items: 1'), findsOneWidget);

      list.addAll([2, 3]);
      await tester.idle();
      await tester.pump();
      expect(builds, 3);
      expect(find.text('items: 3'), findsOneWidget);

      list.clear();
      await tester.idle();
      await tester.pump();
      expect(builds, 4);
      expect(find.text('items: 0'), findsOneWidget);
    });
  });
}
