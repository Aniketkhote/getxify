import 'dart:async';

import 'package:flutter/material.dart';

import '../../../get_core/get_core.dart';
import '../../../get_instance/get_instance.dart';
import '../../get_state_manager.dart';
import 'list_notifier.dart';

typedef InitBuilder<T> = T Function();

typedef GetControllerBuilder<T extends GetLifeCycleMixin> =
    Widget Function(T controller);

extension WatchExt on BuildContext {
  T listen<T>() {
    return Bind.of(this, rebuild: true);
  }
}

extension ReadExt on BuildContext {
  T get<T>() {
    return Bind.of(this);
  }
}

class _GetBuilderInner<T extends GetxController> extends StatefulWidget {
  final T controller;
  final Object? id;
  final Object Function(T value)? filter;
  final GetControllerBuilder<T> builder;

  const _GetBuilderInner({
    required this.controller,
    required this.id,
    required this.filter,
    required this.builder,
  });

  @override
  State<_GetBuilderInner<T>> createState() => _GetBuilderInnerState<T>();
}

class _GetBuilderInnerState<T extends GetxController>
    extends State<_GetBuilderInner<T>> {
  Object? _lastFilterValue;
  Widget? _cachedWidget;

  @override
  Widget build(BuildContext context) {
    Listenable listenable;
    if (widget.id != null) {
      listenable = widget.controller.ensureGroupListenable(widget.id!);
    } else {
      listenable = widget.controller;
    }

    return ListenableBuilder(
      listenable: listenable,
      builder: (context, _) {
        if (widget.filter != null) {
          final newFilter = widget.filter!(widget.controller);
          if (newFilter == _lastFilterValue && _cachedWidget != null) {
            return _cachedWidget!;
          }
          _lastFilterValue = newFilter;
        }
        _cachedWidget = widget.builder(widget.controller);
        return _cachedWidget!;
      },
    );
  }
}

class GetBuilder<T extends GetxController> extends StatelessWidget {
  final GetControllerBuilder<T> builder;
  final bool global;
  final Object? id;
  final String? tag;
  final bool autoRemove;
  final bool assignId;
  final Object Function(T value)? filter;
  final void Function(BindElement<T> state)? initState,
      dispose,
      didChangeDependencies;
  final void Function(Binder<T> oldWidget, BindElement<T> state)?
  didUpdateWidget;
  final T? init;

  const GetBuilder({
    super.key,
    this.init,
    this.global = true,
    required this.builder,
    this.autoRemove = true,
    this.assignId = false,
    this.initState,
    this.filter,
    this.tag,
    this.dispose,
    this.id,
    this.didChangeDependencies,
    this.didUpdateWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Binder(
      init: init == null ? null : () => init!,
      global: global,
      autoRemove: autoRemove,
      assignId: assignId,
      initState: initState,
      tag: tag,
      dispose: dispose,
      lazy: false,
      didChangeDependencies: didChangeDependencies,
      didUpdateWidget: didUpdateWidget,
      child: Builder(
        builder: (context) {
          final controller = Bind.of<T>(context, rebuild: false);
          return _GetBuilderInner<T>(
            controller: controller,
            id: id,
            filter: filter,
            builder: builder,
          );
        },
      ),
    );
  }
}

abstract class Bind<T> extends StatelessWidget {
  const Bind({
    super.key,
    required this.child,
    this.init,
    this.global = true,
    this.autoRemove = true,
    this.assignId = false,
    this.initState,
    this.tag,
    this.dispose,
    this.didChangeDependencies,
    this.didUpdateWidget,
  });

  final InitBuilder<T>? init;

  final bool global;
  final String? tag;
  final bool autoRemove;
  final bool assignId;
  final void Function(BindElement<T> state)? initState,
      dispose,
      didChangeDependencies;
  final void Function(Binder<T> oldWidget, BindElement<T> state)?
  didUpdateWidget;

  final Widget? child;

  static Bind put<S>(S dependency, {String? tag, bool permanent = false}) {
    Get.put<S>(dependency, tag: tag, permanent: permanent);
    return _FactoryBind<S>(autoRemove: permanent, assignId: true, tag: tag);
  }

  static bool fenixMode = false;

  static Bind lazyPut<S>(
    InstanceBuilderCallback<S> builder, {
    String? tag,
    bool? fenix,
    VoidCallback? onClose,
  }) {
    Get.lazyPut<S>(builder, tag: tag, fenix: fenix ?? fenixMode);
    return _FactoryBind<S>(
      tag: tag,
      dispose: (_) {
        onClose?.call();
      },
    );
  }

