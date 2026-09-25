library;

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../../state_manager/src/rx_flutter/rx_notifier.dart';

part 'rx_core/rx_impl.dart';
part 'rx_core/rx_interface.dart';
part 'rx_core/rx_num.dart';
part 'rx_core/rx_string.dart';
part 'rx_iterables/rx_list.dart';
part 'rx_iterables/rx_map.dart';
part 'rx_iterables/rx_set.dart';

typedef RxString = Rx<String>;
typedef RxnString = Rx<String?>;
typedef RxInt = Rx<int>;
typedef RxnInt = Rx<int?>;
typedef RxDouble = Rx<double>;
typedef RxnDouble = Rx<double?>;
typedef RxBool = Rx<bool>;
typedef RxnBool = Rx<bool?>;
typedef RxNum = Rx<num>;
typedef RxnNum = Rx<num?>;

/// Evaluates a condition for extension methods with consistent false-by-default behavior.
/// Used by list, map, and set extensions for conditional operations.
/// Accepts null, bool, or bool Function() and returns a consistent boolean result.
bool evaluateCondition(Object? condition) {
  if (condition == null) return false;
  if (condition is bool) return condition;
  if (condition is bool Function()) return condition();
  return false;
}
