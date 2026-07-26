import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:getxify/get_navigation/src/routes/core/test_kit.dart';

import '../../getxify.dart';
import 'dialog/dialog_route.dart';
import 'root/get_root.dart';
import 'router_report.dart';

class RouteNotFoundException implements Exception {
  final String message;
  RouteNotFoundException(this.message);

  @override
  String toString() => 'RouteNotFoundException: $message';
}

/// It replaces the Flutter Navigator, but needs no context.
/// You can to use navigator.push(YourRoute()) rather
/// Navigator.push(context, YourRoute());
NavigatorState? get navigator => GetNavigationExt(Get).key.currentState;

/// Whether [route] displays a dialog, either GetX's own [GetDialogRoute]
/// or one created by Flutter's native `showDialog`/`showGeneralDialog`.
bool _isDialogRoute(Route<dynamic>? route) =>
    route is GetDialogRoute || route is RawDialogRoute;

/// Whether [route] displays a bottom sheet, either GetX's own
/// [GetModalBottomSheetRoute] or one created by Flutter's native
/// `showModalBottomSheet`.
bool _isBottomSheetRoute(Route<dynamic>? route) =>
    route is GetModalBottomSheetRoute || route is ModalBottomSheetRoute;

extension ExtensionBottomSheet on GetInterface {
  /// Shows a modal bottom sheet containing [bottomsheet].
  ///
  /// [arguments] and [name] are shortcuts to build the sheet's
  /// [RouteSettings], mirroring `Get.dialog`; the arguments become
  /// readable through `Get.arguments` while the sheet is open. When an
  /// explicit [settings] is provided it takes precedence and both
  /// shortcuts are ignored.
  Future<T?> bottomSheet<T>(
    Widget bottomsheet, {
    Color? backgroundColor,
    double? elevation,
    bool persistent = true,
    ShapeBorder? shape,
    Clip? clipBehavior,
    Color? barrierColor,
    bool? ignoreSafeArea,
    bool isScrollControlled = false,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool enableDrag = true,
    Object? arguments,
    String? name,
    RouteSettings? settings,
    Duration? enterBottomSheetDuration,
    Duration? exitBottomSheetDuration,
    Curve? curve,
    bool? showDragHandle,
    Color? dragHandleColor,
    Size? dragHandleSize,
    Color? shadowColor,
    Color? surfaceTintColor,
  }) {
    final navigatorState = Navigator.of(
      overlayContext!,
      rootNavigator: useRootNavigator,
    );
    final routeUnderSheet = _topRouteOf(navigatorState);
    final result = navigatorState.push(
      GetModalBottomSheetRoute<T>(
        builder: (_) => bottomsheet,
        theme: Theme.of(key.currentContext!),
        isScrollControlled: isScrollControlled,

        barrierLabel:
            Localizations.of<MaterialLocalizations>(
              key.currentContext!,
              MaterialLocalizations,
            )?.modalBarrierDismissLabel ??
            const DefaultMaterialLocalizations().modalBarrierDismissLabel,

        backgroundColor: backgroundColor ?? Colors.transparent,
        elevation: elevation,
        shape: shape,
        removeTop: ignoreSafeArea ?? true,
        clipBehavior: clipBehavior,
        isDismissible: isDismissible,
        modalBarrierColor: barrierColor,
        settings: settings ?? RouteSettings(name: name, arguments: arguments),
        enableDrag: enableDrag,
        enterBottomSheetDuration:
            enterBottomSheetDuration ?? const Duration(milliseconds: 250),
        exitBottomSheetDuration:
            exitBottomSheetDuration ?? const Duration(milliseconds: 200),
        curve: curve,
        showDragHandle: showDragHandle,
        dragHandleColor: dragHandleColor,
        dragHandleSize: dragHandleSize,
        shadowColor: shadowColor,
        surfaceTintColor: surfaceTintColor,
      ),
    );
    _relinkDependenciesTo(routeUnderSheet);
    return result;
  }
}

/// Returns the topmost route of [navigatorState] without popping it.
Route<dynamic>? _topRouteOf(NavigatorState navigatorState) {
  Route<dynamic>? topRoute;
  navigatorState.popUntil((route) {
    topRoute = route;
    return true;
  });
  return topRoute;
}

/// Reassigns new dependency registrations to [route].
///
/// Transient overlays (dialogs and bottom sheets) must not own the
/// instances registered while they are open: a `Get.put` executed inside
/// an overlay's builder logically belongs to the page under the overlay
/// and has to survive the overlay's dismissal. Since pushing the overlay
/// synchronously reports it as the current dependency-link target, this
/// restores the target to the route that was topmost before the push.
void _relinkDependenciesTo(Route<dynamic>? route) {
  if (route == null) return;
  RouterReportManager.instance.reportCurrentRoute(route);
}

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

