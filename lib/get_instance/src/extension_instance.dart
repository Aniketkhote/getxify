import 'package:flutter/widgets.dart';

import '../../get_core/get_core.dart';
import '../../get_navigation/src/router_report.dart';
import '../../get_state_manager/src/simple/list_notifier.dart';
import 'lifecycle.dart';

/// Exception thrown when a requested dependency has not been registered
/// in the dependency manager.
class InstanceNotFoundException implements Exception {
  /// The error message associated with this exception.
  final String message;

  /// Creates a new [InstanceNotFoundException] with the given [message].
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

/// Extension on [GetInterface] to reset and clear registered instances.
extension ResetInstance on GetInterface {
  /// Clears all registered instances (and/or tags).
  /// Even the persistent ones.
  /// This should be used at the end or tearDown of unit tests.
  ///
  /// `clearFactory` clears the callbacks registered by [lazyPut]
  /// `clearRouteBindings` clears Instances associated with routes.
  ///
  bool resetInstance({bool clearRouteBindings = true}) {
    if (clearRouteBindings) RouterReportManager.instance.clearRouteKeys();
    GetInstanceExt._singletons.clear();

    return true;
  }
}

/// Main extension on [GetInterface] providing dependency injection features.
extension GetInstanceExt on GetInterface {
  /// A callable shortcut to find/retrieve a registered dependency.
  ///
  /// Example:
  /// ```dart
  /// final controller = Get<MyController>();
  /// ```
  T call<T>() => find<T>();

  /// Holds references to every registered Instance when using
  /// `Get.put()`
  static final Map<String, _InstanceBuilderFactory<Object?>> _singletons = {};

  /// Injects a [dependency] into the dependency manager and immediately initializes it.
  ///
  /// Returns the registered dependency.
  ///
  /// - [tag] Optional tag to identify this specific instance.
  /// - [permanent] If true, prevents the instance from being deleted by SmartManagement.
  S put<S>(S dependency, {String? tag, bool permanent = false}) {
    _insert(
      isSingleton: true,
      name: tag,
      permanent: permanent,
      builder: (() => dependency),
    );
    return find<S>(tag: tag);
  }

  /// Injects an instance of [S] built asynchronously by [builder] into the
  /// dependency manager.
  ///
  /// Awaits [builder] and then registers the resulting instance exactly like
  /// [put], so the regular lifecycle (`onInit`/`onReady`) runs on the ready
  /// instance. Perform any asynchronous setup inside [builder] **before**
  /// returning the instance; lifecycle callbacks such as `onInit` are
  /// synchronous and are not awaited.
  ///
  /// ```dart
  /// await Get.putAsync<StorageService>(() async {
  ///   final service = StorageService();
  ///   await service.init();
  ///   return service;
  /// });
  /// ```
  ///
  /// - [tag] Optional tag to identify this specific instance.
  /// - [permanent] If true, prevents the instance from being deleted by SmartManagement.
  Future<S> putAsync<S>(
    AsyncInstanceBuilderCallback<S> builder, {
    String? tag,
    bool permanent = false,
  }) async {
    return put<S>(await builder(), tag: tag, permanent: permanent);
  }

  /// Creates a new Instance<S> lazily from the `<S>builder()` callback.
  ///
  /// The first time you call `Get.find()`, the `builder()` callback will create
  /// the Instance and persisted as a Singleton (like you would
  /// use `Get.put()`).
  ///
  /// Using `Get.smartManagement` as [SmartManagement.keepFactory] has
  /// the same outcome as using `fenix:true` :
  /// The internal register of `builder()` will remain in memory to recreate
  /// the Instance if the Instance has been removed with `Get.delete()`.
  /// Therefore, future calls to `Get.find()` will return the same Instance.
  ///
  /// If you need to make use of GetxController's life-cycle
  /// (`onInit(), onStart(), onClose()`) [fenix] is a great choice to mix with
  /// `GetBuilder()` and `GetX()` widgets, and/or `GetMaterialApp` Navigation.
  ///
  /// You could use `Get.lazyPut(fenix:true)` in your app's `main()` instead
  /// of `Bindings()` for each `GetPage`.
  /// And the memory management will be similar.
  ///
  /// Subsequent calls to `Get.lazyPut()` with the same parameters
  /// (<[S]> and optionally [tag] will **not** override the original).
  void lazyPut<S>(
    InstanceBuilderCallback<S> builder, {
    String? tag,
    bool? fenix,
    bool permanent = false,
  }) {
    _insert(
      isSingleton: true,
      name: tag,
      permanent: permanent,
      builder: builder,
      fenix: fenix ?? Get.smartManagement == SmartManagement.keepFactory,
    );
  }

