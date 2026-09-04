import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../get_instance/src/bindings_interface.dart';
import '../../../get_navigation.dart';

class GetPage<T> extends Page<T> {
  final GetPageBuilder page;
  final bool? popGesture;
  final Map<String, String>? parameters;
  final String? title;
  final Transition? transition;
  final Curve curve;
  final bool? participatesInRootNavigator;
  final Alignment? alignment;
  final bool maintainState;
  final bool opaque;
  final double Function(BuildContext context)? gestureWidth;
  final List<Binding> bindings;
  final CustomTransition? customTransition;
  final Duration? transitionDuration;
  final Duration? reverseTransitionDuration;
  final bool fullscreenDialog;

  /// Whether the route created for this page prefers to animate a snapshot
  /// of the entering/exiting pages during transitions
  /// ([PageRoute.allowSnapshotting]).
  ///
  /// Set this to `false` when the page keeps animating while a transition
  /// runs (e.g. ripples, shimmers or videos), which a snapshot would
  /// freeze.
  final bool allowSnapshotting;
  final bool preventDuplicates;
  final Completer<T?>? completer;
  // @override
  // final LocalKey? key;

  // @override
  // RouteSettings get settings => this;

  /// The route name this page is registered under.
  ///
  /// Route names must start with a slash (e.g. `/home`); passing a name
  /// without a leading slash throws an [AssertionError] in debug mode.
  @override
  String get name => super.name!;

  final bool inheritParentPath;

  final List<GetPage> children;
  final List<GetMiddleware> middlewares;
  final GetPage? unknownRoute;
  final bool showCupertinoParallax;

  final PreventDuplicateHandlingMode preventDuplicateHandlingMode;

  static void _defaultPopInvokedHandler(bool didPop, Object? result) {}

  GetPage({
    required String name,
    required this.page,
    this.title,
    this.participatesInRootNavigator,
    this.gestureWidth,
    // RouteSettings settings,
    this.maintainState = true,
    this.curve = Curves.linear,
    this.alignment,
    this.parameters,
    this.opaque = true,
    this.transitionDuration,
    this.reverseTransitionDuration,
    this.popGesture,
    this.bindings = const [],
    this.transition,
    this.customTransition,
    this.fullscreenDialog = false,
    this.allowSnapshotting = true,
    this.children = const <GetPage>[],
    this.middlewares = const [],
    this.unknownRoute,
    super.arguments,
    this.showCupertinoParallax = true,
    this.preventDuplicates = true,
    this.preventDuplicateHandlingMode =
        PreventDuplicateHandlingMode.reorderRoutes,
    this.completer,
    this.inheritParentPath = true,
    LocalKey? key,
    super.canPop,
    super.onPopInvoked = _defaultPopInvokedHandler,
    super.restorationId,
  }) : assert(
         name.startsWith('/'),
         'Invalid route name: "$name". '
         'GetPage route names must start with a slash "/". '
         'Use "/$name" instead of "$name".',
       ),
       super(key: key ?? ValueKey(name), name: name);
  // settings = RouteSettings(name: name, arguments: Get.arguments);

  GetPage<T> copyWith({
    LocalKey? key,
    String? name,
    GetPageBuilder? page,
    bool? popGesture,
    Map<String, String>? parameters,
    String? title,
    Transition? transition,
    Curve? curve,
    Alignment? alignment,
    bool? maintainState,
    bool? opaque,
    List<Binding>? bindings,
    CustomTransition? customTransition,
    Duration? transitionDuration,
    Duration? reverseTransitionDuration,
    bool? fullscreenDialog,
    bool? allowSnapshotting,
    RouteSettings? settings,
    List<GetPage<T>>? children,
    GetPage? unknownRoute,
    List<GetMiddleware>? middlewares,
    bool? preventDuplicates,
    PreventDuplicateHandlingMode? preventDuplicateHandlingMode,
    final double Function(BuildContext context)? gestureWidth,
    bool? participatesInRootNavigator,
    Object? arguments,
    bool? showCupertinoParallax,
    Completer<T?>? completer,
    bool? inheritParentPath,
    bool? canPop,
    PopInvokedWithResultCallback<T>? onPopInvoked,
    String? restorationId,
  }) {
    return GetPage(
      key: key ?? this.key,
      participatesInRootNavigator:
          participatesInRootNavigator ?? this.participatesInRootNavigator,
      preventDuplicates: preventDuplicates ?? this.preventDuplicates,
      preventDuplicateHandlingMode:
          preventDuplicateHandlingMode ?? this.preventDuplicateHandlingMode,
      name: name ?? this.name,
      page: page ?? this.page,
      popGesture: popGesture ?? this.popGesture,
      parameters: parameters ?? this.parameters,
      title: title ?? this.title,
      transition: transition ?? this.transition,
      curve: curve ?? this.curve,
      alignment: alignment ?? this.alignment,
      maintainState: maintainState ?? this.maintainState,
      opaque: opaque ?? this.opaque,
      bindings: bindings ?? this.bindings,
      customTransition: customTransition ?? this.customTransition,
      transitionDuration: transitionDuration ?? this.transitionDuration,
      reverseTransitionDuration:
          reverseTransitionDuration ?? this.reverseTransitionDuration,
      fullscreenDialog: fullscreenDialog ?? this.fullscreenDialog,
      allowSnapshotting: allowSnapshotting ?? this.allowSnapshotting,
      children: children ?? this.children,
      unknownRoute: unknownRoute ?? this.unknownRoute,
      middlewares: middlewares ?? this.middlewares,
      gestureWidth: gestureWidth ?? this.gestureWidth,
      arguments: arguments ?? this.arguments,
      showCupertinoParallax:
          showCupertinoParallax ?? this.showCupertinoParallax,
      completer: completer ?? this.completer,
      inheritParentPath: inheritParentPath ?? this.inheritParentPath,
      canPop: canPop ?? this.canPop,
      onPopInvoked: onPopInvoked ?? this.onPopInvoked,
      restorationId: restorationId ?? this.restorationId,
    );
  }

  @override
  Route<T> createRoute(BuildContext context) {
    // return GetPageRoute<T>(settings: this, page: page);
    final page = PageRedirect(
      route: this,
      settings: this,
      unknownRoute: unknownRoute,
    ).getPageToRoute<T>(this, unknownRoute, context);

    return page;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetPage<T> && other.key == key;
  }

  @override
  String toString() =>
      '${objectRuntimeType(this, 'Page')}("$name", $key, $arguments)';

  @override
  int get hashCode {
    return key.hashCode;
  }
}
