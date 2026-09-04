import 'package:material_ui/material_ui.dart';

import '../../../../getxify.dart';

class RouterOutlet<TDelegate extends RouterDelegate<T>, T extends Object>
    extends StatefulWidget {
  final TDelegate routerDelegate;
  final Widget Function(BuildContext context) builder;

  RouterOutlet.builder({super.key, TDelegate? delegate, required this.builder})
    : routerDelegate = delegate ?? Get.delegate<TDelegate, T>()!;

  RouterOutlet({
    Key? key,
    TDelegate? delegate,
    required Iterable<GetPage> Function(T currentNavStack) pickPages,
    required Widget Function(
      BuildContext context,
      TDelegate,
      Iterable<GetPage>? page,
    )
    pageBuilder,
  }) : this.builder(
         builder: (context) {
           final currentConfig = context.delegate.currentConfiguration as T?;
           final rDelegate = context.delegate as TDelegate;
           var picked = currentConfig == null ? null : pickPages(currentConfig);
           if (picked?.isEmpty ?? true) {
             picked = null;
           }
           return pageBuilder(context, rDelegate, picked);
         },
         delegate: delegate,
         key: key,
       );
  @override
  RouterOutletState<TDelegate, T> createState() =>
      RouterOutletState<TDelegate, T>();
}

class RouterOutletState<TDelegate extends RouterDelegate<T>, T extends Object>
    extends State<RouterOutlet<TDelegate, T>> {
  RouterDelegate? delegate;
  late ChildBackButtonDispatcher _backButtonDispatcher;

  void _listener() {
    setState(() {});
  }

  VoidCallback? disposer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    disposer?.call();
    final router = Router.of(context);
    delegate ??= router.routerDelegate;
    delegate?.addListener(_listener);
    disposer = () => delegate?.removeListener(_listener);

    _backButtonDispatcher = router.backButtonDispatcher!
        .createChildBackButtonDispatcher();
  }

  @override
  void dispose() {
    super.dispose();
    disposer?.call();
  }

  @override
  Widget build(BuildContext context) {
    _backButtonDispatcher.takePriority();
    return widget.builder(context);
  }
}

class GetRouterOutlet extends RouterOutlet<GetDelegate, RouteDecoder> {
  /// Creates a nested navigator that renders the tree-branch pages below
  /// [anchorRoute].
  ///
  /// The pages are accumulated across every navigation history entry whose
  /// branch contains the anchor (see [_cumulativeAnchorStack]): navigating
  /// between sibling routes inside the outlet keeps the previous sibling
  /// mounted beneath the new one (state retention), giving the nested
  /// navigator a real stack — which is what allows the iOS back-swipe
  /// gesture to pop between siblings (#2107) — and the outlet keeps its
  /// stack while an unrelated route is on top of the history. Each entry's
  /// contribution is truncated after the first page that itself anchors a
  /// deeper outlet (its descendants are hosted by that outlet) and excludes
  /// pages marked with [GetPage.participatesInRootNavigator], which the
  /// root navigator renders. [filterPages] runs last and can further reduce
  /// the picked pages.
  ///
  /// When the picked set is empty the page matching [initialRoute] is
  /// rendered instead, resolved through the synchronous middleware surface
  /// ([GetMiddleware.redirect] and synchronous
  /// [GetMiddleware.redirectDelegate] results).
  GetRouterOutlet({
    Key? key,
    String? anchorRoute,
    required String initialRoute,
    Iterable<GetPage> Function(Iterable<GetPage> afterAnchor)? filterPages,
    GetDelegate? delegate,
    String? restorationScopeId,
  }) : this.pickPages(
         restorationScopeId: restorationScopeId,
         pickPages: (config) {
           Iterable<GetPage<dynamic>> ret;
           if (anchorRoute == null) {
             // jump the ancestor path
             final length = Uri.parse(initialRoute).pathSegments.length;

             // Pages participating in the root navigator are rendered by
             // [GetDelegate.build]; rendering them here as well would
             // mount them twice.
             ret = config.currentTreeBranch
                 .skip(length)
                 .take(length)
                 .takeWhile((page) => page.participatesInRootNavigator != true);
           } else {
             ret = _cumulativeAnchorStack(
               config,
               anchorRoute,
               delegate ?? Get.rootController.rootDelegate,
             );
           }
           if (filterPages != null) {
             ret = filterPages(ret);
           }
           return ret;
         },
         key: key,
         emptyPage: (delegate) =>
             _resolveInitialPage(delegate, initialRoute) ??
             delegate.notFoundRoute,
         navigatorKey: anchorRoute == null
             ? null
             : Get.nestedKey(anchorRoute)?.navigatorKey,
         delegate: delegate,
       );

