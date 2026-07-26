part of '../rx_types.dart';

/// Extension on [Rx<num>] providing basic operators.
extension RxNumExt<T extends num> on Rx<T> {
  /// Addition operator.
  num operator +(num other) {
    value = (value + other) as T;
    return value;
  }

  /// Subtraction operator.
  num operator -(num other) {
    value = (value - other) as T;
    return value;
  }

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
  num? operator +(num other) {
    if (value != null) {
      value = (value! + other) as T;
      return value;
    }
    return null;
  }

  /// Subtraction operator.
  num? operator -(num other) {
    if (value != null) {
      value = (value! - other) as T;
      return value;
    }
    return null;
  }

  /// Multiplication operator.
  num? operator *(num other) => value != null ? value! * other : null;

  /// Modulo operator.
  num? operator %(num other) => value != null ? value! % other : null;

  /// Division operator.
  double? operator /(num other) => value != null ? value! / other : null;

  /// Truncating division operator.
  int? operator ~/(num other) => value != null ? value! ~/ other : null;

  /// Negate operator.
  num? operator -() => value != null ? -value! : null;

  /// Relational less than operator.
  bool? operator <(num other) => value != null ? value! < other : null;

  /// Relational less than or equal operator.
  bool? operator <=(num other) => value != null ? value! <= other : null;

  /// Relational greater than operator.
  bool? operator >(num other) => value != null ? value! > other : null;

  /// Relational greater than or equal operator.
  bool? operator >=(num other) => value != null ? value! >= other : null;
}

/// Extension on [Rx<double>] providing basic double operators.
extension RxDoubleExt on Rx<double> {
  /// Addition operator.
  Rx<double> operator +(num other) {
    value = value + other;
    return this;
  }

  /// Subtraction operator.
  Rx<double> operator -(num other) {
    value = value - other;
    return this;
  }

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

/// Extension on [Rx<double?>] providing basic double operators.
extension RxnDoubleExt on Rx<double?> {
  /// Addition operator.
  Rx<double?>? operator +(num other) {
    if (value != null) {
      value = value! + other;
      return this;
    }
    return null;
  }

  /// Subtraction operator.
  Rx<double?>? operator -(num other) {
    if (value != null) {
      value = value! - other;
      return this;
    }
    return null;
  }

  /// Multiplication operator.
  double? operator *(num other) => value != null ? value! * other : null;

  /// Modulo operator.
  double? operator %(num other) => value != null ? value! % other : null;

  /// Division operator.
  double? operator /(num other) => value != null ? value! / other : null;

  /// Truncating division operator.
  int? operator ~/(num other) => value != null ? value! ~/ other : null;

  /// Negate operator.
  double? operator -() => value != null ? -value! : null;
}

/// Extension on [Rx<int>] providing basic integer operators.
extension RxIntExt on Rx<int> {
  /// Addition operator.
  Rx<int> operator +(int other) {
    value = value + other;
    return this;
  }

  /// Subtraction operator.
  Rx<int> operator -(int other) {
    value = value - other;
    return this;
  }

  /// Division operator.
  double operator /(num other) => value / other;

  /// Unary negate operator.
  int operator -() => -value;
}

/// Extension on [Rx<int?>] providing basic integer operators.
extension RxnIntExt on Rx<int?> {
  /// Addition operator.
  Rx<int?> operator +(int other) {
    if (value != null) {
      value = value! + other;
    }
    return this;
  }

  /// Subtraction operator.
  Rx<int?> operator -(int other) {
    if (value != null) {
      value = value! - other;
    }
    return this;
  }

  /// Division operator.
  double? operator /(num other) => value != null ? value! / other : null;

  /// Unary negate operator.
  int? operator -() => value != null ? -value! : null;
}
