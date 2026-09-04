import 'package:material_ui/material_ui.dart';

import '../../../getxify.dart';

/// A customized [PopupRoute] used to display a modal bottom sheet.
///
/// This route is responsible for rendering the [BottomSheet] widget with
/// appropriate transition animations, barrier colors, and gesture handling.
class GetModalBottomSheetRoute<T> extends PopupRoute<T> {
  /// Constructs a [GetModalBottomSheetRoute].
  ///
  /// This requires a [builder] that returns the widget content of the bottom sheet.
  /// Standard parameters like [backgroundColor], [elevation], and [shape] will fall back
  /// to the closest [BottomSheetThemeData] if omitted.
  GetModalBottomSheetRoute({
    this.builder,
    this.theme,
    this.barrierLabel,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.removeTop = true,
    this.clipBehavior,
    this.modalBarrierColor,
    this.isDismissible = true,
    this.enableDrag = true,
    this.showDragHandle,
    this.dragHandleColor,
    this.dragHandleSize,
    this.shadowColor,
    this.surfaceTintColor,
    required this.isScrollControlled,
    super.settings,
    this.enterBottomSheetDuration = const Duration(milliseconds: 250),
    this.exitBottomSheetDuration = const Duration(milliseconds: 200),
    this.curve,
  });
  final WidgetBuilder? builder;
  final ThemeData? theme;
  final bool isScrollControlled;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  final Color? modalBarrierColor;
  final bool isDismissible;
  final bool enableDrag;
  final bool? showDragHandle;
  final Color? dragHandleColor;
  final Size? dragHandleSize;
  final Color? shadowColor;
  final Color? surfaceTintColor;
  final Duration enterBottomSheetDuration;
  final Duration exitBottomSheetDuration;
  final Curve? curve;
  final bool removeTop;

  @override
  Duration get transitionDuration => enterBottomSheetDuration;

  @override
  bool get barrierDismissible => isDismissible;

  @override
  final String? barrierLabel;

  @override
  Color get barrierColor => modalBarrierColor ?? Colors.black54;

  AnimationController? _animationController;

  AnimationController? get animationController => _animationController;

  @override
  Animation<double> createAnimation() {
    if (curve != null) {
      return CurvedAnimation(curve: curve!, parent: _animationController!.view);
    }
    return _animationController!.view;
  }

  @override
  AnimationController createAnimationController() {
    assert(_animationController == null);
    _animationController = BottomSheet.createAnimationController(
      navigator!.overlay!,
    );
    _animationController!.duration = enterBottomSheetDuration;
    _animationController!.reverseDuration = exitBottomSheetDuration;
    return _animationController!;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final sheetTheme =
        theme?.bottomSheetTheme ?? Theme.of(context).bottomSheetTheme;
    // By definition, the bottom sheet is aligned to the bottom of the page
    // and isn't exposed to the top padding of the MediaQuery.
    Widget bottomSheet = MediaQuery.removePadding(
      context: context,
      removeTop: removeTop,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _GetModalBottomSheet<T>(
          route: this,
          backgroundColor:
              backgroundColor ??
              sheetTheme.modalBackgroundColor ??
              sheetTheme.backgroundColor,
          elevation:
              elevation ?? sheetTheme.modalElevation ?? sheetTheme.elevation,
          shape: shape,
          clipBehavior: clipBehavior,
          isScrollControlled: isScrollControlled,
          enableDrag: enableDrag,
          showDragHandle: showDragHandle,
          dragHandleColor: dragHandleColor,
          dragHandleSize: dragHandleSize,
          shadowColor: shadowColor,
          surfaceTintColor: surfaceTintColor,
        ),
      ),
    );
    if (theme != null) bottomSheet = Theme(data: theme!, child: bottomSheet);
    // Apps that don't install the material delegates (e.g. GetCupertinoApp)
    // have no MaterialLocalizations in their tree, which made the sheet
    // throw. When the localizations are missing, fall back to
    // DefaultMaterialLocalizations; under GetMaterialApp the inherited
    // localizations are found and the route behaves exactly as before.
    final hasMaterialLocalizations =
        Localizations.of<MaterialLocalizations>(
          context,
          MaterialLocalizations,
        ) !=
        null;
    if (!hasMaterialLocalizations) {
      bottomSheet = Localizations.override(
        context: context,
        delegates: const [DefaultMaterialLocalizations.delegate],
        child: bottomSheet,
      );
    }
    return bottomSheet;
  }
}