  /// Resolves the page rendered for an outlet's `initialRoute` through the
  /// middleware pipeline.
  ///
  /// The router delegate never navigates to an outlet's `initialRoute` (the
  /// page is rendered directly whenever the outlet picks no pages), so
  /// [GetMiddleware.redirectDelegate] would otherwise never run for it.
  /// Middlewares run in ascending [GetMiddleware.priority] order, mirroring
  /// the delegate's own pipeline. Because this resolution happens during
  /// build, only synchronous [GetMiddleware.redirectDelegate] results —
  /// including the default bridge to [GetMiddleware.redirect] — can be
  /// honored directly. When a middleware returns a `Future`, the full
  /// asynchronous pipeline is resolved out-of-band through
  /// [GetDelegate.resolveOutletInitialPageAsync], which rebuilds the outlet
  /// once the result is known (#1978); until then the synchronously
  /// resolved page is rendered. A middleware stopping the navigation
  /// (returning `null`) resolves to `null`, which callers degrade to
  /// [GetDelegate.notFoundRoute].
  static GetPage? _resolveInitialPage(
    GetDelegate delegate,
    String initialRoute,
  ) {
    var sawAsync = false;
    GetPage? resolveSync() {
      var decoder = delegate.matchRoute(
        initialRoute,
        arguments: PageSettings(Uri.parse(initialRoute)),
      );
      final visited = <String>{};
      while (true) {
        final page = decoder.route;
        if (page == null) return null;
        // A middleware redirect cycle can never settle; degrade to the
        // not-found page instead of looping forever during build.
        if (!visited.add(page.name)) return null;
        final middlewares = List.of(page.middlewares)
          ..sort((a, b) => a.priority.compareTo(b.priority));
        RouteDecoder? next;
        for (final middleware in middlewares) {
          final resolved = middleware.redirectDelegate(decoder);
          if (resolved is Future) {
            sawAsync = true;
            continue;
          }
          if (resolved == null) return null;
          if (resolved.pageSettings?.name != decoder.pageSettings?.name) {
            next = resolved;
            break;
          }
        }
        if (next == null) return page;
        decoder = next;
      }
    }

    final syncPage = resolveSync();
    if (!sawAsync) return syncPage;
    final asyncResolution = delegate.resolveOutletInitialPageAsync(
      initialRoute,
    );
    if (asyncResolution.resolved) return asyncResolution.page;
    return syncPage;
  }

  GetRouterOutlet.pickPages({
    super.key,
    Widget Function(GetDelegate delegate)? emptyWidget,
    GetPage Function(GetDelegate delegate)? emptyPage,
    required super.pickPages,
    void Function(Page<dynamic>)? onDidRemovePage,
    String? restorationScopeId,
    GlobalKey<NavigatorState>? navigatorKey,
    GetDelegate? delegate,
  }) : super(
         pageBuilder: (context, rDelegate, pages) {
           final pageRes = <GetPage?>[
             ...?pages,
             if (pages == null || pages.isEmpty) emptyPage?.call(rDelegate),
           ].whereType<GetPage>();

           if (pageRes.isNotEmpty) {
             GetNavigator buildNavigator(GlobalKey<NavigatorState>? key) {
               return GetNavigator(
                 restorationScopeId: restorationScopeId,
                 // Removals performed imperatively on this navigator (an
                 // iOS back-swipe gesture completing, Navigator.pop, an
                 // in-outlet AppBar back button) must pop the matching
                 // history entry, or the popped page would be resurrected
                 // by the next declarative rebuild (#2107). Removals
                 // caused by page-list updates never reach the callback.
                 onDidRemovePage:
                     onDidRemovePage ?? rDelegate.didRemoveOutletPage,
                 pages: pageRes.toList(),
                 key: key,
                 // A pop through the router delegate can surface here as a
                 // page replacement instead of a removal (e.g. a
                 // PopMode.page pop shortening a deep-linked tree branch);
                 // the pop-aware delegate plays the leaving page's reverse
                 // transition instead of a forward push animation (#1883).
                 transitionDelegate: GetTransitionDelegate<dynamic>(
                   isPopNavigation: () => rDelegate.lastNavigationWasPop,
                 ),
               );
             }

             return InheritedNavigator(
               navigatorKey:
                   navigatorKey ?? Get.rootController.rootDelegate.navigatorKey,
               child: _OutletHeroControllerScope(
                 // Two outlets for the same anchor can be mounted at once
                 // (e.g. duplicate shell pages stacked in the root
                 // navigator, or an old shell animating out); attaching the
                 // shared nested-delegate GlobalKey to both navigators
                 // would crash with "Multiple widgets used the same
                 // GlobalKey" (#2742). The key scope hands the shared key
                 // to the most recently mounted outlet only.
                 child: navigatorKey == null
                     ? buildNavigator(null)
                     : _SharedNavigatorKeyScope(
                         sharedKey: navigatorKey,
                         builder: (context, effectiveKey) =>
                             buildNavigator(effectiveKey),
                       ),
               ),
             );
           }
           return (emptyWidget?.call(rDelegate) ?? const SizedBox.shrink());
         },
         delegate: delegate ?? Get.rootController.rootDelegate,
       );