  /// Creates a new Class Instance [S] from the builder callback[S].
  /// Every time [find]<S>() is used, it calls the builder method to generate
  /// a new Instance [S].
  /// It also registers each `instance.onClose()` with the current
  /// Route `Get.reference` to keep the lifecycle active.
  /// Is important to know that the instances created are only stored per Route.
  /// So, if you call `Get.delete<T>()` the "instance factory" used in this
  /// method (`Get.spawn<T>()`) will be removed, but NOT the instances
  /// already created by it.
  ///
  /// Example:
  ///
  /// ```Get.spawn(() => Repl());
  /// Repl a = find();
  /// Repl b = find();
  /// print(a==b); (false)```
  void spawn<S>(
    InstanceBuilderCallback<S> builder, {
    String? tag,
    bool permanent = true,
  }) {
    _insert(
      isSingleton: false,
      name: tag,
      builder: builder,
      permanent: permanent,
    );
  }

  /// Injects the Instance [S] builder into the `_singleton` HashMap.
  void _insert<S>({
    bool? isSingleton,
    String? name,
    bool permanent = false,
    required InstanceBuilderCallback<S> builder,
    bool fenix = false,
  }) {
    final key = _getKey(S, name);

    _InstanceBuilderFactory<S>? dep;
    if (_singletons.containsKey(key)) {
      final newDep = _singletons[key];
      if (newDep == null || !newDep.isDirty) {
        return;
      } else {
        if (newDep is _InstanceBuilderFactory<S>) {
          dep = newDep;
        }
      }
    }
    _singletons[key] = _InstanceBuilderFactory<S>(
      isSingleton: isSingleton,
      builderFunc: builder,
      permanent: permanent,
      isInit: false,
      fenix: fenix,
      tag: name,
      lateRemove: dep,
      // When this registration is created by a page binding's
      // `dependencies()`, remember which route declared it so the first
      // resolution links the instance to the declaring page's route even
      // if it happens under another route (e.g. a deep-linked child page
      // running its ancestors' merged bindings).
      bindingOwnerRouteName:
          RouterReportManager.instance.currentBindingOwnerName,
    );
  }

  /// Initializes the dependencies for a Class Instance [S] (or tag),
  /// If its a Controller, it starts the lifecycle process.
  /// Optionally associating the current Route to the lifetime of the instance,
  /// if `Get.smartManagement` is marked as [SmartManagement.full] or
  /// [SmartManagement.keepFactory]
  /// Only flags `isInit` if it's using `Get.create()`
  /// (not for Singletons access).
  /// Returns the instance if not initialized, required for Get.create() to
  /// work properly.
  S? _initDependencies<S>({String? name}) {
    final key = _getKey(S, name);
    final dep = _singletons[key];
    if (dep == null) return null;
    final isInit = dep.isInit;
    S? i;
    if (!isInit) {
      final isSingleton = dep.isSingleton ?? false;
      if (isSingleton) {
        dep.isInit = true;
      }
      i = _startController<S>(tag: name);

      if (isSingleton) {
        if (Get.smartManagement != SmartManagement.onlyBuilder) {
          RouterReportManager.instance.reportDependencyLinkedToRoute(
            _getKey(S, name),
            ownerRouteName: dep.bindingOwnerRouteName,
          );
        }
      }
    }
    return i;
  }

  InstanceInfo getInstanceInfo<S>({String? tag}) {
    final build = _getDependency<S>(tag: tag);

    return InstanceInfo(
      isPermanent: build?.permanent,
      isSingleton: build?.isSingleton,
      isRegistered: isRegistered<S>(tag: tag),
      isPrepared: !(build?.isInit ?? true),
      isInit: build?.isInit,
    );
  }

  _InstanceBuilderFactory<Object?>? _getDependency<S>({
    String? tag,
    String? key,
  }) {
    final newKey = key ?? _getKey(S, tag);

    if (!_singletons.containsKey(newKey)) {
      Get.log('Instance "$newKey" is not registered.', isError: true);
      return null;
    } else {
      return _singletons[newKey];
    }
  }

  void markAsDirty<S>({String? tag, String? key}) {
    final newKey = key ?? _getKey(S, tag);
    if (_singletons.containsKey(newKey)) {
      final dep = _singletons[newKey];
      if (dep != null && !dep.permanent) {
        dep.isDirty = true;
      }
    }
  }

