import '../rx_types.dart';
import 'rx_impl.dart';

/// Extension on [Rx<String>] providing standard operators.
extension RxStringExt on Rx<String> {
  /// Concatenation operator.
  String operator +(String val) => value + val;
}

/// Extension on [Rx<String?>] providing standard operators.
extension RxnStringExt on Rx<String?> {
  /// Concatenation operator.
  String operator +(String val) => (value ?? '') + val;
}
