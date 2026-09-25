import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../../getxify.dart';

class GetInformationParser extends RouteInformationParser<RouteDecoder> {
  factory GetInformationParser.createInformationParser({
    String initialRoute = '/',
  }) {
    return GetInformationParser(initialRoute: initialRoute);
  }

  final String initialRoute;

  /// Whether the first route information report has already been parsed.
  ///
  /// The platform reports its default location '/' on startup; following
  /// [WidgetsApp.initialRoute] semantics, that first report resolves to
  /// [initialRoute] even when a '/' page is registered. Later reports of
  /// '/' (e.g. the browser navigating back to the root) are parsed
  /// literally so a registered '/' page stays reachable.
  bool _initialParseDone = false;

  GetInformationParser({required this.initialRoute}) {
    Get.log('GetInformationParser is created !');
  }
  @override
  SynchronousFuture<RouteDecoder> parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    final uri = routeInformation.uri;
    var location = uri.toString();
    final isInitialParse = !_initialParseDone;
    _initialParseDone = true;
    if (location == '/') {
      if (isInitialParse && initialRoute != '/') {
        // The platform reported its default location: honor initialRoute
        // even when a '/' page is registered.
        location = initialRoute;
      } else if (!(Get.rootController.rootDelegate).registeredRoutes.any(
        (element) => element.name == '/',
      )) {
        // No corresponding '/' page: relocate to initialRoute.
        location = initialRoute;
      }
    } else if (location.isEmpty) {
      location = initialRoute;
    }

    Get.log('GetInformationParser: route location: $location');

    return SynchronousFuture(RouteDecoder.fromRoute(location));
  }

  @override
  RouteInformation restoreRouteInformation(RouteDecoder configuration) {
    return RouteInformation(
      uri: Uri.tryParse(configuration.pageSettings?.name ?? ''),
      state: null,
    );
  }
}