extension ExtensionSnackbar on GetInterface {
  SnackbarController rawSnackbar({
    String? title,
    String? message,
    Widget? titleText,
    Widget? messageText,
    Widget? icon,
    bool instantInit = true,
    bool shouldIconPulse = true,
    double? maxWidth,
    EdgeInsets margin = const EdgeInsets.all(0.0),
    EdgeInsets padding = const EdgeInsets.all(16),
    double borderRadius = 0.0,
    Color? borderColor,
    double borderWidth = 1.0,
    Color backgroundColor = const Color(0xFF303030),
    Color? leftBarIndicatorColor,
    List<BoxShadow>? boxShadows,
    Gradient? backgroundGradient,
    Widget? mainButton,
    OnTap? onTap,
    Duration? duration = const Duration(seconds: 3),
    bool isDismissible = true,
    DismissDirection? dismissDirection,
    bool showProgressIndicator = false,
    AnimationController? progressIndicatorController,
    Color? progressIndicatorBackgroundColor,
    Animation<Color>? progressIndicatorValueColor,
    SnackPosition snackPosition = SnackPosition.bottom,
    SnackStyle snackStyle = SnackStyle.floating,
    Curve forwardAnimationCurve = Curves.easeOutCirc,
    Curve reverseAnimationCurve = Curves.easeOutCirc,
    Duration animationDuration = const Duration(seconds: 1),
    SnackbarStatusCallback? snackbarStatus,
    double barBlur = 0.0,
    double overlayBlur = 0.0,
    Color? overlayColor,
    Form? userInputForm,
  }) {
    final getSnackBar = GetSnackBar(
      snackbarStatus: snackbarStatus,
      title: title,
      message: message,
      titleText: titleText,
      messageText: messageText,
      snackPosition: snackPosition,
      borderRadius: borderRadius,
      margin: margin,
      duration: duration,
      barBlur: barBlur,
      backgroundColor: backgroundColor,
      icon: icon,
      shouldIconPulse: shouldIconPulse,
      maxWidth: maxWidth,
      padding: padding,
      borderColor: borderColor,
      borderWidth: borderWidth,
      leftBarIndicatorColor: leftBarIndicatorColor,
      boxShadows: boxShadows,
      backgroundGradient: backgroundGradient,
      mainButton: mainButton,
      onTap: onTap,
      isDismissible: isDismissible,
      dismissDirection: dismissDirection,
      showProgressIndicator: showProgressIndicator,
      progressIndicatorController: progressIndicatorController,
      progressIndicatorBackgroundColor: progressIndicatorBackgroundColor,
      progressIndicatorValueColor: progressIndicatorValueColor,
      snackStyle: snackStyle,
      forwardAnimationCurve: forwardAnimationCurve,
      reverseAnimationCurve: reverseAnimationCurve,
      animationDuration: animationDuration,
      overlayBlur: overlayBlur,
      overlayColor: overlayColor,
      userInputForm: userInputForm,
    );

    final controller = SnackbarController(getSnackBar);

    if (instantInit) {
      controller.show();
    } else {
      Engine.instance.addPostFrameCallback((_) {
        controller.show();
      });
    }
    return controller;
  }

  SnackbarController showSnackbar(GetSnackBar snackbar) {
    final controller = SnackbarController(snackbar);
    controller.show();
    return controller;
  }

