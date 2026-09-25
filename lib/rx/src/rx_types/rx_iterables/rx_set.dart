import 'dart:collection';

import '../../../../state_manager/src/controllers/rx_notifier.dart';
import '../rx_types.dart';

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
