/// Creates a new [InstanceNotFoundException] with the given [message].
class InstanceNotFoundException implements Exception {
  final String message;
  InstanceNotFoundException(this.message);

  @override
  String toString() => 'InstanceNotFoundException: $message';
}

/// Holds metadata about the registration and lifecycle state of an instance.
class InstanceInfo {
  /// Whether the instance is marked as permanent.
  final bool? isPermanent;

  /// Whether the instance is registered as a singleton.
  final bool? isSingleton;

  /// Whether the instance is created on demand rather than stored as a singleton.
  bool get isCreate => isSingleton != true;

  /// Whether the dependency is registered in the dependency manager.
  final bool isRegistered;

  /// Whether the dependency is prepared (registered via lazyPut but not yet initialized).
  final bool isPrepared;

  /// Whether the dependency has been initialized.
  final bool? isInit;

  /// Creates a new [InstanceInfo] containing registration details.
  const InstanceInfo({
    required this.isPermanent,
    required this.isSingleton,
    required this.isRegistered,
    required this.isPrepared,
    required this.isInit,
  });

  @override
  String toString() {
    return 'InstanceInfo(isPermanent: $isPermanent, isSingleton: $isSingleton, isRegistered: $isRegistered, isPrepared: $isPrepared, isInit: $isInit)';
  }
}
