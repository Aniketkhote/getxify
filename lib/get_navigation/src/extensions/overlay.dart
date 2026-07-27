part of '../extension_navigation.dart';

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
