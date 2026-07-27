import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

class LifecycleService extends GetxService {
  int inits = 0;
  int closes = 0;

  @override
  void onInit() {
    inits++;
    super.onInit();
  }

  @override
  void onClose() {
    closes++;
    super.onClose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // `lateRemove` chain (markAsDirty + re-registration) must be disposed by
  // the pending non-force delete. Before the fix, the GetxServiceMixin
  // guard returned early in the lateRemove branch, leaking the stale
  // service (onClose never ran) and leaving `lateRemove` set forever, so
  // the live registration became undeletable without force:true.
  test('stale superseded service in lateRemove is disposed by a non-force '
      'delete and the live registration stays deletable', () async {
    Get.put(LifecycleService());
    final first = Get.find<LifecycleService>();
    expect(first.inits, 1);

    // Simulates `reportRouteWillDispose` on pop: markAsDirty only guards
    // on `!permanent`, so a non-permanent service is marked dirty.
    Get.markAsDirty<LifecycleService>();

    // Simulates the re-pushed route registering the key again; the dirty
    // factory is superseded and chained in `lateRemove`.
    Get.put(LifecycleService());
    final second = Get.find<LifecycleService>();
    expect(identical(first, second), false);
    expect(second.inits, 1);

    // The old route disposing must peel off the STALE service even though
    // it is a GetxService: it has already been replaced and is garbage.
    final removed = Get.delete<LifecycleService>();
    expect(
      removed,
      false,
      reason: 'the key must stay registered for the live service',
    );
    expect(
      first.closes,
      1,
      reason: 'the stale superseded service must receive onClose',
    );
    expect(second.closes, 0, reason: 'the live service must not be touched');
    expect(Get.isRegistered<LifecycleService>(), true);
    expect(identical(Get.find<LifecycleService>(), second), true);

    // The lateRemove chain is now clear, so the live service is protected
    // by the normal service guard again (non-force delete is refused)...
    final casualDelete = Get.delete<LifecycleService>();
    expect(
      casualDelete,
      false,
      reason: 'a live GetxService must survive a casual delete',
    );
    expect(second.closes, 0);
    expect(Get.isRegistered<LifecycleService>(), true);

    // ...but it is still deletable with force, proving the chain did not
    // freeze the key.
    final forcedDelete = Get.delete<LifecycleService>(force: true);
    expect(forcedDelete, true);
    expect(second.closes, 1);
    expect(Get.isRegistered<LifecycleService>(), false);

    Get.reset();
  });

  // Two supersessions in flight: each pending disposal peels the oldest
  // stale service; the live one keeps its guard.
  test('nested stale services in lateRemove are peeled oldest-first', () async {
    Get.put(LifecycleService());
    final first = Get.find<LifecycleService>();

    Get.markAsDirty<LifecycleService>();
    Get.put(LifecycleService());
    final second = Get.find<LifecycleService>();

    Get.markAsDirty<LifecycleService>();
    Get.put(LifecycleService());
    final third = Get.find<LifecycleService>();

    expect(Get.delete<LifecycleService>(), false);
    expect(first.closes, 1);
    expect(second.closes, 0);
    expect(third.closes, 0);

    expect(Get.delete<LifecycleService>(), false);
    expect(second.closes, 1);
    expect(third.closes, 0);

    // Chain is clear; the live service is guarded again.
    expect(Get.delete<LifecycleService>(), false);
    expect(third.closes, 0);
    expect(identical(Get.find<LifecycleService>(), third), true);

    expect(Get.delete<LifecycleService>(force: true), true);
    expect(third.closes, 1);
    expect(Get.isRegistered<LifecycleService>(), false);

    Get.reset();
  });
}
