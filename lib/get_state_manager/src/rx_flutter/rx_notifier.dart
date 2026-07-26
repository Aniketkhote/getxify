import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../get_instance/get_instance.dart';
import '../../../get_rx/src/rx_types/rx_types.dart';
import '../../../get_utils/src/equality/equality.dart';
import '../../get_state_manager.dart';
import '../simple/list_notifier.dart';

/// Extension to check if an object is empty.
///
/// This private extension provides a unified way to check emptiness
/// for different types (Iterable, String, Map).
extension _Empty on Object {
  bool _isEmpty() {
    final val = this;
    var result = false;
    if (val is Iterable) {
      result = val.isEmpty;
    } else if (val is String) {
      result = val.trim().isEmpty;
    } else if (val is Map) {
      result = val.isEmpty;
    }
    return result;
  }
}

/// Mixin that adds state management with status tracking.
///
/// This mixin provides a way to manage state with loading, error,
/// success, and empty statuses. It's commonly used with controllers
/// that handle async operations.
mixin StateMixin<T> on ListNotifier {
  T? _value;
  GetStatus<T>? _status;

  /// Fills the initial status based on the value.
  void _fillInitialStatus() {
    _status = (_value == null || _value!._isEmpty())
        ? GetStatus<T>.loading()
        : GetStatus<T>.success(_value as T);
  }

  /// The current status of the state.
  GetStatus<T> get status {
    reportRead();
    return _status ??= _status = GetStatus.loading();
  }

  /// Alias for [value] for convenience.
  T get state => value;

  /// Sets the status and updates the value if it's a success status.
  set status(GetStatus<T> newStatus) {
    if (newStatus == status) return;
    _status = newStatus;
    if (newStatus is SuccessStatus<T>) {
      _value = newStatus.data;
    }
    refresh();
  }

  /// The current value of the state.
  @protected
  T get value {
    reportRead();
    return _value as T;
  }

  /// Sets the value and notifies listeners.
  @protected
  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    refresh();
  }

  /// Changes the status if it's different from the current status.
  @protected
  void change(GetStatus<T> status) {
    if (status != this.status) {
      this.status = status;
    }
  }

  /// Sets the status to success with the given data.
  void setSuccess(T data) {
    change(GetStatus<T>.success(data));
  }

  /// Sets the status to error with the given error object.
  void setError(Object error) {
    change(GetStatus<T>.error(error));
  }

  /// Sets the status to loading.
  void setLoading() {
    change(GetStatus<T>.loading());
  }

  /// Sets the status to empty.
  void setEmpty() {
    change(GetStatus<T>.empty());
  }

  /// Executes a future and automatically handles status changes.
  ///
  /// This method sets the status to loading, executes the future,
  /// and then sets the status to success, error, or empty based on
  /// the result.
  void futurize(
    Future<T> Function() body, {
    T? initialData,
    String? errorMessage,
    bool useEmpty = true,
  }) {
    final compute = body;
    _value ??= initialData;
    status = GetStatus<T>.loading();
    compute().then(
      (newValue) {
        if ((newValue == null || newValue._isEmpty()) && useEmpty) {
          status = GetStatus<T>.empty();
        } else {
          status = GetStatus<T>.success(newValue);
        }

        refresh();
      },
      onError: (err) {
        status = GetStatus.error(
          err is Exception ? err : Exception(errorMessage ?? err.toString()),
        );
        refresh();
      },
    );
  }
}

typedef FuturizeCallback<T> = Future<T> Function(VoidCallback fn);

typedef VoidCallback = void Function();

/// A listenable that implements [RxInterface] for reactive programming.
///
/// This class combines the listener capabilities of [ListNotifierSingle]
/// with the reactive interface of [RxInterface], providing both
/// listener-based and stream-based reactivity.
class GetListenable<T> extends ListNotifierSingle implements RxInterface<T> {
  /// Creates a new [GetListenable] with the initial value.
  GetListenable(T val) : _value = val;

  StreamController<T>? _controller;

  /// Gets or creates the stream controller for this listenable.
  StreamController<T> get subject {
    if (_controller == null) {
      _controller = StreamController<T>.broadcast(
        onCancel: addListener(_streamListener),
      );
      _controller?.add(_value);
    }
    return _controller!;
  }

  /// Listener that adds the current value to the stream.
  void _streamListener() {
    _controller?.add(_value);
  }

  @override
  @mustCallSuper
  void close() {
    removeListener(_streamListener);
    _controller?.close();
    dispose();
  }

  /// The stream of value changes.
  Stream<T> get stream {
    return subject.stream;
  }

  T _value;

  @override
  T get value {
    reportRead();
    return _value;
  }

  /// Notifies listeners of a value change.
  void _notify() {
    refresh();
  }

  /// Sets the value and notifies listeners.
  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    _notify();
  }

  /// Replaces the held value **without** the `==` short-circuit that the
  /// [value] setter applies, then notifies listeners exactly once.
  ///
  /// The setter's early return is right when the assignment replaces a
  /// *value* — nothing observable changed, so nothing needs announcing. It is
  /// wrong when the assignment replaces the *container*: `RxList` swapping a
  /// fixed-length backing list for a growable copy, say. There the old
  /// container may well report itself `==` to the copy (a `List` subclass with
  /// a content-insensitive `==`), and honouring that would silently discard
  /// the mutation just applied to the copy while still looking like it worked.
  ///
  /// Use [value] for value changes; this is only for backing replacement.
  @protected
  void forceValue(T newValue) {
    _value = newValue;
    _notify();
  }

  /// Gets or sets the value when called as a function.
  T? call([T? v]) {
    if (v != null) {
      value = v;
    }
    return value;
  }

  @override
  StreamSubscription<T> listen(
    void Function(T)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => stream.listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError ?? false,
  );

  @override
  String toString() => value.toString();
}

