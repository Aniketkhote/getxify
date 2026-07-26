part of '../rx_types.dart';

/// global object that registers against `GetX` and `Obx`, and allows the
/// reactivity
/// of those `Widgets` and Rx values.

mixin RxObjectMixin<T> on GetListenable<T> {
  /// Makes this Rx look like a function so you can update a new
  /// value using `rx(someOtherValue)`. Practical to assign the Rx directly
  /// to some Widget that has a signature `::onChange(value)`.
  ///
  /// Example:
  /// ```dart
  /// final myText = 'GetX rocks!'.obs;
  ///
  /// // in your Constructor, just to check it works :P
  /// ever(myText, print);
  ///
  /// // in your build(BuildContext) {
  /// TextField(
  ///   onChanged: myText,
  /// ),
  /// ```
  @override
  T call([T? v]) {
    if (v != null) {
      value = v;
    }
    return value;
  }

  /// Forcefully notifies all listeners about the current [value], even if the
  /// value hasn't changed. Useful for refreshing custom objects and triggering UI updates.
  ///
  /// Example:
  /// ```dart
  /// class Person {
  ///   String name;
  ///   Person(this.name);
  /// }
  ///
  /// final person = Person('John').obs;
  /// person.value.name = 'Jane';
  /// person.refresh(); // Notifies Obx to rebuild the widget
  /// ```
  @override
  void refresh() {
    super.refresh();
  }

  bool firstRebuild = true;
  bool sentToStream = false;

  /// Same as `toString()` but using a getter.
  String get string => value.toString();

  @override
  String toString() => value.toString();

  /// Returns the json representation of `value`.
  dynamic toJson() => value;

  /// This equality override works for _RxImpl instances and the internal
  /// values.
  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  bool operator ==(Object o) {
    if (o is T) return value == o;
    if (o is RxObjectMixin<T>) return value == o.value;
    return false;
  }

  @override
  // ignore: avoid_equals_and_hash_code_on_mutable_classes
  int get hashCode => value.hashCode;

  /// Updates the [value] and adds it to the stream, updating the observer
  /// Widget, only if it's different from the previous value.
  @override
  set value(T val) {
    if (isDisposed) return;
    sentToStream = false;
    if (value == val && !firstRebuild) return;
    firstRebuild = false;
    sentToStream = true;
    super.value = val;
  }

  /// Same as the [value] setter but without its `==` short-circuit — see
  /// [GetListenable.forceValue]. Keeps the setter's disposal guard and stream
  /// bookkeeping so the two stay interchangeable in every other respect.
  @override
  void forceValue(T val) {
    if (isDisposed) return;
    firstRebuild = false;
    sentToStream = true;
    super.forceValue(val);
  }

  /// Returns a [StreamSubscription] similar to [listen], but with the
  /// added benefit that it primes the stream with the current [value], rather
  /// than waiting for the next [value]. This should not be called in [onInit]
  /// or anywhere else during the build process.
  StreamSubscription<T> listenAndPump(
    void Function(T event) onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final subscription = listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );

    subject.add(value);

    return subscription;
  }

  /// Subscriptions created by [bindStream], cancelled when this Rx is closed.
  final List<StreamSubscription<T>> _subscriptions = <StreamSubscription<T>>[];

  /// Binds an existing `Stream<T>` to this `Rx<T>` to keep the values in sync.
  /// You can bind multiple sources to update the value.
  ///
  /// Set [cancelPrevious] to `true` to cancel any subscriptions created by
  /// earlier [bindStream] calls before binding the new [stream]. This is
  /// useful when rebinding to a fresh source (e.g. re-entering a page) so
  /// stale streams stop overwriting the value.
  ///
  /// Returns the [StreamSubscription], so callers can pause or cancel the
  /// binding manually. All active subscriptions are cancelled automatically
  /// when this Rx is closed; when [bindStream] is called during an observer
  /// (`GetX` or `Obx`) build, the subscription is also cancelled when that
  /// Widget gets unmounted from the Widget tree.
  StreamSubscription<T> bindStream(
    Stream<T> stream, {
    bool cancelPrevious = false,
  }) {
    if (cancelPrevious) {
      for (final subscription in _subscriptions) {
        subscription.cancel();
      }
      _subscriptions.clear();
    }
    final sub = stream.listen((va) => value = va);
    _subscriptions.add(sub);
    reportAdd(sub.cancel);
    return sub;
  }

  @override
  void close() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    super.close();
  }
}

/// Base Rx class that manages all the stream logic for any Type.
abstract class _RxImpl<T> extends GetListenable<T> with RxObjectMixin<T> {
  _RxImpl(super.initial);

  void addError(Object error, [StackTrace? stackTrace]) {
    subject.addError(error, stackTrace);
  }

  Stream<R> map<R>(R Function(T? data) mapper) => stream.map(mapper);

