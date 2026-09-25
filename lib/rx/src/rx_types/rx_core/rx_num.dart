import '../rx_types.dart';
import 'rx_impl.dart';

/// Helper functions for common numeric operations to reduce code duplication.

/// Performs addition on a non-nullable Rx value.
T _rxAdd<T extends num>(Rx<T> rx, num other) {
  rx.value = (rx.value + other) as T;
  return rx.value;
}

/// Performs subtraction on a non-nullable Rx value.
T _rxSub<T extends num>(Rx<T> rx, num other) {
  rx.value = (rx.value - other) as T;
  return rx.value;
}

/// Performs addition on a non-nullable Rx value and returns the Rx object for chaining.
Rx<T> _rxAddRx<T extends num>(Rx<T> rx, num other) {
  rx.value = (rx.value + other) as T;
  return rx;
}

/// Performs subtraction on a non-nullable Rx value and returns the Rx object for chaining.
Rx<T> _rxSubRx<T extends num>(Rx<T> rx, num other) {
  rx.value = (rx.value - other) as T;
  return rx;
}

/// Performs addition on a nullable Rx value with null-safety.
T? _rxnAdd<T extends num>(Rx<T?> rx, num other) {
  if (rx.value != null) {
    rx.value = (rx.value! + other) as T?;
    return rx.value;
  }
  return null;
}

/// Performs subtraction on a nullable Rx value with null-safety.
T? _rxnSub<T extends num>(Rx<T?> rx, num other) {
  if (rx.value != null) {
    rx.value = (rx.value! - other) as T?;
    return rx.value;
  }
  return null;
}

/// Performs addition on a nullable Rx value and returns the Rx object for chaining.
Rx<T?>? _rxnAddRx<T extends num>(Rx<T?> rx, num other) {
  if (rx.value != null) {
    rx.value = (rx.value! + other) as T?;
    return rx;
  }
  return null;
}

/// Performs subtraction on a nullable Rx value and returns the Rx object for chaining.
Rx<T?>? _rxnSubRx<T extends num>(Rx<T?> rx, num other) {
  if (rx.value != null) {
    rx.value = (rx.value! - other) as T?;
    return rx;
  }
  return null;
}

/// Performs multiplication on a nullable Rx value with null-safety.
num? _rxnMul<T extends num>(Rx<T?> rx, num other) =>
    rx.value != null ? rx.value! * other : null;

/// Performs modulo on a nullable Rx value with null-safety.
num? _rxnMod<T extends num>(Rx<T?> rx, num other) =>
    rx.value != null ? rx.value! % other : null;

/// Performs division on a nullable Rx value with null-safety.
double? _rxnDiv<T extends num>(Rx<T?> rx, num other) =>
    rx.value != null ? rx.value! / other : null;

/// Performs truncating division on a nullable Rx value with null-safety.
int? _rxnTruncDiv<T extends num>(Rx<T?> rx, num other) =>
    rx.value != null ? rx.value! ~/ other : null;

/// Performs negation on a nullable Rx value with null-safety.
num? _rxnNegate<T extends num>(Rx<T?> rx) =>
    rx.value != null ? -rx.value! : null;

/// Performs multiplication on a nullable Rx double value with null-safety.
double? _rxnMulDouble(Rx<double?> rx, num other) =>
    rx.value != null ? rx.value! * other : null;

/// Performs modulo on a nullable Rx double value with null-safety.
double? _rxnModDouble(Rx<double?> rx, num other) =>
    rx.value != null ? rx.value! % other : null;

/// Performs negation on a nullable Rx double value with null-safety.
double? _rxnNegateDouble(Rx<double?> rx) =>
    rx.value != null ? -rx.value! : null;

/// Performs negation on a nullable Rx int value with null-safety.
int? _rxnNegateInt(Rx<int?> rx) => rx.value != null ? -rx.value! : null;

/// Performs less than comparison on a nullable Rx value with null-safety.
bool? _rxnLessThan<T extends num>(Rx<T?> rx, num other) =>
    rx.value != null ? rx.value! < other : null;

/// Performs less than or equal comparison on a nullable Rx value with null-safety.
bool? _rxnLessThanOrEqual<T extends num>(Rx<T?> rx, num other) =>
    rx.value != null ? rx.value! <= other : null;

/// Performs greater than comparison on a nullable Rx value with null-safety.
bool? _rxnGreaterThan<T extends num>(Rx<T?> rx, num other) =>
    rx.value != null ? rx.value! > other : null;

/// Performs greater than or equal comparison on a nullable Rx value with null-safety.
bool? _rxnGreaterThanOrEqual<T extends num>(Rx<T?> rx, num other) =>
    rx.value != null ? rx.value! >= other : null;