  SnackbarController snackbar(
    String title,
    String message, {
    Color? colorText,
    Duration? duration = const Duration(seconds: 3),

    /// with instantInit = false you can put snackbar on initState
    bool instantInit = true,
    SnackPosition? snackPosition,
    Widget? titleText,
    Widget? messageText,
    Widget? icon,
    bool? shouldIconPulse,
    double? maxWidth,
    EdgeInsets? margin,
    EdgeInsets? padding,
    double? borderRadius,
    Color? borderColor,
    double? borderWidth,
    Color? backgroundColor,
    Color? leftBarIndicatorColor,
    List<BoxShadow>? boxShadows,
    Gradient? backgroundGradient,
    TextButton? mainButton,
    OnTap? onTap,
    OnHover? onHover,
    bool? isDismissible,
    bool? showProgressIndicator,
    DismissDirection? dismissDirection,
    AnimationController? progressIndicatorController,
    Color? progressIndicatorBackgroundColor,
    Animation<Color>? progressIndicatorValueColor,
    SnackStyle? snackStyle,
    Curve? forwardAnimationCurve,
    Curve? reverseAnimationCurve,
    Duration? animationDuration,
    double? barBlur,
    double? overlayBlur,
    SnackbarStatusCallback? snackbarStatus,
    Color? overlayColor,
    Form? userInputForm,
  }) {
    final getSnackBar = GetSnackBar(
      snackbarStatus: snackbarStatus,
      titleText:
          titleText ??
          Text(
            title,
            style: TextStyle(
              color: colorText ?? theme.iconTheme.color ?? Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
      messageText:
          messageText ??
          Text(
            message,
            style: TextStyle(
              color: colorText ?? theme.iconTheme.color ?? Colors.black,
              fontWeight: FontWeight.w300,
              fontSize: 14,
            ),
          ),
      snackPosition: snackPosition ?? SnackPosition.top,
      borderRadius: borderRadius ?? 15,
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 10),
      duration: duration,
      barBlur: barBlur ?? 7.0,
      backgroundColor: backgroundColor ?? Colors.grey.withValues(alpha: 0.2),
      icon: icon,
      shouldIconPulse: shouldIconPulse ?? true,
      maxWidth: maxWidth,
      padding: padding ?? const EdgeInsets.all(16),
      borderColor: borderColor,
      borderWidth: borderWidth,
      leftBarIndicatorColor: leftBarIndicatorColor,
      boxShadows: boxShadows,
      backgroundGradient: backgroundGradient,
      mainButton: mainButton,
      onTap: onTap,
      onHover: onHover,
      isDismissible: isDismissible ?? true,
      dismissDirection: dismissDirection,
      showProgressIndicator: showProgressIndicator ?? false,
      progressIndicatorController: progressIndicatorController,
      progressIndicatorBackgroundColor: progressIndicatorBackgroundColor,
      progressIndicatorValueColor: progressIndicatorValueColor,
      snackStyle: snackStyle ?? SnackStyle.floating,
      forwardAnimationCurve: forwardAnimationCurve ?? Curves.easeOutCirc,
      reverseAnimationCurve: reverseAnimationCurve ?? Curves.easeOutCirc,
      animationDuration: animationDuration ?? const Duration(seconds: 1),
      overlayBlur: overlayBlur ?? 0.0,
      overlayColor: overlayColor ?? Colors.transparent,
      userInputForm: userInputForm,
    );

    final controller = SnackbarController(getSnackBar);

    if (instantInit) {
      controller.show();
    } else {
      Engine.instance.addPostFrameCallback((_) {
        controller.show();
      });
    }
    return controller;
  }
}

extension GetNavigationExt on GetInterface {
  /// **Navigation.push()** shortcut.<br><br>
  ///
  /// Pushes a new `page` to the stack
  ///
  /// It has the advantage of not needing context,
  /// so you can call from your business logic
  ///
  /// You can set a custom [transition], and a transition [duration].
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// Just like native routing in Flutter, you can push a route
  /// as a [fullscreenDialog],
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// If you want the same behavior of ios that pops a route when the user drag,
  /// you can set [popGesture] to true
  ///
  /// If you're using the [BindingsInterface] api, you must define it here
  ///
  /// By default, GetX will prevent you from push a route that you already in,
  /// if you want to push anyway, set [preventDuplicates] to false
  ///
  /// For fully custom transition animations, pass a [customTransition];
  /// it takes precedence over [transition].
  Future<T?>? to<T extends Object?>(
    Widget Function() page, {
    bool? opaque,
    Transition? transition,
    Curve? curve,
    Duration? duration,
    String? id,
    String? routeName,
    bool fullscreenDialog = false,
    Object? arguments,
    List<BindingsInterface> bindings = const [],
    bool preventDuplicates = true,
    bool? popGesture,
    bool showCupertinoParallax = true,
    double Function(BuildContext context)? gestureWidth,
    CustomTransition? customTransition,
    bool rebuildStack = true,
    PreventDuplicateHandlingMode preventDuplicateHandlingMode =
        PreventDuplicateHandlingMode.reorderRoutes,
  }) {
    return searchDelegate(id).to(
      page,
      opaque: opaque,
      transition: transition,
      curve: curve,
      duration: duration,
      id: id,
      routeName: routeName,
      fullscreenDialog: fullscreenDialog,
      arguments: arguments,
      bindings: bindings,
      preventDuplicates: preventDuplicates,
      popGesture: popGesture,
      showCupertinoParallax: showCupertinoParallax,
      gestureWidth: gestureWidth,
      customTransition: customTransition,
      rebuildStack: rebuildStack,
      preventDuplicateHandlingMode: preventDuplicateHandlingMode,
    );
  }

  /// **Navigation.pushNamed()** shortcut.<br><br>
  ///
  /// Pushes a new named `page` to the stack.
  ///
  /// It has the advantage of not needing context, so you can call
  /// from your business logic.
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// By default, GetX will prevent you from push a route that you already in,
  /// if you want to push anyway, set [preventDuplicates] to false
  ///
  /// Note: Always put a slash on the route ('/page1'), to avoid unexpected errors
  Future<T?>? toNamed<T>(
    String page, {
    Object? arguments,
    String? id,
    bool preventDuplicates = true,
    Map<String, String>? parameters,
  }) {
    if (parameters != null) {
      final uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }

    return searchDelegate(id).toNamed(
      page,
      arguments: arguments,
      id: id,
      preventDuplicates: preventDuplicates,
      parameters: parameters,
    );
  }

  /// **Navigation.pushReplacementNamed()** shortcut.<br><br>
  ///
  /// Pop the current named `page` in the stack and push a new one in its place
  ///
  /// It has the advantage of not needing context, so you can call
  /// from your business logic.
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// By default, GetX will prevent you from push a route that you already in,
  /// if you want to push anyway, set [preventDuplicates] to false
  ///
  /// Note: Always put a slash on the route ('/page1'), to avoid unexpected errors
  Future<T?>? offNamed<T>(
    String page, {
    Object? arguments,
    String? id,
    Map<String, String>? parameters,
  }) {
    if (parameters != null) {
      final uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }
    return searchDelegate(id).offNamed(
      page,
      arguments: arguments,
      id: id,
      // preventDuplicates: preventDuplicates,
      parameters: parameters,
    );
  }

