import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../get_instance/get_instance.dart';
import '../../../get_rx/src/rx_types/rx_types.dart';
import '../../../get_utils/src/equality/equality.dart';
import '../../get_state_manager.dart';
import '../simple/list_notifier.dart';

/// Extension to check if an object is empty.
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
mixin StateMixin<T> on ListNotifier {
  T? _value;
  GetStatus<T>? _status;

  void _fillInitialStatus() {
    _status = (_value == null || _value!._isEmpty())
        ? GetStatus<T>.loading()
        : GetStatus<T>.success(_value as T);
  }

  GetStatus<T> get status {
    reportRead();
    return _status ??= _status = GetStatus.loading();
  }

  T get state => value;

  set status(GetStatus<T> newStatus) {
    if (newStatus == status) return;
    _status = newStatus;
    if (newStatus is SuccessStatus<T>) {
      _value = newStatus.data;
    }
    refresh();
  }

  @protected
  T get value {
    reportRead();
    return _value as T;
  }

  @protected
  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    refresh();
  }

  @protected
  void change(T? newState, {GetStatus<T>? status}) {
    if (newState != null) {
      _value = newState;
    }
    if (status != null) {
      _status = status;
    } else if (newState != null) {
      _status = newState._isEmpty()
          ? GetStatus<T>.empty()
          : GetStatus<T>.success(newState);
    }
    refresh();
  }

  void setSuccess(T data) {
    change(data, status: GetStatus<T>.success(data));
  }

  void setError(Object error) {
    change(null, status: GetStatus<T>.error(error));
  }

  void setLoading() {
    change(null, status: GetStatus<T>.loading());
  }

  void setEmpty() {
    change(null, status: GetStatus<T>.empty());
  }

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

class GetListenable<T> extends ListNotifierSingle implements RxInterface<T> {
  GetListenable(T val) : _value = val;

  StreamController<T>? _controller;

  StreamController<T> get subject {
    if (_controller == null) {
      _controller = StreamController<T>.broadcast(
        onCancel: addListener(_streamListener),
      );
      _controller?.add(_value);
    }
    return _controller!;
  }

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

  Stream<T> get stream {
    return subject.stream;
  }

  T _value;

  @override
  T get value {
    reportRead();
    return _value;
  }

  void _notify() {
    refresh();
  }

  set value(T newValue) {
    if (_value == newValue) return;
    _value = newValue;
    _notify();
  }

  @protected
  void forceValue(T newValue) {
    _value = newValue;
    _notify();
  }

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

class Value<T> extends ListNotifier
    with StateMixin<T>
    implements ValueListenable<T?> {
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

  void update(T Function(T? value) fn) {
    value = fn(value);
  }

  @override
  String toString() => value.toString();

  Object? toJson() => (value as dynamic)?.toJson();
}

abstract class GetNotifier<T> extends Value<T> with GetLifeCycleMixin {
  GetNotifier(super.initial);
}

extension StateExt<T> on StateMixin<T> {
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
          return onEmpty ?? const SizedBox.shrink();
        } else if (status.isSuccess) {
          return widget(value);
        } else if (status.isCustom) {
          return onCustom?.call(context) ?? const SizedBox.shrink();
        }
        return widget(value);
      },
    );
  }
}

typedef NotifierBuilder<T> = Widget Function(T state);

/// Sealed class representing different states of a notifier.
sealed class GetStatus<T> with Equality {
  const GetStatus();

  factory GetStatus.loading() => LoadingStatus<T>();

  factory GetStatus.error(Object message) => ErrorStatus<T, Object>(message);

  factory GetStatus.empty() => EmptyStatus<T>();

  factory GetStatus.success(T data) => SuccessStatus<T>(data);

  factory GetStatus.custom() => CustomStatus<T>();

  bool get isLoading => this is LoadingStatus<T>;

  bool get isSuccess => this is SuccessStatus<T>;

  bool get isError => this is ErrorStatus<T, dynamic>;

  bool get isEmpty => this is EmptyStatus<T>;

  bool get isCustom => !isLoading && !isSuccess && !isError && !isEmpty;

  Object? get error {
    final self = this;
    if (self is ErrorStatus<T, dynamic>) {
      return self.error;
    }
    return null;
  }

  String get errorMessage {
    final self = this;
    if (self is ErrorStatus<T, dynamic>) {
      if (self.error != null) {
        if (self.error is String) {
          return self.error as String;
        }
        return self.error.toString();
      }
    }
    return '';
  }

  T? get data {
    final self = this;
    if (self is SuccessStatus<T>) {
      return self.data;
    }
    return null;
  }
}

class CustomStatus<T> extends GetStatus<T> {
  @override
  List get props => [];
}

class LoadingStatus<T> extends GetStatus<T> {
  @override
  List get props => [];
}

class SuccessStatus<T> extends GetStatus<T> {
  @override
  final T data;

  const SuccessStatus(this.data);

  @override
  List get props => [data];
}

class ErrorStatus<T, S> extends GetStatus<T> {
  @override
  final S? error;

  const ErrorStatus([this.error]);

  @override
  List get props => [error];
}

class EmptyStatus<T> extends GetStatus<T> {
  @override
  List get props => [];
}

typedef GetState<T> = GetStatus<T>;

extension StatusDataExt<T> on GetStatus<T> {
  R when<R>({
    required R Function() loading,
    required R Function(T data) success,
    required R Function(Object? error) error,
    required R Function() empty,
    R Function()? custom,
  }) {
    final self = this;
    if (self is LoadingStatus<T>) {
      return loading();
    } else if (self is SuccessStatus<T>) {
      return success(self.data);
    } else if (self is ErrorStatus<T, dynamic>) {
      return error(self.error);
    } else if (self is EmptyStatus<T>) {
      return empty();
    } else if (self is CustomStatus<T>) {
      return (custom ?? loading)();
    }
    return loading();
  }

  R maybeWhen<R>({
    required R Function() orElse,
    R Function()? loading,
    R Function(T data)? success,
    R Function(Object? error)? error,
    R Function()? empty,
    R Function()? custom,
  }) {
    final self = this;
    if (self is LoadingStatus<T> && loading != null) {
      return loading();
    } else if (self is SuccessStatus<T> && success != null) {
      return success(self.data);
    } else if (self is ErrorStatus<T, dynamic> && error != null) {
      return error(self.error);
    } else if (self is EmptyStatus<T> && empty != null) {
      return empty();
    } else if (self is CustomStatus<T> && custom != null) {
      return custom();
    }
    return orElse();
  }
}
