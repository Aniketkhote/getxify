import 'package:cupertino_ui/cupertino_ui.dart';

import '../../../../getxify.dart';

class GetPageRoute<T> extends PageRoute<T> with GetPageRouteTransitionMixin<T> {
  /// Creates a custom page route with GetX navigation features.
  ///
  /// This route supports custom transitions, bindings, middleware, and
  /// route reporting. It extends [PageRoute] and adds GetX-specific
  /// functionality for dependency injection and navigation control.
  ///
  /// The [page] or [settings] must be provided.
  ///
  /// When [allowSnapshotting] is omitted it is taken from the [GetPage]
  /// the route was created for (its [settings], for routes created through
  /// the pages API), so [GetPage.allowSnapshotting] reaches the route
  /// without extra plumbing.
  GetPageRoute({
    super.settings,
    this._allowSnapshotting,
    this.transitionDuration = const Duration(milliseconds: 300),
    this.reverseTransitionDuration = const Duration(milliseconds: 300),
    this.opaque = true,
    this.parameter,
    this.gestureWidth,
    this.curve,
    this.alignment,
    this.transition,
    this.popGesture,
    this.customTransition,
    this.barrierDismissible = false,
    this.barrierColor,
    this.bindings = const [],
    this.routeName,
    this.page,
    this.title,
    this.showCupertinoParallax = true,
    this.barrierLabel,
    this.maintainState = true,
    super.fullscreenDialog,
    this.middlewares,
    this.bindingOwnerNames,
  }) : _middlewareRunner = MiddlewareRunner(middlewares);

  /// The explicit [PageRoute.allowSnapshotting] override passed to the
  /// constructor, or `null` to defer to the [GetPage] this route was
  /// created for (see [allowSnapshotting]).
  final bool? _allowSnapshotting;

  @override
  bool get allowSnapshotting {
    final settings = this.settings;
    if (_allowSnapshotting != null) return _allowSnapshotting;
    if (settings is GetPage) return settings.allowSnapshotting;
    return super.allowSnapshotting;
  }

  @override
  final Duration transitionDuration;

  @override
  final Duration reverseTransitionDuration;

  /// The page builder function that creates the route's content.
  final GetPageBuilder? page;

  /// The name of the route for navigation and reporting.
  final String? routeName;

  /// Custom transition widget for this route.
  final CustomTransition? customTransition;

  /// List of bindings to apply to this route.
  final List<Binding> bindings;

  /// The name of the page that declared each entry of [bindings], for
  /// entries inherited from ancestor pages during route-tree flattening.
  ///
  /// A page created from a nested route carries the merged bindings of its
  /// whole ancestor chain, so that deep-linking to it still registers the
  /// ancestors' dependencies. Dependencies registered by such an inherited
  /// binding are linked to the declaring ancestor's route (when installed)
  /// instead of this one, so they survive this route's disposal while the
  /// ancestor's view is still alive. Bindings absent from this map are
  /// treated as declared by this route's own page.
  final Map<Binding, String>? bindingOwnerNames;

  /// Route parameters passed as key-value pairs.
  final Map<String, String>? parameter;

  @override
  final bool showCupertinoParallax;

  @override
  final bool opaque;

  /// Whether the route can be popped with a gesture.
  final bool? popGesture;

  @override
  final bool barrierDismissible;

  /// The transition animation type for this route.
  final Transition? transition;

  /// The animation curve for the transition.
  final Curve? curve;

  /// The alignment for the transition animation.
  final Alignment? alignment;

  /// Middleware to run during route lifecycle.
  final List<GetMiddleware>? middlewares;

  @override
  final Color? barrierColor;

  @override
  final String? barrierLabel;

  @override
  final bool maintainState;

  /// The title of the route.
  @override
  final String? title;

  /// Function to determine the gesture width for swipe-to-pop.
  ///
  /// When null, the back gesture is recognized across the full page width.
  /// When provided, the gesture only starts within the returned width from
  /// the leading edge (widened as needed to cover a display notch).
  @override
  final double Function(BuildContext context)? gestureWidth;

  /// Runner for executing middleware callbacks.
  final MiddlewareRunner _middlewareRunner;

  @override
  void dispose() {
    super.dispose();
    _middlewareRunner.runOnPageDispose();
    _child = null;
  }

  Widget? _child;

  Widget _getChild() {
    if (_child != null) return _child!;

    final bindingsToBind = _middlewareRunner.runOnBindingsStart(bindings);

    final pageToBuild = _middlewareRunner.runOnPageBuildStart(page)!;

    final Set<String> scopedKeys = {};

    if (bindingsToBind != null && bindingsToBind.isNotEmpty) {
      Get.runWithScope(scopedKeys, () {
        for (final item in bindingsToBind) {
          item.dependencies();
        }
      });
    }

    _child = _middlewareRunner.runOnPageBuilt(pageToBuild());

    if (scopedKeys.isNotEmpty) {
      _child = GetDependencyScope(keys: scopedKeys, child: _child!);
    }

    return _child!;
  }

  @override
  Widget buildContent(BuildContext context) {
    return _getChild();
  }

  @override
  String get debugLabel => '${super.debugLabel}(${settings.name})';
}