/// A value that can be listened to and has status tracking.
///
/// This class combines [ListNotifier] for listener management,
/// [StateMixin] for status tracking, and [ValueListenable] for
/// Flutter integration.
class Value<T> extends ListNotifier
    with StateMixin<T>
    implements ValueListenable<T?> {
  /// Creates a new [Value] with the initial value.
  Value(T val) {
    _value = val;
    _fillInitialStatus();
  }

  @override
  T get value {
    reportRead();
    return _value as T;
  }

  @override
  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    refresh();
  }

  T? call([T? v]) {
    if (v != null) {
      value = v;
    }
    return value;
  }

  /// Updates the value using a function.
  void update(T Function(T? value) fn) {
    value = fn(value);
  }

  @override
  String toString() => value.toString();

  /// Converts the value to JSON if possible.
  Object? toJson() => (value as dynamic)?.toJson();
}

/// A notifier with status, state, and GetX lifecycle support.
///
/// This class combines [Value] with [GetLifeCycleMixin] to provide
/// a full-featured notifier that can be used with GetX's dependency
/// injection and lifecycle management.
abstract class GetNotifier<T> extends Value<T> with GetLifeCycleMixin {
  GetNotifier(super.initial);
}

/// Extension on [StateMixin] that provides a widget builder.
///
/// This extension adds the [obx] method which builds different
/// widgets based on the current status.
extension StateExt<T> on StateMixin<T> {
  /// Builds a widget based on the current status.
  ///
  /// This method returns different widgets depending on whether the
  /// status is loading, error, empty, success, or custom.
  Widget obx(
    NotifierBuilder<T> widget, {
    Widget Function(String? error)? onError,
    Widget? onLoading,
    Widget? onEmpty,
    WidgetBuilder? onCustom,
  }) {
    return Observer(
      builder: (context) {
        if (status.isLoading) {
          return onLoading ?? const Center(child: CircularProgressIndicator());
        } else if (status.isError) {
          return onError != null
              ? onError(status.errorMessage)
              : Center(
                  child: Text('An error occurred: ${status.errorMessage}'),
                );
        } else if (status.isEmpty) {
          return onEmpty ??
              const SizedBox.shrink(); // Also can be widget(null); but is risky
        } else if (status.isSuccess) {
          return widget(value);
        } else if (status.isCustom) {
          return onCustom?.call(context) ??
              const SizedBox.shrink(); // Also can be widget(null); but is risky
        }
        return widget(value);
      },
    );
  }
}

/// Builder function for notifier widgets.
typedef NotifierBuilder<T> = Widget Function(T state);

/// Sealed class representing different states of a notifier.
///
/// This class provides a type-safe way to represent different
/// states: loading, error, empty, success, and custom.
sealed class GetStatus<T> with Equality {
  const GetStatus();

  /// Creates a loading status.
  factory GetStatus.loading() => LoadingStatus<T>();

  /// Creates an error status with a message.
  factory GetStatus.error(Object message) => ErrorStatus<T, Object>(message);

  /// Creates an empty status.
  factory GetStatus.empty() => EmptyStatus<T>();

  /// Creates a success status with data.
  factory GetStatus.success(T data) => SuccessStatus<T>(data);

  /// Creates a custom status.
  factory GetStatus.custom() => CustomStatus<T>();
}

/// Represents a custom status.
class CustomStatus<T> extends GetStatus<T> {
  @override
  List get props => [];
}

/// Represents a loading status.
class LoadingStatus<T> extends GetStatus<T> {
  @override
  List get props => [];
}

/// Represents a success status with data.
class SuccessStatus<T> extends GetStatus<T> {
  final T data;

  const SuccessStatus(this.data);

  @override
  List get props => [data];
}

/// Represents an error status with an error object.
class ErrorStatus<T, S> extends GetStatus<T> {
  final S? error;

  const ErrorStatus([this.error]);

  @override
  List get props => [error];
}

/// Represents an empty status.
class EmptyStatus<T> extends GetStatus<T> {
  @override
  List get props => [];
}

/// Extension on [GetStatus] providing convenience getters.
extension StatusDataExt<T> on GetStatus<T> {
  /// Whether this status is loading.
  bool get isLoading => this is LoadingStatus;

  /// Whether this status is success.
  bool get isSuccess => this is SuccessStatus;

  /// Whether this status is error.
  bool get isError => this is ErrorStatus;

  /// Whether this status is empty.
  bool get isEmpty => this is EmptyStatus;

  /// Whether this status is custom.
  bool get isCustom => !isLoading && !isSuccess && !isError && !isEmpty;

  /// The error object if this is an error status.
  Object? get error {
    if (this is ErrorStatus) {
      return (this as ErrorStatus).error;
    }
    return null;
  }

  /// The error message as a string.
  String get errorMessage {
    final isError = this is ErrorStatus;
    if (isError) {
      final err = this as ErrorStatus;
      if (err.error != null) {
        if (err.error is String) {
          return err.error as String;
        }
        return err.error.toString();
      }
    }

    return '';
  }

  /// The data if this is a success status.
  T? get data {
    if (this is SuccessStatus<T>) {
      final success = this as SuccessStatus<T>;
      return success.data;
    }
    return null;
  }
}
