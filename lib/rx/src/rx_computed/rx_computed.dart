import 'package:flutter/foundation.dart';

import '../../../state_manager/src/controllers/list_notifier.dart';
import '../../../state_manager/src/controllers/rx_notifier.dart';
import '../rx_types/rx_types.dart';

/// A reactive computed value that automatically tracks observed dependencies
/// and memoizes its result until dependencies change.
class RxComputed<T> extends GetListenable<T> with RxObjectMixin<T> {
  final T Function() _compute;
  final Set<Listenable> _dependencies = {};
  bool _isDirty = false;

  RxComputed._(this._compute, super.initialValue) : super();

  /// Creates a computed reactive value that tracks dependencies evaluated in [compute].
  static RxComputed<T> create<T>(T Function() compute) {
    final data = NotifyData(updater: () {}, throwException: false);
    final initial = Notifier.instance.append(data, compute);
    final instance = RxComputed<T>._(compute, initial);
    instance._trackDependencies(data.readNotifiers);
    return instance;
  }

  void _trackDependencies(Iterable<Listenable> newDeps) {
    for (final dep in _dependencies) {
      dep.removeListener(_onDependencyChanged);
    }
    _dependencies.clear();
    for (final dep in newDeps) {
      _dependencies.add(dep);
      dep.addListener(_onDependencyChanged);
    }
  }

  void _onDependencyChanged() {
    _isDirty = true;
    _recompute();
  }

  void _recompute() {
    if (isDisposed) return;
    final data = NotifyData(updater: () {}, throwException: false);
    final nextValue = Notifier.instance.append(data, _compute);
    _trackDependencies(data.readNotifiers);
    _isDirty = false;
    value = nextValue;
  }

  @override
  T get value {
    if (_isDirty) {
      _recompute();
    }
    reportRead();
    return super.value;
  }

  @override
  void close() {
    for (final dep in _dependencies) {
      dep.removeListener(_onDependencyChanged);
    }
    _dependencies.clear();
    super.close();
  }
}

/// Creates a computed reactive value that tracks dependencies evaluated in [compute].
RxComputed<T> rxComputed<T>(T Function() compute) => RxComputed.create(compute);
