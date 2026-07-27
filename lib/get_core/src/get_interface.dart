import 'package:flutter/foundation.dart';

import 'log.dart';

/// The base class/interface that allows other packages (like navigation,
/// state management, etc.) to merge their capabilities into the global `Get`
/// instance through Dart extensions.
abstract class GetInterface {
  /// Whether logging is enabled. Defaults to `kDebugMode`.
  bool isLogEnable = kDebugMode;

  /// Custom callback function used to print log outputs.
  LogWriterCallback log = defaultLogWriterCallback;

  /// Prints structured information to the console if [isLogEnable] is true.
  ///
  /// - [info] The message text to print.
  /// - [title] A prefix tag/title for the log entry.
  void printInfo({String? info, String? title}) {
    log('$title $info', isError: false);
  }
}