  GetRouterOutlet.builder({
    super.key,
    required super.builder,
    String? route,
    GetDelegate? routerDelegate,
  }) : super.builder(
         delegate:
             routerDelegate ??
             (route != null
                 ? Get.nestedKey(route)
                 : Get.rootController.rootDelegate),
       );
}

/// The page stack an outlet anchored at [anchorRoute] renders, accumulated
/// across [delegate]'s navigation history (#2107).
///
/// Every history entry whose tree branch contains the anchor contributes
/// the pages the outlet would render for that entry alone: the branch pages
/// below the anchor, truncated after the first page that anchors a deeper
/// outlet (its descendants are hosted by that outlet) and at the first page
/// participating in the root navigator (rendered by [GetDelegate.build];
/// rendering it here as well would mount it twice). The contributions are
/// stacked in history order, so navigating between sibling routes inside
/// the outlet keeps the previous sibling mounted beneath the new one (state
/// retention) and hands the nested navigator a real stack — a route that is
/// alone in its navigator can never be popped by the iOS back-swipe
/// gesture, and a sibling pop becomes a genuine removal with its reverse
/// transition instead of a page replacement. Entries whose branch does not
/// contain the anchor (unrelated routes sitting on top of the history) are
/// skipped, keeping the outlet's stack alive while they are shown (#3336).
///
/// Walking backward from the newest matching entry, the accumulation stops
/// at the first entry that contributes no pages (the anchor itself was
/// (re)entered, resetting the outlet towards its initial route) or whose
/// contribution overlaps a page already stacked (a newer entry re-visits a
/// page an older entry keeps below its own leaf, e.g. `/products` pushed
/// while `/products/1` is in the history): stacking past either would
/// duplicate page keys — the navigator requires them unique — or resurrect
/// pages above the current route. Older entries therefore never override
/// the pages the newest entries put on top, and each page key is picked at
/// most once.
///
/// Falls back to [config]'s branch when no history entry contains the
/// anchor.
List<GetPage> _cumulativeAnchorStack(
  RouteDecoder config,
  String anchorRoute,
  GetDelegate delegate,
) {
  Iterable<GetPage> contributionOf(List<GetPage> branch) {
    return _stopAfterNestedOutletAnchor(
      branch.pickAfterRoute(anchorRoute),
      anchorRoute,
    ).takeWhile((page) => page.participatesInRootNavigator != true);
  }

  final stack = <GetPage>[];
  final stackedKeys = <LocalKey?>{};
  var anchorFound = false;
  final activePages = delegate.activePages;
  for (var i = activePages.length - 1; i >= 0; i--) {
    final branch = activePages[i].currentTreeBranch;
    if (!branch.any((page) => page.name == anchorRoute)) continue;
    anchorFound = true;
    final contribution = contributionOf(branch).toList();
    if (contribution.isEmpty ||
        contribution.any((page) => stackedKeys.contains(page.key))) {
      break;
    }
    stack.insertAll(0, contribution);
    stackedKeys.addAll(contribution.map((page) => page.key));
  }
  if (!anchorFound) {
    return contributionOf(config.currentTreeBranch).toList();
  }
  return stack;
}

/// Truncates [pages] after the first page that itself anchors a deeper
/// nested outlet (a registered nested navigation key), keeping that page
/// but dropping its descendants.
///
/// Descendant pages are hosted by the deeper outlet's navigator; leaking
/// them into the outer outlet as well would stack them over the deeper
/// outlet's host page and render them twice.
Iterable<GetPage> _stopAfterNestedOutletAnchor(
  Iterable<GetPage> pages,
  String anchorRoute,
) {
  final result = <GetPage>[];
  for (final page in pages) {
    result.add(page);
    if (page.name != anchorRoute &&
        Get.rootController.keys.containsKey(page.name)) {
      break;
    }
  }
  return result;
}

