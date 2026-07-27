import 'package:flutter/widgets.dart';

/// A customized [PopupRoute] used to display a modal dialog.
///
/// This route is responsible for rendering the dialog content and handling
/// transition animations, barrier effects, and dismiss gestures.
class GetDialogRoute<T> extends PopupRoute<T> {
  /// Constructs a [GetDialogRoute].
  ///
  /// Requires a [pageBuilder] function to build the dialog widget.
  /// [barrierDismissible], [barrierLabel], [barrierColor], [transitionDuration],
  /// [transitionBuilder], and [settings] can be customized as needed.
  GetDialogRoute({
    required this.pageBuilder,
    this.barrierDismissible = true,
    this.barrierLabel,
    this.barrierColor = const Color(0x80000000),
    this.transitionDuration = const Duration(milliseconds: 200),
    this.transitionBuilder,
    super.settings,
    this.anchorPoint,
    this._traversalEdgeBehavior,
  });

  final RoutePageBuilder pageBuilder;

  @override
  final bool barrierDismissible;

  @override
  final String? barrierLabel;

  @override
  final Color barrierColor;

  @override
  final Duration transitionDuration;

  final RouteTransitionsBuilder? transitionBuilder;

  final Offset? anchorPoint;

  final TraversalEdgeBehavior? _traversalEdgeBehavior;
  @override
  TraversalEdgeBehavior? get traversalEdgeBehavior =>
      _traversalEdgeBehavior ?? super.traversalEdgeBehavior;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: pageBuilder(context, animation, secondaryAnimation),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (transitionBuilder == null) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.linear),
        child: child,
      );
    } // Some default transition
    return transitionBuilder!(context, animation, secondaryAnimation, child);
  }
}