class _GetModalBottomSheet<T> extends StatefulWidget {
  const _GetModalBottomSheet({
    super.key,
    this.route,
    this.backgroundColor,
    this.elevation,
    this.shape,
    this.clipBehavior,
    this.isScrollControlled = false,
    this.enableDrag = true,
    this.showDragHandle,
    this.dragHandleColor,
    this.dragHandleSize,
    this.shadowColor,
    this.surfaceTintColor,
  });
  final GetModalBottomSheetRoute<T>? route;
  final bool isScrollControlled;
  final Color? backgroundColor;
  final double? elevation;
  final ShapeBorder? shape;
  final Clip? clipBehavior;
  final bool enableDrag;
  final bool? showDragHandle;
  final Color? dragHandleColor;
  final Size? dragHandleSize;
  final Color? shadowColor;
  final Color? surfaceTintColor;

  @override
  _GetModalBottomSheetState<T> createState() => _GetModalBottomSheetState<T>();
}

class _GetModalBottomSheetState<T> extends State<_GetModalBottomSheet<T>> {
  String _getRouteLabel(MaterialLocalizations localizations) {
    if ((Theme.of(context).platform == TargetPlatform.android) ||
        (Theme.of(context).platform == TargetPlatform.fuchsia)) {
      return localizations.dialogLabel;
    } else {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    assert(debugCheckHasMaterialLocalizations(context));
    final mediaQuery = MediaQuery.of(context);
    final localizations = MaterialLocalizations.of(context);
    final routeLabel = _getRouteLabel(localizations);

    return AnimatedBuilder(
      animation: widget.route?.animation ?? const AlwaysStoppedAnimation(0.0),
      builder: (context, child) {
        // Disable the initial animation when accessible navigation is on so
        // that the semantics are added to the tree at the correct time.
        final animationValue = mediaQuery.accessibleNavigation
            ? 1.0
            : (widget.route?.animation?.value ?? 0.0);
        return Semantics(
          scopesRoute: true,
          namesRoute: true,
          label: routeLabel,
          explicitChildNodes: true,
          child: ClipRect(
            child: CustomSingleChildLayout(
              delegate: _GetModalBottomSheetLayout(
                animationValue,
                widget.isScrollControlled,
              ),
              child: BottomSheet(
                animationController: widget.route?.animationController,
                onClosing: () {
                  if (widget.route?.isCurrent ?? false) {
                    Navigator.pop(context);
                  }
                },
                builder: widget.route?.builder ?? (context) => const SizedBox(),
                backgroundColor: widget.backgroundColor,
                elevation: widget.elevation,
                shape: widget.shape,
                clipBehavior: widget.clipBehavior,
                enableDrag: widget.enableDrag,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GetModalBottomSheetLayout extends SingleChildLayoutDelegate {
  _GetModalBottomSheetLayout(this.progress, this.isScrollControlled);

  final double progress;
  final bool isScrollControlled;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      minWidth: constraints.maxWidth,
      maxWidth: constraints.maxWidth,
      minHeight: 0.0,
      maxHeight: isScrollControlled
          ? constraints.maxHeight
          : constraints.maxHeight * 9.0 / 16.0,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    return Offset(0.0, size.height - childSize.height * progress);
  }

  @override
  bool shouldRelayout(_GetModalBottomSheetLayout oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