/// Attaches a shared navigator [GlobalKey] to exactly one mounted outlet
/// at a time (#2742).
///
/// Every [GetRouterOutlet] anchored at the same route receives the same
/// nested-delegate GlobalKey, and two such outlets can legitimately be
/// mounted at once — duplicate shell pages stacked in the root navigator,
/// or an outgoing shell still animating while its replacement enters. A
/// GlobalKey may only be attached to one widget per frame, so each scope
/// registers per shared key and only the most recently mounted registrant
/// builds with it; the others fall back to a State-owned key.
///
/// Ownership changes are applied in a post-frame callback so the shared
/// key is never claimed by a new location while the previous holder could
/// still claim it in the same frame: on a handover both scopes rebuild
/// together (the old one releasing the key, the new one adopting it), and
/// on the owner's disposal the key is re-adopted only after the owner's
/// element has unmounted.
class _SharedNavigatorKeyScope extends StatefulWidget {
  const _SharedNavigatorKeyScope({
    required this.sharedKey,
    required this.builder,
  });

  final GlobalKey<NavigatorState> sharedKey;
  final Widget Function(BuildContext context, GlobalKey<NavigatorState> key)
  builder;

  @override
  State<_SharedNavigatorKeyScope> createState() =>
      _SharedNavigatorKeyScopeState();
}

class _SharedNavigatorKeyScopeState extends State<_SharedNavigatorKeyScope> {
  /// Mounted scopes per shared key, oldest first; the last entry owns the
  /// key. Entries remove themselves on disposal, so the map cannot leak.
  static final Map<
    GlobalKey<NavigatorState>,
    List<_SharedNavigatorKeyScopeState>
  >
  _registrants = {};

  /// Fallback key for the frames in which this scope does not hold the
  /// shared key; State-owned so the navigator it names is not remounted on
  /// every rebuild.
  late final GlobalKey<NavigatorState> _fallbackKey =
      GlobalKey<NavigatorState>();

  /// Whether the shared key has been released to this scope. Owning the
  /// key ([_isOwner]) is not enough: a freshly mounted scope must not
  /// attach it while the previous holder's navigator element is still live.
  bool _sharedKeyReleased = false;

  bool get _isOwner {
    final registrants = _registrants[widget.sharedKey];
    return registrants != null &&
        registrants.isNotEmpty &&
        identical(registrants.last, this);
  }

  @override
  void initState() {
    super.initState();
    _register(widget.sharedKey);
  }

  void _register(GlobalKey<NavigatorState> key) {
    final registrants = _registrants.putIfAbsent(key, () => []);
    final previous = registrants.isEmpty ? null : registrants.last;
    registrants.add(this);
    if (previous == null) {
      _sharedKeyReleased = true;
      return;
    }
    // Handover: after this frame the previous holder rebuilds without the
    // key and this scope rebuilds with it. Both rebuild within the same
    // later frame, which is the supported way to move a GlobalKey.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (previous.mounted) previous.setState(() {});
      if (mounted && _isOwner) setState(() => _sharedKeyReleased = true);
    });
  }

  void _unregister(GlobalKey<NavigatorState> key) {
    final registrants = _registrants[key];
    if (registrants == null) return;
    final wasOwner =
        registrants.isNotEmpty && identical(registrants.last, this);
    registrants.remove(this);
    if (registrants.isEmpty) {
      _registrants.remove(key);
      return;
    }
    if (!wasOwner) return;
    final next = registrants.last;
    // Re-adopt after this frame, once the disposed holder's element is gone.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (next.mounted && next._isOwner) {
        next.setState(() => next._sharedKeyReleased = true);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _SharedNavigatorKeyScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sharedKey != widget.sharedKey) {
      _unregister(oldWidget.sharedKey);
      _sharedKeyReleased = false;
      _register(widget.sharedKey);
    }
  }

  @override
  void dispose() {
    _unregister(widget.sharedKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final key = _isOwner && _sharedKeyReleased
        ? widget.sharedKey
        : _fallbackKey;
    return widget.builder(context, key);
  }
}

