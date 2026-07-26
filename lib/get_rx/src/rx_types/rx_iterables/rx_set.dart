part of '../rx_types.dart';

/// Create a set similar to `Set<T>` but reactive.
class RxSet<E> extends GetListenable<Set<E>>
    with SetMixin<E>, RxObjectMixin<Set<E>> {
  RxSet([Set<E>? initial]) : super(initial ?? <E>{});

  factory RxSet.from(Iterable elements) {
    return RxSet(Set.from(elements));
  }

  /// Creates a [Set] from [elements].
  factory RxSet.of(Iterable<E> elements) {
    return RxSet(Set.of(elements));
  }

  /// Creates an unmodifiable set containing all [elements].
  factory RxSet.unmodifiable(Iterable<E> elements) {
    return RxSet(Set.unmodifiable(elements));
  }

  /// Creates an identity set with the default implementation, [LinkedHashSet].
  factory RxSet.identity() {
    return RxSet(Set.identity());
  }

  /// Special override to push() element(s) in a reactive way
  /// inside the Set.
  RxSet<E> operator +(Set<E> val) {
    addAll(val);
    return this;
  }

  void update(void Function(Iterable<E>? value) fn) {
    fn(value);
    refresh();
  }

  @override
  bool add(E value) {
    final hasAdded = this.value.add(value);
    if (hasAdded) {
      refresh();
    }
    return hasAdded;
  }

  @override
  bool contains(Object? element) {
    return value.contains(element);
  }

  @override
  Iterator<E> get iterator => value.iterator;

  @override
  int get length => value.length;

  @override
  E? lookup(Object? element) {
    return value.lookup(element);
  }

  @override
  bool remove(Object? value) {
    var hasRemoved = this.value.remove(value);
    if (hasRemoved) {
      refresh();
    }
    return hasRemoved;
  }

  @override
  Set<E> toSet() {
    return value.toSet();
  }

  @override
  void addAll(Iterable<E> elements) {
    value.addAll(elements);
    refresh();
  }

  @override
  void clear() {
    value.clear();
    refresh();
  }

  @override
  void removeAll(Iterable<Object?> elements) {
    value.removeAll(elements);
    refresh();
  }

  @override
  void retainAll(Iterable<Object?> elements) {
    value.retainAll(elements);
    refresh();
  }

  @override
  void retainWhere(bool Function(E) test) {
    value.retainWhere(test);
    refresh();
  }

  @override
  void removeWhere(bool Function(E) test) {
    value.removeWhere(test);
    refresh();
  }
}

extension SetExtension<E> on Set<E> {
  /// Wraps this set in an [RxSet].
  ///
  /// Unlike `List.obs` and `Map.obs`, which adopt the receiver as the backing
  /// collection, this **copies** into a fresh mutable set. Long-standing
  /// behaviour, kept for compatibility, but worth knowing: it means
  /// `Set.unmodifiable({1, 2}).obs` and `const {1, 2}.obs` produce a fully
  /// mutable [RxSet], where the list and map equivalents keep the caller's
  /// unmodifiable collection and go on rejecting mutation. Wrap the receiver
  /// explicitly — `RxSet(Set.unmodifiable({1, 2}))` — if you want the opt-in
  /// carried over.
  RxSet<E> get obs {
    return RxSet<E>(<E>{})..addAll(this);
  }

  /// Add [item] to [Set<E>] only if [condition] is true.
  void addIf(Object? condition, E item) {
    final isTrue = switch (condition) {
      bool b => b,
      Condition c => c(),
      _ => false,
    };
    if (isTrue) add(item);
  }

  /// Adds [Iterable<E>] to [Set<E>] only if [condition] is true.
  void addAllIf(Object? condition, Iterable<E> items) {
    final isTrue = switch (condition) {
      bool b => b,
      Condition c => c(),
      _ => false,
    };
    if (isTrue) addAll(items);
  }

  /// Replaces all existing items of this set with [item]
  ///
  /// On an [RxSet] the backing set is replaced with a fresh mutable set
  /// rather than mutated in place, so this works even when the set was
  /// created from an unmodifiable source (e.g. `const {}` or
  /// `Set.unmodifiable`), and listeners are notified exactly once.
  ///
  /// The copy is `toSet()` of the current backing, which always produces a
  /// mutable set and preserves as much of the backing as the backing exposes:
  /// its runtime element type always, and its ordering discipline only when
  /// the backing has one to preserve — `UnmodifiableSetView.toSet()` forwards
  /// to its source, so a view over a `SplayTreeSet` copies to a
  /// `SplayTreeSet`, comparator included. `Set.unmodifiable` and `const {}`
  /// forward too, but their source is already a plain insertion-ordered
  /// `LinkedHashSet`, so the copy is one as well and later additions append
  /// rather than sorting themselves in.
  void assign(E item) {
    if (this case final RxSet<E> rx) {
      rx.value = rx.value.toSet()
        ..clear()
        ..add(item);
    } else {
      clear();
      add(item);
    }
  }

  /// Replaces all existing items of this set with [items]
  ///
  /// On an [RxSet] the backing set is replaced with a fresh mutable set
  /// rather than mutated in place, so this works even when the set was
  /// created from an unmodifiable source (e.g. `const {}` or
  /// `Set.unmodifiable`), and listeners are notified exactly once.
  ///
  /// The copy has the same fidelity as the one described on [assign].
  void assignAll(Iterable<E> items) {
    if (this case final RxSet<E> rx) {
      rx.value = rx.value.toSet()
        ..clear()
        ..addAll(items);
    } else {
      clear();
      addAll(items);
    }
  }
}