  /// Uses a callback to update [value] internally, similar to [refresh],
  /// but provides the current value as the argument.
  /// Makes sense for custom Rx types (like Models).
  ///
  /// Sample:
  /// ```
  ///  class Person {
  ///     String name, last;
  ///     int age;
  ///     Person({this.name, this.last, this.age});
  ///     @override
  ///     String toString() => '$name $last, $age years old';
  ///  }
  ///
  /// final person = Person(name: 'John', last: 'Doe', age: 18).obs;
  /// person.update((person) {
  ///   person.name = 'Roi';
  /// });
  /// print( person );
  /// ```
  void update(T Function(T? val) fn) {
    value = fn(value);
    // subject.add(value);
  }

  /// Following certain practices on Rx data, we might want to react to certain
  /// listeners when a value has been provided, even if the value is the same.
  /// At the moment, we ignore part of the process if we `.call(value)` with
  /// the same value since it holds the value and there's no real
  /// need triggering the entire process for the same value inside, but
  /// there are other situations where we might be interested in
  /// triggering this.
  ///
  /// For example, supposed we have a `int seconds = 2` and we want to animate
  /// from invisible to visible a widget in two seconds:
  /// `RxEvent<int>.call(seconds);`
  /// then after a click happens, you want to call a `RxEvent<int>.call(seconds)`.
  /// By doing `call(seconds)`, if the value being held is the same,
  /// the listeners won't trigger, hence we need this new `trigger` function.
  /// This will refresh the listener of an AnimatedWidget and will keep
  /// the value if the Rx is kept in memory.
  /// Sample:
  /// ```
  /// Rx<Int> secondsRx = RxInt();
  /// secondsRx.listen((value) => print("$value seconds set"));
  ///
  /// secondsRx.call(2);      // This won't trigger any listener, since the value is the same
  /// secondsRx.trigger(2);   // This will trigger the listener independently from the value.
  /// ```
  ///
  void trigger(T v) {
    var firstRebuild = this.firstRebuild;
    value = v;
    // If it's not the first rebuild, the listeners have been called already
    // So we won't call them again.
    if (!firstRebuild && !sentToStream) {
      subject.add(v);
    }
  }
}


extension RxBoolExt on Rx<bool> {
  bool get isTrue => value;

  bool get isFalse => !isTrue;

  bool operator &(bool other) => other && value;

  bool operator |(bool other) => other || value;

  bool operator ^(bool other) => !other == value;

  /// Toggles the bool [value] between false and true.
  /// A shortcut for `flag.value = !flag.value;`
  void toggle() {
    call(!value);
    // return this;
  }
}

extension RxnBoolExt on Rx<bool?> {
  bool? get isTrue => value;

  bool? get isFalse {
    if (value != null) return !isTrue!;
    return null;
  }

  bool? operator &(bool other) {
    if (value != null) {
      return other && value!;
    }
    return null;
  }

  bool? operator |(bool other) {
    if (value != null) {
      return other || value!;
    }
    return null;
  }

  bool? operator ^(bool other) => !other == value;

  /// Toggles the bool [value] between false and true.
  /// A shortcut for `flag.value = !flag.value;`
  void toggle() {
    if (value != null) {
      call(!value!);
      // return this;
    }
  }
}

/// Foundation class used for custom `Types` outside the common native Dart
/// types.
/// For example, any custom "Model" class, like User().obs will use `Rx` as
/// wrapper.
class Rx<T> extends _RxImpl<T> {
  Rx(super.initial);

  @override
  dynamic toJson() {
    try {
      return (value as dynamic)?.toJson();
    } on Exception catch (_) {
      throw Exception('$T has not method [toJson]');
    }
  }
}

class Rxn<T> extends Rx<T?> {
  Rxn([super.initial]);

  @override
  dynamic toJson() {
    try {
      return (value as dynamic)?.toJson();
    } on Exception catch (_) {
      throw Exception('$T has not method [toJson]');
    }
  }
}

extension StringExtension on String {
  /// Returns a `RxString` with [this] `String` as initial value.
  RxString get obs => RxString(this);
}

extension IntExtension on int {
  /// Returns a `RxInt` with [this] `int` as initial value.
  RxInt get obs => RxInt(this);
}

extension DoubleExtension on double {
  /// Returns a `RxDouble` with [this] `double` as initial value.
  RxDouble get obs => RxDouble(this);
}

extension BoolExtension on bool {
  /// Returns a `RxBool` with [this] `bool` as initial value.
  RxBool get obs => RxBool(this);
}

extension RxT<T extends Object> on T {
  /// Returns a `Rx` instance with [this] `T` as initial value.
  Rx<T> get obs => Rx<T>(this);
}

/// This method replaces the old `.obs` extension to avoid conflicts with
/// Dart 3 features. T will be inferred by contextual type inference.
extension RxTNew on Object {
  /// Returns a `Rx` instance with [this] `T` as initial value.
  Rx<T> obs<T>() => Rx<T>(this as T);
}