  /// **Navigation.popUntil()** shortcut.<br><br>
  ///
  /// Calls pop several times in the stack until [predicate] returns true
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// [predicate] can be used like this:
  /// `Get.until((route) => Get.currentRoute == '/home')`so when you get to home page,
  ///
  /// or also like this:
  /// `Get.until((route) => !Get.isDialogOpen())`, to make sure the
  /// dialog is closed
  void until(bool Function(GetPage<dynamic>) predicate, {String? id}) {
    return searchDelegate(id).backUntil(predicate);
  }

  /// **Navigation.pushNamedAndRemoveUntil()** shortcut.<br><br>
  ///
  /// Push the given named `page`, and then pop several pages in the stack
  /// until [predicate] returns true
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// [predicate] can be used like this:
  /// `Get.offNamedUntil(page, ModalRoute.withName('/home'))`
  /// to pop routes in stack until home,
  /// or like this:
  /// `Get.offNamedUntil((route) => !Get.isDialogOpen())`,
  /// to make sure the dialog is closed
  ///
  /// Note: Always put a slash on the route name ('/page1'), to avoid unexpected errors
  Future<T?>? offNamedUntil<T>(
    String page,
    bool Function(GetPage<dynamic>)? predicate, {
    String? id,
    Object? arguments,
    Map<String, String>? parameters,
  }) {
    if (parameters != null) {
      final uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }

    return searchDelegate(id).offNamedUntil<T>(
      page,
      predicate: predicate,
      id: id,
      arguments: arguments,
      parameters: parameters,
    );
  }

  /// **Navigation.popAndPushNamed()** shortcut.<br><br>
  ///
  /// Pop the current named page and pushes a new `page` to the stack
  /// in its place
  ///
  /// You can send any type of value to the other route in the [arguments].
  /// It is very similar to `offNamed()` but use a different approach
  ///
  /// The `offNamed()` pop a page, and goes to the next. The
  /// `offAndToNamed()` goes to the next page, and removes the previous one.
  /// The route transition animation is different.
  Future<T?>? offAndToNamed<T>(
    String page, {
    Object? arguments,
    String? id,
    Object? result,
    Map<String, String>? parameters,
  }) {
    if (parameters != null) {
      final uri = Uri(path: page, queryParameters: parameters);
      page = uri.toString();
    }
    return searchDelegate(
      id,
    ).backAndtoNamed(page, arguments: arguments, result: result);
  }

  /// **Navigation.removeRoute()** shortcut.<br><br>
  ///
  /// Remove a specific [route] from the stack
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  void removeRoute(String name, {String? id}) {
    return searchDelegate(id).removeRoute(name);
  }

  /// **Navigation.pushNamedAndRemoveUntil()** shortcut.<br><br>
  ///
  /// Push a named `page` and pop several pages in the stack
  /// until [predicate] returns true. [predicate] is optional
  ///
  /// It has the advantage of not needing context, so you can
  /// call from your business logic.
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// [predicate] can be used like this:
  /// `Get.until((route) => Get.currentRoute == '/home')`so when you get to home page,
  /// or also like
  /// `Get.until((route) => !Get.isDialogOpen())`, to make sure the dialog
  /// is closed
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// Note: Always put a slash on the route ('/page1'), to avoid unexpected errors
  Future<T?>? offAllNamed<T>(
    String newRouteName, {
    // bool Function(GetPage<dynamic>)? predicate,
    Object? arguments,
    String? id,
    Map<String, String>? parameters,
  }) {
    if (parameters != null) {
      final uri = Uri(path: newRouteName, queryParameters: parameters);
      newRouteName = uri.toString();
    }

    return searchDelegate(id).offAllNamed<T>(
      newRouteName,
      arguments: arguments,
      id: id,
      parameters: parameters,
    );
  }

  /// Returns true if a Snackbar, Dialog or BottomSheet is currently OPEN
  bool get isOverlaysOpen =>
      (isSnackbarOpen ||
      (isDialogOpen ?? false) ||
      (isBottomSheetOpen ?? false));

  /// Returns true if there is no Snackbar, Dialog or BottomSheet open
  bool get isOverlaysClosed =>
      (!isSnackbarOpen &&
      !(isDialogOpen ?? false) &&
      !(isBottomSheetOpen ?? false));

