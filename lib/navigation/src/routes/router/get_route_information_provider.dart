import 'package:flutter/widgets.dart';

import 'get_router_delegate.dart';

/// A [RouteInformationProvider] that keeps the platform (browser) history
/// in sync with the page stack managed by a [GetDelegate].
///
/// Replace-style navigations ([GetDelegate.off], [GetDelegate.offAll],
/// [GetDelegate.offAllNamed] and similar) remove entries from
/// [GetDelegate.activePages], so the resulting URL update must overwrite the
/// current browser history entry instead of pushing a new one. The default
/// [PlatformRouteInformationProvider] reports every URL change as a push,
/// which on Flutter Web lets the browser back button resurrect pages that
/// were already removed from the stack.
///
/// On every report this provider consumes [GetDelegate.consumeReplaceReport]
/// and upgrades [RouteInformationReportingType.none] to
/// [RouteInformationReportingType.neglect] when the delegate marked the last
/// stack mutation as a replacement, so the engine receives `replace: true`.
///
/// The very first report after startup is always upgraded the same way: no
/// user navigation can have occurred before it, so it merely normalizes the
/// engine's initial location (initial-route resolution, default-child
/// expansion or a middleware redirect). Pushing it would create a phantom
/// history entry that activates the browser back button on a plain page
/// load (#3266).
class GetRouteInformationProvider extends PlatformRouteInformationProvider {
  /// Creates a provider bound to the given [GetDelegate].
  ///
  /// [initialRouteInformation] sets the default route information, exactly
  /// like [PlatformRouteInformationProvider.initialRouteInformation].
  GetRouteInformationProvider(
    this._delegate, {
    required super.initialRouteInformation,
  });

  final GetDelegate _delegate;

  /// Whether the first route information report has already been sent to
  /// the engine (see the class documentation).
  bool _firstReportDone = false;

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    final replace = _delegate.consumeReplaceReport();
    final isFirstReport = !_firstReportDone;
    _firstReportDone = true;
    if ((replace || isFirstReport) &&
        type == RouteInformationReportingType.none) {
      type = RouteInformationReportingType.neglect;
    }
    super.routerReportsNewRouteInformation(routeInformation, type: type);
  }
}