  static Bind create<S>(
    InstanceCreateBuilderCallback<S> builder, {
    String? tag,
    bool permanent = true,
  }) {
    return _FactoryBind<S>(create: builder, tag: tag, global: false);
  }

  static Bind spawn<S>(
    InstanceBuilderCallback<S> builder, {
    String? tag,
    bool permanent = true,
  }) {
    Get.spawn<S>(builder, tag: tag, permanent: permanent);
    return _FactoryBind<S>(tag: tag, global: false, autoRemove: permanent);
  }

  static S find<S>({String? tag}) => Get.find<S>(tag: tag);

  static Future<bool> delete<S>({String? tag, bool force = false}) async =>
      Get.delete<S>(tag: tag, force: force);

  static Future<void> deleteAll({bool force = false}) async =>
      Get.deleteAll(force: force);

  static void reloadAll({bool force = false}) => Get.reloadAll(force: force);

  static void reload<S>({String? tag, String? key, bool force = false}) =>
      Get.reload<S>(tag: tag, key: key, force: force);

  static bool isRegistered<S>({String? tag}) => Get.isRegistered<S>(tag: tag);

  static bool isPrepared<S>({String? tag}) => Get.isPrepared<S>(tag: tag);

  /// Replaces the registered instance of type [P] with a new [child]
  /// instance.
  ///
  /// Delegates to [Get.replace], so registrations that a plain [delete]
  /// keeps alive (a `fenix` factory, a [GetxService], or an entry with a
  /// pending `lateRemove` disposal) are evicted and the new [child] always
  /// takes their place.
  ///
  /// - [tag] Optional tag to identify the instance.
  static void replace<P>(P child, {String? tag}) =>
      Get.replace<P>(child, tag: tag);

  /// Replaces the registered dependency of type [P] with a new lazy
  /// factory [builder].
  ///
  /// Delegates to [Get.lazyReplace], so registrations that a plain
  /// [delete] keeps alive (a `fenix` factory, a [GetxService], or an entry
  /// with a pending `lateRemove` disposal) are evicted and the new
  /// [builder] always takes their place.
  ///
  /// - [tag] Optional tag to identify the instance.
  /// - [fenix] If true, the builder persists in memory to recreate the
  ///   instance if deleted. Defaults to true when the replaced instance
  ///   was permanent.
  static void lazyReplace<P>(
    InstanceBuilderCallback<P> builder, {
    String? tag,
    bool? fenix,
  }) => Get.lazyReplace<P>(builder, tag: tag, fenix: fenix);

  /// Injects an instance of [S] built asynchronously by [builder] into the
  /// dependency manager, returning a [Bind] for the registered instance.
  ///
  /// Delegates to [Get.putAsync]: the [builder] future is awaited and the
  /// resulting instance is registered like [put], so the regular lifecycle
  /// (`onInit`/`onReady`) runs on the ready instance. Perform any
  /// asynchronous setup inside [builder] **before** returning the instance.
  ///
  /// - [tag] Optional tag to identify this specific instance.
  /// - [permanent] If true, prevents the instance from being deleted by
  ///   SmartManagement.
  static Future<Bind<S>> putAsync<S>(
    AsyncInstanceBuilderCallback<S> builder, {
    String? tag,
    bool permanent = false,
  }) async {
    await Get.putAsync<S>(builder, tag: tag, permanent: permanent);
    return _FactoryBind<S>(autoRemove: permanent, assignId: true, tag: tag);
  }

  factory Bind.builder({
    Widget? child,
    InitBuilder<T>? init,
    InstanceCreateBuilderCallback<T>? create,
    bool global = true,
    bool autoRemove = true,
    bool assignId = false,
    String? tag,
    void Function(BindElement<T> state)? initState,
    void Function(BindElement<T> state)? dispose,
    void Function(BindElement<T> state)? didChangeDependencies,
    void Function(Binder<T> oldWidget, BindElement<T> state)? didUpdateWidget,
  }) => _FactoryBind<T>(
    init: init,
    create: create,
    global: global,
    autoRemove: autoRemove,
    assignId: assignId,
    initState: initState,
    tag: tag,
    dispose: dispose,
    didChangeDependencies: didChangeDependencies,
    didUpdateWidget: didUpdateWidget,
    child: child,
  );