  /// **Navigation.popUntil()** shortcut.<br><br>
  ///
  /// Pop the current page, snackbar, dialog or bottomsheet in the stack
  ///
  /// if your set [closeOverlays] to true, Get.back() will close the
  /// currently open snackbar/dialog/bottomsheet AND the current page
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// When the topmost route handles the pop internally — for example a
  /// [Scaffold] with an open drawer, or a persistent bottom sheet, both of
  /// which register a [LocalHistoryEntry] on the enclosing route — that
  /// entry is consumed (e.g. the drawer closes) and the page itself stays,
  /// matching `Navigator.pop` semantics.
  ///
  /// It has the advantage of not needing context, so you can call
  /// from your business logic.
  ///
  /// Returns whether the back navigation was performed: `false` when
  /// [canPop] is true but there is no route to go back to (e.g. the
  /// current page is the only one in the stack, as after a deep link),
  /// so callers can detect the ignored back and react, `true` otherwise.
  bool back<T>({T? result, bool canPop = true, int times = 1, String? id}) {
    if (times < 1) {
      times = 1;
    }

    if (times > 1) {
      var count = 0;
      searchDelegate(id).backUntil((route) => count++ == times);
      return true;
    } else {
      if (_topRoute(id: id)?.willHandlePopInternally == true) {
        searchDelegate(id).navigatorKey.currentState?.pop<T>(result);
        return true;
      }
      if (canPop) {
        if (searchDelegate(id).canBack == true) {
          searchDelegate(id).back<T>(result);
          return true;
        }
        return false;
      } else {
        searchDelegate(id).back<T>(result);
        return true;
      }
    }
  }

  void backLegacy<T>({
    T? result,
    bool closeOverlays = false,
    bool canPop = true,
    int times = 1,
    String? id,
  }) {
    if (closeOverlays) {
      closeAllOverlays();
    }

    if (times < 1) {
      times = 1;
    }

    if (times > 1) {
      var count = 0;
      return searchDelegate(id).navigatorKey.currentState?.popUntil((route) {
        return count++ == times;
      });
    } else {
      if (canPop) {
        if (searchDelegate(id).navigatorKey.currentState?.canPop() == true) {
          return searchDelegate(id).navigatorKey.currentState?.pop<T>(result);
        }
      } else {
        return searchDelegate(id).navigatorKey.currentState?.pop<T>(result);
      }
    }
  }

  /// Returns the topmost [Route] on the navigator of the delegate
  /// matching [id], without popping it.
  Route<dynamic>? _topRoute({String? id}) {
    Route<dynamic>? currentRoute;
    searchDelegate(id).navigatorKey.currentState?.popUntil((route) {
      currentRoute = route;
      return true;
    });
    return currentRoute;
  }

  void closeAllDialogsAndBottomSheets(String? id) {
    // It can not be divided, because dialogs and bottomsheets can not be consecutive
    var topRoute = _topRoute(id: id);
    while (_isDialogRoute(topRoute) || _isBottomSheetRoute(topRoute)) {
      _popOverlayRoute(topRoute!, id: id, result: null);
      topRoute = _topRoute(id: id);
    }
  }

  /// Close all currently open dialogs, returning a [result] to each
  /// of them, if provided
  void closeAllDialogs<T>({String? id, T? result}) {
    var topRoute = _topRoute(id: id);
    while (_isDialogRoute(topRoute)) {
      _popOverlayRoute(topRoute!, id: id, result: result);
      topRoute = _topRoute(id: id);
    }
  }

  /// Close the currently open dialog, returning a [result], if provided
  void closeDialog<T>({String? id, T? result}) {
    final topRoute = _topRoute(id: id);
    // Stop if there is no dialog open
    if (!_isDialogRoute(topRoute)) return;

    _popOverlayRoute(topRoute!, id: id, result: result);
  }

  void closeBottomSheet<T>({String? id, T? result}) {
    final topRoute = _topRoute(id: id);
    // Stop if there is no bottomsheet open
    if (!_isBottomSheetRoute(topRoute)) return;

    _popOverlayRoute(topRoute!, id: id, result: result);
  }

  /// Close the current overlay (e.g. dialog or bottom sheet) returning
  /// the [result], if provided.
  ///
  /// Page routes managed by the router delegate are never popped by this
  /// method. If the navigator still shows a page that was already removed
  /// declaratively (for example by a [back] call awaited in the same frame),
  /// the pop is retried once after the pending frame settles, so the actual
  /// overlay is closed instead of a page.
  void closeOverlay<T>({String? id, T? result}) {
    final topRoute = _topRoute(id: id);
    if (topRoute == null) return;

    _popOverlayRoute(topRoute, id: id, result: result);
  }

  /// Pops [topRoute] — the already-resolved topmost route of the navigator
  /// matching [id] — following the [closeOverlay] semantics, without
  /// scanning the navigator again.
  void _popOverlayRoute<T>(
    Route<dynamic> topRoute, {
    required String? id,
    required T? result,
  }) {
    final navigatorState = searchDelegate(id).navigatorKey.currentState;
    if (navigatorState == null) return;

    if (topRoute.settings is Page) {
      engine.addPostFrameCallback((_) {
        if (_routingOrNull == null) return;
        final route = _topRoute(id: id);
        if (route != null && route.settings is! Page) {
          searchDelegate(id).navigatorKey.currentState?.pop(result);
        }
      });
      return;
    }

    navigatorState.pop(result);
  }

  /// Close all currently open bottom sheets, returning a [result] to each
  /// of them, if provided
  void closeAllBottomSheets<T>({String? id, T? result}) {
    var topRoute = _topRoute(id: id);
    while (_isBottomSheetRoute(topRoute)) {
      _popOverlayRoute(topRoute!, id: id, result: result);
      topRoute = _topRoute(id: id);
    }
  }

