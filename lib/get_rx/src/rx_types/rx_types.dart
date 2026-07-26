library;

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../../../get_state_manager/src/rx_flutter/rx_notifier.dart';
import '../rx_typedefs/rx_typedefs.dart';

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
