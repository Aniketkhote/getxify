import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

class _TestNotifierController extends GetxController {
  void triggerGroup(Object id) {
    notifyGroupChildren(id);
  }

  void triggerGroupLegacy(Object id) {
    // ignore: deprecated_member_use_from_same_package
    notifyGroupChildrens(id);
  }
}

void main() {
  test('notifyGroupChildren and legacy alias execute without error', () {
    final controller = _TestNotifierController();
    expect(() => controller.triggerGroup('my-group'), returnsNormally);
    expect(() => controller.triggerGroupLegacy('my-group'), returnsNormally);
  });
}
