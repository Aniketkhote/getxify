import 'package:flutter/widgets.dart';

/// Abstract class for defining custom page transitions.
///
/// Implement this class to create custom transition animations for navigation.
/// The [buildTransition] method should return a widget that applies the desired
/// transition effect to the [child] widget.
///
/// Example implementation:
/// ```dart
/// class FadeInTransition extends CustomTransition {
///   @override
///   Widget buildTransition(
///     BuildContext context,
///     Curve? curve,
///     Alignment? alignment,
///     Animation<double> animation,
///     Animation<double> secondaryAnimation,
///     Widget child,
///   ) {
///     return FadeTransition(
///       opacity: CurvedAnimation(parent: animation, curve: curve ?? Curves.easeInOut),
///       child: child,
///     );
///   }
/// }
/// ```
abstract class CustomTransition {
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  );
}