  /// Initializes the controller
  S _startController<S>({String? tag}) {
    final key = _getKey(S, tag);
    final dep = _singletons[key];
    if (dep == null) {
      throw InstanceNotFoundException(
        'Instance "$S" with tag "$tag" not found',
      );
    }
    final i = dep.getDependency() as S;
    if (i is GetLifeCycleMixin) {
      i.onStart();
      if (tag == null) {
        Get.log('Instance "$S" has been initialized');
      } else {
        Get.log('Instance "$S" with tag "$tag" has been initialized');
      }
      if (dep.isSingleton == false) {
        RouterReportManager.instance.appendRouteByCreate(i);
      }
    }
    return i;
  }

  /// Finds an existing registered instance of type [S], or creates and registers a new one
  /// using [dep] if not already registered.
  ///
  /// - [tag] Optional tag to identify the instance.
  S putOrFind<S>(InstanceBuilderCallback<S> dep, {String? tag}) {
    final key = _getKey(S, tag);

    if (_singletons.containsKey(key)) {
      final existing = _singletons[key];
      if (existing == null) {
        return put(dep(), tag: tag);
      }
      return existing.getDependency() as S;
    } else {
      return put(dep(), tag: tag);
    }
  }

  /// Finds the registered type <[S]> (or [tag])
  /// In case of using Get.create to register a type <[S]> or [tag],
  /// it will create an instance each time you call [find].
  /// If the registered type <[S]> (or [tag]) is a Controller,
  /// it will initialize its lifecycle.
  S find<S>({String? tag}) {
    final key = _getKey(S, tag);
    if (isRegistered<S>(tag: tag)) {
      final dep = _singletons[key];
      if (dep == null) {
        if (tag == null) {
          throw InstanceNotFoundException('Class "$S" is not registered');
        } else {
          throw InstanceNotFoundException(
            'Class "$S" with tag "$tag" is not registered',
          );
        }
      }

      /// The lifecycle starts inside `initDependencies`, so we return
      /// the instance from there to make it compatible with `Get.create()`.
      final i = _initDependencies<S>(name: tag);
      if (i != null) return i;
      return dep.getDependency() as S;
    } else {
      // ignore: lines_longer_than_80_chars
      throw InstanceNotFoundException(
        '"$S" not found. You need to call "Get.put($S())" or "Get.lazyPut(()=>$S())"',
      );
    }
  }

  /// Finds and returns the registered instance of type [S] if it exists, otherwise returns `null`.
  ///
  /// - [tag] Optional tag to identify the instance.
  S? findOrNull<S>({String? tag}) {
    if (isRegistered<S>(tag: tag)) {
      return find<S>(tag: tag);
    }
    return null;
  }

  /// Replaces an existing registered instance of type [P] with a new [child] instance.
  ///
  /// If the existing instance is permanent, it will be forcefully deleted first before
  /// the new child is registered.
  ///
  /// Registrations that [delete] intentionally keeps alive (a `fenix`
  /// factory kept for resurrection, a [GetxService], or an entry whose
  /// `lateRemove` disposal is still pending) are evicted outright, so the
  /// new [child] always takes their place.
  ///
  /// - [tag] Optional tag to identify the instance.
  void replace<P>(P child, {String? tag}) {
    final info = getInstanceInfo<P>(tag: tag);
    final permanent = (info.isPermanent ?? false);
    delete<P>(tag: tag, force: permanent);
    _evictSurvivingRegistration(_getKey(P, tag));
    put(child, tag: tag, permanent: permanent);
  }

  /// Replaces an existing registered dependency of type [P] with a new lazy factory [builder].
  ///
  /// If the existing instance is permanent, it will be forcefully deleted first.
  ///
  /// Registrations that [delete] intentionally keeps alive (a `fenix`
  /// factory kept for resurrection, a [GetxService], or an entry whose
  /// `lateRemove` disposal is still pending) are evicted outright, so the
  /// new [builder] always takes their place.
  ///
  /// - [tag] Optional tag to identify the instance.
  /// - [fenix] If true, the builder callback will persist in memory to recreate the instance if deleted.
  ///   If not provided, defaults to true if the parent instance was permanent.
  void lazyReplace<P>(
    InstanceBuilderCallback<P> builder, {
    String? tag,
    bool? fenix,
  }) {
    final info = getInstanceInfo<P>(tag: tag);
    final permanent = (info.isPermanent ?? false);
    delete<P>(tag: tag, force: permanent);
    _evictSurvivingRegistration(_getKey(P, tag));
    lazyPut(builder, tag: tag, fenix: fenix ?? permanent);
  }

