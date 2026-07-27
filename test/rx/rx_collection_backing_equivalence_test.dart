// Property / differential tests for the backing collections of RxList, RxSet
// and RxMap under the *narrow* healing contract.
//
// fixed_length_backing_assign_test.dart pins down individual crashes. These
// tests pin down the two *properties* the hardening is supposed to deliver,
// which are duals of each other:
//
//  1. EQUIVALENCE. A backing that carries no immutability intent — a
//     fixed-length list such as `List.empty()`, `List.filled()` or a
//     `Uint8List` — must be observationally INDISTINGUISHABLE from a plain
//     growable list. Every operation is run against a growable control and
//     against one subject per awkward backing shape, and the contents, length,
//     iteration order, return value, thrown error type and listener
//     notification count are diffed.
//
//  2. REJECTION. A backing that *is* an explicit opt-in to immutability —
//     `List.unmodifiable`, `const [...]`, `UnmodifiableListView`,
//     `Set.unmodifiable`, `Map.unmodifiable` — must NOT be equivalent. Where
//     the growable control succeeds, the unmodifiable subject throws
//     `UnsupportedError`, notifies nobody, keeps its contents, and — the
//     important anti-regression — keeps its *identity*: a failed capability
//     probe must have no side effect, so the RxList must still be holding the
//     very same backing object afterwards and must still reject the next
//     mutation. Unmodifiable is forever.
//
// `assign` / `assignAll` are the single documented exception to (2): they
// replace the contents wholesale by publishing a fresh mutable collection, so
// they succeed on every backing and are diffed against the control like a
// fixed-length subject. Each operation below declares which side of that line
// it falls on via [_Unmod].
//
// RxSet and RxMap have no healing at all — `dart:core` has no
// fixed-length-but-writable Set or Map, so "unmodifiable" is their only
// failure mode and it is always honoured. Their equivalence sections
// therefore only carry mutable and nested-Rx subjects.
//
// Notifications are counted through `addListener` — the synchronous fan-out
// that both `refresh()` and `value =` end in — rather than through the
// broadcast stream, so the counts are exact and need no event-loop turn. Two
// tests at the bottom cross-check that the stream sees the same thing.
import 'dart:collection';
import 'dart:math';

// `Uint8List` comes from foundation's re-export of `dart:typed_data`;
// importing it directly here would be flagged as an unnecessary import.
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/get_rx/get_rx.dart';

/// What an operation is expected to do to a collection whose backing is an
/// explicit opt-in to immutability.
enum _Unmod {
  /// The backing's own [UnsupportedError] comes out, nothing changes and
  /// nobody is notified. This is the case for every real mutator.
  throws,

  /// The operation succeeds and stays equivalent to the growable control.
  /// Only `assign`/`assignAll` (which replace the contents wholesale) and
  /// operations that never actually attempt a mutation qualify.
  succeeds,
}

/// A named operation applied to a collection of type [T].
class _Op<T> {
  const _Op(this.name, this.run, {this.unmod = _Unmod.throws});

  /// An operation whose return value is not part of its contract.
  factory _Op.action(
    String name,
    void Function(T target) body, {
    _Unmod unmod = _Unmod.throws,
  }) {
    return _Op<T>(name, (target) {
      body(target);
      return null;
    }, unmod: unmod);
  }

  final String name;

  /// Returns whatever the member under test returns, so return values are
  /// diffed too; `null` stands in for a `void` member.
  final Object? Function(T target) run;

  /// Behaviour over an unmodifiable backing. See [_Unmod].
  final _Unmod unmod;
}

typedef _ListOp = _Op<RxList<int>>;
typedef _SetOp = _Op<RxSet<int>>;
typedef _MapOp = _Op<RxMap<String, int>>;

const _listSeed = <int>[1, 2, 3];
const _setSeed = <int>{1, 2, 3};
const _mapSeed = <String, int>{'a': 1, 'b': 2};

List<int> _growableSeed() => List<int>.of(_listSeed);
Set<int> _mutableSeed() => Set<int>.of(_setSeed);
Map<String, int> _mutableMapSeed() => Map<String, int>.of(_mapSeed);

/// Backings that all hold `[1, 2, 3]` and must all behave exactly like a
/// plain growable list: either they already are mutable, or they are
/// fixed-length and therefore heal on the first length change.
///
/// The growable entry is the control run as a subject, so the harness
/// self-checks.
final _equivalentListBackings = <String, List<int> Function()>{
  'growable (self-check)': _growableSeed,
  'fixed-length (List.of growable: false)': () =>
      List<int>.of(_listSeed, growable: false),
  'fixed-length (List.filled)': () =>
      List<int>.filled(3, 0, growable: false)..setAll(0, _listSeed),
  // The canonical "fixed-length but very much writable" buffer, and a
  // different implementation class from `_List`.
  'fixed-length (Uint8List)': () => Uint8List.fromList(_listSeed),
  // Reachable through `someRxList.obs`, and the one shape both capability
  // probes short-circuit instead of probing.
  'nested RxList': () => RxList<int>(_growableSeed()),
};

/// Backings that declared themselves immutable and must never be healed.
final _unmodifiableListBackings = <String, List<int> Function()>{
  'List.unmodifiable': () => List<int>.unmodifiable(_listSeed),
  'const literal': () => _listSeed,
  // A different implementation class again: a live *view* over a growable
  // list, which the probes must classify by behaviour rather than by type.
  'UnmodifiableListView': () => UnmodifiableListView<int>(_growableSeed()),
};

/// The empty counterparts, i.e. the exact shape of the production report:
/// `RxList<T> x = List<T>.empty().obs;`.
final _equivalentEmptyListBackings = <String, List<int> Function()>{
  'growable (self-check)': () => <int>[],
  'fixed-length (List.empty)': () => List<int>.empty(),
  'fixed-length (Uint8List)': () => Uint8List(0),
  'nested RxList': () => RxList<int>(<int>[]),
};

final _unmodifiableEmptyListBackings = <String, List<int> Function()>{
  'List.unmodifiable': () => List<int>.unmodifiable(const []),
  'const literal': () => const <int>[],
  'UnmodifiableListView': () => UnmodifiableListView<int>(<int>[]),
};

/// RxSet never heals, so the only equivalent subjects are ones that were
/// mutable to begin with.
final _equivalentSetBackings = <String, Set<int> Function()>{
  'mutable (self-check)': _mutableSeed,
  'nested RxSet': () => RxSet<int>(_mutableSeed()),
};

