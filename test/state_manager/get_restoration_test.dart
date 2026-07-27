import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

class RestorableCounterController extends GetxController
    with GetRestorationMixin {
  @override
  String? get restorationId => 'counter_controller';

  int get count => restore('count', 10);
  set count(int val) => persist('count', val);
}

void main() {
  test(
    'GetRestorationMixin persists and restores state using RestorationBucket',
    () {
      final controller = RestorableCounterController();

      expect(controller.count, 10);

      controller.count = 42;
      expect(controller.count, 42);

      final mockBucket = RestorationBucket.empty(
        restorationId: 'test_root',
        debugOwner: 'test',
      );

      controller.initRestoration(mockBucket);
      expect(controller.restorationBucket, isNotNull);
      expect(controller.count, 42);

      controller.onClose();
      expect(controller.restorationBucket, isNull);
    },
  );
}