  /// Removes a registration that survived [delete] so that a follow-up
  /// [put]/[lazyPut] issued by [replace]/[lazyReplace] registers the new
  /// builder instead of being ignored by `_insert`.
  ///
  /// [delete] keeps an entry registered when it is a `fenix` factory
  /// (retained for resurrection), a live [GetxService], or when a
  /// `lateRemove` chain is pending (in which case only the oldest
  /// superseded factory was peeled off). Any instance in the surviving
  /// entry that has not yet received `onDelete` gets it here; `onDelete`
  /// is idempotent, so instances already disposed by [delete] are safe.
  void _evictSurvivingRegistration(String key) {
    final dep = _singletons[key];
    if (dep == null) return;

    var stale = dep.lateRemove;
    while (stale != null) {
      final i = stale.dependency;
      if (i is GetLifeCycleMixin) {
        i.onDelete();
        Get.log('"$key" onDelete() called');
      }
      stale = stale.lateRemove;
    }

    final i = dep.dependency;
    if (i is GetLifeCycleMixin) {
      i.onDelete();
      Get.log('"$key" onDelete() called');
    }

    _singletons.remove(key);
    Get.log('"$key" deleted from memory');
  }

  /// Generates the key based on [type] (and optionally a [name])
  /// to register an Instance Builder in the hashmap.
  ///
  /// A nullable [type] is normalized to its non-nullable form, so a
  /// registration whose generic argument was inferred as nullable (e.g.
  /// `MyController? c = Get.put(MyController());`) shares the same key
  /// as `Get.put<MyController>(...)` and `Get.find<MyController>()`.
  String _getKey(Type type, String? name) {
    final typeName = type.toString();
    final cleanType = typeName.endsWith('?')
        ? typeName.substring(0, typeName.length - 1)
        : typeName;
    return name == null ? cleanType : '$cleanType$name';
  }

  /// Delete registered Class Instance [S] (or [tag]) and, closes any open
  /// controllers `DisposableInterface`, cleans up the memory
  ///
  /// Deletes the Instance<[S]>, cleaning the memory and closes any open
  /// controllers (`DisposableInterface`).
  ///
  /// If the registration was replaced while the previous route was still
  /// disposing (the superseded factory is kept in `lateRemove`), only the
  /// superseded instance is disposed and the fresh registration stays
  /// alive, in which case this returns `false`.
  ///
  /// - [tag] Optional "tag" used to register the Instance
  /// - [key] For internal usage, is the processed key used to register
  ///   the Instance. **don't use** it unless you know what you are doing.
  /// - [force] Will delete an Instance even if marked as `permanent`.
  bool delete<S>({String? tag, String? key, bool force = false}) {
    final newKey = key ?? _getKey(S, tag);

    if (!_singletons.containsKey(newKey)) {
      Get.log('Instance "$newKey" already removed.', isError: true);
      return false;
    }

    final dep = _singletons[newKey];

    if (dep == null) return false;

    if (dep.lateRemove != null) {
      // The registration was replaced while a previous route was still
      // disposing. Each pending disposal peels off the oldest superseded
      // factory; the live registration is only removed once no superseded
      // factory remains.
      var parent = dep;
      while (parent.lateRemove!.lateRemove != null) {
        parent = parent.lateRemove!;
      }
      final stale = parent.lateRemove!;
      final i = stale.dependency;
      // Note: the `GetxServiceMixin` guard is intentionally NOT applied
      // here. It exists to keep LIVE services alive across casual deletes;
      // a superseded factory in `lateRemove` has already been replaced by
      // a newer registration, so keeping it would only leak the stale
      // instance and make the live one undeletable (the guard would fire
      // on every subsequent delete before the chain is cleared).
      if (i is GetLifeCycleMixin) {
        i.onDelete();
        Get.log('"$newKey" onDelete() called');
      }
      parent.lateRemove = null;
      Get.log('"$newKey" deleted from memory');
      return false;
    }

    if (dep.permanent && !force) {
      Get.log(
        // ignore: lines_longer_than_80_chars
        '"$newKey" has been marked as permanent, SmartManagement is not authorized to delete it.',
        isError: true,
      );
      return false;
    }
    final i = dep.dependency;

    if (i is GetxServiceMixin && !force) {
      return false;
    }

    if (i is GetLifeCycleMixin) {
      i.onDelete();
      Get.log('"$newKey" onDelete() called');
    }

    if (dep.fenix) {
      dep.dependency = null;
      dep.isInit = false;
      dep.isDirty = false;
      return true;
    } else {
      _singletons.remove(newKey);
      if (_singletons.containsKey(newKey)) {
        Get.log('Error removing object "$newKey"', isError: true);
      } else {
        Get.log('"$newKey" deleted from memory');
      }
      return true;
    }
  }

