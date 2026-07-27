import 'package:flutter/widgets.dart';

import '../../../get_instance/get_instance.dart';

/// A mixin that provides Flutter state restoration support to [GetLifeCycleMixin] controllers.
///
/// Controllers using [GetRestorationMixin] can persist and restore state values
/// to survive OS process termination on Android and iOS.
///
/// Example:
/// ```dart
/// class CounterController extends GetxController with GetRestorationMixin {
///   @override
///   String? get restorationId => 'counter_controller';

///   int get count => restore('count', 0);
///   set count(int val) => persist('count', val);
/// }
/// ```
mixin GetRestorationMixin on GetLifeCycleMixin {
  /// The restoration ID used to identify this controller's restoration bucket.
  ///
  /// Override this getter to return a unique ID for this controller instance.
  String? get restorationId => null;

  RestorationBucket? _bucket;

  /// The current restoration bucket for this controller.
  RestorationBucket? get restorationBucket => _bucket;

  final Map<String, Object?> _restorationData = {};

  /// Restores a value associated with [key] or returns [defaultValue] if no restored value exists.
  @protected
  T restore<T>(String key, T defaultValue) {
    if (_bucket != null && _bucket!.contains(key)) {
      final value = _bucket!.read<T>(key);
      if (value != null) return value;
    }
    return _restorationData.containsKey(key)
        ? _restorationData[key] as T
        : defaultValue;
  }

  /// Persists a restorable [value] associated with [key] into the restoration bucket.
  @protected
  void persist<T>(String key, T value) {
    _restorationData[key] = value;
    if (_bucket != null) {
      _bucket!.write(key, value);
    }
  }

  /// Initializes restoration using the provided parent [bucket].
  void initRestoration(RestorationBucket? bucket) {
    if (bucket == null || restorationId == null) return;
    _bucket = bucket.claimChild(restorationId!, debugOwner: this);
    _restorationData.forEach((key, value) {
      if (!_bucket!.contains(key)) {
        _bucket!.write(key, value);
      }
    });
  }

  @override
  @mustCallSuper
  void onClose() {
    _restorationData.clear();
    _bucket?.dispose();
    _bucket = null;
    super.onClose();
  }
}
