part of '../extension_navigation.dart';

extension ExtensionDialog on GetInterface {
  /// Show a dialog.
  /// You can pass a [transitionDuration] and/or [transitionCurve],
  /// overriding the defaults when the dialog shows up and closes.
  /// When the dialog closes, uses those animations in reverse.
  ///
  /// Pass a [transitionBuilder] to fully replace the default fade
  /// animation with a custom one; [transitionCurve] is ignored in
  /// that case, while [transitionDuration] still drives the animation.
  Future<T?> dialog<T>(
    Widget widget, {
    bool barrierDismissible = true,
    Color? barrierColor,
    bool useSafeArea = true,
    GlobalKey<NavigatorState>? navigatorKey,
    Object? arguments,
    Duration? transitionDuration,
    Curve? transitionCurve,
    RouteTransitionsBuilder? transitionBuilder,
    String? name,
    RouteSettings? routeSettings,
    Offset? anchorPoint,
    TraversalEdgeBehavior? traversalEdgeBehavior,
    String? id,
  }) {
    assert(debugCheckHasMaterialLocalizations(context!));

    final theme = Theme.of(context!);
    return generalDialog<T>(
      pageBuilder: (buildContext, animation, secondaryAnimation) {
        final pageChild = widget;
        Widget dialog = Builder(
          builder: (context) {
            return Theme(data: theme, child: pageChild);
          },
        );
        if (useSafeArea) {
          dialog = SafeArea(child: dialog);
        }
        return dialog;
      },
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context!).modalBarrierDismissLabel,
      barrierColor: barrierColor ?? Colors.black54,
      transitionDuration: transitionDuration ?? defaultDialogTransitionDuration,
      transitionBuilder:
          transitionBuilder ??
          (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: transitionCurve ?? defaultDialogTransitionCurve,
              ),
              child: child,
            );
          },
      navigatorKey: navigatorKey,
      routeSettings:
          routeSettings ?? RouteSettings(arguments: arguments, name: name),
      anchorPoint: anchorPoint,
      traversalEdgeBehavior: traversalEdgeBehavior,
      id: id,
    );
  }

  /// Api from showGeneralDialog with no context
  Future<T?> generalDialog<T>({
    required RoutePageBuilder pageBuilder,
    bool barrierDismissible = false,
    String? barrierLabel,
    Color barrierColor = const Color(0x80000000),
    Duration transitionDuration = const Duration(milliseconds: 200),
    RouteTransitionsBuilder? transitionBuilder,
    GlobalKey<NavigatorState>? navigatorKey,
    RouteSettings? routeSettings,
    Offset? anchorPoint,
    TraversalEdgeBehavior? traversalEdgeBehavior,
    String? id,
  }) {
    assert(!barrierDismissible || barrierLabel != null);
    final key = navigatorKey ?? Get.nestedKey(id)?.navigatorKey;
    final nav =
        key?.currentState ??
        Navigator.of(
          overlayContext!,
          rootNavigator: true,
        ); //overlay context will always return the root navigator
    final routeUnderDialog = _topRouteOf(nav);
    final result = nav.push<T>(
      GetDialogRoute<T>(
        pageBuilder: pageBuilder,
        barrierDismissible: barrierDismissible,
        barrierLabel: barrierLabel,
        barrierColor: barrierColor,
        transitionDuration: transitionDuration,
        transitionBuilder: transitionBuilder,
        settings: routeSettings,
        anchorPoint: anchorPoint,
        traversalEdgeBehavior: traversalEdgeBehavior,
      ),
    );
    _relinkDependenciesTo(routeUnderDialog);
    return result;
  }

  /// Custom UI Dialog.
  ///
  /// Besides the cancel and confirm buttons, a third action can be added:
  /// pass [custom] to render your own action widget, or use [textCustom]
  /// and/or [onCustom] to render a default-styled button labeled
  /// [textCustom] (defaults to "Custom") that invokes [onCustom] when
  /// tapped. Like the confirm button, the custom button does not close
  /// the dialog by itself; close it from your callback if desired.
  /// For custom body content use [content] instead.
  ///
  /// Set [canPop] to false to block the system back gesture/button from
  /// dismissing the dialog; it can then only be closed programmatically
  /// (e.g. `Get.back()` from one of its actions). [onWillPop] is still
  /// invoked for every pop attempt, with `didPop` false when the pop
  /// was blocked.
  Future<T?> defaultDialog<T>({
    String title = "Alert",
    EdgeInsetsGeometry? titlePadding,
    TextStyle? titleStyle,
    Widget? content,
    String? id,
    EdgeInsetsGeometry? contentPadding,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    VoidCallback? onCustom,
    Color? cancelTextColor,
    Color? confirmTextColor,
    String? textConfirm,
    String? textCancel,
    String? textCustom,
    Widget? confirm,
    Widget? cancel,
    Widget? custom,
    Color? backgroundColor,
    bool barrierDismissible = true,
    Color? buttonColor,
    String middleText = "\n",
    TextStyle? middleTextStyle,
    double radius = 20.0,
    List<Widget>? actions,
    PopInvokedWithResultCallback<T>? onWillPop,
    bool canPop = true,
    GlobalKey<NavigatorState>? navigatorKey,
    Offset? anchorPoint,
    TraversalEdgeBehavior? traversalEdgeBehavior,
    bool scrollable = false,
  }) {
    var leanCancel = onCancel != null || textCancel != null;
    var leanConfirm = onConfirm != null || textConfirm != null;
    var leanCustom = onCustom != null || textCustom != null;
    actions ??= [];

    if (cancel != null) {
      actions.add(cancel);
    } else {
      if (leanCancel) {
        actions.add(
          TextButton(
            style: TextButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  color: buttonColor ?? theme.colorScheme.secondary,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
            onPressed: () {
              if (onCancel == null) {
                closeAllDialogs();
              } else {
                onCancel.call();
              }
            },
            child: Text(
              textCancel ?? "Cancel",
              style: TextStyle(
                color: cancelTextColor ?? theme.colorScheme.secondary,
              ),
            ),
          ),
        );
      }
    }
    if (confirm != null) {
      actions.add(confirm);
    } else {
      if (leanConfirm) {
        actions.add(
          TextButton(
            style: TextButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: buttonColor ?? theme.colorScheme.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
            child: Text(
              textConfirm ?? "Ok",
              style: TextStyle(
                color: confirmTextColor ?? theme.colorScheme.surface,
              ),
            ),
            onPressed: () {
              onConfirm?.call();
            },
          ),
        );
      }
    }
    if (custom != null) {
      actions.add(custom);
    } else {
      if (leanCustom) {
        actions.add(
          TextButton(
            style: TextButton.styleFrom(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: buttonColor ?? theme.colorScheme.secondary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
            child: Text(
              textCustom ?? "Custom",
              style: TextStyle(
                color: confirmTextColor ?? theme.colorScheme.surface,
              ),
            ),
            onPressed: () {
              onCustom?.call();
            },
          ),
        );
      }
    }

    Widget baseAlertDialog = Builder(
      builder: (context) {
        return AlertDialog(
          titlePadding: titlePadding ?? const EdgeInsets.all(8),
          contentPadding: contentPadding ?? const EdgeInsets.all(8),
          scrollable: scrollable,

          backgroundColor:
              backgroundColor ?? DialogTheme.of(context).backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(radius)),
          ),
          title: Text(title, textAlign: TextAlign.center, style: titleStyle),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              content ??
                  Text(
                    middleText,
                    textAlign: TextAlign.center,
                    style: middleTextStyle,
                  ),
              const SizedBox(height: 16),
              ButtonTheme(
                minWidth: 78.0,
                height: 34.0,
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: actions!,
                ),
              ),
            ],
          ),
          // actions: actions, // ?? <Widget>[cancelButton, confirmButton],
          buttonPadding: EdgeInsets.zero,
        );
      },
    );

    return dialog<T>(
      (onWillPop != null || !canPop)
          ? PopScope<T>(
              canPop: canPop,
              onPopInvokedWithResult: (didPop, result) =>
                  onWillPop?.call(didPop, result),
              child: baseAlertDialog,
            )
          : baseAlertDialog,
      barrierDismissible: barrierDismissible,
      navigatorKey: navigatorKey,
      anchorPoint: anchorPoint,
      traversalEdgeBehavior: traversalEdgeBehavior,
      id: id,
    );
  }
}
