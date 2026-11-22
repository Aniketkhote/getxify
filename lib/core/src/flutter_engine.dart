import 'package:flutter/widgets.dart';

/// Helper class to interact with the Flutter framework's bindings.
abstract final class Engine {
  /// Returns the current [WidgetsBinding] instance, ensuring it is initialized first.
  static WidgetsBinding get instance =>
      WidgetsFlutterBinding.ensureInitialized();
}