  /// Deletes the dependency registered under [key] on behalf of a disposed
  /// route, keeping it alive when still-mounted widgets depend on it.
  ///
  /// Meant for internal usage of the `RouterReportManager`: when a route is
  /// disposed, the instances linked to it are deleted. An instance that
  /// still has widget subscribers (`GetBuilder`/`GetX` listeners) at that
  /// moment may be shared with widgets of another, still-visible route —
  /// e.g. a controller created during a rebuild of a lower route's subtree
  /// while the disposed route was topmost — so its deletion is deferred to
  /// the end of the frame, after the disposed route's own subtree has
  /// unmounted and released its subscriptions:
  ///
  ///  * if no subscriber remains, the instance is deleted normally;
  ///  * if subscribers remain, they belong to still-mounted widgets of
  ///    other routes and the instance is kept alive (it is disposed later
  ///    by its creator widget's unmount or an explicit delete).
  ///
  /// A registration superseded while the route was disposing (pending
  /// `lateRemove` chain) is peeled synchronously, exactly like [delete].
  void deleteRouteDependency(String key) {
    final dep = _singletons[key];
    if (dep == null) {
      Get.log('Instance "$key" already removed.', isError: true);
      return;
    }

    final live = dep.dependency;
    final hasSubscribers =
        live is ListNotifierSingleMixin &&
        !live.isDisposed &&
        live.hasSubscribers;
    if (dep.lateRemove != null || !hasSubscribers) {
      delete(key: key);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = _singletons[key];
      if (current == null) return;
      if (!identical(current, dep)) {
        // The registration was superseded meanwhile (e.g. the same key was
        // re-registered for a fresh route while this route was disposing).
        // If the stale factory is pending in the lateRemove chain, peel it
        // like the synchronous path would have; a fresh unrelated
        // registration must not be touched.
        var chain = current.lateRemove;
        while (chain != null) {
          if (identical(chain, dep)) {
            delete(key: key);
            return;
          }
          chain = chain.lateRemove;
        }
        return;
      }
      if (!live.isDisposed && live.hasSubscribers) {
        // The disposed route marked the key dirty on its way out; the
        // instance is consciously kept alive for its remaining
        // subscribers, so it must not be treated as stale by future
        // registrations.
        dep.isDirty = false;
        Get.log(
          'Instance "$key" was kept alive on route disposal: '
          'widgets are still subscribed to it.',
        );
        return;
      }
      delete(key: key);
    });
  }

  /// Deletes all registered instances from memory, invokes their onDelete/close lifecycles,
  /// and cleans up resources.
  ///
  /// - [force] If true, deletes even the instances marked as `permanent`.
  void deleteAll({bool force = false}) {
    final keys = _singletons.keys.toList();
    for (final key in keys) {
      delete(key: key, force: force);
    }
  }

  /// Reloads all registered instances by clearing their active dependency objects
  /// and resetting their initialization states.
  ///
  /// Each initialized instance receives its `onDelete` lifecycle (which
  /// triggers `onClose`) before being cleared, mirroring [reload].
  /// Instances marked as `permanent` and [GetxService]s are skipped
  /// unless [force] is true.
  ///
  /// - [force] If true, reloads even the instances marked as `permanent`
  ///   and `GetxService`s.
  void reloadAll({bool force = false}) {
    // Iterate over a snapshot of the keys (like [deleteAll]): the `onDelete`
    // lifecycle below runs user `onClose` callbacks, which may mutate the
    // registry (e.g. `Get.delete<Other>()`, `Get.put`) and would otherwise
    // throw a ConcurrentModificationError mid-iteration.
    final keys = _singletons.keys.toList();
    for (final key in keys) {
      final value = _singletons[key];
      if (value == null) {
        // Removed by a lifecycle callback of a previously reloaded instance.
        continue;
      }
      if (value.permanent && !force) {
        Get.log('Instance "$key" is permanent. Skipping reload');
        continue;
      }

      final i = value.dependency;

      if (i is GetxServiceMixin && !force) {
        Get.log('Instance "$key" is a GetxService. Skipping reload');
        continue;
      }

      if (i is GetLifeCycleMixin) {
        i.onDelete();
        Get.log('"$key" onDelete() called');
      }

      value.dependency = null;
      value.isInit = false;
      Get.log('Instance "$key" was reloaded.');
    }
  }

