library;

import 'rx_core/rx_impl.dart';

export 'rx_core/rx_impl.dart';
export 'rx_core/rx_interface.dart';
export 'rx_core/rx_num.dart';
export 'rx_core/rx_string.dart';
export 'rx_iterables/rx_list.dart';
export 'rx_iterables/rx_map.dart';
export 'rx_iterables/rx_set.dart';

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
