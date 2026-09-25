import 'dart:developer' as developer;
import 'get_main.dart';

/// Signature for a custom log writer function callback.
typedef LogWriterCallback = void Function(String text, {bool isError});

/// The default log writer callback used by GetX.
///
/// Logs the message to the developer console under the name 'GETX' if [isError] is true
/// or if [Get.isLogEnable] is enabled.
void defaultLogWriterCallback(String value, {bool isError = false}) {
  if (isError || Get.isLogEnable) developer.log(value, name: 'GETX');
}
