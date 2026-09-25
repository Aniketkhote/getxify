import 'package:flutter/widgets.dart';

/// A [TransitionDelegate] that resolves page-list changes like the
/// framework's [DefaultTransitionDelegate], except while [isPopNavigation]
/// reports that the change being applied was caused by a back navigation.
///
/// A pop through GetX's router delegate (`GetDelegate.back`,
/// `GetDelegate.popRoute`, the browser back button, ...) mutates the
/// declarative page list. When the revealed page was already in the previous
/// list the navigator performs a genuine removal and the default delegate
/// correctly plays the leaving route's pop animation. But when the pop
/// surfaces as a *replacement* — the incoming page was not in the previous
/// list, which is the norm for nested `GetRouterOutlet` stacks that render
/// only the current tree branch — the default delegate marks the incoming
/// page for push (a forward animation) and completes the leaving route
/// without any animation (#1883).
///
/// While [isPopNavigation] returns `true` this delegate instead:
///
///  * enters new pages in place, without a forward animation
///    ([RouteTransitionRecord.markForAdd]);
///  * pops the top-most exiting route with its reverse transition
///    ([RouteTransitionRecord.markForPop]) — unless pageless routes
///    (dialogs, sheets) sit on top of it, mirroring the default delegate;
///  * completes every other exiting route without animation; and
///  * keeps the exiting routes above the entering ones in the resulting
///    history, so the pop animation plays on top of the revealed page.
///
/// When [isPopNavigation] returns `false` the resolution is byte-for-byte
/// the [DefaultTransitionDelegate]'s.
class GetTransitionDelegate<T> extends TransitionDelegate<T> {
  /// Creates a transition delegate that applies pop semantics whenever
  /// [isPopNavigation] returns `true` at resolve time.
  const GetTransitionDelegate({required this.isPopNavigation});

  /// Whether the page-list change being resolved was caused by a back
  /// navigation. Read live from the router delegate at resolve time.
  final ValueGetter<bool> isPopNavigation;

  @override
  Iterable<RouteTransitionRecord> resolve({
    required List<RouteTransitionRecord> newPageRouteHistory,
    required Map<RouteTransitionRecord?, RouteTransitionRecord>
    locationToExitingPageRoute,
    required Map<RouteTransitionRecord?, List<RouteTransitionRecord>>
    pageRouteToPagelessRoutes,
  }) {
    if (!isPopNavigation()) {
      return const DefaultTransitionDelegate<dynamic>().resolve(
        newPageRouteHistory: newPageRouteHistory,
        locationToExitingPageRoute: locationToExitingPageRoute,
        pageRouteToPagelessRoutes: pageRouteToPagelessRoutes,
      );
    }
    // Collects the exiting page routes in visual order (bottom to top):
    // routes removed from the bottom of the original stack first, then, for
    // every page kept in the new history, the chain of routes that was
    // removed from directly above it.
    final exitingRoutes = <RouteTransitionRecord>[];
    void collectExitingFrom(RouteTransitionRecord? location) {
      final exitingPageRoute = locationToExitingPageRoute[location];
      if (exitingPageRoute == null) return;
      exitingRoutes.add(exitingPageRoute);
      // Another route may have been removed from directly above this one.
      collectExitingFrom(exitingPageRoute);
    }

    collectExitingFrom(null);
    final results = <RouteTransitionRecord>[];
    for (final pageRoute in newPageRouteHistory) {
      if (pageRoute.isWaitingForEnteringDecision) {
        // The page enters because a pop revealed it: it must appear in
        // place, without a forward animation.
        pageRoute.markForAdd();
      }
      results.add(pageRoute);
      collectExitingFrom(pageRoute);
    }
    for (final exitingPageRoute in exitingRoutes) {
      if (exitingPageRoute.isWaitingForExitingDecision) {
        final hasPagelessRoute = pageRouteToPagelessRoutes.containsKey(
          exitingPageRoute,
        );
        // Only the top-most exiting route plays the pop animation; anything
        // below it is covered and completes instantly, as in the default
        // delegate. When the top-most exiting route needs no decision (it
        // is already animating out), nothing else pops on top of it.
        final isTopExitingRoute = identical(
          exitingPageRoute,
          exitingRoutes.last,
        );
        if (isTopExitingRoute && !hasPagelessRoute) {
          exitingPageRoute.markForPop(exitingPageRoute.route.currentResult);
        } else {
          exitingPageRoute.markForComplete(
            exitingPageRoute.route.currentResult,
          );
        }
        if (hasPagelessRoute) {
          final pagelessRoutes = pageRouteToPagelessRoutes[exitingPageRoute]!;
          for (final pagelessRoute in pagelessRoutes) {
            // A pageless route that belongs to an exiting page-based route
            // may not require a decision (e.g. the page list was updated
            // right after a Navigator.pop).
            if (pagelessRoute.isWaitingForExitingDecision) {
              if (isTopExitingRoute &&
                  identical(pagelessRoute, pagelessRoutes.last)) {
                pagelessRoute.markForPop(pagelessRoute.route.currentResult);
              } else {
                pagelessRoute.markForComplete(
                  pagelessRoute.route.currentResult,
                );
              }
            }
          }
        }
      }
      // Exiting routes are appended after (visually above) the entering
      // pages, so the popping route animates out on top of the page it
      // reveals instead of disappearing beneath it.
      results.add(exitingPageRoute);
    }
    return results;
  }
}

/// A [Navigator] preconfigured for GetX's Router (Navigator 2.0) flow.
///
/// Hero support comes from the enclosing [HeroControllerScope] installed by
/// `MaterialApp.router`/`CupertinoApp.router` (which `GetMaterialApp` and
/// `GetCupertinoApp` always build). No [HeroController] is added to
/// [observers] here: the scope's controller is already attached to this
/// navigator by the framework, and registering a second controller would
/// start two hero flights per transition — doubled heroes and
/// `Hero` divert assertion failures during back gestures.
class GetNavigator extends Navigator {
  GetNavigator({
    super.key,
    super.onDidRemovePage,
    required super.pages,
    List<NavigatorObserver>? observers,
    super.reportsRouteUpdateToEngine,
    TransitionDelegate? transitionDelegate,
    super.initialRoute,
    super.restorationScopeId,
  }) : super(
         observers: [...?observers],
         transitionDelegate:
             transitionDelegate ?? const DefaultTransitionDelegate<dynamic>(),
       );
}
