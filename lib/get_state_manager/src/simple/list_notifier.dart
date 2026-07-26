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

/// A notifier that combines single and group listener capabilities.
///
/// This class extends [ChangeNotifier] and provides both single listener
/// functionality (via [ListNotifierSingleMixin]) and group listener
/// functionality (via [ListNotifierGroupMixin]). It's the base notifier
/// used by GetX controllers.
class ListNotifier extends ChangeNotifier
    with ListNotifierSingleMixin, ListNotifierGroupMixin {}

/// A notifier with single listener support.
class ListNotifierSingle extends ChangeNotifier with ListNotifierSingleMixin {}

/// A notifier with group listener support identified by ID.
class ListNotifierGroup extends ChangeNotifier with ListNotifierGroupMixin {}

/// Mixin that adds single listener functionality to [ChangeNotifier].
///
/// This mixin leverages Flutter's native [ChangeNotifier] engine under the
/// hood for optimized $O(1)$ listener management.
mixin ListNotifierSingleMixin on ChangeNotifier {
  bool _isDisposed = false;

  @override
  Disposer addListener(VoidCallback listener) {
    super.addListener(listener);
    return () => removeListener(listener);
  }

  /// Notifies all listeners to update using Flutter's native [ChangeNotifier].
  @protected
  void refresh() {
    notifyListeners();
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

  bool get isDisposed => _isDisposed;

  /// Returns true if there is at least one active listener.
  bool get hasSubscribers => hasListeners;

  /// Disposes the notifier and cleans up native [ChangeNotifier] listeners.
  @override
  @mustCallSuper
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

/// Mixin that adds group listener functionality to [ChangeNotifier].
mixin ListNotifierGroupMixin on ChangeNotifier {
  HashMap<Object?, ChangeNotifier>? _updatersGroupIds =
      HashMap<Object?, ChangeNotifier>();

  /// Notifies all listeners in a specific group.
  void _notifyGroupUpdate(Object id) {
    _updatersGroupIds?[id]?.notifyListeners();
  }

  /// Reports that a listener group was read.
  @protected
  void notifyGroupChildrens(Object id) {
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
    _notifyGroupUpdate(id);
  }

  /// Removes a listener from a specific group.
  void removeListenerId(Object id, VoidCallback listener) {
    _updatersGroupIds?[id]?.removeListener(listener);
  }

  /// Disposes all listener groups.
  @override
  @mustCallSuper
  void dispose() {
    _updatersGroupIds?.forEach((_, value) => value.dispose());
    _updatersGroupIds = null;
    super.dispose();
  }

  /// Adds a listener to a specific group identified by [key].
  Disposer addListenerId(Object? key, VoidCallback listener) {
    _updatersGroupIds![key] ??= ChangeNotifier();
    final group = _updatersGroupIds![key]!;
    group.addListener(listener);
    return () => group.removeListener(listener);
  }

  /// Ensures a group [ChangeNotifier] exists for [id] and returns it.
  ChangeNotifier ensureGroupListenable(Object id) {
    return _updatersGroupIds![id] ??= ChangeNotifier();
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
  void read(Listenable updaters) {
    final data = _notifyData;
    final listener = data?.updater;
    if (listener != null && !data!._subscribedNotifiers.contains(updaters)) {
      data._subscribedNotifiers.add(updaters);
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
  NotifyData({
    required this.updater,
    required this.disposers,
    this.throwException = true,
  });

  final GetStateUpdate updater;
  final List<VoidCallback> disposers;
  final bool throwException;
  final Set<Listenable> _subscribedNotifiers = Set<Listenable>.identity();
}