  void closeAllOverlays() {
    closeAllDialogsAndBottomSheets(null);
    closeAllSnackbars();
  }

  /// Closes the currently open snackbars, dialogs and bottom sheets.
  ///
  /// When [closeAll] is true (the default), every open overlay of the
  /// selected kinds is closed; otherwise only the topmost one is.
  /// Dialogs and bottom sheets are closed returning [result] to the
  /// `Future` returned when they were opened.
  ///
  /// If the topmost route handles the pop internally — for example a
  /// [Scaffold] with an open drawer, which registers a [LocalHistoryEntry]
  /// on the enclosing route — that entry is consumed first (e.g. the
  /// drawer closes) while the page itself stays.
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  void close<T extends Object>({
    bool closeAll = true,
    bool closeSnackbar = true,
    bool closeDialog = true,
    bool closeBottomSheet = true,
    String? id,
    T? result,
  }) {
    if (_topRoute(id: id)?.willHandlePopInternally == true) {
      searchDelegate(id).navigatorKey.currentState?.pop();
    }

    void handleClose(
      bool closeCondition,
      void Function() closeAllFunction,
      void Function() closeSingleFunction, [
      bool Function()? isOpenCondition,
    ]) {
      if (closeCondition) {
        if (closeAll) {
          closeAllFunction();
        } else if (isOpenCondition?.call() == true) {
          closeSingleFunction();
        }
      }
    }

    handleClose(closeSnackbar, closeAllSnackbars, closeCurrentSnackbar);
    handleClose(
      closeDialog,
      () => closeAllDialogs(id: id, result: result),
      () => closeOverlay(id: id, result: result),
      () => _isDialogRoute(_topRoute(id: id)),
    );
    handleClose(
      closeBottomSheet,
      () => closeAllBottomSheets(id: id, result: result),
      () => closeOverlay(id: id, result: result),
      () => _isBottomSheetRoute(_topRoute(id: id)),
    );
  }

  /// **Navigation.pushReplacement()** shortcut .<br><br>
  ///
  /// Pop the current page and pushes a new `page` to the stack
  ///
  /// It has the advantage of not needing context,
  /// so you can call from your business logic
  ///
  /// You can set a custom [transition], define a Tween [curve],
  /// and a transition [duration].
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// Just like native routing in Flutter, you can push a route
  /// as a [fullscreenDialog],
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// If you want the same behavior of ios that pops a route when the user drag,
  /// you can set [popGesture] to true
  ///
  /// If you're using the [BindingsInterface] api, you must define it here
  ///
  /// By default, GetX will prevent you from push a route that you already in,
  /// if you want to push anyway, set [preventDuplicates] to false
  ///
  /// For fully custom transition animations, pass a [customTransition];
  /// it takes precedence over [transition].
  Future<T?>? off<T>(
    Widget Function() page, {
    bool? opaque,
    Transition? transition,
    Curve? curve,
    bool? popGesture,
    String? id,
    String? routeName,
    Object? arguments,
    List<BindingsInterface> bindings = const [],
    bool fullscreenDialog = false,
    bool preventDuplicates = true,
    Duration? duration,
    double Function(BuildContext context)? gestureWidth,
    CustomTransition? customTransition,
  }) {
    routeName ??= "/${page.runtimeType.toString()}";
    routeName = _cleanRouteName(routeName);
    if (preventDuplicates && routeName == currentRoute) {
      return null;
    }
    return searchDelegate(id).off(
      page,
      opaque: opaque ?? true,
      transition: transition,
      curve: curve,
      popGesture: popGesture,
      id: id,
      routeName: routeName,
      arguments: arguments,
      bindings: bindings,
      fullscreenDialog: fullscreenDialog,
      preventDuplicates: preventDuplicates,
      duration: duration,
      gestureWidth: gestureWidth,
      customTransition: customTransition,
    );
  }

  Future<T?> offUntil<T>(
    Widget Function() page,
    bool Function(GetPage) predicate, [
    Object? arguments,
    String? id,
  ]) {
    return searchDelegate(id).offUntil(page, predicate, arguments);
  }