final _unmodifiableSetBackings = <String, Set<int> Function()>{
  'Set.unmodifiable': () => Set<int>.unmodifiable(_setSeed),
  'const literal': () => _setSeed,
  'UnmodifiableSetView': () => UnmodifiableSetView<int>(_mutableSeed()),
};

final _equivalentMapBackings = <String, Map<String, int> Function()>{
  'mutable (self-check)': _mutableMapSeed,
  'nested RxMap': () => RxMap<String, int>(_mutableMapSeed()),
};

final _unmodifiableMapBackings = <String, Map<String, int> Function()>{
  'Map.unmodifiable': () => Map<String, int>.unmodifiable(_mapSeed),
  'const literal': () => _mapSeed,
  'UnmodifiableMapView': () =>
      UnmodifiableMapView<String, int>(_mutableMapSeed()),
};

/// Everything observable about a collection after one operation ran on it.
class _Result {
  const _Result({
    required this.contents,
    required this.iterated,
    required this.length,
    required this.result,
    required this.notifications,
    required this.error,
  });

  final List<Object?> contents;
  final List<Object?> iterated;
  final int length;
  final Object? result;
  final int notifications;
  final Object? error;
}

/// Attaches a synchronous listener and returns a getter for its call count.
int Function() _watch(Listenable rx) {
  var count = 0;
  rx.addListener(() => count++);
  return () => count;
}

_Result _runList(List<int> backing, _ListOp op) {
  final rx = RxList<int>(backing);
  final notifications = _watch(rx);
  Object? result;
  Object? error;
  try {
    result = op.run(rx);
  } catch (e) {
    error = e;
  }
  return _Result(
    contents: rx.toList(),
    iterated: [for (final element in rx) element],
    length: rx.length,
    result: result,
    notifications: notifications(),
    error: error,
  );
}

_Result _runSet(Set<int> backing, _SetOp op) {
  final rx = RxSet<int>(backing);
  final notifications = _watch(rx);
  Object? result;
  Object? error;
  try {
    result = op.run(rx);
  } catch (e) {
    error = e;
  }
  return _Result(
    contents: rx.toList(),
    iterated: [for (final element in rx) element],
    length: rx.length,
    result: result,
    notifications: notifications(),
    error: error,
  );
}

_Result _runMap(Map<String, int> backing, _MapOp op) {
  final rx = RxMap<String, int>(backing);
  final notifications = _watch(rx);
  Object? result;
  Object? error;
  try {
    result = op.run(rx);
  } catch (e) {
    error = e;
  }
  return _Result(
    contents: [for (final key in rx.keys) '$key=${rx[key]}'],
    iterated: rx.keys.toList(),
    length: rx.length,
    result: result,
    notifications: notifications(),
    error: error,
  );
}

/// Diffs a subject against the control. [maxNotifications] is `null` for
/// multi-operation sequences, where more than one notification is expected.
void _expectSame(
  String label,
  _Result subject,
  _Result control, {
  int? maxNotifications = 1,
}) {
  expect(subject.contents, control.contents, reason: '$label: contents');
  expect(subject.iterated, control.iterated, reason: '$label: iteration order');
  expect(subject.length, control.length, reason: '$label: length');
  expect(subject.result, control.result, reason: '$label: return value');
  // Only the runtime type is compared: the messages embed indices and lengths
  // that are equal here anyway, but comparing them would make the tests
  // hostage to dart:core wording.
  expect(
    subject.error?.runtimeType,
    control.error?.runtimeType,
    reason:
        '$label: thrown error (subject ${subject.error}, '
        'control ${control.error})',
  );
  expect(
    subject.notifications,
    control.notifications,
    reason: '$label: notification count',
  );
  if (maxNotifications != null) {
    expect(
      subject.notifications,
      lessThanOrEqualTo(maxNotifications),
      reason: '$label: one call must notify at most once',
    );
  }
}

/// The dual of [_expectSame] for a list: the operation must be *rejected* by
/// the backing, leaving no trace at all.
void _expectListRejects(
  String label,
  List<int> backing,
  _ListOp op,
  List<int> seed,
) {
  final before = backing.toList();
  final rx = RxList<int>(backing);
  final notifications = _watch(rx);

  expect(
    () => op.run(rx),
    throwsUnsupportedError,
    reason: "$label: an unmodifiable backing must surface its own error",
  );
  expect(rx, seed, reason: '$label: contents must be unchanged');
  expect(rx.length, seed.length, reason: '$label: length must be unchanged');
  expect(notifications(), 0, reason: '$label: nobody may be notified');
  expect(
    identical(rx.value, backing),
    isTrue,
    reason:
        '$label: the backing must not have been swapped — a failed '
        'capability probe must have no side effect',
  );
  expect(backing, before, reason: '$label: the backing itself is untouched');
  expect(
    () => rx.add(999),
    throwsUnsupportedError,
    reason: '$label: unmodifiable is forever',
  );
  expect(identical(rx.value, backing), isTrue, reason: '$label: still aliased');
}

void _expectSetRejects(String label, Set<int> backing, _SetOp op) {
  final before = backing.toSet();
  final rx = RxSet<int>(backing);
  final notifications = _watch(rx);

  expect(() => op.run(rx), throwsUnsupportedError, reason: label);
  expect(rx, _setSeed, reason: '$label: contents must be unchanged');
  expect(notifications(), 0, reason: '$label: nobody may be notified');
  expect(
    identical(rx.value, backing),
    isTrue,
    reason: '$label: the backing must not have been swapped',
  );
  expect(backing, before, reason: '$label: the backing itself is untouched');
  expect(
    () => rx.add(999),
    throwsUnsupportedError,
    reason: '$label: unmodifiable is forever',
  );
}

void _expectMapRejects(String label, Map<String, int> backing, _MapOp op) {
  final before = Map<String, int>.of(backing);
  final rx = RxMap<String, int>(backing);
  final notifications = _watch(rx);

  expect(() => op.run(rx), throwsUnsupportedError, reason: label);
  expect(rx, _mapSeed, reason: '$label: contents must be unchanged');
  expect(notifications(), 0, reason: '$label: nobody may be notified');
  expect(
    identical(rx.value, backing),
    isTrue,
    reason: '$label: the backing must not have been swapped',
  );
  expect(backing, before, reason: '$label: the backing itself is untouched');
  expect(
    () => rx['zz'] = 1,
    throwsUnsupportedError,
    reason: '$label: unmodifiable is forever',
  );
}