  /// Reloads/restarts a specific registered dependency of type [S].
  ///
  /// Clears the active dependency object and calls its `onDelete` lifecycle
  /// before resetting its initialization state.
  ///
  /// - [tag] Optional tag to identify the instance.
  /// - [key] Optional unique registry key.
  /// - [force] If true, reloads even if the instance is marked as `permanent`.
  void reload<S>({String? tag, String? key, bool force = false}) {
    final newKey = key ?? _getKey(S, tag);

    final builder = _getDependency<S>(tag: tag, key: newKey);
    if (builder == null) return;

    if (builder.permanent && !force) {
      Get.log(
        '''Instance "$newKey" is permanent. Use [force = true] to force the restart.''',
        isError: true,
      );
      return;
    }

    final i = builder.dependency;

    if (i is GetxServiceMixin && !force) {
      return;
    }

    if (i is GetLifeCycleMixin) {
      i.onDelete();
      Get.log('"$newKey" onDelete() called');
    }

    builder.dependency = null;
    builder.isInit = false;
    Get.log('Instance "$newKey" was restarted.');
  }

  /// Checks whether an instance of type [S] (and optionally with [tag]) is registered in memory.
  ///
  /// - [tag] Optional tag to identify the instance.
  bool isRegistered<S>({String? tag}) =>
      _singletons.containsKey(_getKey(S, tag));

  /// Checks whether a lazy factory callback for type [S] (and optionally with [tag]) is registered
  /// and ready to be initialized.
  ///
  /// - [tag] Optional tag to identify the lazy instance.
  bool isPrepared<S>({String? tag}) {
    final newKey = _getKey(S, tag);
    final builder = _getDependency<S>(tag: tag, key: newKey);
    return builder != null && !builder.isInit;
  }
}

/// Callback type for building singleton or lazy instances of type [S].
typedef InstanceBuilderCallback<S> = S Function();

/// Callback type for building instances of type [S] on demand using [BuildContext].
typedef InstanceCreateBuilderCallback<S> = S Function(BuildContext _);

/// Callback type for asynchronously building instances of type [S].
typedef AsyncInstanceBuilderCallback<S> = Future<S> Function();

/// Internal class to register instances with `Get.put<S>()`.
class _InstanceBuilderFactory<S> {
  /// Marks the Builder as a single instance.
  /// For reusing [dependency] instead of [builderFunc]
  bool? isSingleton;

  /// When fenix mode is available, when a new instance is need
  /// Instance manager will recreate a new instance of S
  bool fenix;

  /// Stores the actual object instance when [isSingleton]=true.
  S? dependency;

  /// Generates (and regenerates) the instance when [isSingleton]=false.
  /// Usually used by factory methods
  InstanceBuilderCallback<S> builderFunc;

  /// Flag to persist the instance in memory,
  /// without considering `Get.smartManagement`
  bool permanent = false;

  bool isInit = false;

  _InstanceBuilderFactory<S>? lateRemove;

  bool isDirty = false;

  String? tag;

  /// The name of the route whose page binding created this registration,
  /// or `null` when it was not created by a page binding. Used to link the
  /// instance to the declaring page's route on its first resolution.
  final String? bindingOwnerRouteName;

  _InstanceBuilderFactory({
    required this.isSingleton,
    required this.builderFunc,
    required this.permanent,
    required this.isInit,
    required this.fenix,
    required this.tag,
    required this.lateRemove,
    this.bindingOwnerRouteName,
  });

  void _showInitLog() {
    if (tag == null) {
      Get.log('Instance "$S" has been created');
    } else {
      Get.log('Instance "$S" has been created with tag "$tag"');
    }
  }

  /// Gets the actual instance by its [builderFunc] or the persisted instance.
  S getDependency() {
    if (isSingleton ?? false) {
      if (dependency case final dep?) {
        return dep;
      }
      _showInitLog();
      return dependency = builderFunc();
    }
    return builderFunc();
  }
}
