part of '../extension_navigation.dart';

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