  static T of<T>(BuildContext context, {bool rebuild = false}) {
    final inheritedElement =
        context.getElementForInheritedWidgetOfExactType<Binder<T>>()
            as BindElement<T>?;

    if (inheritedElement == null) {
      throw BindError(controller: '$T', tag: null);
    }

    if (rebuild) {
      context.dependOnInheritedElement(inheritedElement);
    }

    final controller = inheritedElement.controller;

    return controller;
  }

  @factory
  Bind<T> _copyWithChild(Widget child);
}

class _FactoryBind<T> extends Bind<T> {
  final InstanceCreateBuilderCallback<T>? create;

  const _FactoryBind({
    super.key,
    super.child,
    super.init,
    this.create,
    super.global = true,
    super.autoRemove = true,
    super.assignId = false,
    super.initState,
    super.tag,
    super.dispose,
    super.didChangeDependencies,
    super.didUpdateWidget,
  });

  @override
  Bind<T> _copyWithChild(Widget child) {
    return Bind<T>.builder(
      init: init,
      create: create,
      global: global,
      autoRemove: autoRemove,
      assignId: assignId,
      initState: initState,
      tag: tag,
      dispose: dispose,
      didChangeDependencies: didChangeDependencies,
      didUpdateWidget: didUpdateWidget,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Binder<T>(
      create: create,
      global: global,
      autoRemove: autoRemove,
      assignId: assignId,
      initState: initState,
      tag: tag,
      dispose: dispose,
      didChangeDependencies: didChangeDependencies,
      didUpdateWidget: didUpdateWidget,
      child: child!,
    );
  }
}

class Binds extends StatelessWidget {
  final List<Bind<Object?>> binds;
  final Widget child;

  Binds({super.key, required this.binds, required this.child})
    : assert(binds.isNotEmpty);

  @override
  Widget build(BuildContext context) =>
      binds.reversed.fold(child, (widget, e) => e._copyWithChild(widget));
}

class Binder<T> extends InheritedWidget {
  /// Create an inherited widget that updates its dependents when [controller]
  /// sends notifications.
  ///
  /// The [child] argument is required
  const Binder({
    super.key,
    required super.child,
    this.init,
    this.global = true,
    this.autoRemove = true,
    this.assignId = false,
    this.lazy = true,
    this.initState,
    this.tag,
    this.dispose,
    this.didChangeDependencies,
    this.didUpdateWidget,
    this.create,
  });

  final InitBuilder<T>? init;
  final InstanceCreateBuilderCallback? create;
  final bool global;
  final String? tag;
  final bool lazy;
  final bool autoRemove;
  final bool assignId;
  final void Function(BindElement<T> state)? initState,
      dispose,
      didChangeDependencies;
  final void Function(Binder<T> oldWidget, BindElement<T> state)?
  didUpdateWidget;

  @override
  bool updateShouldNotify(Binder<T> oldWidget) {
    return oldWidget.tag != tag ||
        oldWidget.global != global ||
        oldWidget.autoRemove != autoRemove ||
        oldWidget.assignId != assignId;
  }

  @override
  InheritedElement createElement() => BindElement<T>(this);
}

/// The BindElement is responsible for injecting dependencies into the widget
/// tree so that they can be observed
class BindElement<T> extends InheritedElement {
  BindElement(Binder<T> super.widget) {
    initState();
  }

  final disposers = <Disposer>[];

  InitBuilder<T>? _controllerBuilder;

  T? _controller;

  T get controller {
    if (_controller == null) {
      _controller = _controllerBuilder?.call();
      _subscribeToController();
      if (_controller == null) {
        throw BindError(controller: T, tag: widget.tag);
      }
      return _controller!;
    } else {
      return _controller!;
    }
  }

  bool? _isCreator = false;
  bool? _needStart = false;
  bool _wasStarted = false;
  VoidCallback? _remove;

  void initState() {
    _resolveController(widget);
    widget.initState?.call(this);
  }