/// Extension on [Rx<num>] providing basic operators.
extension RxNumExt<T extends num> on Rx<T> {
  /// Addition operator.
  num operator +(num other) => _rxAdd(this, other);

  /// Subtraction operator.
  num operator -(num other) => _rxSub(this, other);

  /// Multiplication operator.
  num operator *(num other) => value * other;

  /// Modulo operator.
  num operator %(num other) => value % other;

  /// Division operator.
  double operator /(num other) => value / other;

  /// Truncating division operator.
  int operator ~/(num other) => value ~/ other;

  /// Negate operator.
  num operator -() => -value;

  /// Relational less than operator.
  bool operator <(num other) => value < other;

  /// Relational less than or equal operator.
  bool operator <=(num other) => value <= other;

  /// Relational greater than operator.
  bool operator >(num other) => value > other;

  /// Relational greater than or equal operator.
  bool operator >=(num other) => value >= other;
}

/// Extension on [Rx<num?>] providing basic operators.
extension RxnNumExt<T extends num> on Rx<T?> {
  /// Addition operator.
  num? operator +(num other) => _rxnAdd(this, other);

  /// Subtraction operator.
  num? operator -(num other) => _rxnSub(this, other);

  /// Multiplication operator.
  num? operator *(num other) => _rxnMul(this, other);

  /// Modulo operator.
  num? operator %(num other) => _rxnMod(this, other);

  /// Division operator.
  double? operator /(num other) => _rxnDiv(this, other);

  /// Truncating division operator.
  int? operator ~/(num other) => _rxnTruncDiv(this, other);

  /// Negate operator.
  num? operator -() => _rxnNegate(this);

  /// Relational less than operator.
  bool? operator <(num other) => _rxnLessThan(this, other);

  /// Relational less than or equal operator.
  bool? operator <=(num other) => _rxnLessThanOrEqual(this, other);

  /// Relational greater than operator.
  bool? operator >(num other) => _rxnGreaterThan(this, other);

  /// Relational greater than or equal operator.
  bool? operator >=(num other) => _rxnGreaterThanOrEqual(this, other);
}

/// Extension on [Rx<double>] providing basic double operators with chaining support.
extension RxDoubleExt on Rx<double> {
  /// Addition operator that returns [Rx<double>] for chaining.
  Rx<double> operator +(num other) => _rxAddRx(this, other);

  /// Subtraction operator that returns [Rx<double>] for chaining.
  Rx<double> operator -(num other) => _rxSubRx(this, other);

  /// Multiplication operator.
  double operator *(num other) => value * other;

  /// Modulo operator.
  double operator %(num other) => value % other;

  /// Division operator.
  double operator /(num other) => value / other;

  /// Truncating division operator.
  int operator ~/(num other) => value ~/ other;

  /// Negate operator.
  double operator -() => -value;
}

/// Extension on [Rx<double?>] providing basic double operators with chaining support.
extension RxnDoubleExt on Rx<double?> {
  /// Addition operator that returns [Rx<double?>] for chaining when value is not null.
  Rx<double?>? operator +(num other) => _rxnAddRx(this, other);

  /// Subtraction operator that returns [Rx<double?>] for chaining when value is not null.
  Rx<double?>? operator -(num other) => _rxnSubRx(this, other);

  /// Multiplication operator.
  double? operator *(num other) => _rxnMulDouble(this, other);

  /// Modulo operator.
  double? operator %(num other) => _rxnModDouble(this, other);

  /// Division operator.
  double? operator /(num other) => _rxnDiv(this, other);

  /// Truncating division operator.
  int? operator ~/(num other) => _rxnTruncDiv(this, other);

  /// Negate operator.
  double? operator -() => _rxnNegateDouble(this);
}

/// Extension on [Rx<int>] providing basic integer operators with chaining support.
extension RxIntExt on Rx<int> {
  /// Addition operator that returns [Rx<int>] for chaining.
  Rx<int> operator +(int other) => _rxAddRx(this, other);

  /// Subtraction operator that returns [Rx<int>] for chaining.
  Rx<int> operator -(int other) => _rxSubRx(this, other);

  /// Division operator.
  double operator /(num other) => value / other;

  /// Unary negate operator.
  int operator -() => -value;
}

/// Extension on [Rx<int?>] providing basic integer operators with chaining support.
extension RxnIntExt on Rx<int?> {
  /// Addition operator that returns [Rx<int?>] for chaining when value is not null.
  Rx<int?> operator +(int other) => _rxnAddRx(this, other) ?? this;

  /// Subtraction operator that returns [Rx<int?>] for chaining when value is not null.
  Rx<int?> operator -(int other) => _rxnSubRx(this, other) ?? this;

  /// Division operator.
  double? operator /(num other) => _rxnDiv(this, other);

  /// Unary negate operator.
  int? operator -() => _rxnNegateInt(this);
}
