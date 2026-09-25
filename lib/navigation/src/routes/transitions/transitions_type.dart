import 'package:flutter/widgets.dart';

import '../core/default_route.dart';

enum Transition {
  fade,
  fadeIn,
  rightToLeft,
  leftToRight,
  upToDown,
  downToUp,
  rightToLeftWithFade,
  leftToRightWithFade,
  zoom,
  topLevel,
  noTransition,
  cupertino,
  cupertinoDialog,
  size,
  circularReveal,
  native,

  /// Delegates to Flutter's `PredictiveBackPageTransitionsBuilder`, letting
  /// the route participate in Android's predictive back gesture and falling
  /// back to the zoom transition when no predictive back gesture is in
  /// progress.
  predictiveBack,
}

typedef GetPageBuilder = Widget Function();
typedef GetRouteAwarePageBuilder<T> = Widget Function([GetPageRoute<T>? route]);