  /// Resolves the controller this element binds to, using [binder]'s
  /// configuration (tag, `init`/`create` builders, `global`).
  ///
  /// Called from [initState] with the initial widget and from [update]
  /// with the incoming widget when its `tag` changed, so the element
  /// rebinds to the instance registered under the new tag.
  void _resolveController(Binder<T> binder) {
    var isRegistered = Get.isRegistered<T>(tag: binder.tag);

    if (binder.global) {
      if (isRegistered) {
        if (Get.isPrepared<T>(tag: binder.tag)) {
          _isCreator = true;
        } else {
          _isCreator = false;
        }

        _controllerBuilder = () => Get.find<T>(tag: binder.tag);
      } else {
        if (binder.create == null && binder.init == null) {
          throw BindError(
            controller: T,
            tag: binder.tag,
            message:
                'No instance of "$T" '
                '${binder.tag == null ? 'without a tag' : 'with tag "${binder.tag}"'} '
                'is registered, and no "init" or "create" builder was '
                'supplied to this GetBuilder/Bind. If "$T" was registered '
                'with Get.put(..., tag: ...), pass the same tag to this '
                'widget, or provide an "init"/"create" builder so it can '
                'create the instance itself.',
          );
        }
        _controllerBuilder = () =>
            (binder.create?.call(this) ?? binder.init?.call());
        _isCreator = true;
        if (binder.lazy) {
          Get.lazyPut<T>(_controllerBuilder!, tag: binder.tag);
        } else {
          Get.put<T>(_controllerBuilder!(), tag: binder.tag);
        }
      }
    } else {
      if (binder.create != null) {
        _controllerBuilder = () => binder.create!.call(this);
        Get.spawn<T>(_controllerBuilder!, tag: binder.tag, permanent: false);
      } else {
        _controllerBuilder = binder.init;
      }
      _isCreator = true;
      _needStart = true;
    }
  }

  /// Register to listen Controller's events.
  /// It gets a reference to the remove() callback, to delete the
  /// setState "link" from the Controller.
  void _subscribeToController() {
    final localController = _controller;

    if (_needStart == true && localController is GetLifeCycleMixin) {
      localController.onStart();
      _needStart = false;
      _wasStarted = true;
    }

    if (localController is Listenable) {
      _remove?.call();
      localController.addListener(getUpdate);
      _remove = () => localController.removeListener(getUpdate);
    } else if (localController is StreamController) {
      _remove?.call();
      final stream = localController.stream.listen((_) => getUpdate());
      _remove = () => stream.cancel();
    }

    _tickerProvider = localController is GetTickerProvider
        ? localController
        : null;
    _updateTickerMode();
  }

  bool _isMounted = false;

  /// The controller cast to [GetTickerProvider] when it uses
  /// [GetSingleTickerProviderStateMixin] or [GetTickerProviderStateMixin],
  /// cached in [_subscribeToController] so [_updateTickerMode] does not
  /// repeat the type check on every dependency change.
  GetTickerProvider? _tickerProvider;

  /// Forwards this element's [TickerMode] to the controller when it is a
  /// [GetTickerProvider], so its tickers are muted while tickers are
  /// disabled in this subtree.
  void _updateTickerMode() {
    if (!_isMounted) return;
    _tickerProvider?.didChangeDependencies(this);
  }

  /// Marks controllers whose disposal was requested by their creator
  /// element while other elements were still subscribed, so the last
  /// unsubscribing element can finish the disposal.
  static final Expando<bool> _deferredDisposal = Expando<bool>();

  /// Whether [controller] still has live listeners other than this
  /// element's own (already removed) subscription — e.g. a freshly
  /// inflated [BindElement] that replaced this one after a tree-shape
  /// change (LayoutBuilder breakpoint swap), or another `GetBuilder`
  /// on the same still-visible page.
  static bool _hasOtherSubscribers(Object? controller) =>
      controller is ListNotifierSingleMixin &&
      !controller.isDisposed &&
      controller.hasSubscribers;

  /// Finishes a disposal deferred by this controller's creator element:
  /// deletes the controller from the registry when it is still the
  /// registered singleton for this key, otherwise closes the orphaned
  /// instance directly.
  void _completeDeferredDisposal(Object controller, String? tag) {
    _deferredDisposal[controller] = null;
    final info = Get.getInstanceInfo<T>(tag: tag);
    if (info.isRegistered &&
        (info.isSingleton ?? false) &&
        (info.isInit ?? false) &&
        identical(Get.find<T>(tag: tag), controller)) {
      Get.delete<T>(tag: tag);
    } else if (controller is GetLifeCycleMixin) {
      controller.onDelete();
    }
  }

