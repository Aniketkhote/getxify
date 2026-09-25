import '../getxify.dart';

/// Extension on [GetInterface] providing utilities to reset application state.
extension GetResetExt on GetInterface {
  /// Resets all registered instances, translations, and optionally clears route bindings.
  ///
  /// Typically used at the end or tearDown of unit tests to ensure a clean state
  /// for subsequent test runs.
  ///
  /// - [clearRouteBindings] If true, clears the internal route key registry.
  void reset({bool clearRouteBindings = true}) {
    Get.resetInstance(clearRouteBindings: clearRouteBindings);
    Get.clearTranslations();
  }
}