/// Single-call mutations of an `RxList<int>` seeded with `[1, 2, 3]`.
final _listOps = <_ListOp>[
  // --- length-changing members -------------------------------------------
  _ListOp.action('add', (l) => l.add(4)),
  _ListOp.action('addAll', (l) => l.addAll([4, 5])),
  _ListOp.action('addAll (empty)', (l) => l.addAll(const <int>[])),
  // The exact production crash: insert into a fixed-length backing.
  _ListOp.action('insert at 0', (l) => l.insert(0, 0)),
  _ListOp.action('insert at end', (l) => l.insert(3, 9)),
  _ListOp.action('insertAll', (l) => l.insertAll(1, [7, 8])),
  _ListOp('remove (present)', (l) => l.remove(2)),
  _ListOp('remove (absent)', (l) => l.remove(99)),
  _ListOp('removeAt', (l) => l.removeAt(1)),
  _ListOp('removeLast', (l) => l.removeLast()),
  _ListOp.action('removeRange', (l) => l.removeRange(0, 2)),
  _ListOp.action('removeWhere', (l) => l.removeWhere((e) => e.isEven)),
  _ListOp.action('removeWhere (no match)', (l) => l.removeWhere((e) => e > 9)),
  _ListOp.action('retainWhere', (l) => l.retainWhere((e) => e > 1)),
  // The second latent crash in the production report.
  _ListOp.action('clear', (l) => l.clear()),
  _ListOp('length = 0', (l) => l.length = 0),
  _ListOp('length = 1', (l) => l.length = 1),
  _ListOp.action('replaceRange (shorter)', (l) => l.replaceRange(0, 2, [9])),
  // FixedLengthListMixin.replaceRange throws even when the length is kept.
  _ListOp.action('replaceRange (same length)', (l) {
    l.replaceRange(0, 1, [9]);
  }),
  _ListOp.action('replaceRange (longer)', (l) {
    l.replaceRange(0, 1, [8, 9]);
  }),
  _ListOp('operator + returns this', (l) => identical(l + <int>[4, 5], l)),
  // --- element-writing members -------------------------------------------
  // These need no healing: a fixed-length list accepts them in place and an
  // unmodifiable one rejects them on its own.
  _ListOp.action('operator []=', (l) => l[0] = 9),
  _ListOp.action('first =', (l) => l.first = 9),
  _ListOp.action('last =', (l) => l.last = 9),
  _ListOp.action('sort (default)', (l) => l.sort()),
  _ListOp.action('sort (descending)', (l) => l.sort((a, b) => b.compareTo(a))),
  // The same seed makes shuffle deterministic; every list implementation
  // shares ListBase.shuffle, so the control and the subjects must agree.
  _ListOp.action('shuffle (seeded)', (l) => l.shuffle(Random(42))),
  _ListOp.action('setAll', (l) => l.setAll(1, [7, 8])),
  _ListOp.action('setRange', (l) => l.setRange(0, 2, [7, 8])),
  _ListOp.action('setRange (skipCount)', (l) {
    l.setRange(0, 2, [0, 7, 8], 1);
  }),
  _ListOp.action('fillRange', (l) => l.fillRange(0, 2, 9)),
  // --- members that only delegate ----------------------------------------
  _ListOp.action('addNonNull', (l) => l.addNonNull(4)),
  _ListOp.action('addIf (true)', (l) => l.addIf(true, 4)),
  // Never touches the backing at all, so it is fine everywhere.
  _ListOp.action(
    'addIf (false)',
    (l) => l.addIf(false, 4),
    unmod: _Unmod.succeeds,
  ),
  _ListOp.action('addAllIf (true)', (l) => l.addAllIf(true, [4, 5])),
  _ListOp.action('cast view add', (l) => l.cast<num>().add(4)),
  // --- the documented exception ------------------------------------------
  // assign/assignAll replace the contents wholesale, so they publish a fresh
  // growable list instead of mutating the current one and therefore work over
  // an unmodifiable backing too.
  _ListOp.action('assign', (l) => l.assign(9), unmod: _Unmod.succeeds),
  _ListOp.action(
    'assignAll',
    (l) => l.assignAll([7, 8, 9]),
    unmod: _Unmod.succeeds,
  ),
  _ListOp.action(
    'assignAll (empty)',
    (l) => l.assignAll(const <int>[]),
    unmod: _Unmod.succeeds,
  ),
  // --- calls that must fail, and must fail identically -------------------
  // Growing a List<int> writes nulls, so this throws a TypeError on the
  // growable control and on the fixed-length subjects (inside the copy). An
  // unmodifiable backing refuses before it ever gets that far.
  _ListOp('length = 5 (grow non-nullable)', (l) => l.length = 5),
  _ListOp('removeAt (out of range)', (l) => l.removeAt(99)),
  _ListOp.action('insert (out of range)', (l) => l.insert(99, 0)),
  _ListOp.action('removeRange (past end)', (l) => l.removeRange(0, 99)),
  _ListOp.action('setRange (past end)', (l) => l.setRange(0, 9, [1, 2])),
  _ListOp.action('setAll (past end)', (l) => l.setAll(2, [7, 8])),
];

/// Operations valid on an empty list, for the `List.empty()` backings.
final _emptyListOps = <_ListOp>[
  _ListOp.action('add', (l) => l.add(1)),
  _ListOp.action('insert at 0', (l) => l.insert(0, 1)),
  _ListOp.action('addAll', (l) => l.addAll([1, 2])),
  _ListOp.action('clear', (l) => l.clear()),
  _ListOp('length = 0', (l) => l.length = 0),
  _ListOp('remove (absent)', (l) => l.remove(1)),
  _ListOp.action('removeWhere', (l) => l.removeWhere((e) => true)),
  // Vacuous, but the unmodifiable mixins throw for an empty range too.
  _ListOp.action('sort', (l) => l.sort()),
  // `shuffle` is the exception: with fewer than two elements there is nothing
  // to swap, so `RxList.shuffle` returns without ever asking the backing to
  // write — exactly as the inherited `ListMixin.shuffle` always did. It stays
  // equivalent to the growable control instead of throwing.
  _ListOp.action(
    'shuffle (seeded)',
    (l) => l.shuffle(Random(7)),
    unmod: _Unmod.succeeds,
  ),
  _ListOp.action('setRange (empty range)', (l) => l.setRange(0, 0, const [])),
  _ListOp.action('fillRange (empty range)', (l) => l.fillRange(0, 0, 1)),
  _ListOp.action(
    'assignAll',
    (l) => l.assignAll([1, 2]),
    unmod: _Unmod.succeeds,
  ),
  _ListOp.action('assign', (l) => l.assign(1), unmod: _Unmod.succeeds),
  _ListOp('removeLast (throws)', (l) => l.removeLast()),
  _ListOp('operator + returns this', (l) => identical(l + <int>[1], l)),
];

