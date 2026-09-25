import '../rx_types.dart';

extension ListExtension<E> on List<E> {
  RxList<E> get obs => RxList<E>(this);

  /// Add [item] to [List<E>] only if [condition] is true.
  void addNonNull(E item) {
    if (item != null) add(item);
  }

  /// Add [item] to [List<E>] only if [condition] is true.
  void addIf(Object? condition, E item) {
    if (evaluateCondition(condition)) add(item);
  }

  /// Adds [Iterable<E>] to [List<E>] only if [condition] is true.
  void addAllIf(Object? condition, Iterable<E> items) {
    if (evaluateCondition(condition)) addAll(items);
  }

  /// Replaces all existing items of this list with [item]
  ///
  /// On an [RxList] the backing list is replaced with a fresh growable
  /// list rather than mutated in place, so this works even when the list
  /// was created from a fixed-length or unmodifiable source (e.g.
  /// `List.empty().obs` or `const [].obs`), and listeners are notified
  /// exactly once.
  void assign(E item) {
    if (this case final RxList<E> rx) {
      rx.value = rx.value.take(0).toList()..add(item);
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
    if (this case final RxList<E> rx) {
      rx.value = rx.value.take(0).toList()..addAll(items);
    } else {
      clear();
      addAll(items);
    }
  }
}

extension MapExtension<K, V> on Map<K, V> {
  RxMap<K, V> get obs {
    return RxMap<K, V>(this);
  }

  /// Adds [key] and [value] to map if [condition] is true.
  void addIf(Object? condition, K key, V value) {
    if (evaluateCondition(condition)) {
      this[key] = value;
    }
  }

  /// Adds all [values] to map if [condition] is true.
  void addAllIf(Object? condition, Map<K, V> values) {
    if (evaluateCondition(condition)) addAll(values);
  }

  /// Replaces all existing items of this map with [key] and [val].
  void assign(K key, V val) {
    if (this is RxMap<K, V>) {
      (this as RxMap<K, V>).value = <K, V>{key: val};
    } else {
      clear();
      this[key] = val;
    }
  }

  /// Replaces all existing items of this map with [val].
  void assignAll(Map<K, V> val) {
    if (val is RxMap && this is RxMap) {
      if ((val as RxMap).value == (this as RxMap).value) return;
    }
    if (this is RxMap) {
      final map = (this as RxMap);
      if (map.value == val) return;
      // The value setter refreshes exactly once when the instance differs,
      // which the guard above already established.
      map.value = val;
    } else {
      if (this == val) return;
      clear();
      addAll(val);
    }
  }
}

extension SetExtension<E> on Set<E> {
  /// Wraps this set in an [RxSet].
  RxSet<E> get obs {
    return RxSet<E>(<E>{})..addAll(this);
  }

  /// Add [item] to [Set<E>] only if [condition] is true.
  void addIf(Object? condition, E item) {
    if (evaluateCondition(condition)) add(item);
  }

  /// Adds [Iterable<E>] to [Set<E>] only if [condition] is true.
  void addAllIf(Object? condition, Iterable<E> items) {
    if (evaluateCondition(condition)) addAll(items);
  }

  /// Replaces all existing items of this set with [item]
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
