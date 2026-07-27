import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:getxify/get_utils/src/extensions/iterable_extensions.dart';

import '../../../../get_core/get_core.dart';
import '../../../../get_instance/src/bindings_interface.dart';
import '../../../../get_navigation/get_navigation.dart';
import '../../../../get_utils/src/platform/platform.dart';

class NavigationException implements Exception {
  final String message;
  NavigationException(this.message);

  @override
  String toString() => 'NavigationException: $message';
}

class GetDelegate extends RouterDelegate<RouteDecoder>
    with
        ChangeNotifier,
        PopNavigatorRouterDelegateMixin<RouteDecoder>,
        IGetNavigation {
  factory GetDelegate.createDelegate({
    GetPage<dynamic>? notFoundRoute,
    List<GetPage> pages = const [],
    List<NavigatorObserver>? navigatorObservers,
    TransitionDelegate<dynamic>? transitionDelegate,
    PopMode backButtonPopMode = PopMode.history,
    PreventDuplicateHandlingMode preventDuplicateHandlingMode =
        PreventDuplicateHandlingMode.reorderRoutes,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return GetDelegate(
      notFoundRoute: notFoundRoute,
      navigatorObservers: navigatorObservers,
      transitionDelegate: transitionDelegate,
      backButtonPopMode: backButtonPopMode,
      preventDuplicateHandlingMode: preventDuplicateHandlingMode,
      pages: pages,
      navigatorKey: navigatorKey,
    );
  }

  final List<RouteDecoder> _activePages = <RouteDecoder>[];
  final PopMode backButtonPopMode;
  final PreventDuplicateHandlingMode preventDuplicateHandlingMode;

  final GetPage notFoundRoute;

  final List<NavigatorObserver>? navigatorObservers;
  final TransitionDelegate<dynamic>? transitionDelegate;

  final Iterable<GetPage> Function(RouteDecoder currentNavStack)?
  pickPagesForRootNavigator;

  List<RouteDecoder> get activePages => _activePages;

  bool _pendingReplaceReport = false;

  /// Whether the currently executing push-style navigation was delegated by
  /// a replace-style method (e.g. [offUntil] calls [to] internally). While
  /// true, ordinary push entrypoints must not clear [_pendingReplaceReport],
  /// otherwise they would cancel the legitimately pending replace report.
  bool _delegatedReplaceNavigation = false;

  /// Returns whether the next route information report should overwrite the
  /// current platform history entry instead of pushing a new one, and clears
  /// the pending state.
  ///
  /// Replace-style navigations ([off], [offAll], [offAllNamed],
  /// [offNamed], [offNamedUntil], [offUntil], [toNamedAndOffUntil] and
  /// [backAndtoNamed]) mark the delegate so that
  /// [GetRouteInformationProvider] reports the resulting URL update to the
  /// engine with `replace: true`, keeping the browser history on Flutter Web
  /// in sync with [activePages].
  bool consumeReplaceReport() {
    final result = _pendingReplaceReport;
    _pendingReplaceReport = false;
    return result;
  }

  bool _lastNavigationWasPop = false;

  /// Whether the change currently being applied to [activePages] was caused
  /// by a back navigation ([back], [popRoute], [backUntil], [popModeUntil]
  /// or the platform reporting a back navigation on Flutter Web).
  ///
  /// While `true`, [GetTransitionDelegate] resolves page-list changes with
  /// pop semantics: the leaving page plays its reverse transition and the
  /// page revealed by the pop enters without a forward animation, even when
  /// the pop surfaces to a navigator as a page *replacement* — the norm for
  /// nested [GetRouterOutlet]s, which render only the current tree branch
  /// (#1883).
  ///
  /// The flag is cleared by push/replace navigations and at the end of the
  /// frame that rendered the pop, so later page-list changes resolve with
  /// the default forward semantics again.
  bool get lastNavigationWasPop => _lastNavigationWasPop;

  void _markNavigationAsPop() {
    _lastNavigationWasPop = true;
    // Bounds the pop semantics to the frame that renders this change.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lastNavigationWasPop = false;
    });
  }

  final _routeTree = ParseRouteTree(routes: []);

  List<GetPage> get registeredRoutes => _routeTree.routes;

  void addPages(List<GetPage> getPages) {
    _routeTree.addRoutes(getPages);
  }

  void clearRouteTree() {
    _routeTree.routes.clear();
  }

  void addPage(GetPage getPage) {
    _routeTree.addRoute(getPage);
  }

  void removePage(GetPage getPage) {
    _routeTree.removeRoute(getPage);
  }

  RouteDecoder matchRoute(String name, {PageSettings? arguments}) {
    return _routeTree.matchRoute(name, arguments: arguments);
  }

  /// Returns the middlewares declared directly on the registered page
  /// matching [name], excluding middlewares inherited from ancestor pages
  /// during route-tree flattening, or `null` when no registered page
  /// matches [name].
  ///
  /// Inherited middlewares participate in navigation decisions
  /// ([GetMiddleware.redirect], [GetMiddleware.redirectDelegate] and
  /// [GetMiddleware.onPageCalled]) but their page lifecycle callbacks must
  /// only run on the route of the page that declared them, so [PageRedirect]
  /// hands this subset to the created [GetPageRoute].
  List<GetMiddleware>? ownMiddlewaresOf(String name) {
    return _routeTree.ownMiddlewaresOf(name);
  }

  // GlobalKey<NavigatorState> get navigatorKey => Get.key;

  @override
  GlobalKey<NavigatorState> navigatorKey;

  final String? restorationScopeId;

  /// Whether the web URL strategy has already been applied in this process.
  ///
  /// The Flutter web engine only allows the URL strategy to be set once,
  /// before the app has been initialized, so any root [GetDelegate] created
  /// afterwards (e.g. after remounting [GetRoot] or on a hot restart) must
  /// not attempt to set it again, otherwise the engine throws
  /// "Cannot set URL strategy a second time".
  static bool _urlStrategyApplied = false;

  GetDelegate({
    GetPage? notFoundRoute,
    this.navigatorObservers,
    this.transitionDelegate,
    this.backButtonPopMode = PopMode.history,
    this.preventDuplicateHandlingMode =
        PreventDuplicateHandlingMode.reorderRoutes,
    this.pickPagesForRootNavigator,
    this.restorationScopeId,
    bool showHashOnUrl = false,
    GlobalKey<NavigatorState>? navigatorKey,
    required List<GetPage> pages,
  }) : navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>(),
       notFoundRoute = notFoundRoute ??= GetPage(
         name: '/404',
         page: () =>
             const Scaffold(body: Center(child: Text('Route not found'))),
       ) {
    if (!showHashOnUrl && GetPlatform.isWeb && !_urlStrategyApplied) {
      _urlStrategyApplied = true;
      try {
        setUrlStrategy();
      } catch (e) {
        // Setting the strategy is best-effort: the web engine forbids it
        // once the app has been initialized (or when the application set
        // one itself before runApp), which must not break navigation.
        Get.log('Could not set the URL strategy: $e', isError: true);
      }
    }
    addPages(pages);
    addPage(notFoundRoute);
    Get.log('GetDelegate is created !');
  }

  Future<RouteDecoder?> runMiddleware(RouteDecoder config) {
    return _runMiddleware(config, <String>{});
  }

  Future<RouteDecoder?> _runMiddleware(
    RouteDecoder config,
    Set<String> visited,
  ) async {
    if (config.currentTreeBranch.isEmpty ||
        config.currentTreeBranch.last.middlewares.isEmpty) {
      return config;
    }
    final location = config.pageSettings?.name;
    if (location != null && !visited.add(location)) {
      // A middleware redirect cycle can never settle; degrade to the
      // not-found page (mirroring [PageRedirect.getPageToRoute]) instead
      // of recursing forever.
      Get.log(
        'Redirect loop detected while resolving "$location". '
        'Falling back to ${notFoundRoute.name}.',
        isError: true,
      );
      return _getRouteDecoder(_buildPageSettings(notFoundRoute.name)) ?? config;
    }
    // Middlewares run in ascending [GetMiddleware.priority] order, and the
    // route-tree flattening lists inherited (ancestor) middlewares before
    // the page's own, so at equal priority a parent guard runs first.
    final middlewares = List.of(config.currentTreeBranch.last.middlewares)
      ..sort((a, b) => a.priority.compareTo(b.priority));
    var iterator = config;
    // Save/restore instead of clearing: an overlapping navigation (or a
    // synchronous resolution during the awaits below) must not clobber the
    // parameters another in-flight resolution is still relying on.
    final previousResolvingParameters = PageRedirect.resolvingParameters;
    try {
      PageRedirect.resolvingParameters = config.pageSettings?.params;
      for (var item in middlewares) {
        var redirectRes = await item.redirectDelegate(iterator);

        if (redirectRes == null) {
          config.route?.completer?.complete();
          return null;
        }
        if (redirectRes.route == null) {
          // The middleware redirected to a location that is not registered:
          // degrade gracefully to the not-found page.
          redirectRes =
              _getRouteDecoder(_buildPageSettings(notFoundRoute.name)) ??
              redirectRes;
        }
        if (config != redirectRes) {
          config.route?.completer?.complete();
          Get.log('Redirect to ${redirectRes.pageSettings?.name}');
        }

        iterator = redirectRes;
        // Stop the iteration over the middleware if we changed page
        // and that redirectRes is not the same as the current config.
        if (config != redirectRes) {
          break;
        }
      }
    } finally {
      PageRedirect.resolvingParameters = previousResolvingParameters;
    }
    // If the target is not the same as the source, we need
    // to run the middlewares for the new route.
    if (iterator != config) {
      return await _runMiddleware(iterator, visited);
    }
    return iterator;
  }

  Future<void> _unsafeHistoryAdd(RouteDecoder config) async {
    final res = await runMiddleware(config);
    if (res == null) return;
    _activePages.add(res);
  }

  Future<T?> _unsafeHistoryRemoveAt<T>(int index, T result) async {
    if (index == _activePages.length - 1 && _activePages.length > 1) {
      //removing WILL update the current route
      final toCheck = _activePages[_activePages.length - 2];
      final resMiddleware = await runMiddleware(toCheck);
      if (resMiddleware == null) return null;
      _activePages[_activePages.length - 2] = resMiddleware;
    }

    final completer = _activePages.removeAt(index).route?.completer;
    if (completer?.isCompleted == false) completer!.complete(result);

    return completer?.future as T?;
  }

  /// The settings of the page whose widget subtree is currently being
  /// built, or `null` outside of a page build.
  ///
  /// When several pages are pushed within the same frame, the lower pages
  /// build while a newer entry already sits on top of [activePages], so a
  /// top-of-stack lookup would hand them the newest route's arguments.
  /// Scoping [arguments] and [parameters] to the building page keeps every
  /// page (and the controllers it instantiates while building) bound to its
  /// own settings.
  static PageSettings? _buildingPageSettings;

  static bool _buildingPageResetScheduled = false;

  static void _reportBuildingPage(PageSettings settings) {
    _buildingPageSettings = settings;
    if (_buildingPageResetScheduled) return;
    _buildingPageResetScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildingPageSettings = null;
      _buildingPageResetScheduled = false;
    });
  }

  /// The arguments of the page currently being built, falling back to the
  /// arguments of the top-most entry of [activePages] outside of a page
  /// build, so that pages pushed within the same frame each observe their
  /// own arguments.
  T arguments<T>() {
    final building = _buildingPageSettings;
    if (building != null) return building.arguments as T;
    return currentConfiguration?.pageSettings?.arguments as T;
  }

  /// The parameters of the page currently being built, falling back to the
  /// parameters of the top-most entry of [activePages] outside of a page
  /// build (see [arguments]).
  ///
  /// While middlewares of an in-flight navigation are being resolved, the
  /// parameters of the route being resolved
  /// ([PageRedirect.resolvingParameters]) take precedence, so that
  /// middlewares observe the parameters of the navigation they are deciding
  /// on instead of the previous route's.
  Map<String, String> get parameters {
    final resolving = PageRedirect.resolvingParameters;
    if (resolving != null) return resolving;
    final building = _buildingPageSettings;
    if (building != null) return building.params;
    return currentConfiguration?.pageSettings?.params ?? {};
  }

  PageSettings? get pageSettings {
    return currentConfiguration?.pageSettings;
  }

  Future<void> _pushHistory(RouteDecoder config) async {
    if (config.route!.preventDuplicates) {
      final originalEntryIndex = _activePages.indexWhere(
        (element) => element.pageSettings?.name == config.pageSettings?.name,
      );
      if (originalEntryIndex >= 0) {
        switch (preventDuplicateHandlingMode) {
          case PreventDuplicateHandlingMode.popUntilOriginalRoute:
            popModeUntil(config.pageSettings!.name, popMode: PopMode.page);
            break;
          case PreventDuplicateHandlingMode.reorderRoutes:
            await _unsafeHistoryRemoveAt(originalEntryIndex, null);
            await _unsafeHistoryAdd(config);
            break;
          case PreventDuplicateHandlingMode.doNothing:
          default:
            break;
        }
        return;
      }
    }
    await _unsafeHistoryAdd(config);
  }

  Future<T?> _popHistory<T>(T result) async {
    if (!_canPopHistory()) return null;
    return await _doPopHistory(result);
  }

  Future<T?> _doPopHistory<T>(T result) async {
    return _unsafeHistoryRemoveAt<T>(_activePages.length - 1, result);
  }

  Future<T?> _popPage<T>(T result) async {
    if (!_canPopPage()) return null;
    return await _doPopPage(result);
  }

  // returns the popped page
  Future<T?> _doPopPage<T>(T result) async {
    final currentBranch = currentConfiguration?.currentTreeBranch;
    if (currentBranch != null && currentBranch.length > 1) {
      //remove last part only
      final remaining = currentBranch.take(currentBranch.length - 1);
      final prevHistoryEntry = _activePages.length > 1
          ? _activePages[_activePages.length - 2]
          : null;

      //check if current route is the same as the previous route
      if (prevHistoryEntry != null) {
        //if so, pop the entire _activePages entry
        final newLocation = remaining.last.name;
        final prevLocation = prevHistoryEntry.pageSettings?.name;
        if (newLocation == prevLocation) {
          //pop the entire _activePages entry
          return await _popHistory(result);
        }
      }

      //create a new route with the remaining tree branch
      if (_activePages.length > 1) {
        final res = await _popHistory<T>(result);
        await _pushHistory(RouteDecoder(remaining.toList(), null));
        return res;
      }
      // The only history entry cannot go through _popHistory (which refuses
      // to empty the stack): replace it with the shortened branch instead,
      // so the pop surfaces to the navigator as the removal of the leaf
      // page rather than as a push of its parent on top of it.
      final parent = await runMiddleware(
        RouteDecoder(remaining.toList(), null),
      );
      // A middleware stopped the navigation to the parent route: keep the
      // current entry rather than leaving the stack empty.
      if (parent == null) return null;
      _popWithResult<T>(result);
      _activePages.add(parent);
      return null;
    } else {
      //remove entire entry
      return await _popHistory(result);
    }
  }

  Future<T?> _pop<T>(PopMode mode, T result) async {
    _markNavigationAsPop();
    switch (mode) {
      case PopMode.history:
        return await _popHistory<T>(result);
      case PopMode.page:
        return await _popPage<T>(result);
    }
  }

  Future<T?> popHistory<T>(T result) async {
    return await _popHistory<T>(result);
  }

  bool _canPopHistory() {
    return _activePages.length > 1;
  }

  Future<bool> canPopHistory() {
    return SynchronousFuture(_canPopHistory());
  }

  bool _canPopPage() {
    final currentTreeBranch = currentConfiguration?.currentTreeBranch;
    if (currentTreeBranch == null) return false;
    return currentTreeBranch.length > 1 ? true : _canPopHistory();
  }

  Future<bool> canPopPage() {
    return SynchronousFuture(_canPopPage());
  }

  bool _canPop(PopMode mode) {
    switch (mode) {
      case PopMode.history:
        return _canPopHistory();
      case PopMode.page:
        return _canPopPage();
    }
  }

  /// Computes the page stack hosted by the root navigator from the
  /// navigation history.
  ///
  /// When no page of any [activePages] entry declares
  /// [GetPage.participatesInRootNavigator], every history entry contributes
  /// its leaf route (the default behavior: all routes participate in the
  /// root navigator).
  ///
  /// Otherwise the stack is derived across all history entries in stack
  /// order: an entry whose tree branch carries participation marks
  /// contributes its pages marked `true`, while an unmarked entry (a plain
  /// top-level route) contributes its leaf route. Pages are deduplicated by
  /// key, so several entries sharing a marked ancestor (e.g. two children
  /// of the same nested shell) keep a single instance of that ancestor
  /// mounted. Deriving the stack from the whole history — instead of only
  /// the current entry's branch — keeps a nested shell, its navigator and
  /// its controllers alive when an unrelated sibling route is pushed on top
  /// of it.
  Iterable<GetPage> getVisualPages(RouteDecoder? currentHistory) {
    final anyMarked = _activePages.any(
      (entry) => entry.currentTreeBranch.any(
        (page) => page.participatesInRootNavigator != null,
      ),
    );
    if (!anyMarked) {
      //default behavior, all routes participate in root navigator
      return _activePages.map((e) => e.route!);
    }
    final seenKeys = <LocalKey?>{};
    final pages = <GetPage>[];
    for (final entry in _activePages) {
      final marked = entry.currentTreeBranch
          .where((page) => page.participatesInRootNavigator != null)
          .toList();
      final contribution = marked.isEmpty
          ? [if (entry.route != null) entry.route!]
          : marked.where((page) => page.participatesInRootNavigator == true);
      for (final page in contribution) {
        if (seenKeys.add(page.key)) pages.add(page);
      }
    }
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    final currentHistory = currentConfiguration;
    final pages = currentHistory == null
        ? <GetPage>[]
        : pickPagesForRootNavigator?.call(currentHistory).toList() ??
              getVisualPages(currentHistory).toList();
    if (pages.isEmpty) {
      return ColoredBox(color: Theme.of(context).scaffoldBackgroundColor);
    }
    return GetNavigator(
      key: navigatorKey,
      onDidRemovePage: _onDidRemoveVisualRoute,
      pages: pages,
      observers: navigatorObservers,
      // The pop-aware delegate resolves exactly like the framework default
      // except while [lastNavigationWasPop] is set, so back navigations
      // that surface as page replacement play a pop animation (#1883).
      transitionDelegate:
          transitionDelegate ??
          GetTransitionDelegate<dynamic>(
            isPopNavigation: () => _lastNavigationWasPop,
          ),
    );
  }

  @override
  Future<void> goToUnknownPage([bool clearPages = false]) async {
    if (clearPages) _activePages.clear();

    final pageSettings = _buildPageSettings(notFoundRoute.name);
    final routeDecoder = _getRouteDecoder(pageSettings);

    _push(routeDecoder!);
  }

  @protected
  void _popWithResult<T>([T? result]) {
    final completer = _activePages.removeLast().route?.completer;
    if (completer?.isCompleted == false) completer!.complete(result);
  }

  /// Removes a duplicate history [entry] superseded by a new push,
  /// completing its route completer so that a navigation future still
  /// awaiting the removed entry (e.g. an earlier [to] call) resolves and
  /// runs its cleanup instead of pending forever.
  void _removeSupersededEntry(RouteDecoder entry) {
    final index = _activePages.indexWhere((e) => identical(e, entry));
    if (index >= 0) _activePages.removeAt(index);
    final completer = entry.route?.completer;
    if (completer?.isCompleted == false) completer!.complete(null);
  }

  /// Rekeys [decoder]'s route with a fresh unique key so the navigator
  /// disposes any same-key page and rebuilds this one from scratch, instead
  /// of updating the old route in place and keeping its stale content.
  void _recreateEntry(RouteDecoder decoder) {
    final route = decoder.route;
    if (route == null) return;
    final builder = _sourceBuilder[route];
    final rekeyed = route.copyWith(key: UniqueKey());
    if (builder != null) _sourceBuilder[rekeyed] = builder;
    decoder.route = rekeyed;
  }

  @override
  Future<T?> toNamed<T>(
    String page, {
    Object? arguments,
    String? id,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
  }) async {
    // A push-style navigation must win over a replace-style navigation
    // issued earlier in the same frame, since the router only reports the
    // final configuration to the engine once per frame.
    if (!_delegatedReplaceNavigation) _pendingReplaceReport = false;
    final args = _buildPageSettings(page, arguments);
    final route = _getRouteDecoder<T>(args);
    if (route != null) {
      if (!preventDuplicates) {
        route.route = route.route!.copyWith(preventDuplicates: false);
      }
      return _push<T>(route);
    } else {
      goToUnknownPage();
    }
    return null;
  }

  @override
  Future<T?> to<T>(
    Widget Function() page, {
    bool? opaque,
    Transition? transition,
    Curve? curve,
    Duration? duration,
    String? id,
    String? routeName,
    bool fullscreenDialog = false,
    Object? arguments,
    List<Binding> bindings = const [],
    bool preventDuplicates = true,
    bool? popGesture,
    bool showCupertinoParallax = true,
    double Function(BuildContext context)? gestureWidth,
    CustomTransition? customTransition,
    bool rebuildStack = true,
    PreventDuplicateHandlingMode preventDuplicateHandlingMode =
        PreventDuplicateHandlingMode.reorderRoutes,
  }) async {
    // A push-style navigation must win over a replace-style navigation
    // issued earlier in the same frame (see [toNamed]). [offUntil] delegates
    // to this method after setting the pending replace report, in which case
    // the flag must be preserved.
    if (!_delegatedReplaceNavigation) _pendingReplaceReport = false;
    // Names arriving from the context navigation extensions were cleaned
    // with the legacy closure-only rule, so provided names are re-cleaned
    // to also cover constructor tear-offs (#2245); explicit user names are
    // untouched, since the pattern only matches runtimeType artifacts.
    routeName = _cleanRouteName(routeName ?? "/${page.runtimeType}");

    final getPage = GetPage<T>(
      name: routeName,
      opaque: opaque ?? true,
      page: page,
      gestureWidth: gestureWidth,
      showCupertinoParallax: showCupertinoParallax,
      popGesture: popGesture ?? Get.defaultPopGesture,
      transition: transition ?? Get.defaultTransition,
      curve: curve ?? Get.defaultTransitionCurve,
      customTransition: customTransition,
      fullscreenDialog: fullscreenDialog,
      bindings: bindings,
      transitionDuration: duration ?? Get.defaultTransitionDuration,
      preventDuplicates: preventDuplicates,
      preventDuplicateHandlingMode: preventDuplicateHandlingMode,
    );

    _routeTree.addRoute(getPage);
    final args = _buildPageSettings(routeName, arguments);
    // Auto-generated route names collide when two different page closures
    // return the same widget type, and a route tree lookup would resolve
    // such a name to the page registered by an earlier, still active call.
    // Decoding directly from the page built for this call guarantees the
    // correct widget is used.
    final route = _configureRouterDecoder<T>(
      RouteDecoder([getPage], args),
      args,
    );
    final result = await _push<T>(route, rebuildStack: rebuildStack);
    _routeTree.removeRoute(getPage);
    return result;
  }

  @override
  Future<T?> off<T>(
    Widget Function() page, {
    bool? opaque,
    Transition? transition,
    Curve? curve,
    Duration? duration,
    String? id,
    String? routeName,
    bool fullscreenDialog = false,
    Object? arguments,
    List<Binding> bindings = const [],
    bool preventDuplicates = true,
    bool? popGesture,
    bool showCupertinoParallax = true,
    double Function(BuildContext context)? gestureWidth,
    CustomTransition? customTransition,
  }) async {
    // Names arriving from the context navigation extensions were cleaned
    // with the legacy closure-only rule, so provided names are re-cleaned
    // to also cover constructor tear-offs (#2245); explicit user names are
    // untouched, since the pattern only matches runtimeType artifacts.
    routeName = _cleanRouteName(routeName ?? "/${page.runtimeType}");
    final route = GetPage<T>(
      name: routeName,
      opaque: opaque ?? true,
      page: page,
      gestureWidth: gestureWidth,
      showCupertinoParallax: showCupertinoParallax,
      popGesture: popGesture ?? Get.defaultPopGesture,
      transition: transition ?? Get.defaultTransition,
      curve: curve ?? Get.defaultTransitionCurve,
      customTransition: customTransition,
      fullscreenDialog: fullscreenDialog,
      bindings: bindings,
      transitionDuration: duration ?? Get.defaultTransitionDuration,
    );

    final args = _buildPageSettings(routeName, arguments);
    _pendingReplaceReport = true;
    return _replace(args, route);
  }

  @override
  Future<T?>? offAll<T>(
    Widget Function() page, {
    bool Function(GetPage route)? predicate,
    bool opaque = true,
    bool? popGesture,
    String? id,
    String? routeName,
    Object? arguments,
    List<Binding> bindings = const [],
    bool fullscreenDialog = false,
    Transition? transition,
    Curve? curve,
    Duration? duration,
    bool showCupertinoParallax = true,
    double Function(BuildContext context)? gestureWidth,
    CustomTransition? customTransition,
  }) async {
    // Names arriving from the context navigation extensions were cleaned
    // with the legacy closure-only rule, so provided names are re-cleaned
    // to also cover constructor tear-offs (#2245); explicit user names are
    // untouched, since the pattern only matches runtimeType artifacts.
    routeName = _cleanRouteName(routeName ?? "/${page.runtimeType}");
    final route = GetPage<T>(
      name: routeName,
      opaque: opaque,
      page: page,
      gestureWidth: gestureWidth,
      showCupertinoParallax: showCupertinoParallax,
      popGesture: popGesture ?? Get.defaultPopGesture,
      transition: transition ?? Get.defaultTransition,
      curve: curve ?? Get.defaultTransitionCurve,
      customTransition: customTransition,
      fullscreenDialog: fullscreenDialog,
      bindings: bindings,
      transitionDuration: duration ?? Get.defaultTransitionDuration,
    );

    final args = _buildPageSettings(routeName, arguments);

    final newPredicate = predicate ?? (route) => false;

    _pendingReplaceReport = true;
    while (_activePages.length > 1 && !newPredicate(_activePages.last.route!)) {
      _popWithResult();
    }

    return _replace(args, route);
  }

  @override
  Future<T?>? offAllNamed<T>(
    String newRouteName, {
    // bool Function(GetPage route)? predicate,
    Object? arguments,
    String? id,
    Map<String, String>? parameters,
  }) async {
    final args = _buildPageSettings(newRouteName, arguments);
    final route = _getRouteDecoder<T>(args);
    if (route == null) return null;

    _pendingReplaceReport = true;
    while (_activePages.length > 1) {
      _activePages.removeLast();
    }

    return _replaceNamed(route);
  }

  @override
  Future<T?>? offNamedUntil<T>(
    String page, {
    bool Function(GetPage route)? predicate,
    Object? arguments,
    String? id,
    Map<String, String>? parameters,
  }) async {
    final args = _buildPageSettings(page, arguments);
    final route = _getRouteDecoder<T>(args);
    if (route == null) return null;

    final newPredicate = predicate ?? (route) => false;

    _pendingReplaceReport = true;
    while (_activePages.length > 1 && !newPredicate(_activePages.last.route!)) {
      _activePages.removeLast();
    }

    return _push(route);
  }

  @override
  Future<T?> offNamed<T>(
    String page, {
    Object? arguments,
    String? id,
    Map<String, String>? parameters,
  }) async {
    final args = _buildPageSettings(page, arguments);
    final route = _getRouteDecoder<T>(args);
    if (route == null) return null;
    _pendingReplaceReport = true;
    _popWithResult();
    return _push<T>(route);
  }

  @override
  Future<T?> toNamedAndOffUntil<T>(
    String page,
    bool Function(GetPage) predicate, [
    Object? data,
  ]) async {
    final arguments = _buildPageSettings(page, data);

    final route = _getRouteDecoder<T>(arguments);

    if (route == null) return null;

    _pendingReplaceReport = true;
    while (_activePages.isNotEmpty && !predicate(_activePages.last.route!)) {
      _popWithResult();
    }

    return _push<T>(route);
  }

  @override
  Future<T?> offUntil<T>(
    Widget Function() page,
    bool Function(GetPage) predicate, [
    Object? arguments,
  ]) async {
    _pendingReplaceReport = true;
    while (_activePages.isNotEmpty && !predicate(_activePages.last.route!)) {
      _popWithResult();
    }

    // [to] clears the pending replace report for ordinary pushes; mark this
    // push as delegated so the flag set above survives. The guard only needs
    // to cover the synchronous prefix of [to], which is where the clear runs.
    _delegatedReplaceNavigation = true;
    final result = to<T>(page, arguments: arguments);
    _delegatedReplaceNavigation = false;
    return result;
  }

  @override
  void removeRoute<T>(String name) {
    _activePages.remove(RouteDecoder.fromRoute(name));
  }

  /// The topmost visual [Route] currently shown by this delegate's
  /// navigator, or `null` if the navigator is not mounted yet.
  Route<dynamic>? get _topVisualRoute {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return null;
    Route<dynamic>? topRoute;
    navigator.popUntil((route) {
      topRoute = route;
      return true;
    });
    return topRoute;
  }

  /// Whether the topmost visual route is pageless, that is a route pushed
  /// imperatively on the navigator (e.g. a dialog, bottom sheet or a raw
  /// [Navigator.push] route) that has no matching entry in [activePages].
  bool get _topRouteIsPageless {
    final route = _topVisualRoute;
    return route != null && route.settings is! Page;
  }

  /// Whether [back] is able to pop a route, either a pageless route
  /// sitting on top of the navigator or a previous entry in [activePages].
  bool get canBack {
    return _activePages.length > 1 || _topRouteIsPageless;
  }

  void _checkIfCanBack() {
    assert(() {
      if (!canBack) {
        final last = _activePages.last;
        final name = last.route?.name;
        throw NavigationException('The page $name cannot be popped');
      }
      return true;
    }());
  }

  @override
  Future<R?> backAndtoNamed<T, R>(
    String page, {
    T? result,
    Object? arguments,
  }) async {
    final args = _buildPageSettings(page, arguments);
    final route = _getRouteDecoder<R>(args);
    if (route == null) return null;
    _pendingReplaceReport = true;
    _popWithResult<T>(result);
    return _push<R>(route);
  }

  /// Removes routes according to [PopMode]
  /// until it reaches the specific [fullRoute],
  /// DOES NOT remove the [fullRoute]
  @override
  Future<void> popModeUntil(
    String fullRoute, {
    PopMode popMode = PopMode.history,
  }) async {
    // remove history or page entries until you meet route
    var iterator = currentConfiguration;
    while (_canPop(popMode) && iterator != null) {
      //the next line causes wasm compile error if included in the while loop
      //https://github.com/flutter/flutter/issues/140110
      if (iterator.pageSettings?.name == fullRoute) {
        break;
      }
      await _pop(popMode, null);
      // replace iterator
      iterator = currentConfiguration;
    }
    notifyListeners();
  }

  @override
  void backUntil(bool Function(GetPage) predicate) {
    _markNavigationAsPop();
    while (_activePages.length > 1 && !predicate(_activePages.last.route!)) {
      _popWithResult();
    }

    notifyListeners();
  }

  Future<T?> _replace<T>(PageSettings arguments, GetPage<T> page) async {
    _lastNavigationWasPop = false;
    _routeTree.addRoute(page);

    // Decode directly from the page built for this call: a route tree
    // lookup could resolve an auto-generated name to a same-name page
    // registered by an earlier, still active navigation (see [to]).
    final decoder = _configureRouterDecoder<T>(
      RouteDecoder([page], arguments),
      arguments,
    );

    final activePage = await runMiddleware(decoder);
    if (activePage == null) {
      _routeTree.removeRoute(page);
      return null;
    }

    final index = _activePages.length > 1 ? _activePages.length - 1 : 0;
    _recreateIfSameKey(index, activePage);
    _activePages[index] = activePage;

    notifyListeners();
    final result = await activePage.route?.completer?.future as Future<T?>?;
    _routeTree.removeRoute(page);

    return result;
  }

  /// Rekeys [activePage] when it shares its page key with the entry it is
  /// about to replace at [index].
  ///
  /// Replacing an entry with a same-key page (e.g. [offAllNamed] targeting
  /// the route that remains at the bottom of the stack) would make the
  /// navigator update the existing route in place, keeping its stale
  /// content, bindings and controllers alive; a fresh key forces the old
  /// route to be disposed and the page to be rebuilt from scratch (#2899).
  void _recreateIfSameKey(int index, RouteDecoder activePage) {
    if (index >= _activePages.length) return;
    if (_activePages[index].route?.key == activePage.route?.key) {
      _recreateEntry(activePage);
    }
  }

  Future<T?> _replaceNamed<T>(RouteDecoder page) async {
    _lastNavigationWasPop = false;
    final activePage = await runMiddleware(page);
    if (activePage == null) return null;

    final index = _activePages.length > 1 ? _activePages.length - 1 : 0;
    _recreateIfSameKey(index, activePage);
    _activePages[index] = activePage;

    notifyListeners();
    final result = await activePage.route?.completer?.future as Future<T?>?;
    return result;
  }

  /// Takes a route [name] String generated by [to], [off], [offAll]
  /// (and similar context navigation methods), cleans the extra chars and
  /// accommodates the format.
  String _cleanRouteName(String name) {
    // A page builder's runtimeType prints as '(<parameters>) => <Widget>',
    // where the parameter list is empty for closures but not for
    // constructor tear-offs (e.g. `MyPage.new` prints as
    // '({Key? key}) => MyPage'), so the whole list is stripped (#2245).
    // Names cleaned by the context navigation extensions arrive with the
    // space and arrow already percent-encoded, so both forms are matched.
    name = name.replaceFirst(
      RegExp(r'\(.*\)(?:%20|\s)*(?:=>|=%3E)(?:%20|\s)*'),
      '',
    );

    /// uncomment for URL styling.
    // name = name.paramCase!;
    if (!name.startsWith('/')) {
      name = '/$name';
    }
    return Uri.tryParse(name)?.toString() ?? name;
  }

  PageSettings _buildPageSettings(String page, [Object? data]) {
    var uri = Uri.parse(page);
    return PageSettings(uri, data);
  }

  @protected
  RouteDecoder? _getRouteDecoder<T>(PageSettings arguments) {
    var page = arguments.uri.path;
    final parameters = arguments.params;
    if (parameters.isNotEmpty) {
      final uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }

    final decoder = _routeTree.matchRoute(page, arguments: arguments);
    final route = decoder.route;
    if (route == null) return null;

    return _configureRouterDecoder<T>(decoder, arguments);
  }

  @protected
  RouteDecoder _configureRouterDecoder<T>(
    RouteDecoder decoder,
    PageSettings arguments,
  ) {
    final parameters = arguments.params.isEmpty
        ? arguments.query
        : arguments.params;
    arguments.params.addAll(arguments.query);
    if (decoder.parameters.isEmpty) {
      decoder.parameters.addAll(parameters);
    }

    final route = decoder.route;
    if (route != null) {
      final pageBuilder = route.page;
      final configured = route.copyWith(
        completer: _activePages.isEmpty ? null : Completer<T?>(),
        arguments: arguments,
        parameters: parameters,
        key: ValueKey(arguments.name),
        page: () => _PageBuildScope(settings: arguments, child: pageBuilder()),
      );
      _sourceBuilder[configured] = pageBuilder;
      decoder.route = configured;
    }

    return decoder;
  }

  /// Maps a configured [GetPage] back to the page builder it was decoded
  /// from, so that two decodes of the same registered route can be
  /// recognized even though each decode wraps the builder in its own
  /// [_PageBuildScope] closure.
  ///
  /// Two different pages can share a route name (and therefore a page key)
  /// when the name is auto-generated from the closure's widget type (see
  /// [to]); comparing source builders lets [_push] rebuild the page when
  /// the duplicate actually carries a different builder.
  static final Expando<GetPageBuilder> _sourceBuilder =
      Expando<GetPageBuilder>();

  /// Whether [newRoute] was decoded from the same page builder as
  /// [existingRoute]; `false` when either builder is unknown.
  static bool _sameSourceBuilder(GetPage? newRoute, GetPage? existingRoute) {
    final newBuilder = newRoute == null ? null : _sourceBuilder[newRoute];
    final existingBuilder = existingRoute == null
        ? null
        : _sourceBuilder[existingRoute];
    if (newBuilder == null || existingBuilder == null) return false;
    return identical(newBuilder, existingBuilder);
  }

  Future<T?> _push<T>(RouteDecoder decoder, {bool rebuildStack = true}) async {
    _lastNavigationWasPop = false;
    var res = await runMiddleware(decoder);
    if (res == null) {
      // A middleware stopped the navigation. When that happens while the
      // page stack is still empty (initial route, deep link or web
      // refresh), leaving the stack empty would render a permanently blank
      // screen, so fall back to the not-found page.
      if (_activePages.isEmpty) {
        final notFound = _getRouteDecoder<T>(
          _buildPageSettings(notFoundRoute.name),
        );
        if (notFound != null) {
          _activePages.add(notFound);
          if (rebuildStack) notifyListeners();
        }
      }
      return null;
    }

    final preventDuplicateHandlingMode =
        res.route?.preventDuplicateHandlingMode ??
        PreventDuplicateHandlingMode.reorderRoutes;

    final onStackPage = _activePages.firstWhereOrNull(
      (element) => element.route?.key == res.route?.key,
    );

    if (onStackPage == null) {
      /// There are no duplicate routes in the stack
      _activePages.add(res);
    } else if (res.route?.preventDuplicates == false) {
      /// Duplicates are explicitly allowed: push a new instance with a
      /// unique page key, since the navigator requires page keys to be
      /// unique within its stack.
      _recreateEntry(res);
      _activePages.add(res);
    } else {
      /// There are duplicate routes, apply the handling mode
      switch (preventDuplicateHandlingMode) {
        case PreventDuplicateHandlingMode.doNothing:
          break;
        case PreventDuplicateHandlingMode.reorderRoutes:
          _removeSupersededEntry(onStackPage);
          if (!_sameSourceBuilder(res.route, onStackPage.route)) {
            // The duplicate name belongs to a different page builder (two
            // page closures returning the same widget type share the same
            // auto-generated name): reusing the page key would make the
            // navigator keep the old route and its stale content, so the
            // new page must be rebuilt under a fresh key.
            _recreateEntry(res);
          }
          _activePages.add(res);
          break;
        case PreventDuplicateHandlingMode.popUntilOriginalRoute:
          while (_activePages.length > 1 &&
              !identical(_activePages.last, onStackPage)) {
            _popWithResult();
          }
          break;
        case PreventDuplicateHandlingMode.recreate:
          _removeSupersededEntry(onStackPage);
          _recreateEntry(res);
          _activePages.add(res);
      }
    }
    if (rebuildStack) {
      notifyListeners();
    }

    return decoder.route?.completer?.future as Future<T?>?;
  }

  /// Handles a route reported by the platform (a deep link, or the browser
  /// back/forward buttons on Flutter Web).
  ///
  /// When the reported route already exists in [activePages], the stack is
  /// popped back to that entry so the pages above it are removed instead of
  /// being duplicated or resurrected. Unknown routes keep the previous
  /// behavior and are pushed on top of the stack, preserving deep links.
  @override
  Future<void> setNewRoutePath(RouteDecoder configuration) async {
    final page = configuration.route;
    if (page == null) {
      goToUnknownPage();
      return;
    }
    // Seed the very first route synchronously when no middleware can
    // intervene, so the initial page is part of the router's first frame:
    // a single-pump `tester.pumpWidget(GetMaterialApp(home: ...))` must
    // find the home widget (#3244). Routes guarded by middlewares keep the
    // asynchronous pipeline below, which resolves redirects first.
    if (_activePages.isEmpty &&
        configuration.currentTreeBranch.last.middlewares.isEmpty) {
      _activePages.add(configuration);
      // During the initial route processing the router is amid its own
      // first build and rebuilds right after this call, so notifying is
      // both illegal and unnecessary; the navigator only exists — making
      // a notification required — once that first build completed.
      if (navigatorKey.currentContext != null) notifyListeners();
      return;
    }
    final reportedName = configuration.pageSettings?.name;
    var existingIndex = _activePages.lastIndexWhere(
      (element) => element.pageSettings?.name == reportedName,
    );
    if (existingIndex == _activePages.length - 1 && _activePages.length > 1) {
      // The reported route has the same name as the current top entry. When
      // a lower duplicate exists (duplicates can be pushed with
      // preventDuplicates disabled), the platform is navigating back to that
      // duplicate, so pop to the highest matching entry strictly below the
      // top. Without a lower duplicate this stays a no-op, as the platform
      // is merely re-reporting the current route.
      final lowerIndex = _activePages.lastIndexWhere(
        (element) => element.pageSettings?.name == reportedName,
        _activePages.length - 2,
      );
      if (lowerIndex >= 0) {
        existingIndex = lowerIndex;
      }
    }
    if (existingIndex >= 0) {
      if (existingIndex < _activePages.length - 1) {
        // A platform back navigation with a pageless route (dialog, bottom
        // sheet, imperative [Navigator.push] route) on top must dismiss
        // that overlay instead of popping the page it is anchored to; each
        // back press then closes a single overlay.
        if (_topRouteIsPageless) {
          await handlePopupRoutes();
          notifyListeners();
          return;
        }
        // When exactly one page would be popped, honor the top route's
        // pop-veto surface (PopScope, WillPopScope, Page.canPop), like
        // [popRoute] does. Multi-entry history jumps cannot be vetoed
        // per page.
        if (existingIndex == _activePages.length - 2) {
          final target = _activePages[existingIndex];
          if (await _isPopVetoed()) {
            notifyListeners();
            return;
          }
          // The history may have been mutated while awaiting the veto
          // check (a willPop callback can navigate), mirroring [popRoute]'s
          // post-await guard: re-locate the target entry and bail out when
          // it is gone, so the pop loop cannot remove unrelated pages.
          existingIndex = _activePages.lastIndexWhere(
            (element) => identical(element, target),
          );
          if (existingIndex < 0) {
            notifyListeners();
            return;
          }
        }
      }
      if (existingIndex < _activePages.length - 1) _markNavigationAsPop();
      while (_activePages.length - 1 > existingIndex) {
        _popWithResult();
      }
      notifyListeners();
      return;
    }
    await _push(configuration);
  }

  @override
  RouteDecoder? get currentConfiguration {
    if (_activePages.isEmpty) return null;
    final route = _activePages.last;
    return route;
  }

  /// Pops the topmost visual route through the navigator when it is a
  /// pageless route (e.g. a dialog, bottom sheet or a route pushed
  /// imperatively with [Navigator.push]), returning `true` if a pop
  /// was handled and `false` when the topmost route is a page managed
  /// by this delegate.
  Future<bool> handlePopupRoutes({Object? result}) async {
    if (_topRouteIsPageless) {
      return await navigatorKey.currentState!.maybePop(result);
    }
    return false;
  }

  /// Consults the pop-veto surface of the topmost visual route, mirroring
  /// [NavigatorState.maybePop]: first the deprecated `Route.willPop`
  /// (`WillPopScope` callbacks), then [Route.popDisposition] ([PopScope]
  /// widgets and [Page.canPop]).
  ///
  /// Returns `true` when the pop must not proceed. A veto surfaced through
  /// [Route.popDisposition] notifies the route via
  /// [Route.onPopInvokedWithResult] with `didPop: false`, so
  /// [PopScope.onPopInvokedWithResult] observes the blocked attempt. The
  /// pop is also considered handled when the top route changed while
  /// awaiting the `willPop` callbacks.
  Future<bool> _isPopVetoed([Object? result]) async {
    final route = _topVisualRoute;
    if (route == null) return false;
    // ignore: deprecated_member_use
    if (await route.willPop() == RoutePopDisposition.doNotPop) {
      return true;
    }
    if (!identical(_topVisualRoute, route)) return true;
    if (route.popDisposition == RoutePopDisposition.doNotPop) {
      route.onPopInvokedWithResult(false, result);
      return true;
    }
    return false;
  }

  @override
  Future<bool> popRoute({Object? result, PopMode? popMode}) async {
    //Returning false will cause the entire app to be popped.
    final wasPopup = await handlePopupRoutes(result: result);
    if (wasPopup) return true;

    final mode = popMode ?? backButtonPopMode;
    if (_canPop(mode)) {
      if (await _isPopVetoed(result)) return true;
      // The history may have been mutated while awaiting the veto check.
      if (!_canPop(mode)) return true;
      await _pop(mode, result);
      notifyListeners();
      return true;
    }

    return super.popRoute();
  }

  /// Pops the topmost route with an optional [result].
  ///
  /// Pageless routes pushed imperatively on the navigator (e.g. dialogs,
  /// bottom sheets or raw [Navigator.push] routes) are popped through the
  /// navigator itself, so the pages managed by this delegate stay intact.
  /// Otherwise the last entry of [activePages] is removed declaratively.
  @override
  void back<T>([T? result]) {
    if (_topRouteIsPageless) {
      navigatorKey.currentState?.pop<T>(result);
      return;
    }
    _checkIfCanBack();
    _markNavigationAsPop();
    _popWithResult<T>(result);
    notifyListeners();
  }

  void _onDidRemoveVisualRoute(Page<dynamic> page) {
    final index = _activePages.lastIndexWhere(
      (e) => identical(e.route, page) || e.route == page,
    );
    // The page may already have been removed from the history (e.g. by a
    // declarative [back] call whose rebuild has not been applied yet).
    if (index < 0) return;
    final completer = _activePages.removeAt(index).route?.completer;
    if (completer?.isCompleted == false) completer!.complete(null);
    notifyListeners();
  }

  /// Whether [dispose] has run; guards the out-of-band initial-page
  /// resolutions of [resolveOutletInitialPageAsync], which complete after
  /// the frame that scheduled them and must not touch a disposed notifier.
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// State of the asynchronous middleware resolutions started by
  /// [resolveOutletInitialPageAsync], per outlet initial route.
  final Map<String, _OutletInitialPageResolution> _outletInitialResolutions =
      {};

  /// The result of the full — asynchronous — middleware pipeline for an
  /// outlet's [initialRoute], starting or refreshing that resolution in the
  /// background (#1978).
  ///
  /// [GetRouterOutlet] resolves the page rendered for its `initialRoute`
  /// during build, where only synchronous [GetMiddleware.redirectDelegate]
  /// results can be honored; a middleware returning a `Future` would be
  /// ignored entirely. When the outlet's synchronous resolution encounters
  /// such a middleware it calls this method: the full pipeline
  /// ([runMiddleware]) is scheduled after the current frame (notifying
  /// listeners mid-build is illegal) and `resolved: false` is returned, so
  /// the outlet keeps showing the synchronously resolved page meanwhile.
  /// Once the pipeline completes, listeners are notified — rebuilding the
  /// outlets — whenever the outcome differs from the previously resolved
  /// one, and later calls return `resolved: true` with the resolved [page]
  /// (`null` when a middleware stopped the navigation, which callers
  /// degrade to [notFoundRoute]).
  ///
  /// Each call also refreshes the resolution (at most one runs at a time),
  /// mirroring how the synchronous middleware surface re-runs on every
  /// build in which the outlet is empty, so middleware decision changes
  /// are picked up. The refresh only notifies when the resolved page
  /// changed, so stable decisions cannot rebuild in a loop.
  ({bool resolved, GetPage? page}) resolveOutletInitialPageAsync(
    String initialRoute,
  ) {
    final resolution = _outletInitialResolutions.putIfAbsent(
      initialRoute,
      _OutletInitialPageResolution.new,
    );
    if (!resolution.inFlight) {
      resolution.inFlight = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          if (_disposed) return;
          final decoder = matchRoute(
            initialRoute,
            arguments: PageSettings(Uri.parse(initialRoute)),
          );
          final result = await runMiddleware(decoder);
          if (_disposed) return;
          final page = result?.route;
          final changed =
              !resolution.resolved || resolution.page?.key != page?.key;
          resolution.resolved = true;
          resolution.page = page;
          if (changed) notifyListeners();
        } finally {
          resolution.inFlight = false;
        }
      });
    }
    return (resolved: resolution.resolved, page: resolution.page);
  }

  /// Reflects a page removal performed imperatively on a nested
  /// [GetRouterOutlet] navigator back into this delegate's history (#2107).
  ///
  /// The outlet's page stack is derived declaratively from [activePages],
  /// and the framework only reports removals that did *not* originate from
  /// a page-list update — an iOS back-swipe gesture completing (the
  /// gesture's dragEnd calls [NavigatorState.pop]), a [Navigator.pop] on
  /// the outlet navigator, an in-outlet `AppBar` back button, ... Without
  /// this bookkeeping such a pop leaves the history untouched, so the URL
  /// stays stale and the next rebuild resurrects the popped page.
  ///
  /// Mirroring [_onDidRemoveVisualRoute], the last history entry whose leaf
  /// route is the removed [page] is popped and its route completer is
  /// completed, resolving the navigation future that pushed it. Removals
  /// whose entry has already left the history (a declarative [back] racing
  /// this callback) are ignored, guarding against feedback loops with
  /// declarative rebuilds. When the matching entry is the *only* history
  /// entry (a deep link into a nested branch), the entry cannot be removed
  /// without blanking the app: its tree branch is shortened instead,
  /// mirroring [PopMode.page] semantics, so the outlet reveals the parent
  /// page. Like the root handler — and unlike [popRoute] — no middleware
  /// runs: the route has already been popped visually.
  void didRemoveOutletPage(Page<dynamic> page) {
    final index = _activePages.lastIndexWhere(
      (e) => identical(e.route, page) || e.route == page,
    );
    if (index < 0) return;
    final entry = _activePages[index];
    if (_activePages.length > 1) {
      _activePages.removeAt(index);
    } else {
      final branch = entry.currentTreeBranch;
      // The only page of the only entry cannot be popped (the navigator
      // itself should never allow it: such a route is its first route).
      if (branch.length < 2) return;
      _activePages[index] = RouteDecoder(
        branch.sublist(0, branch.length - 1),
        null,
      );
    }
    final completer = entry.route?.completer;
    if (completer?.isCompleted == false) completer!.complete(null);
    notifyListeners();
  }
}

/// State of one asynchronous outlet initial-route resolution
/// (see [GetDelegate.resolveOutletInitialPageAsync]).
class _OutletInitialPageResolution {
  /// Whether a pipeline run is currently in flight (throttles refreshes).
  bool inFlight = false;

  /// Whether at least one pipeline run has completed, making [page]
  /// meaningful (`page == null` alone cannot distinguish "not yet
  /// resolved" from "resolved to a stopped navigation").
  bool resolved = false;

  /// The page the pipeline last resolved to, or `null` for a stopped
  /// navigation.
  GetPage? page;
}

/// Reports the [PageSettings] of the page whose subtree is being built, so
/// that [GetDelegate.arguments] and [GetDelegate.parameters] resolve to the
/// building page instead of the top of the stack while several pages build
/// within the same frame.
class _PageBuildScope extends StatelessWidget {
  const _PageBuildScope({required this.settings, required this.child});

  final PageSettings settings;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    GetDelegate._reportBuildingPage(settings);
    return child;
  }
}