/// Multi-operation sequences: a backing swapped mid-sequence must not change
/// what the rest of the sequence does.
final _listSequences = <_ListOp>[
  _ListOp.action('clear, insert, add', (l) {
    l.clear();
    l.insert(0, 7);
    l.add(8);
  }),
  _ListOp.action('insert at 0 three times', (l) {
    for (var i = 0; i < 3; i++) {
      l.insert(0, i);
    }
  }),
  _ListOp.action('sort, removeWhere, addAll', (l) {
    l.sort((a, b) => b.compareTo(a));
    l.removeWhere((e) => e.isOdd);
    l.addAll([10, 11]);
  }),
  // The one sequence that survives an unmodifiable backing: the leading
  // assignAll replaces it with a fresh growable list, after which the rest of
  // the sequence is ordinary.
  _ListOp.action('assignAll, add, removeAt', (l) {
    l.assignAll([5, 6, 7]);
    l.add(8);
    l.removeAt(0);
  }, unmod: _Unmod.succeeds),
  _ListOp.action('length = 0, addAll, sort', (l) {
    l.length = 0;
    l.addAll([3, 1, 2]);
    l.sort();
  }),
  _ListOp.action('setAll, remove, insertAll', (l) {
    l.setAll(0, [9, 8, 7]);
    l.remove(8);
    l.insertAll(0, [0, 1]);
  }),
  _ListOp.action('element write then length change', (l) {
    // An element write leaves a fixed-length backing in place; the following
    // length change still has to work.
    l[0] = 42;
    l.add(43);
    l.removeLast();
    l.shuffle(Random(3));
  }),
  _ListOp.action('failed op then successful op', (l) {
    try {
      l.removeAt(99);
    } on RangeError {
      // The failure must not corrupt or detach anything. On an unmodifiable
      // backing the error is an UnsupportedError instead, so it escapes this
      // catch — which is exactly the rejection the dual test asserts.
    }
    l.add(4);
  }),
];

final _setOps = <_SetOp>[
  _SetOp('add (new)', (s) => s.add(4)),
  _SetOp('add (duplicate)', (s) => s.add(1)),
  _SetOp.action('addAll', (s) => s.addAll({4, 5})),
  _SetOp.action('addAll (empty)', (s) => s.addAll(const <int>{})),
  _SetOp('remove (present)', (s) => s.remove(2)),
  _SetOp('remove (absent)', (s) => s.remove(99)),
  _SetOp.action('removeAll', (s) => s.removeAll([1, 2])),
  _SetOp.action('removeAll (nothing)', (s) => s.removeAll([99])),
  _SetOp.action('retainAll', (s) => s.retainAll([2])),
  _SetOp.action('retainWhere', (s) => s.retainWhere((e) => e > 1)),
  _SetOp.action('removeWhere', (s) => s.removeWhere((e) => e.isEven)),
  _SetOp.action('clear', (s) => s.clear()),
  // `update` hands the callback the real backing set, so an unmodifiable one
  // throws from inside the callback.
  _SetOp.action('update', (s) {
    s.update((value) {
      (value! as Set<int>).add(9);
    });
  }),
  _SetOp('operator + returns this', (s) => identical(s + {4, 5}, s)),
  _SetOp.action('cast view add', (s) => s.cast<num>().add(4)),
  _SetOp.action('addIf (true)', (s) => s.addIf(true, 4)),
  _SetOp.action(
    'addIf (false)',
    (s) => s.addIf(false, 4),
    unmod: _Unmod.succeeds,
  ),
  _SetOp.action('addAllIf (true)', (s) => s.addAllIf(true, {4, 5})),
  _SetOp.action('assign', (s) => s.assign(9), unmod: _Unmod.succeeds),
  _SetOp.action(
    'assignAll',
    (s) => s.assignAll({7, 8}),
    unmod: _Unmod.succeeds,
  ),
];

final _setSequences = <_SetOp>[
  _SetOp.action('clear, add, remove', (s) {
    s.clear();
    s.add(7);
    s.remove(7);
    s.addAll({1, 2});
  }),
  _SetOp.action('removeWhere, addAll, retainAll', (s) {
    s.removeWhere((e) => e.isOdd);
    s.addAll({4, 5, 6});
    s.retainAll([4, 6]);
  }),
  _SetOp.action('assignAll, add, remove', (s) {
    s.assignAll({5, 6});
    s.add(7);
    s.remove(5);
  }, unmod: _Unmod.succeeds),
];

final _mapOps = <_MapOp>[
  _MapOp.action('operator []= (new key)', (m) => m['c'] = 3),
  _MapOp.action('operator []= (existing key)', (m) => m['a'] = 9),
  _MapOp('remove (present)', (m) => m.remove('a')),
  _MapOp('remove (absent)', (m) => m.remove('zz')),
  _MapOp.action('addAll', (m) => m.addAll({'c': 3})),
  _MapOp.action('addAll (empty)', (m) => m.addAll(const <String, int>{})),
  _MapOp.action('addEntries', (m) => m.addEntries([const MapEntry('c', 3)])),
  _MapOp('putIfAbsent (absent)', (m) => m.putIfAbsent('c', () => 3)),
  _MapOp('putIfAbsent (present)', (m) => m.putIfAbsent('a', () => 9)),
  _MapOp('update (present)', (m) => m.update('a', (v) => v + 1)),
  _MapOp(
    'update (absent, ifAbsent)',
    (m) => m.update('c', (v) => v, ifAbsent: () => 7),
  ),
  _MapOp.action('updateAll', (m) => m.updateAll((key, value) => value * 2)),
  _MapOp.action('removeWhere', (m) => m.removeWhere((key, value) => value > 1)),
  _MapOp.action('removeWhere (no match)', (m) {
    m.removeWhere((key, value) => value > 99);
  }),
  _MapOp.action('clear', (m) => m.clear()),
  _MapOp.action('cast view write', (m) => m.cast<String, num>()['c'] = 3),
  _MapOp.action('addIf (true)', (m) => m.addIf(true, 'c', 3)),
  _MapOp.action(
    'addIf (false)',
    (m) => m.addIf(false, 'c', 3),
    unmod: _Unmod.succeeds,
  ),
  _MapOp.action('addAllIf (true)', (m) => m.addAllIf(true, {'c': 3})),
  _MapOp.action('assign', (m) => m.assign('z', 9), unmod: _Unmod.succeeds),
  _MapOp.action(
    'assignAll',
    (m) => m.assignAll({'y': 8, 'z': 9}),
    unmod: _Unmod.succeeds,
  ),
  // Must fail identically on every mutable backing; an unmodifiable one
  // refuses before the ArgumentError can be raised.
  _MapOp('update (absent, no ifAbsent)', (m) => m.update('c', (v) => v)),
];