  /// Detaches this element from its current controller: removes the
  /// listener subscription and applies the creator-side removal rules
  /// (autoRemove/assignId deletion, deferred disposal) against the
  /// current [widget]'s tag.
  ///
  /// Shared by [dispose] (element unmount) and [update] (rebinding when
  /// the widget's `tag` changed).
  void _unbindController() {
    _remove?.call();
    _remove = null;

    final localController = _controller;
    final oldTag = widget.tag;

    if (_isCreator! || widget.assignId) {
      if (widget.autoRemove && Get.isRegistered<T>(tag: widget.tag)) {
        if (_hasOtherSubscribers(localController)) {
          _deferredDisposal[localController as Object] = true;
          scheduleMicrotask(() {
            if (localController is ListNotifierSingleMixin &&
                _deferredDisposal[localController] == true &&
                !_hasOtherSubscribers(localController)) {
              _completeDeferredDisposal(localController, oldTag);
            }
          });
        } else {
          Get.delete<T>(tag: widget.tag);
        }
      } else if (_wasStarted &&
          widget.autoRemove &&
          localController is GetLifeCycleMixin &&
          !Get.isRegistered<T>(tag: widget.tag)) {
        if (_hasOtherSubscribers(localController)) {
          _deferredDisposal[localController as Object] = true;
          scheduleMicrotask(() {
            if (localController is ListNotifierSingleMixin &&
                _deferredDisposal[localController] == true &&
                !_hasOtherSubscribers(localController)) {
              _completeDeferredDisposal(localController, oldTag);
            }
          });
        } else {
          localController.onDelete();
        }
      }
    } else if (localController is ListNotifierSingleMixin &&
        _deferredDisposal[localController] == true &&
        !_hasOtherSubscribers(localController)) {
      _completeDeferredDisposal(localController, oldTag);
    }
  }

  void dispose() {
    widget.dispose?.call(this);

    _unbindController();

    for (final disposer in disposers) {
      disposer();
    }

    disposers.clear();

    _controller = null;
    _tickerProvider = null;
    _isCreator = null;
    _needStart = null;
    _controllerBuilder = null;
  }

  @override
  Binder<T> get widget {
    final w = super.widget;
    if (w is! Binder<T>) {
      throw StateError('Widget is not a Binder<$T>');
    }
    return w;
  }

  var _dirty = false;

  @override
  void update(Binder<T> newWidget) {
    if (widget.tag != newWidget.tag) {
      _rebindController(newWidget);
    } else {
      if (_wasStarted) {
        _subscribeToController();
      }
    }
    widget.didUpdateWidget?.call(widget, this);
    super.update(newWidget);
  }

  /// Releases the controller bound under the previous `tag` and resolves
  /// the one that [newWidget]'s tag refers to, so a rebuild that changes
  /// `tag` binds dependents to the new instance instead of keeping the
  /// stale one.
  ///
  /// The old controller goes through the same removal rules as on
  /// unmount ([_unbindController]), so a controller this element created
  /// with `autoRemove` is deleted (or defer-disposed while other
  /// elements still subscribe) under its original tag.
  void _rebindController(Binder<T> newWidget) {
    _unbindController();
    _controller = null;
    _controllerBuilder = null;
    _isCreator = false;
    _needStart = false;
    _wasStarted = false;
    _tickerProvider = null;
    _resolveController(newWidget);
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _isMounted = true;
    _updateTickerMode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTickerMode();
    widget.didChangeDependencies?.call(this);
  }

  @override
  Widget build() {
    if (_dirty) {
      notifyClients(widget);
    }
    return super.build();
  }

  void getUpdate() {
    _dirty = true;
    markNeedsBuild();
  }

  @override
  void notifyClients(Binder<T> oldWidget) {
    super.notifyClients(oldWidget);
    _dirty = false;
  }

  @override
  void unmount() {
    _isMounted = false;
    dispose();
    super.unmount();
  }
}

class BindError<T> extends Error {
  /// The type of the class the user tried to retrieve
  final T controller;

  /// The tag used in the failed lookup, if any.
  final String? tag;

  /// Optional description of why the bind failed; when provided it is
  /// used verbatim instead of the generic "no ancestor found" message.
  final String? message;

  /// Creates a [BindError]
  BindError({required this.controller, required this.tag, this.message});

  @override
  String toString() {
    if (message != null) {
      return 'Error: $message';
    }

    if (controller == 'dynamic') {
      return '''Error: please specify type [<T>] when calling context.listen<T>() or context.find<T>() method.''';
    }

    return '''Error: No Bind<$controller>  ancestor found. To fix this, please add a Bind<$controller> widget ancestor to the current context.
      ''';
  }
}

/// [Binding] should be extended.
/// When using `GetMaterialApp`, all `GetPage`s and navigation
/// methods (like Get.to()) have a `binding` property that takes an
/// instance of Bindings to manage the
/// dependencies() (via Get.put()) for the Route you are opening.
// ignore: one_member_abstracts
abstract class Binding extends BindingsInterface<List<Bind>> {}