  ///
  /// Push a `page` and pop several pages in the stack
  /// until [predicate] returns true. [predicate] is optional
  ///
  /// It has the advantage of not needing context,
  /// so you can call from your business logic
  ///
  /// You can set a custom [transition], a [curve] and a transition [duration].
  ///
  /// You can send any type of value to the other route in the [arguments].
  ///
  /// Just like native routing in Flutter, you can push a route
  /// as a [fullscreenDialog],
  ///
  /// [predicate] can be used like this:
  /// `Get.until((route) => Get.currentRoute == '/home')`so when you get to home page,
  /// or also like
  /// `Get.until((route) => !Get.isDialogOpen())`, to make sure the dialog
  /// is closed
  ///
  /// [id] is for when you are using nested navigation,
  /// as explained in documentation
  ///
  /// If you want the same behavior of ios that pops a route when the user drag,
  /// you can set [popGesture] to true
  ///
  /// If you're using the [BindingsInterface] api, you must define it here
  ///
  /// By default, GetX will prevent you from push a route that you already in,
  /// if you want to push anyway, set [preventDuplicates] to false
  ///
  /// For fully custom transition animations, pass a [customTransition];
  /// it takes precedence over [transition].
  Future<T?>? offAll<T>(
    Widget Function() page, {
    bool Function(GetPage<dynamic>)? predicate,
    bool? opaque,
    bool? popGesture,
    String? id,
    String? routeName,
    Object? arguments,
    List<BindingsInterface> bindings = const [],
    bool fullscreenDialog = false,
    Transition? transition,
    Curve? curve,
    Duration? duration,
    double Function(BuildContext context)? gestureWidth,
    CustomTransition? customTransition,
  }) {
    routeName ??= "/${page.runtimeType.toString()}";
    routeName = _cleanRouteName(routeName);
    return searchDelegate(id).offAll<T>(
      page,
      predicate: predicate,
      opaque: opaque ?? true,
      popGesture: popGesture,
      id: id,
      //  routeName routeName,
      arguments: arguments,
      bindings: bindings,
      fullscreenDialog: fullscreenDialog,
      transition: transition,
      curve: curve,
      duration: duration,
      gestureWidth: gestureWidth,
      customTransition: customTransition,
    );
  }

  /// Takes a route [name] String generated by [to], [off], [offAll]
  /// (and similar context navigation methods), cleans the extra chars and
  /// accommodates the format.
  String _cleanRouteName(String name) {
    name = name.replaceAll('() => ', '');

    /// uncomment for URL styling.
    // name = name.paramCase!;
    if (!name.startsWith('/')) {
      name = '/$name';
    }
    return Uri.tryParse(name)?.toString() ?? name;
  }

  Future<void> updateLocale(Locale l) async {
    Get.locale = l;
    // Record that the locale was chosen explicitly so that subsequent
    // device locale changes never clobber the user's selection, even when
    // the chosen locale matches the locale last auto-applied from the device.
    rootController.localeSetExplicitly = true;
    await forceAppUpdate();
  }

  /// As a rule, Flutter knows which widget to update,
  /// so this command is rarely needed. We can mention situations
  /// where you use const so that widgets are not updated with setState,
  /// but you want it to be forcefully updated when an event like
  /// language change happens. using context to make the widget dirty
  /// for performRebuild() is a viable solution.
  /// However, in situations where this is not possible, or at least,
  /// is not desired by the developer, the only solution for updating
  /// widgets that Flutter does not want to update is to use reassemble
  /// to forcibly rebuild all widgets. Attention: calling this function will
  /// reconstruct the application from the sketch, use this with caution.
  /// Your entire application will be rebuilt, and touch events will not
  /// work until the end of rendering.
  Future<void> forceAppUpdate() async {
    await engine.performReassemble();
  }

  void appUpdate() => rootController.update();

  void changeTheme(ThemeData theme) {
    rootController.setTheme(theme);
  }

  void changeThemeMode(ThemeMode themeMode) {
    rootController.setThemeMode(themeMode);
  }

  GlobalKey<NavigatorState>? addKey(GlobalKey<NavigatorState> newKey) {
    return rootController.addKey(newKey);
  }

  GetDelegate? nestedKey(String? key) {
    return rootController.nestedKey(key);
  }

  GetDelegate searchDelegate(String? k) {
    if (k != null) {
      if (!keys.containsKey(k)) {
        throw RouteNotFoundException('Route id ($k) not found');
      }
      return keys[k]!;
    }

    final currentContext = context;
    if (currentContext != null) {
      try {
        final router = Router.of(currentContext);
        if (router.routerDelegate is GetDelegate) {
          return router.routerDelegate as GetDelegate;
        }
      } catch (_) {}
    }

    return Get.rootController.rootDelegate;
  }

  /// give name from current route
  String get currentRoute => routing.current;

  /// give name from previous route
  String get previousRoute => routing.previous;

  /// check if snackbar is open,
  /// or false if routing is not initialized yet
  bool get isSnackbarOpen =>
      _routingOrNull != null &&
      SnackbarController.isSnackbarBeingShown; //routing.isSnackbar;

  /// Closes all queued snackbars.
  ///
  /// When [withAnimations] is false, the currently visible snackbar is
  /// removed immediately, skipping its exit animation.
  void closeAllSnackbars({bool withAnimations = true}) {
    SnackbarController.cancelAllSnackbars(withAnimations: withAnimations);
  }

  /// Closes the currently visible snackbar, if any.
  ///
  /// When [withAnimations] is false, the snackbar is removed immediately,
  /// skipping its exit animation.
  Future<void> closeCurrentSnackbar({bool withAnimations = true}) async {
    await SnackbarController.closeCurrentSnackbar(
      withAnimations: withAnimations,
    );
  }

  /// check if dialog is open,
  /// or null if routing is not initialized yet
  bool? get isDialogOpen => _routingOrNull?.isDialog;

  /// check if bottomsheet is open,
  /// or null if routing is not initialized yet
  bool? get isBottomSheetOpen => _routingOrNull?.isBottomSheet;

  /// check a raw current route
  Route<dynamic>? get rawRoute => routing.route;

