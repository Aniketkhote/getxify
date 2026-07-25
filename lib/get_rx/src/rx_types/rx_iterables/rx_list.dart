part of '../rx_types.dart';

/// Create a list similar to `List<T>` but reactive.
///
/// ## Healing a fixed-length backing list
///
/// An `RxList` wraps ("aliases") whatever list it is built from, so the
/// backing list may well be one that refuses length changes. `List.empty()`
/// and `List.filled()` are **fixed-length** by default, and
/// `List<T>.empty().obs` is a very common way to spell "an empty reactive
/// list" — after which the first `add`/`insert` used to blow up with
/// `Unsupported operation: Cannot add to a fixed-length list` deep inside
/// `dart:core`.
///
/// A fixed-length list carries no *immutability intent*: it is simply a list
/// whose length happens to be fixed, and `growable: false` being the default
/// on `List.empty()`/`List.filled()` is an accident of the `dart:core` API,
/// not a decision the caller made. So a length-changing mutator on a
/// fixed-length backing **heals**: the backing is transparently replaced with
/// a growable copy, the mutation is applied to that copy, and listeners are
/// notified exactly once.
///
/// An **unmodifiable** backing (`List.unmodifiable`, `const []`,
/// `UnmodifiableListView`) is the opposite: it is an explicit opt-in to
/// immutability. It is left alone. Every mutation still throws
/// [UnsupportedError] from the backing itself, exactly as it always has —
/// silently healing it would delete a guard the caller deliberately put in
/// place, with no compile error to warn them.
///
/// ## The aliasing contract, precisely
///
/// | backing      | element write (`[]=`, `sort`, …) | length change (`add`, `clear`, …) |
/// |--------------|----------------------------------|-----------------------------------|
/// | growable     | in place, stays aliased          | in place, stays aliased           |
/// | fixed-length | in place, stays aliased          | **heals** (detaches to a copy)    |
/// | unmodifiable | **throws** `UnsupportedError`    | **throws** `UnsupportedError`     |
///
/// Three consequences to be aware of:
///
/// * A length change on a fixed-length backing **permanently** detaches this
///   `RxList` from it — even one that changes nothing, such as a `removeWhere`
///   that matches no element. Element writes made before that call landed in
///   the caller's list; element writes made after it do not, because from then
///   on the `RxList` owns a growable copy. If you need writes to keep reaching
///   a fixed-length buffer (a `Uint8List`, say), keep a reference to it and
///   never call a length-changing member on the `RxList`.
/// * Healing changes which exception a still-illegal operation reports,
///   because it now fails against the copy rather than against the backing:
///   `RxList<int>(List.filled(3, 0)).length = 5` throws `TypeError` (you
///   cannot pad a non-nullable list with nulls) where it used to throw
///   `UnsupportedError`.
/// * Element writes need no healing at all: a fixed-length list already
///   accepts them in place, and an unmodifiable one already rejects them.
///   They are plain in-place mutations followed by a single notification.
///
/// Two caveats on the "unmodifiable throws" row.
///
/// The first is `shuffle`: with fewer than two elements it has nothing to
/// swap, so it returns without asking the backing to write anything and never
/// reaches the point of being refused. That is what the inherited
/// `ListMixin.shuffle` always did, and this class keeps it.
///
/// The second is that an *empty* backing cannot always be told apart from an
/// empty fixed-length one, because there is no element to attempt a write
/// against. Two empty shapes are therefore healed rather than honoured — a
/// `ListBase` subclass that rejects mutation only through `length=`/`[]=`, and
/// an unmodifiable typed-data view over a zero-length buffer
/// (`Uint8List(0).asUnmodifiableView()`). Neither can hold data, so nothing is
/// at risk of being overwritten. Every `dart:core` unmodifiable list is
/// classified correctly whether empty or not, as is an unmodifiable
/// typed-data view over a buffer with at least one byte in it.
///
/// ### The documented exception: `assign` / `assignAll`
///
/// [ListExtension.assign] and [ListExtension.assignAll] work over **any**
/// backing, unmodifiable included — they publish a fresh growable list rather
/// than mutating the current one. This is intentional, not an oversight: they
/// *replace the contents wholesale*, so which list object happened to be
/// holding the old contents is an implementation detail with nothing left to
/// protect. `add`/`insert`/`clear`, by contrast, mutate a collection the
/// caller declared unmodifiable, so they must keep throwing.
///
/// ## Note for implementors
///
/// The two capability probes ([_canChangeLength] and [_canWriteElements]) are
/// deliberately different and the difference is load-bearing: together they
/// tell *fixed-length* (heals) from *unmodifiable* (throws). Collapsing them
/// into one probe would either heal unmodifiable backings or stop healing
/// fixed-length ones. Please do not "optimise" them away.
///
/// Probing is itself a write (`length = length`, `list[0] = list[0]`), so a
/// backing list that observes writes — one that logs, marks itself dirty or
/// persists — sees extra no-op writes: one `length=` per length-changing call
/// on a growable backing, plus one element write when that first probe fails.
/// Element operations never probe. Nested `RxList` backings are
/// short-circuited so they never see any of it.
class RxList<E> extends GetListenable<List<E>>
    with ListMixin<E>, RxObjectMixin<List<E>> {
  RxList([List<E>? initial]) : super(initial ?? <E>[]);

  /// Creates a list of the given [length] with [fill] at every position.
  ///
  /// With `growable: false` (the default) the backing list is fixed-length,
  /// which carries no immutability intent: the first length-changing mutation
  /// heals it by swapping in a growable copy, permanently detaching this
  /// `RxList` from the fixed-length buffer. Element writes go to that buffer
  /// in place until then. See the class documentation.
  factory RxList.filled(int length, E fill, {bool growable = false}) {
    return RxList(List.filled(length, fill, growable: growable));
  }

  /// Creates an empty list.
  ///
  /// As with [RxList.filled], `growable: false` (the default) only picks a
  /// fixed-length *initial* backing list — the returned [RxList] can still be
  /// added to, and heals itself on the first `add`/`insert`/`clear`.
  factory RxList.empty({bool growable = false}) {
    return RxList(List.empty(growable: growable));
  }

  /// Creates a list containing all [elements].
  factory RxList.from(Iterable elements, {bool growable = true}) {
    return RxList(List.from(elements, growable: growable));
  }

  /// Creates a list from [elements].
  factory RxList.of(Iterable<E> elements, {bool growable = true}) {
    return RxList(List.of(elements, growable: growable));
  }

  /// Generates a list of values.
  factory RxList.generate(
    int length,
    E Function(int index) generator, {
    bool growable = true,
  }) {
    return RxList(List.generate(length, generator, growable: growable));
  }

  /// Creates an unmodifiable list containing all [elements].
  ///
  /// Unlike a fixed-length backing, an unmodifiable one is never healed: an
  /// [RxList] built this way genuinely rejects mutation. `add`, `insert`,
  /// `clear`, `[]=`, `sort` and friends all throw [UnsupportedError] from the
  /// backing list, and the `RxList` is left untouched.
  ///
  /// The one documented exception is [ListExtension.assign] /
  /// [ListExtension.assignAll], which replace the contents wholesale by
  /// publishing a new growable backing list — see the class documentation for
  /// why that is intended.
  factory RxList.unmodifiable(Iterable elements) {
    return RxList(List.unmodifiable(elements));
  }

  /// Whether [list] accepts length changes (`add`, `insert`, `remove`,
  /// `clear`, `length=`, `replaceRange`).
  ///
  /// Probed rather than type-checked so third-party list implementations are
  /// classified correctly too: `length = length` is a no-op on a growable
  /// list and throws [UnsupportedError] on a fixed-length or unmodifiable
  /// one. Only the probe is wrapped in a `catch` — never the real mutation,
  /// whose [UnsupportedError]s (e.g. from a user callback) must propagate.
  ///
  /// The probe is *total*: any other error means "cannot classify", and the
  /// answer is then `true`, which routes to the in-place branch — exactly what
  /// happened before healing existed. A partial `ListBase` whose `length=`
  /// throws a `StateError`/`UnimplementedError` but whose `add` works must not
  /// be broken by a no-op write the caller never asked for.
  ///
  /// It does assume that a list which refuses length changes refuses this one
  /// too. Every `dart:core` fixed-length list does — `FixedLengthListMixin`
  /// rejects the setter outright, without looking at the value. A third-party
  /// list that tolerates `length = length` while rejecting real length changes
  /// would be classified growable and never heal; it would simply keep
  /// throwing, as it did before healing existed.
  static bool _canChangeLength<T>(List<T> list) {
    // Short-circuit a nested RxList: probing through it would notify its own
    // listeners for every mutation of the outer list. Claiming `true` is also
    // the right answer — the inner RxList applies its own three-way policy to
    // the action, healing or throwing exactly as it would on its own.
    if (list is RxList) return true;
    try {
      list.length = list.length;
      return true;
    } on UnsupportedError {
      return false;
    } catch (_) {
      return true;
    }
  }

  /// Whether [list] accepts in-place element writes (`[]=`, `sort`,
  /// `shuffle`, `setAll`, `setRange`, `fillRange`).
  ///
  /// This is strictly weaker than [_canChangeLength], and that gap is the
  /// whole point of the probe: a *fixed-length* list happily overwrites its
  /// elements, only an *unmodifiable* one refuses. So for a backing that has
  /// already failed [_canChangeLength], this is what discriminates the two —
  /// `true` means fixed-length (heal it), `false` means the caller opted into
  /// immutability (let the backing throw). Element operations themselves
  /// never consult it: they are plain in-place mutations, correct on both
  /// kinds of backing without any help.
  ///
  /// Probed rather than type-checked, for the same reason as
  /// [_canChangeLength], and with the same rule about the `catch`. This probe
  /// is total too, but "cannot classify" answers `false` here: `false` routes
  /// to the branch that runs the action straight against the backing, which is
  /// the pre-healing behaviour that an unclassifiable backing should keep.
  ///
  /// ### The empty-list hole
  ///
  /// An empty list has no element to overwrite, so `[]=` cannot be probed and
  /// the empty branch below stands in for it. That branch is exact for every
  /// `dart:core` unmodifiable list and for typed-data views over a non-empty
  /// buffer, but two shapes remain genuinely indistinguishable from an empty
  /// fixed-length list, and both **heal**:
  ///
  /// * a `ListBase` subclass that rejects mutation only through `length=` and
  ///   `[]=` — `ListMixin.setRange` returns early for a vacuous range without
  ///   ever reaching `[]=`;
  /// * an unmodifiable typed-data view over a zero-length buffer
  ///   (`Uint8List(0).asUnmodifiableView()`) — there is no byte anywhere to
  ///   attempt a write against.
  ///
  /// Neither can hold data, so nothing is at risk of being overwritten; the
  /// cost is that an empty immutability marker is not honoured. Documented
  /// rather than papered over — see the class documentation.
  static bool _canWriteElements<T>(List<T> list) {
    // Defensive: unreachable while [_canChangeLength] short-circuits a nested
    // RxList to `true`, but it keeps the two probes independently correct.
    if (list is RxList) return true;
    if (list.isEmpty) {
      // Typed data first: `_UnmodifiableUint8ArrayView` and friends only
      // reject writes that actually touch an element, so they accept a vacuous
      // `setRange` and the generic branch below would misread them as
      // fixed-length. Their underlying buffer does not lie, so probe that
      // instead — a no-op write of a byte back over itself, which leaves the
      // buffer's contents untouched.
      if (list is TypedData) {
        try {
          final bytes = (list as TypedData).buffer.asUint8List();
          if (bytes.isNotEmpty) {
            bytes[0] = bytes[0];
            return true;
          }
          // Zero-length buffer: nothing to probe, and nothing to protect
          // either. Heal, so that the common `RxList(Uint8List(0))` works and
          // so that the answer is the same on the VM and on the web.
          return true;
        } on UnsupportedError {
          return false;
        } catch (_) {
          return false;
        }
      }
      // There is no element to overwrite, so `[]=` cannot be probed. This
      // branch decides the fate of the single most common case there is —
      // `List<T>.empty().obs` then `.add(...)` — so it has to be exactly
      // right: a `dart:core` unmodifiable list throws even for a vacuous
      // range, while a fixed-length one accepts it, which is precisely the
      // distinction wanted. Answering `false` here (or falling back to
      // [_canChangeLength], which is `false` for fixed-length too) would make
      // `List.empty().obs.add(x)` throw again.
      try {
        list.setRange(0, 0, const []);
        return true;
      } on UnsupportedError {
        return false;
      } catch (_) {
        return false;
      }
    }
    try {
      list[0] = list[0];
      return true;
    } on UnsupportedError {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Applies a length-changing [action] to the backing list. Three-way:
  ///
  /// * growable backing — mutate in place, notify once;
  /// * fixed-length backing (refuses length changes but accepts element
  ///   writes) — heal it: run [action] against a growable copy and publish
  ///   that copy, notifying once;
  /// * unmodifiable backing — run [action] straight against it so the
  ///   backing's own [UnsupportedError] propagates untouched, leaving this
  ///   `RxList` unchanged and un-notified.
  R _mutateLength<R>(R Function(List<E> list) action) {
    final current = value;
    if (_canChangeLength(current)) {
      final result = action(current);
      refresh();
      return result;
    }
    if (_canWriteElements(current)) {
      // Fixed-length: no immutability intent, so heal it.
      return _mutateCopy(current, action);
    }
    // Unmodifiable: an explicit opt-in to immutability. Do not synthesise or
    // wrap an error — just perform the mutation and let the real one out. The
    // refresh is for the (pathological) backing that refuses `length=` yet
    // accepts this particular action; it keeps such a list behaving as it did
    // before healing existed.
    final result = action(current);
    refresh();
    return result;
  }

  /// Runs [action] on a growable copy of [current] and publishes the copy as
  /// the new backing list, notifying listeners exactly once.
  R _mutateCopy<R>(List<E> current, R Function(List<E> list) action) {
    // toList() always returns a growable list, and reifies the *backing*
    // list's runtime element type, so covariance keeps behaving as it did
    // before the copy (this is what `assign`/`assignAll` rely on too).
    final copy = current.toList();
    // Run the action before publishing: if it throws (a RangeError, a
    // TypeError, an exception from a user callback...) the copy is dropped
    // and this RxList keeps its previous state.
    final result = action(copy);
    // [forceValue], never `value = copy`: the `value` setter short-circuits
    // when the old backing reports itself `==` to the copy, and a `List`
    // subclass with a content-insensitive `==` would then have the swap — and
    // with it the mutation just applied to the copy — silently dropped while
    // still looking like it succeeded. A backing replacement is not a value
    // change, so the equality gate must not apply to it.
    forceValue(copy);
    // [forceValue] notifies exactly once, unless it refused the swap because
    // this Rx is disposed. The backing is then still [current], so notify from
    // here instead, like the in-place branch does — including the "used after
    // dispose" assert it trips, which the in-place branch and RxSet/RxMap also
    // trip.
    //
    // The test is `identical(value, current)`, never `!identical(value, copy)`:
    // a listener that reassigns `value` while the notification is fanning out
    // would make the latter true and notify a second time.
    if (identical(value, current)) refresh();
    return result;
  }

  @override
  Iterator<E> get iterator => value.iterator;

  @override
  void operator []=(int index, E val) {
    // No healing: a fixed-length backing accepts element writes in place, an
    // unmodifiable one throws on its own. See the class documentation.
    value[index] = val;
    refresh();
  }

  /// Special override to push() element(s) in a reactive way
  /// inside the List.
  @override
  RxList<E> operator +(Iterable<E> val) {
    addAll(val);
    return this;
  }

  @override
  E operator [](int index) {
    return value[index];
  }

  @override
  void add(E element) {
    _mutateLength((list) => list.add(element));
  }

  @override
  void addAll(Iterable<E> iterable) {
    _mutateLength((list) => list.addAll(iterable));
  }

  @override
  bool remove(Object? element) {
    return _mutateLength((list) => list.remove(element));
  }

  @override
  void removeWhere(bool Function(E element) test) {
    _mutateLength((list) => list.removeWhere(test));
  }

  @override
  void retainWhere(bool Function(E element) test) {
    _mutateLength((list) => list.retainWhere(test));
  }

  @override
  int get length => value.length;

  @override
  set length(int newLength) {
    _mutateLength((list) => list.length = newLength);
  }

  @override
  void clear() {
    _mutateLength((list) => list.clear());
  }

  @override
  E removeAt(int index) {
    return _mutateLength((list) => list.removeAt(index));
  }

  @override
  E removeLast() {
    return _mutateLength((list) => list.removeLast());
  }

  @override
  void removeRange(int start, int end) {
    _mutateLength((list) => list.removeRange(start, end));
  }

  @override
  void insert(int index, E element) {
    _mutateLength((list) => list.insert(index, element));
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    _mutateLength((list) => list.insertAll(index, iterable));
  }

  @override
  Iterable<E> get reversed => value.reversed;

  @override
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    value.setRange(start, end, iterable, skipCount);
    refresh();
  }

  @override
  void fillRange(int start, int end, [E? fill]) {
    value.fillRange(start, end, fill);
    refresh();
  }

  @override
  void replaceRange(int start, int end, Iterable<E> newContents) {
    // On the length path even when `end - start == newContents.length`:
    // FixedLengthListMixin.replaceRange rejects it unconditionally, with
    // "Cannot remove from a fixed-length list". Verified, not assumed.
    _mutateLength((list) => list.replaceRange(start, end, newContents));
  }

  @override
  void setAll(int index, Iterable<E> iterable) {
    value.setAll(index, iterable);
    refresh();
  }

  @override
  Iterable<E> where(bool Function(E) test) {
    return value.where(test);
  }

  @override
  Iterable<T> whereType<T>() {
    return value.whereType<T>();
  }

  @override
  void sort([int Function(E a, E b)? compare]) {
    value.sort(compare);
    refresh();
  }

  /// Overridden only to collapse the notifications: `ListMixin.shuffle`
  /// swaps elements through `[]=`, which would notify `2 * (length - 1)`
  /// times. Delegating to the backing list notifies once instead — and once
  /// even for a list of 0 or 1 elements, where the inherited version made no
  /// swaps and so notified not at all.
  ///
  /// [random] is intentionally left unannotated: this library does not import
  /// `dart:math`, so `Random?` cannot be named here — override inference
  /// copies the type straight from `ListMixin.shuffle`, keeping the public
  /// signature identical.
  @override
  void shuffle([random]) {
    // A list of 0 or 1 elements has nothing to swap. The inherited version
    // returned without touching `[]=` at all, so it did not throw on an
    // unmodifiable backing; `List.shuffle` does throw there, unconditionally.
    // Return early to keep `const <T>[].obs.shuffle()` working as it always
    // has, while still emitting this override's single notification.
    if (value.length < 2) {
      refresh();
      return;
    }
    value.shuffle(random);
    refresh();
  }
}

extension ListExtension<E> on List<E> {
  RxList<E> get obs => RxList<E>(this);

  /// Add [item] to [List<E>] only if [item] is not null.
  void addNonNull(E item) {
    if (item != null) add(item);
  }

  /// Add [item] to [List<E>] only if [condition] is true.
  void addIf(Object? condition, E item) {
    if (condition is Condition) condition = condition();
    if (condition is bool && condition) add(item);
  }

  /// Adds [Iterable<E>] to [List<E>] only if [condition] is true.
  void addAllIf(Object? condition, Iterable<E> items) {
    if (condition is Condition) condition = condition();
    if (condition is bool && condition) addAll(items);
  }

  /// Replaces all existing items of this list with [item]
  ///
  /// On an [RxList] the backing list is replaced with a fresh growable
  /// list rather than mutated in place, so this works even when the list
  /// was created from a fixed-length or unmodifiable source (e.g.
  /// `List.empty().obs` or `const [].obs`), and listeners are notified
  /// exactly once.
  void assign(E item) {
    if (this is RxList) {
      final rx = this as RxList;
      // toList() preserves the backing list's runtime element type while
      // always producing a growable, mutable copy.
      rx.value = rx.value.toList()
        ..clear()
        ..add(item);
    } else {
      clear();
      add(item);
    }
  }

  /// Replaces all existing items of this list with [items]
  ///
  /// On an [RxList] the backing list is replaced with a fresh growable
  /// list rather than mutated in place, so this works even when the list
  /// was created from a fixed-length or unmodifiable source (e.g.
  /// `List.empty().obs` or `const [].obs`), and listeners are notified
  /// exactly once.
  void assignAll(Iterable<E> items) {
    if (this is RxList) {
      final rx = this as RxList;
      rx.value = rx.value.toList()
        ..clear()
        ..addAll(items);
    } else {
      clear();
      addAll(items);
    }
  }
}
