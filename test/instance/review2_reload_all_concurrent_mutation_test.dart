// running each instance's onDelete/onClose lifecycle. An onClose that
// mutates the registry (Get.delete<Other>(), Get.put, ...) must not abort
// the iteration with a ConcurrentModificationError.
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

class OtherController extends GetxController {
  int closes = 0;

  @override
  void onClose() {
    closes++;
    super.onClose();
  }
}

class LateController extends GetxController {}

class MutatingController extends GetxController {
  int closes = 0;

  @override
  void onClose() {
    closes++;
    // Mutates the registry while reloadAll is iterating it.
    Get.delete<OtherController>(force: true);
    super.onClose();
  }
}

class PuttingController extends GetxController {
  int closes = 0;

  @override
  void onClose() {
    closes++;
    // Grows the registry while reloadAll is iterating it.
    Get.put(LateController());
    super.onClose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    Get.reset();
  });

  test('reloadAll survives an onClose that deletes another instance', () {
    // Insertion order matters: the mutating controller must be visited
    // before the one its onClose deletes.
    final mutating = Get.put(MutatingController());
    final other = Get.put(OtherController());

    expect(() => Get.reloadAll(), returnsNormally);

    expect(mutating.closes, 1);
    // OtherController was force-deleted mid-iteration by the onClose
    // callback: it must receive exactly one onClose (from the delete) and
    // must not be visited again by reloadAll.
    expect(other.closes, 1);
    expect(Get.isRegistered<OtherController>(), false);

    // The mutating controller itself was reloaded (its registration
    // survived and stays resolvable; `put` re-yields the same instance).
    expect(Get.isRegistered<MutatingController>(), true);
    expect(() => Get.find<MutatingController>(), returnsNormally);
  });

  test('reloadAll survives an onClose that registers a new instance', () {
    final putting = Get.put(PuttingController());

    expect(() => Get.reloadAll(), returnsNormally);

    expect(putting.closes, 1);
    // The instance registered mid-iteration stays registered untouched.
    expect(Get.isRegistered<LateController>(), true);
  });
}