/// Hosts a persistent [HeroController] scoped to a nested outlet navigator.
///
/// `MaterialApp.router`/`CupertinoApp.router` install a single
/// [HeroControllerScope] above the root navigator. Without an inner scope,
/// every nested outlet navigator would attach that same controller and
/// Flutter reports "A HeroController can not be shared by multiple
/// Navigators". Owning the controller in a [State] keeps hero flight state
/// alive across outlet rebuilds.
class _OutletHeroControllerScope extends StatefulWidget {
  const _OutletHeroControllerScope({required this.child});

  final Widget child;

  @override
  State<_OutletHeroControllerScope> createState() =>
      _OutletHeroControllerScopeState();
}

class _OutletHeroControllerScopeState
    extends State<_OutletHeroControllerScope> {
  final HeroController _controller = MaterialApp.createMaterialHeroController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HeroControllerScope(controller: _controller, child: widget.child);
  }
}

class InheritedNavigator extends InheritedWidget {
  const InheritedNavigator({
    super.key,
    required super.child,
    required this.navigatorKey,
  });
  final GlobalKey<NavigatorState> navigatorKey;

  static InheritedNavigator? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InheritedNavigator>();
  }

  @override
  bool updateShouldNotify(InheritedNavigator oldWidget) {
    return true;
  }
}

extension NavKeyExt on BuildContext {
  GlobalKey<NavigatorState>? get parentNavigatorKey {
    return InheritedNavigator.of(this)?.navigatorKey;
  }
}

extension PagesListExt on List<GetPage> {
  /// Returns the route and all following routes after the given route.
  Iterable<GetPage> pickFromRoute(String route) {
    return skipWhile((value) => value.name != route);
  }

  /// Returns the routes after the given route.
  Iterable<GetPage> pickAfterRoute(String route) {
    // If the provided route is root, we take the first route after root.
    if (route == '/') {
      return pickFromRoute(route).skip(1).take(1);
    }
    // Otherwise, we skip the route and take all routes after it.
    return pickFromRoute(route).skip(1);
  }
}

typedef NavigatorItemBuilderBuilder =
    Widget Function(BuildContext context, List<String> routes, int index);

class IndexedRouteBuilder<T> extends StatelessWidget {
  const IndexedRouteBuilder({
    super.key,
    required this.builder,
    required this.routes,
  });
  final List<String> routes;
  final NavigatorItemBuilderBuilder builder;

  // Method to get the current index based on the route
  int _getCurrentIndex(String currentLocation) {
    for (int i = 0; i < routes.length; i++) {
      if (currentLocation.startsWith(routes[i])) {
        return i;
      }
    }
    return 0; // default index
  }

  @override
  Widget build(BuildContext context) {
    final location = context.location;
    final index = _getCurrentIndex(location);

    return builder(context, routes, index);
  }
}

mixin RouterListenerMixin<T extends StatefulWidget> on State<T> {
  RouterDelegate? delegate;

  void _listener() {
    setState(() {});
  }

  VoidCallback? disposer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    disposer?.call();
    final router = Router.of(context);
    delegate ??= router.routerDelegate as GetDelegate;

    delegate?.addListener(_listener);
    disposer = () => delegate?.removeListener(_listener);
  }

  @override
  void dispose() {
    super.dispose();
    disposer?.call();
  }
}

class RouterListenerInherited extends InheritedWidget {
  const RouterListenerInherited({super.key, required super.child});

  static RouterListenerInherited? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<RouterListenerInherited>();
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return true;
  }
}

class RouterListener extends StatefulWidget {
  const RouterListener({super.key, required this.builder});
  final WidgetBuilder builder;

  @override
  State<RouterListener> createState() => RouteListenerState();
}

class RouteListenerState extends State<RouterListener>
    with RouterListenerMixin {
  @override
  Widget build(BuildContext context) {
    return RouterListenerInherited(child: Builder(builder: widget.builder));
  }
}

class BackButtonCallback extends StatefulWidget {
  const BackButtonCallback({super.key, required this.builder});
  final WidgetBuilder builder;

  @override
  State<BackButtonCallback> createState() => RouterListenerState();
}

class RouterListenerState extends State<BackButtonCallback>
    with RouterListenerMixin {
  late ChildBackButtonDispatcher backButtonDispatcher;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = Router.of(context);
    backButtonDispatcher = router.backButtonDispatcher!
        .createChildBackButtonDispatcher();
  }

  @override
  Widget build(BuildContext context) {
    backButtonDispatcher.takePriority();
    return widget.builder(context);
  }
}
