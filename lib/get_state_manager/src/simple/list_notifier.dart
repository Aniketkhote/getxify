import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:getxify/get_common/obx_error.dart';

/// Callback function to remove a listener.
///
/// This is returned by [addListener] and can be called to remove
/// the listener from the notifier.
typedef Disposer = void Function();

/// Callback function to update state.
///
/// This is used to trigger widget rebuilds when state changes.
typedef GetStateUpdate = void Function();

class _InternalNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// A notifier that combines single and group listener capabilities.
///
/// This class extends [Listenable] and provides both single listener
/// functionality (via [ListNotifierSingleMixin]) and group listener
/// functionality (via [ListNotifierGroupMixin]). It's the base notifier
/// used by GetX controllers.
class ListNotifier extends Listenable
    with ListNotifierSingleMixin, ListNotifierGroupMixin {}

/// A notifier with single listener support.
///
/// This is a type alias for [ListNotifier] with only the
/// [ListNotifierSingleMixin] mixed in, providing basic single
/// listener functionality.
class ListNotifierSingle = ListNotifier with ListNotifierSingleMixin;

/// A notifier with group listener support identified by ID.
///
/// This is a type alias for [ListNotifier] with only the
/// [ListNotifierGroupMixin] mixed in, providing group listener
/// functionality where listeners can be grouped by ID.
class ListNotifierGroup = ListNotifier with ListNotifierGroupMixin;

/// Mixin that adds single listener functionality to [Listenable].
///
/// This mixin leverages Flutter's native [ChangeNotifier] engine under the
/// hood for optimized $O(1)$ listener management.
mixin ListNotifierSingleMixin implements Listenable {
  _InternalNotifier? _notifier = _InternalNotifier();
  final Set<GetStateUpdate> _updaters = <GetStateUpdate>{};

  @override
  Disposer addListener(GetStateUpdate listener) {
    assert(_debugAssertNotDisposed());
    _updaters.add(listener);
    _notifier!.addListener(listener);
    return () => removeListener(listener);
  }

  bool containsListener(GetStateUpdate listener) {
    return _updaters.contains(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    if (isDisposed) return;
    _updaters.remove(listener);
    _notifier?.removeListener(listener);
  }

  /// Notifies all listeners to update using Flutter's native [ChangeNotifier].
  @protected
  void refresh() {
    assert(_debugAssertNotDisposed());
    _notifyUpdate();
  }

  /// Reports that this notifier was read.
  @protected
  void reportRead() {
    Notifier.instance.read(this);
  }

  /// Reports a disposer callback to the global notifier.
  @protected
  void reportAdd(VoidCallback disposer) {
    Notifier.instance.add(disposer);
  }

  void _notifyUpdate() {
    assert(_debugAssertNotDisposed());
    _notifier?.notify();
  }

  bool get isDisposed => _notifier == null;

  bool _debugAssertNotDisposed() {
    assert(() {
      if (isDisposed) {
        throw FlutterError(
          '''A $runtimeType was used after being disposed.\n
'Once you have called dispose() on a $runtimeType, it can no longer be used.''',
        );
      }
      return true;
    }());
    return true;
  }

  /// Returns the number of active listeners.
  int get listenersLength {
    assert(_debugAssertNotDisposed());
    return _updaters.length;
  }

  /// Disposes the notifier and cleans up native [ChangeNotifier] listeners.
  @mustCallSuper
  void dispose() {
    assert(_debugAssertNotDisposed());
    _updaters.clear();
    _notifier?.dispose();
    _notifier = null;
  }
}

/// Mixin that adds group listener functionality to [Listenable].
mixin ListNotifierGroupMixin on Listenable {
  HashMap<Object?, ListNotifierSingleMixin>? _updatersGroupIds =
      HashMap<Object?, ListNotifierSingleMixin>();

  /// Notifies all listeners in a specific group.
  void _notifyGroupUpdate(Object id) {
    _updatersGroupIds?[id]?._notifyUpdate();
  }

  /// Reports that a listener group was read.
  @protected
  void notifyGroupChildrens(Object id) {
    assert(_debugAssertNotDisposed());
    if (_updatersGroupIds?[id] case final group?) {
      Notifier.instance.read(group);
    }
  }

  /// Checks if a listener group with the given ID exists.
  bool containsId(Object id) {
    return _updatersGroupIds?.containsKey(id) ?? false;
  }

  /// Refreshes only the listeners in a specific group.
  @protected
  void refreshGroup(Object id) {
    assert(_debugAssertNotDisposed());
    _notifyGroupUpdate(id);
  }

  bool _debugAssertNotDisposed() {
    assert(() {
      if (_updatersGroupIds == null) {
        throw FlutterError(
          '''A $runtimeType was used after being disposed.\n
'Once you have called dispose() on a $runtimeType, it can no longer be used.''',
        );
      }
      return true;
    }());
    return true;
  }

  /// Removes a listener from a specific group.
  void removeListenerId(Object id, VoidCallback listener) {
    assert(_debugAssertNotDisposed());
    _updatersGroupIds?[id]?.removeListener(listener);
  }

  /// Disposes all listener groups.
  @mustCallSuper
  void dispose() {
    assert(_debugAssertNotDisposed());
    _updatersGroupIds?.forEach((_, value) => value.dispose());
    _updatersGroupIds = null;
  }

  /// Adds a listener to a specific group identified by [key].
  Disposer addListenerId(Object? key, GetStateUpdate listener) {
    _updatersGroupIds![key] ??= ListNotifierSingle();
    return _updatersGroupIds![key]!.addListener(listener);
  }

  /// Disposes a specific listener group.
  void disposeId(Object id) {
    _updatersGroupIds?[id]?.dispose();
    _updatersGroupIds?.remove(id);
  }
}

/// Singleton that manages reactive dependencies.
class Notifier {
  Notifier._();

  static Notifier? _instance;
  static Notifier get instance => _instance ??= Notifier._();

  NotifyData? _notifyData;

  /// Adds a disposer callback to the current notification data.
  void add(VoidCallback listener) {
    _notifyData?.disposers.add(listener);
  }

  /// Reads a notifier and sets up automatic listener tracking.
  void read(ListNotifierSingleMixin updaters) {
    final listener = _notifyData?.updater;
    if (listener != null && !updaters.containsListener(listener)) {
      updaters.addListener(listener);
      add(() => updaters.removeListener(listener));
    }
  }

  /// Executes a builder function with reactive tracking.
  T append<T>(NotifyData data, T Function() builder) {
    _notifyData = data;
    final result = builder();
    if (data.disposers.isEmpty && data.throwException) {
      throw const ObxError();
    }
    _notifyData = null;
    return result;
  }
}

/// Data container for reactive notification tracking.
class NotifyData {
  const NotifyData({
    required this.updater,
    required this.disposers,
    this.throwException = true,
  });

  final GetStateUpdate updater;
  final List<VoidCallback> disposers;
  final bool throwException;
}
