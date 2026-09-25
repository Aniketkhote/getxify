import 'dart:async';

import 'package:cupertino_ui/cupertino_ui.dart';

import '../../../../getxify.dart';

/// The Page Middlewares.
/// The Functions will be called in this order
/// (( [redirect] -> [onPageCalled] -> [onBindingsStart] ->
/// [onPageBuildStart] -> [onPageBuilt] -> [onPageDispose] ))
abstract class GetMiddleware {
  GetMiddleware({this.priority = 0});

  /// The Order of the Middlewares to run.
  ///
  /// {@tool snippet}
  /// This Middewares will be called in this order.
  /// ```dart
  /// final middlewares = [
  ///   GetMiddleware(priority: 2),
  ///   GetMiddleware(priority: 5),
  ///   GetMiddleware(priority: 4),
  ///   GetMiddleware(priority: -8),
  /// ];
  /// ```
  ///  -8 => 2 => 4 => 5
  /// {@end-tool}
  final int priority;

  /// This function will be called when the page of
  /// the called route is being searched for.
  /// It take RouteSettings as a result an redirect to the new settings or
  /// give it null and there will be no redirecting.
  /// {@tool snippet}
  /// ```dart
  /// GetPage redirect(String route) {
  ///   final authService = Get.find<AuthService>();
  ///   return authService.authed.value ? null : RouteSettings(name: '/login');
  /// }
  /// ```
  /// {@end-tool}
  RouteSettings? redirect(String? route) => null;

  /// Similar to [redirect],
  /// This function will be called when the router delegate changes the
  /// current route.
  ///
  /// The default implementation bridges to [redirect]: when [redirect]
  /// returns a non-null [RouteSettings] pointing to another location, the
  /// navigation is redirected there (carrying the settings' arguments),
  /// otherwise the incoming route proceeds untouched. Overriding this
  /// method replaces that bridge, so an override that should keep honoring
  /// [redirect] must call `super.redirectDelegate`.
  ///
  /// if this returns null, the navigation is stopped,
  /// and no new routes are pushed.
  ///
  /// The incoming route's arguments are available through [route.args]
  /// and can be forwarded to the redirect target with
  /// `RouteDecoder.fromRoute(target, arguments: route.args)`.
  /// {@tool snippet}
  /// ```dart
  /// GetNavConfig? redirect(GetNavConfig route) {
  ///   final authService = Get.find<AuthService>();
  ///   return authService.authed.value ? null : RouteSettings(name: '/login');
  /// }
  /// ```
  /// {@end-tool}
  FutureOr<RouteDecoder?> redirectDelegate(RouteDecoder route) {
    final settings = redirect(route.pageSettings?.name);
    final target = settings?.name;
    if (target != null && target != route.pageSettings?.name) {
      return RouteDecoder.fromRoute(target, arguments: settings!.arguments);
    }
    return route;
  }

  /// This function will be called when this Page is called
  /// you can use it to change something about the page or give it new page
  /// {@tool snippet}
  /// ```dart
  /// GetPage onPageCalled(GetPage page) {
  ///   final authService = Get.find<AuthService>();
  ///   return page.copyWith(title: 'Welcome ${authService.UserName}');
  /// }
  /// ```
  /// {@end-tool}
  GetPage? onPageCalled(GetPage? page) => page;

  /// This function will be called right before the [Binding]s are initialized.
  /// Here you can change [Binding]s for this page
  /// {@tool snippet}
  /// ```dart
  /// List<Binding> onBindingsStart(List<Binding> bindings) {
  ///   final authService = Get.find<AuthService>();
  ///   if (authService.isAdmin) {
  ///     bindings.add(AdminBinding());
  ///   }
  ///   return bindings;
  /// }
  /// ```
  /// {@end-tool}
  List<R>? onBindingsStart<R>(List<R>? bindings) => bindings;

  /// This function will be called right after the [Binding]s are initialized.
  GetPageBuilder? onPageBuildStart(GetPageBuilder? page) => page;

  /// This function will be called right after the
  /// GetPage.page function is called and will give you the result
  /// of the function. and take the widget that will be showed.
  Widget onPageBuilt(Widget page) => page;

  void onPageDispose() {}
}

class MiddlewareRunner {
  MiddlewareRunner(List<GetMiddleware>? middlewares)
    : _middlewares = middlewares != null
          ? (List.of(middlewares)..sort(_compareMiddleware))
          : const [];

  final List<GetMiddleware> _middlewares;

  static int _compareMiddleware(GetMiddleware a, GetMiddleware b) =>
      a.priority.compareTo(b.priority);

  GetPage? runOnPageCalled(GetPage? page) {
    for (final middleware in _middlewares) {
      page = middleware.onPageCalled(page);
    }
    return page;
  }

  RouteSettings? runRedirect(String? route) {
    for (final middleware in _middlewares) {
      final redirectTo = middleware.redirect(route);
      if (redirectTo != null) {
        return redirectTo;
      }
    }
    return null;
  }