  /// check if default opaque route is enable
  bool get isOpaqueRouteDefault => defaultOpaqueRoute;

  /// give access to currentContext
  BuildContext? get context => key.currentContext;

  /// give access to current Overlay Context
  BuildContext? get overlayContext {
    BuildContext? overlay;
    key.currentState?.overlay?.context.visitChildElements((element) {
      overlay = element;
    });
    return overlay;
  }

  /// give access to Theme.of(context)
  ThemeData get theme {
    var theme = ThemeData.fallback();
    if (context != null) {
      theme = Theme.of(context!);
    }
    return theme;
  }

  /// The current null safe [WidgetsBinding]
  WidgetsBinding get engine {
    return WidgetsFlutterBinding.ensureInitialized();
  }

  /// The window to which this binding is bound.
  ui.PlatformDispatcher get window => engine.platformDispatcher;

  Locale? get deviceLocale => window.locale;

  GlobalKey<NavigatorState> get key => rootController.key;

  Map<String, GetDelegate> get keys => rootController.keys;

  GetRootState get rootController => GetRootState.controller;

  ConfigData get _getxController => GetRootState.controller.config;

  bool? get defaultPopGesture => _getxController.defaultPopGesture;
  bool get defaultOpaqueRoute => _getxController.defaultOpaqueRoute;

  Transition? get defaultTransition => _getxController.defaultTransition;

  /// The transition duration applied to routes that don't set their own:
  /// the `transitionDuration` given to `GetMaterialApp`/`GetCupertinoApp`,
  /// or 300 milliseconds when none was provided.
  Duration get defaultTransitionDuration {
    return _getxController.transitionDuration ??
        _getxController.defaultTransitionDuration;
  }

  Curve get defaultTransitionCurve => _getxController.defaultTransitionCurve;

  Curve get defaultDialogTransitionCurve {
    return _getxController.defaultDialogTransitionCurve;
  }

  Duration get defaultDialogTransitionDuration {
    return _getxController.defaultDialogTransitionDuration;
  }

  Routing get routing => _getxController.routing;

  /// [routing] when the GetX widget tree is initialized, or `null` before
  /// that (accessing [routing] earlier would throw).
  Routing? get _routingOrNull => GetRoot.treeInitialized ? routing : null;

  bool get _shouldUseMock => GetTestMode.active && !GetRoot.treeInitialized;

  /// give current arguments
  dynamic get arguments {
    return args();
  }

  T args<T>() {
    if (_shouldUseMock) {
      return GetTestMode.arguments as T;
    }
    // Dialogs and bottom sheets are pushed imperatively on the navigator
    // and never enter the delegate's page stack, so arguments given to
    // `Get.dialog`/`Get.bottomSheet` live only in the overlay route's
    // settings. While such an overlay is topmost, honor its arguments;
    // an overlay opened without arguments keeps exposing the underlying
    // page's arguments, and closing the overlay restores them.
    final overlayRoute = _routingOrNull?.route;
    if (overlayRoute != null &&
        (_isDialogRoute(overlayRoute) || _isBottomSheetRoute(overlayRoute)) &&
        overlayRoute.isCurrent &&
        overlayRoute.settings.arguments != null) {
      return overlayRoute.settings.arguments as T;
    }
    return rootController.rootDelegate.arguments<T>();
  }

  Map<String, String?> get parameters {
    if (_shouldUseMock) {
      return GetTestMode.parameters;
    }

    return rootController.rootDelegate.parameters;
  }

  /// Casts the stored router delegate to a desired type
  TDelegate? delegate<TDelegate extends RouterDelegate<TPage>, TPage>() =>
      _getxController.routerDelegate as TDelegate?;
}

extension OverlayExt on GetInterface {
  /// Shows a translucent barrier with a [loadingWidget] on top of the
  /// current page while [asyncFunction] runs, then returns its result.
  ///
  /// The barrier and the loading widget are always removed when
  /// [asyncFunction] completes, whether it returns a value or throws
  /// (any thrown object, not only [Exception]s); errors are rethrown
  /// to the caller.
  Future<T> showOverlay<T>({
    required Future<T> Function() asyncFunction,
    Color opacityColor = Colors.black,
    Widget? loadingWidget,
    double opacity = .5,
  }) async {
    final navigatorState = Navigator.of(
      Get.overlayContext!,
      rootNavigator: false,
    );
    final overlayState = navigatorState.overlay!;

    final overlayEntryOpacity = OverlayEntry(
      builder: (context) {
        return Opacity(
          opacity: opacity,
          child: Container(color: opacityColor),
        );
      },
    );
    final overlayEntryLoader = OverlayEntry(
      builder: (context) {
        return loadingWidget ??
            const Center(
              child: SizedBox(height: 90, width: 90, child: Text('Loading...')),
            );
      },
    );
    overlayState.insert(overlayEntryOpacity);
    overlayState.insert(overlayEntryLoader);

    final T data;

    try {
      data = await asyncFunction();
    } finally {
      overlayEntryLoader.remove();
      overlayEntryOpacity.remove();
    }

    return data;
  }
}
