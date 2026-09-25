import 'dart:collection';

import '../../../../state_manager/src/controllers/rx_notifier.dart';
import '../rx_types.dart';

/// Create a map similar to `Map<K, V>` but reactive.
class RxMap<K, V> extends GetListenable<Map<K, V>>
    with MapMixin<K, V>, RxObjectMixin<Map<K, V>> {
  RxMap([Map<K, V>? initial]) : super(initial ?? <K, V>{});

  factory RxMap.from(Map<K, V> other) {
    return RxMap(Map.from(other));
  }

  /// Creates a [LinkedHashMap] with the same keys and values as [other].
  factory RxMap.of(Map<K, V> other) {
    return RxMap(Map.of(other));
  }

  /// Creates an unmodifiable hash based map containing the entries of [other].
  factory RxMap.unmodifiable(Map<Object?, Object?> other) {
    return RxMap(Map.unmodifiable(other));
  }

  /// Creates an identity map with the default implementation, [LinkedHashMap].
  factory RxMap.identity() {
    return RxMap(Map.identity());
  }

  /// Creates a [Map] where the keys and values are computed from [iterable].
  factory RxMap.fromIterable(
    Iterable iterable, {
    K Function(dynamic element)? key,
    V Function(dynamic element)? value,
  }) {
    return RxMap(Map.fromIterable(iterable, key: key, value: value));
  }

  /// Creates a [Map] associating the given [keys] to [values].
  factory RxMap.fromIterables(Iterable<K> keys, Iterable<V> values) {
    return RxMap(Map.fromIterables(keys, values));
  }

  /// Creates a [Map] from [entries].
  factory RxMap.fromEntries(Iterable<MapEntry<K, V>> entries) {
    return RxMap(Map.fromEntries(entries));
  }

  @override
  V? operator [](Object? key) {
    return value[key as K];
  }

  @override
  void operator []=(K key, V value) {
    this.value[key] = value;
    refresh();
  }

  @override
  void clear() {
    value.clear();
    refresh();
  }

  @override
  Iterable<K> get keys => value.keys;

  @override
  V? remove(Object? key) {
    final val = value.remove(key);
    refresh();
    return val;
  }

  @override
  void addAll(Map<K, V> other) {
    value.addAll(other);
    refresh();
  }

  @override
  void addEntries(Iterable<MapEntry<K, V>> newEntries) {
    value.addEntries(newEntries);
    refresh();
  }

  @override
  V putIfAbsent(K key, V Function() ifAbsent) {
    final hasKey = value.containsKey(key);
    final val = value.putIfAbsent(key, ifAbsent);
    if (!hasKey) {
      refresh();
    }
    return val;
  }

  @override
  V update(K key, V Function(V value) update, {V Function()? ifAbsent}) {
    final val = value.update(key, update, ifAbsent: ifAbsent);
    refresh();
    return val;
  }

  @override
  void updateAll(V Function(K key, V value) update) {
    value.updateAll(update);
    refresh();
  }

  @override
  void removeWhere(bool Function(K key, V value) test) {
    value.removeWhere(test);
    refresh();
  }
}