  List<R>? runOnBindingsStart<R>(List<R>? bindings) {
    for (final middleware in _middlewares) {
      bindings = middleware.onBindingsStart(bindings);
    }
    return bindings;
  }

  GetPageBuilder? runOnPageBuildStart(GetPageBuilder? page) {
    for (final middleware in _middlewares) {
      page = middleware.onPageBuildStart(page);
    }
    return page;
  }

  Widget runOnPageBuilt(Widget page) {
    for (final middleware in _middlewares) {
      page = middleware.onPageBuilt(page);
    }
    return page;
  }

  void runOnPageDispose() {
    for (final middleware in _middlewares) {
      middleware.onPageDispose();
    }
  }
}

class PageRedirect {
  GetPage? route;
  GetPage? unknownRoute;
  RouteSettings? settings;
  bool isUnknown;

  PageRedirect({
    this.route,
    this.unknownRoute,
    this.isUnknown = false,
    this.settings,
  });

  /// The parameters of the route whose middlewares are currently being
  /// evaluated, or `null` when no middleware resolution is in flight.
  ///
  /// While middlewares run for an in-flight navigation, the router
  /// delegate's history still reflects the previous route, so a top-of-stack
  /// lookup would hand [GetMiddleware.redirect] and
  /// [GetMiddleware.onPageCalled] stale parameters. [GetDelegate.parameters]
  /// (and therefore `Get.parameters`) prefers this override while it is set,
  /// making the parameters of the route being resolved (including the query
  /// parameters added by a previous redirect) visible to middlewares.
  static Map<String, String>? resolvingParameters;

  // redirect all pages that needs redirecting
  GetPageRoute<T> getPageToRoute<T>(
    GetPage rou,
    GetPage? unk,
    BuildContext context,
  ) {
    var redirected = false;
    final visited = <String>{};
    while (needRecheck(context)) {
      redirected = true;
      final target = settings?.name;
      if (target == null || !visited.add(target)) {
        // A middleware redirect cycle can never settle; degrade to the
        // not-found page instead of looping forever on the UI thread.
        isUnknown = true;
        break;
      }
    }
    final r = isUnknown
        ? unk ?? context.delegate.notFoundRoute
        : (redirected ? route ?? rou : rou);

    // Attribute each binding of the (possibly nested) page to the branch
    // page that declared it, so dependencies registered by inherited
    // ancestor bindings link to the ancestor's route instead of this one
    // (deep-linking to a nested page must not take ownership of its
    // ancestors' controllers).
    final bindingOwners = ParseRouteTree.bindingOwnersOf(
      context.delegate.matchRoute(r.name).currentTreeBranch,
    );

    return GetPageRoute<T>(
      page: r.page,
      parameter: r.parameters,
      alignment: r.alignment,
      title: r.title,
      maintainState: r.maintainState,
      routeName: r.name,
      settings: rou,
      curve: r.curve,
      showCupertinoParallax: r.showCupertinoParallax,
      gestureWidth: r.gestureWidth,
      opaque: r.opaque,
      customTransition: r.customTransition,
      bindings: r.bindings,
      transitionDuration: r.transitionDuration ?? Get.defaultTransitionDuration,
      reverseTransitionDuration:
          r.reverseTransitionDuration ?? Get.defaultTransitionDuration,
      // performIncomeAnimation: _r.performIncomeAnimation,
      // performOutGoingAnimation: _r.performOutGoingAnimation,
      transition: r.transition,
      popGesture: r.popGesture,
      fullscreenDialog: r.fullscreenDialog,
      middlewares: context.delegate.ownMiddlewaresOf(r.name) ?? r.middlewares,
      bindingOwnerNames: bindingOwners,
    );
  }

  /// check if redirect is needed
  bool needRecheck(BuildContext context) {
    if (settings == null && route != null) {
      settings = route;
    }
    final match = context.delegate.matchRoute(settings!.name!);

    // No Match found
    if (match.route == null) {
      isUnknown = true;
      return false;
    }

    // No middlewares found return match.
    if (match.route!.middlewares.isEmpty) {
      route = match.route;
      return false;
    }

    final runner = MiddlewareRunner(match.route!.middlewares);
    final matchParameters = match.route!.parameters;
    final previousResolvingParameters = resolvingParameters;
    resolvingParameters = matchParameters == null
        ? null
        : Map<String, String>.of(matchParameters);
    try {
      final called = runner.runOnPageCalled(match.route);
      if (called == null) {
        // Returning null from onPageCalled cancels the page: degrade
        // gracefully to the not-found page.
        isUnknown = true;
        return false;
      }
      route = called;

      final newSettings = runner.runRedirect(settings!.name);
      if (newSettings == null) {
        return false;
      }
      settings = newSettings;
      return true;
    } finally {
      resolvingParameters = previousResolvingParameters;
    }
  }
}