final _mapSequences = <_MapOp>[
  _MapOp.action('clear, write, remove', (m) {
    m.clear();
    m['x'] = 1;
    m['y'] = 2;
    m.remove('x');
  }),
  _MapOp.action('updateAll, addAll, removeWhere', (m) {
    m.updateAll((key, value) => value * 10);
    m.addAll({'c': 3});
    m.removeWhere((key, value) => value >= 20);
  }),
  _MapOp.action('assignAll, write, remove', (m) {
    m.assignAll({'x': 1, 'y': 2});
    m['z'] = 3;
    m.remove('x');
  }, unmod: _Unmod.succeeds),
];

void main() {
  // ---------------------------------------------------------------------
  // 1. Equivalence: no immutability intent means indistinguishable.
  // ---------------------------------------------------------------------

  group(
    'RxList over [1, 2, 3]: a fixed-length backing equals a growable one',
    () {
      test('list operations equivalence matrix suite', () {
        for (final op in _listOps) {
          final control = _runList(_growableSeed(), op);
          for (final backing in _equivalentListBackings.entries) {
            _expectSame(
              '${op.name} on ${backing.key}',
              _runList(backing.value(), op),
              control,
            );
          }
        }
      });
    },
  );

  group(
    'RxList over an empty fixed-length backing equals an empty growable one',
    () {
      test('empty list operations equivalence matrix suite', () {
        for (final op in _emptyListOps) {
          final control = _runList(<int>[], op);
          for (final backing in _equivalentEmptyListBackings.entries) {
            _expectSame(
              '${op.name} on ${backing.key}',
              _runList(backing.value(), op),
              control,
            );
          }
        }
      });
    },
  );

  group('RxList sequences: a fixed-length backing equals a growable one', () {
    test('list sequences equivalence matrix suite', () {
      for (final op in _listSequences) {
        final control = _runList(_growableSeed(), op);
        for (final backing in _equivalentListBackings.entries) {
          _expectSame(
            '${op.name} on ${backing.key}',
            _runList(backing.value(), op),
            control,
            maxNotifications: null,
          );
        }
      }
    });
  });

  group('RxSet over {1, 2, 3} behaves the same on every mutable backing', () {
    test('set operations equivalence matrix suite', () {
      for (final op in [..._setOps, ..._setSequences]) {
        final control = _runSet(_mutableSeed(), op);
        for (final backing in _equivalentSetBackings.entries) {
          _expectSame(
            '${op.name} on ${backing.key}',
            _runSet(backing.value(), op),
            control,
            maxNotifications: null,
          );
        }
      }
    });
  });

  group(
    'RxMap over {a: 1, b: 2} behaves the same on every mutable backing',
    () {
      test('map operations equivalence matrix suite', () {
        for (final op in [..._mapOps, ..._mapSequences]) {
          final control = _runMap(_mutableMapSeed(), op);
          for (final backing in _equivalentMapBackings.entries) {
            _expectSame(
              '${op.name} on ${backing.key}',
              _runMap(backing.value(), op),
              control,
              maxNotifications: null,
            );
          }
        }
      });
    },
  );

  // ---------------------------------------------------------------------
  // 2. Rejection: an unmodifiable backing is NOT equivalent, by design.
  // ---------------------------------------------------------------------

  group(
    'RxList over an unmodifiable backing rejects what a growable one accepts',
    () {
      test('list operations rejection matrix suite', () {
        for (final op in _listOps) {
          final control = _runList(_growableSeed(), op);
          for (final backing in _unmodifiableListBackings.entries) {
            final label = '${op.name} on ${backing.key}';
            if (op.unmod == _Unmod.succeeds) {
              _expectSame(label, _runList(backing.value(), op), control);
            } else {
              _expectListRejects(label, backing.value(), op, _listSeed);
            }
          }
        }
      });
    },
  );

  group('RxList over an empty unmodifiable backing rejects mutation', () {
    test('empty list operations rejection matrix suite', () {
      for (final op in _emptyListOps) {
        final control = _runList(<int>[], op);
        for (final backing in _unmodifiableEmptyListBackings.entries) {
          final label = '${op.name} on ${backing.key}';
          if (op.unmod == _Unmod.succeeds) {
            _expectSame(label, _runList(backing.value(), op), control);
          } else {
            _expectListRejects(label, backing.value(), op, const <int>[]);
          }
        }
      }
    });
  });

  group('RxList sequences over an unmodifiable backing are rejected', () {
    test('list sequences rejection matrix suite', () {
      for (final op in _listSequences) {
        final control = _runList(_growableSeed(), op);
        for (final backing in _unmodifiableListBackings.entries) {
          final label = '${op.name} on ${backing.key}';
          if (op.unmod == _Unmod.succeeds) {
            _expectSame(
              label,
              _runList(backing.value(), op),
              control,
              maxNotifications: null,
            );
          } else {
            _expectListRejects(label, backing.value(), op, _listSeed);
          }
        }
      }
    });
  });

  group('RxSet over an unmodifiable backing rejects mutation', () {
    for (final op in [..._setOps, ..._setSequences]) {
      test(op.name, () {
        final control = _runSet(_mutableSeed(), op);
        for (final backing in _unmodifiableSetBackings.entries) {
          final label = '${op.name} on ${backing.key}';
          if (op.unmod == _Unmod.succeeds) {
            _expectSame(
              label,
              _runSet(backing.value(), op),
              control,
              maxNotifications: null,
            );
          } else {
            _expectSetRejects(label, backing.value(), op);
          }
        }
      });
    }
  });

  group('RxMap over an unmodifiable backing rejects mutation', () {
    for (final op in [..._mapOps, ..._mapSequences]) {
      test(op.name, () {
        final control = _runMap(_mutableMapSeed(), op);
        for (final backing in _unmodifiableMapBackings.entries) {
          final label = '${op.name} on ${backing.key}';
          if (op.unmod == _Unmod.succeeds) {
            _expectSame(
              label,
              _runMap(backing.value(), op),
              control,
              maxNotifications: null,
            );
          } else {
            _expectMapRejects(label, backing.value(), op);
          }
        }
      });
    }
  });

  // ---------------------------------------------------------------------
  // 3. The two invariants, stated as duals.
  // ---------------------------------------------------------------------

  group('healing is idempotently unsticking', () {
    test('no RxList operation leaves a list that rejects a later add', () {
      final ops = [..._listOps, ..._listSequences];
      for (final backing in _equivalentListBackings.entries) {
        for (final op in ops) {
          final label = '${op.name} on ${backing.key}';
          final rx = RxList<int>(backing.value());
          try {
            op.run(rx);
          } catch (_) {
            // Operations that are meant to throw must leave a usable list too.
          }
          expect(() => rx.add(999), returnsNormally, reason: label);
          expect(rx.last, 999, reason: label);
          expect(
            () {
              rx.insert(0, -1);
              rx.removeAt(0);
              rx.removeLast();
              rx.clear();
              rx.addAll([1, 2]);
              rx[0] = 3;
              rx.sort();
            },
            returnsNormally,
            reason: label,
          );
          expect(rx, [2, 3], reason: label);
        }
      }
    });

    test('no RxList operation leaves an empty list stuck', () {
      for (final backing in _equivalentEmptyListBackings.entries) {
        for (final op in _emptyListOps) {
          final label = '${op.name} on ${backing.key}';
          final rx = RxList<int>(backing.value());
          try {
            op.run(rx);
          } catch (_) {
            // See above.
          }
          expect(
            () {
              rx.clear();
              rx.add(1);
              rx.insert(0, 0);
            },
            returnsNormally,
            reason: label,
          );
          expect(rx, [0, 1], reason: label);
        }
      }
    });

    test(
      'no RxSet operation leaves a mutable set that rejects a later add',
      () {
        for (final backing in _equivalentSetBackings.entries) {
          for (final op in [..._setOps, ..._setSequences]) {
            final label = '${op.name} on ${backing.key}';
            final rx = RxSet<int>(backing.value());
            try {
              op.run(rx);
            } catch (_) {
              // See above.
            }
            expect(
              () {
                rx.add(999);
                rx.remove(999);
                rx.clear();
                rx.addAll({1, 2});
              },
              returnsNormally,
              reason: label,
            );
            expect(rx, {1, 2}, reason: label);
          }
        }
      },
    );

    test(
      'no RxMap operation leaves a mutable map that rejects a later write',
      () {
        for (final backing in _equivalentMapBackings.entries) {
          for (final op in [..._mapOps, ..._mapSequences]) {
            final label = '${op.name} on ${backing.key}';
            final rx = RxMap<String, int>(backing.value());
            try {
              op.run(rx);
            } catch (_) {
              // See above.
            }
            expect(
              () {
                rx['zz'] = 1;
                rx.remove('zz');
                rx.clear();
                rx.addAll({'k': 1});
              },
              returnsNormally,
              reason: label,
            );
            expect(rx, {'k': 1}, reason: label);
          }
        }
      },
    );
  });

  group('unmodifiable is forever', () {
    // The dual invariant. `_expectListRejects` already asserts this per
    // operation; these tests state it once more as the standalone property,
    // including for the `assign`/`assignAll` seam, which is the *only* way an
    // unmodifiable backing is ever legitimately replaced.
    test('a rejected RxList mutation never swaps the backing', () {
      for (final backing in _unmodifiableListBackings.entries) {
        for (final op in [..._listOps, ..._listSequences]) {
          if (op.unmod == _Unmod.succeeds) continue;
          final label = '${op.name} on ${backing.key}';
          final original = backing.value();
          final rx = RxList<int>(original);
          try {
            op.run(rx);
          } on UnsupportedError {
            // Expected; asserted exhaustively by the rejection group above.
          }
          expect(
            identical(rx.value, original),
            isTrue,
            reason: '$label: the probe must have had no side effect',
          );
          expect(() => rx.add(999), throwsUnsupportedError, reason: label);
          expect(rx, _listSeed, reason: label);
        }
      }
    });

    test('a rejected RxSet/RxMap mutation never swaps the backing', () {
      for (final backing in _unmodifiableSetBackings.entries) {
        for (final op in [..._setOps, ..._setSequences]) {
          if (op.unmod == _Unmod.succeeds) continue;
          final original = backing.value();
          final rx = RxSet<int>(original);
          try {
            op.run(rx);
          } on UnsupportedError {
            // Expected.
          }
          expect(identical(rx.value, original), isTrue, reason: op.name);
          expect(() => rx.add(999), throwsUnsupportedError, reason: op.name);
        }
      }
      for (final backing in _unmodifiableMapBackings.entries) {
        for (final op in [..._mapOps, ..._mapSequences]) {
          if (op.unmod == _Unmod.succeeds) continue;
          final original = backing.value();
          final rx = RxMap<String, int>(original);
          try {
            op.run(rx);
          } on UnsupportedError {
            // Expected.
          }
          expect(identical(rx.value, original), isTrue, reason: op.name);
          expect(() => rx['zz'] = 1, throwsUnsupportedError, reason: op.name);
        }
      }
    });

    test('assign/assignAll is the only escape, and it is a fresh backing', () {
      final backing = List<int>.unmodifiable(_listSeed);
      final rx = RxList<int>(backing);

      expect(() => rx.add(4), throwsUnsupportedError);
      rx.assignAll([7, 8]);

      expect(
        identical(rx.value, backing),
        isFalse,
        reason: 'assignAll publishes a new, growable backing list',
      );
      expect(backing, _listSeed, reason: 'the old backing is untouched');
      // And from here on the RxList is an ordinary growable one.
      expect(() => rx.add(9), returnsNormally);
      expect(rx, [7, 8, 9]);
    });
  });

  // ---------------------------------------------------------------------
  // 4. Aliasing: heal exactly when required and never more.
  // ---------------------------------------------------------------------

  group('aliasing and copying are only as aggressive as they must be', () {
    test('a growable backing is still mutated in place', () {
      final backing = <int>[1, 2, 3];
      final rx = RxList<int>(backing);

      rx.add(4);
      rx.sort((a, b) => b.compareTo(a));

      expect(identical(rx.value, backing), isTrue);
      expect(backing, [4, 3, 2, 1]);
    });

    test('a fixed-length backing is still written in place by element ops', () {
      final backing = List<int>.of(_listSeed, growable: false);
      final rx = RxList<int>(backing);

      rx.sort((a, b) => b.compareTo(a));
      rx[2] = 0;
      rx.shuffle(Random(1));
      rx.fillRange(0, 1, 5);
      rx.setAll(1, [6]);
      rx.setRange(2, 3, [7]);

      expect(
        identical(rx.value, backing),
        isTrue,
        reason: 'element writes must not detach a fixed-length backing',
      );
      expect(rx, backing, reason: 'the writes landed in the caller list');
    });

    test('a Uint8List backing stays aliased under element writes', () {
      // The canonical "fixed-length but very much writable" buffer.
      final backing = Uint8List.fromList(_listSeed);
      final rx = RxList<int>(backing);

      rx[0] = 9;
      rx.sort();
      rx.fillRange(0, 1, 4);

      expect(identical(rx.value, backing), isTrue);
      expect(backing, [4, 3, 9]);

      // ...and heals, detaching, on the first length change.
      rx.add(5);
      expect(identical(rx.value, backing), isFalse);
      expect(backing, [4, 3, 9], reason: 'the buffer is left as it was');
      expect(rx, [4, 3, 9, 5]);
    });

    test('a length change detaches a fixed-length backing exactly once', () {
      final backing = List<int>.of(_listSeed, growable: false);
      final rx = RxList<int>(backing);

      rx.add(4);
      final swapped = rx.value;
      rx.add(5);

      expect(backing, _listSeed, reason: 'the caller list must be untouched');
      expect(
        identical(rx.value, swapped),
        isTrue,
        reason: 'the growable copy must be reused, not re-copied',
      );
      expect(rx, [1, 2, 3, 4, 5]);
    });

    test('an unmodifiable backing is never written to, and never swapped', () {
      final source = <int>[1, 2, 3];
      final backing = List<int>.unmodifiable(source);
      final rx = RxList<int>(backing);
      final notifications = _watch(rx);

      expect(() => rx.sort((a, b) => b.compareTo(a)), throwsUnsupportedError);
      expect(() => rx.add(4), throwsUnsupportedError);
      expect(() => rx[0] = 9, throwsUnsupportedError);

      expect(backing, [1, 2, 3]);
      expect(source, [1, 2, 3]);
      expect(rx, [1, 2, 3]);
      expect(identical(rx.value, backing), isTrue);
      expect(notifications(), 0);
    });

    test('an unmodifiable set/map backing is never written to', () {
      final setBacking = Set<int>.unmodifiable(_setSeed);
      final mapBacking = Map<String, int>.unmodifiable(_mapSeed);
      final rxSet = RxSet<int>(setBacking);
      final rxMap = RxMap<String, int>(mapBacking);
      final setNotifications = _watch(rxSet);
      final mapNotifications = _watch(rxMap);

      expect(() => rxSet.add(4), throwsUnsupportedError);
      expect(() => rxMap['c'] = 3, throwsUnsupportedError);

      expect(setBacking, _setSeed);
      expect(mapBacking, _mapSeed);
      expect(rxSet, _setSeed);
      expect(rxMap, _mapSeed);
      expect(identical(rxSet.value, setBacking), isTrue);
      expect(identical(rxMap.value, mapBacking), isTrue);
      expect(setNotifications(), 0);
      expect(mapNotifications(), 0);
    });
  });

  // ---------------------------------------------------------------------
  // 5. Errors are never swallowed, on either path.
  // ---------------------------------------------------------------------

  group('failures are reported, not swallowed', () {
    test('an UnsupportedError from a user comparator propagates', () {
      for (final backing in _equivalentListBackings.entries) {
        final rx = RxList<int>(backing.value());
        final notifications = _watch(rx);

        expect(
          () => rx.sort((a, b) => throw UnsupportedError('from the callback')),
          throwsUnsupportedError,
          reason: backing.key,
        );
        // Only the capability probes may catch an UnsupportedError.
        expect(notifications(), 0, reason: backing.key);
      }
    });

    test('an unmodifiable backing refuses sort before the comparator runs', () {
      for (final backing in _unmodifiableListBackings.entries) {
        final rx = RxList<int>(backing.value());
        final notifications = _watch(rx);
        var comparatorCalls = 0;

        expect(
          () => rx.sort((a, b) {
            comparatorCalls++;
            return a.compareTo(b);
          }),
          throwsUnsupportedError,
          reason: backing.key,
        );
        expect(comparatorCalls, 0, reason: backing.key);
        expect(notifications(), 0, reason: backing.key);
        expect(rx, _listSeed, reason: backing.key);
      }
    });

    test('a throwing predicate leaves the list untouched', () {
      for (final backing in _equivalentListBackings.entries) {
        final rx = RxList<int>(backing.value());
        final notifications = _watch(rx);

        expect(
          () => rx.removeWhere((e) => throw StateError('boom')),
          throwsStateError,
          reason: backing.key,
        );
        expect(rx, _listSeed, reason: backing.key);
        expect(notifications(), 0, reason: backing.key);
      }
    });

    test('a throwing predicate over an unmodifiable list never runs', () {
      for (final backing in _unmodifiableListBackings.entries) {
        final rx = RxList<int>(backing.value());
        final notifications = _watch(rx);

        // The backing refuses first, so the StateError is never reached.
        expect(
          () => rx.removeWhere((e) => throw StateError('boom')),
          throwsUnsupportedError,
          reason: backing.key,
        );
        expect(rx, _listSeed, reason: backing.key);
        expect(notifications(), 0, reason: backing.key);
      }
    });

    test('a throwing map callback leaves the map untouched', () {
      for (final backing in _equivalentMapBackings.entries) {
        final rx = RxMap<String, int>(backing.value());
        final notifications = _watch(rx);

        expect(
          () => rx.updateAll((key, value) => throw StateError('boom')),
          throwsStateError,
          reason: backing.key,
        );
        expect(rx, _mapSeed, reason: backing.key);
        expect(notifications(), 0, reason: backing.key);
      }
    });

    test('an unmodifiable map refuses updateAll before the callback runs', () {
      for (final backing in _unmodifiableMapBackings.entries) {
        final rx = RxMap<String, int>(backing.value());
        final notifications = _watch(rx);

        expect(
          () => rx.updateAll((key, value) => throw StateError('boom')),
          throwsUnsupportedError,
          reason: backing.key,
        );
        expect(rx, _mapSeed, reason: backing.key);
        expect(notifications(), 0, reason: backing.key);
      }
    });
  });

  // ---------------------------------------------------------------------
  // 6. The copies that do happen keep the backing's runtime element type.
  // ---------------------------------------------------------------------

  group('covariance survives the copy', () {
    test('a healed fixed-length List<int> backing still rejects a double', () {
      for (final backing in <String, List<num> Function()>{
        'List.of growable: false': () =>
            List<int>.of(_listSeed, growable: false),
        'Uint8List': () => Uint8List.fromList(_listSeed),
      }.entries) {
        final rx = RxList<num>(backing.value());

        rx.removeAt(0);

        expect(rx, [2, 3], reason: backing.key);
        expect(
          () => rx.add(0.5),
          throwsA(isA<TypeError>()),
          reason: '${backing.key}: the copy must keep the runtime element type',
        );
      }
    });

    test('an assignAll copy of a List<int> backing still rejects a double', () {
      final rx = RxList<num>(List<int>.unmodifiable(_listSeed));

      // The mutator path is closed...
      expect(() => rx.removeAt(0), throwsUnsupportedError);
      // ...but assignAll replaces the contents wholesale, and its copy keeps
      // the backing's runtime element type just like the healing copy does —
      // so the copy is a List<int> and refuses a List<num> outright.
      expect(() => rx.assignAll(<num>[2, 3]), throwsA(isA<TypeError>()));
      rx.assignAll(<int>[2, 3]);

      expect(rx, [2, 3]);
      expect(() => rx.add(0.5), throwsA(isA<TypeError>()));
    });

    test('an assignAll copy of a Set<int> backing still rejects a double', () {
      final rx = RxSet<num>(Set<int>.unmodifiable(_setSeed));

      expect(() => rx.remove(1), throwsUnsupportedError);
      expect(() => rx.assignAll(<num>{2, 3}), throwsA(isA<TypeError>()));
      rx.assignAll(<int>{2, 3});

      expect(rx, {2, 3});
      expect(() => rx.add(0.5), throwsA(isA<TypeError>()));
    });
  });

  // ---------------------------------------------------------------------
  // 7. Nested Rx backings and the broadcast stream.
  // ---------------------------------------------------------------------

  group('nested Rx backings are short-circuited, not probed', () {
    test('mutating the outer list notifies the inner one exactly once', () {
      final inner = RxList<int>(_growableSeed());
      final outer = RxList<int>(inner);
      final innerCount = _watch(inner);
      final outerCount = _watch(outer);

      outer.add(4);
      outer.sort((a, b) => b.compareTo(a));

      expect(outer, [4, 3, 2, 1]);
      expect(inner, [4, 3, 2, 1]);
      expect(outerCount(), 2);
      expect(innerCount(), 2, reason: 'the probes must not notify');
    });

    test('an inner RxList applies its own policy to the outer mutation', () {
      // The outer list short-circuits the probes and hands the action to the
      // inner RxList, which heals or throws exactly as it would standalone.
      final healing = RxList<int>(RxList<int>(List<int>.empty()));
      healing.add(1);
      expect(healing, [1]);

      final frozen = RxList<int>(
        RxList<int>(List<int>.unmodifiable(_listSeed)),
      );
      expect(() => frozen.add(4), throwsUnsupportedError);
      expect(frozen, _listSeed);
    });

    test('mutating the outer set/map notifies the inner one exactly once', () {
      final innerSet = RxSet<int>(_mutableSeed());
      final outerSet = RxSet<int>(innerSet);
      final innerSetCount = _watch(innerSet);
      outerSet.add(4);
      expect(innerSetCount(), 1);

      final innerMap = RxMap<String, int>(_mutableMapSeed());
      final outerMap = RxMap<String, int>(innerMap);
      final innerMapCount = _watch(innerMap);
      outerMap['c'] = 3;
      expect(innerMapCount(), 1);
    });
  });

  group('the broadcast stream agrees with the listener count', () {
    test('one stream event per mutation of a fixed-length backing', () async {
      final RxList<int> rx = List<int>.empty().obs;
      var events = 0;
      rx.listen((_) => events++);
      // The stream event *is* the live backing list, and the broadcast
      // controller delivers in a later microtask, so every delivered event
      // points at the same (final) list. Snapshot synchronously instead.
      final snapshots = <List<int>>[];
      rx.addListener(() => snapshots.add(rx.toList()));

      rx.insert(0, 1);
      rx.insert(0, 2);
      rx.clear();
      await Future<void>.delayed(Duration.zero);

      expect(events, 3);
      expect(snapshots, [
        [1],
        [2, 1],
        <int>[],
      ]);
    });

    test('one stream event per mutation of a mutable map', () async {
      final rx = RxMap<String, int>(_mutableMapSeed());
      var events = 0;
      rx.listen((_) => events++);

      rx['c'] = 3;
      rx.remove('a');
      await Future<void>.delayed(Duration.zero);

      expect(events, 2);
      expect(rx, {'b': 2, 'c': 3});
    });

    test('a rejected mutation produces no stream event at all', () async {
      final rx = RxMap<String, int>(Map<String, int>.unmodifiable(_mapSeed));
      var events = 0;
      rx.listen((_) => events++);

      expect(() => rx['c'] = 3, throwsUnsupportedError);
      expect(() => rx.remove('a'), throwsUnsupportedError);
      expect(() => rx.clear(), throwsUnsupportedError);
      await Future<void>.delayed(Duration.zero);

      expect(events, 0);
      expect(rx, _mapSeed);
    });

    test(
      'assignAll over an unmodifiable backing emits exactly one event',
      () async {
        final rx = RxMap<String, int>(Map<String, int>.unmodifiable(_mapSeed));
        var events = 0;
        rx.listen((_) => events++);

        rx.assignAll({'z': 9});
        await Future<void>.delayed(Duration.zero);

        expect(events, 1);
        expect(rx, {'z': 9});
      },
    );
  });
}
