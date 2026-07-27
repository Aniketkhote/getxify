// ignore_for_file: avoid_classes_with_only_static_members

import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

import 'util/matcher.dart' as m;

class Mock {
  static Future<String> test() async {
    await Future.delayed(Duration.zero);
    return 'test';
  }
}

abstract class MyController with GetLifeCycleMixin {}

class DisposableController extends MyController {}

// ignore: one_member_abstracts
abstract class Service {
  String post();
}

class Api implements Service {
  @override
  String post() {
    return 'test';
  }
}

class ParentController with GetLifeCycleMixin {
  int init = 0;
  int close = 0;
  int count = 0;

  void increment() => count++;

  @override
  void onInit() {
    init++;
    super.onInit();
  }

  @override
  void onClose() {
    close++;
    super.onClose();
  }
}

class ChildController extends ParentController {}

class ParentService extends GetxService {
  int close = 0;

  @override
  void onClose() {
    close++;
    super.onClose();
  }
}

class ChildService extends ParentService {}

class ReloadController with GetLifeCycleMixin {
  int init = 0;
  int close = 0;
  int count = 0;

  void increment() => count++;

  @override
  void onInit() {
    init++;
    super.onInit();
  }

  @override
  void onClose() {
    close++;
    super.onClose();
  }
}

class ReloadService extends GetxService {
  int close = 0;

  @override
  void onClose() {
    close++;
    super.onClose();
  }
}

class KeyController with GetLifeCycleMixin {
  int init = 0;

  @override
  void onInit() {
    init++;
    super.onInit();
  }
}

class AsyncController with GetLifeCycleMixin {
  int init = 0;
  int close = 0;
  bool ready = false;

  Future<void> setup() async {
    await Future<void>.delayed(Duration.zero);
    ready = true;
  }

  @override
  void onInit() {
    init++;
    super.onInit();
  }

  @override
  void onClose() {
    close++;
    super.onClose();
  }
}

class LifecycleController extends GetxController {
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
  test('Get.put test', () async {
    final instance = Get.put<Controller>(Controller());
    expect(instance, Get.find<Controller>());
    Get.reset();
  });

  test('Get start and delete called just one time', () async {
    Get
      ..put(Controller())
      ..put(Controller());

    final controller = Get.find<Controller>();
    expect(controller.init, 1);

    Get
      ..delete<Controller>()
      ..delete<Controller>();
    expect(controller.close, 1);
    Get.reset();
  });

  test('Get.put tag test', () async {
    final instance = Get.put<Controller>(Controller(), tag: 'one');
    final instance2 = Get.put<Controller>(Controller(), tag: 'two');
    expect(instance == instance2, false);
    expect(
      Get.find<Controller>(tag: 'one') == Get.find<Controller>(tag: 'two'),
      false,
    );
    expect(
      Get.find<Controller>(tag: 'one') == Get.find<Controller>(tag: 'one'),
      true,
    );
    expect(
      Get.find<Controller>(tag: 'two') == Get.find<Controller>(tag: 'two'),
      true,
    );
    Get.reset();
  });

  test('Get.lazyPut tag test', () async {
    Get.lazyPut<Controller>(() => Controller(), tag: 'one');
    Get.lazyPut<Controller>(() => Controller(), tag: 'two');

    expect(
      Get.find<Controller>(tag: 'one') == Get.find<Controller>(tag: 'two'),
      false,
    );
    expect(
      Get.find<Controller>(tag: 'one') == Get.find<Controller>(tag: 'one'),
      true,
    );
    expect(
      Get.find<Controller>(tag: 'two') == Get.find<Controller>(tag: 'two'),
      true,
    );
    Get.reset();
  });

  test('Get.lazyPut test', () async {
    final controller = Controller();
    Get.lazyPut<Controller>(() => controller);
    final ct1 = Get.find<Controller>();
    expect(ct1, controller);
    Get.reset();
  });

  test('Get.lazyPut fenix test', () async {
    Get.lazyPut<Controller>(() => Controller(), fenix: true);
    Get.find<Controller>().increment();

    expect(Get.find<Controller>().count, 1);
    Get.delete<Controller>();
    expect(Get.find<Controller>().count, 0);
    Get.reset();
  });

  test('Get.lazyPut without fenix', () async {
    Get.lazyPut<Controller>(() => Controller());
    Get.find<Controller>().increment();

    expect(Get.find<Controller>().count, 1);
    Get.delete<Controller>();
    expect(
      () => Get.find<Controller>(),
      throwsA(const m.TypeMatcher<Exception>()),
    );
    Get.reset();
  });

  test('Get.reloadInstance test', () async {
    Get.lazyPut<Controller>(() => Controller());
    var ct1 = Get.find<Controller>();
    ct1.increment();
    expect(ct1.count, 1);
    ct1 = Get.find<Controller>();
    expect(ct1.count, 1);
    Get.reload<Controller>();
    ct1 = Get.find<Controller>();
    expect(ct1.count, 0);
    Get.reset();
  });

  test('GetxService test', () async {
    Get.lazyPut<PermanentService>(() => PermanentService());
    var sv1 = Get.find<PermanentService>();
    var sv2 = Get.find<PermanentService>();
    expect(sv1, sv2);
    expect(Get.isRegistered<PermanentService>(), true);
    Get.delete<PermanentService>();
    expect(Get.isRegistered<PermanentService>(), true);
    Get.delete<PermanentService>(force: true);
    expect(Get.isRegistered<PermanentService>(), false);
    Get.reset();
  });

  test('Get.lazyPut with abstract class test', () async {
    final api = Api();
    Get.lazyPut<Service>(() => api);
    final ct1 = Get.find<Service>();
    expect(ct1, api);
    Get.reset();
  });

  test('Get.spawn with abstract class test', () async {
    Get.spawn<Service>(() => Api());
    final ct1 = Get.find<Service>();
    final ct2 = Get.find<Service>();
    expect(ct1 == ct2, false);
    Get.reset();
  });

  test('Get.putOrFind test', () async {
    final ct1 = Get.putOrFind<Controller>(() => Controller());
    expect(ct1.init, 1);
    expect(Get.isRegistered<Controller>(), true);

    final ct2 = Get.putOrFind<Controller>(() => Controller());
    expect(ct2, ct1);
    expect(ct2.init, 1);
    Get.reset();
  });

  group('test put, delete and check onInit execution', () {
    tearDownAll(Get.reset);

    test('Get.put test with init check', () async {
      final instance = Get.put(DisposableController());
      expect(instance, Get.find<DisposableController>());
      expect(instance.initialized, true);
    });

    test('Get.delete test with disposable controller', () async {
      Get.put(DisposableController());
      expect(Get.delete<DisposableController>(), true);
      expect(
        () => Get.find<DisposableController>(),
        throwsA(const m.TypeMatcher<Exception>()),
      );
    });

    test(
      'Get.put test after delete with disposable controller and init check',
      () async {
        final instance = Get.put<DisposableController>(DisposableController());
        expect(instance, Get.find<DisposableController>());
        expect(instance.initialized, true);
      },
    );
  });

  group('Get.replace test for replacing parent instance that is', () {
    tearDown(Get.reset);
    test('temporary', () async {
      Get.put(DisposableController());
      Get.replace<DisposableController>(Controller());
      final instance = Get.find<DisposableController>();
      expect(instance is Controller, isTrue);
      expect((instance as Controller).init, greaterThan(0));
    });

    test('permanent', () async {
      Get.put(DisposableController(), permanent: true);
      Get.replace<DisposableController>(Controller());
      final instance = Get.find<DisposableController>();
      expect(instance is Controller, isTrue);
      expect((instance as Controller).init, greaterThan(0));
    });

    test('tagged temporary', () async {
      const tag = 'tag';
      Get.put(DisposableController(), tag: tag);
      Get.replace<DisposableController>(Controller(), tag: tag);
      final instance = Get.find<DisposableController>(tag: tag);
      expect(instance is Controller, isTrue);
      expect((instance as Controller).init, greaterThan(0));
    });

    test('tagged permanent', () async {
      const tag = 'tag';
      Get.put(DisposableController(), permanent: true, tag: tag);
      Get.replace<DisposableController>(Controller(), tag: tag);
      final instance = Get.find<DisposableController>(tag: tag);
      expect(instance is Controller, isTrue);
      expect((instance as Controller).init, greaterThan(0));
    });

    test('a generic parent type', () async {
      const tag = 'tag';
      Get.put<MyController>(DisposableController(), permanent: true, tag: tag);
      Get.replace<MyController>(Controller(), tag: tag);
      final instance = Get.find<MyController>(tag: tag);
      expect(instance is Controller, isTrue);
      expect((instance as Controller).init, greaterThan(0));
    });
  });

  group('Get.lazyReplace replaces parent instance', () {
    tearDown(Get.reset);
    test('without fenix', () async {
      Get.put(DisposableController());
      Get.lazyReplace<DisposableController>(() => Controller());
      final instance = Get.find<DisposableController>();
      expect(instance, isA<Controller>());
      expect((instance as Controller).init, greaterThan(0));
    });

    test('with fenix', () async {
      Get.put(DisposableController());
      Get.lazyReplace<DisposableController>(() => Controller(), fenix: true);
      expect(Get.find<DisposableController>(), isA<Controller>());
      (Get.find<DisposableController>() as Controller).increment();

      expect((Get.find<DisposableController>() as Controller).count, 1);
      Get.delete<DisposableController>();
      expect((Get.find<DisposableController>() as Controller).count, 0);
    });

    test('with fenix when parent is permanent', () async {
      Get.put(DisposableController(), permanent: true);
      Get.lazyReplace<DisposableController>(() => Controller());
      final instance = Get.find<DisposableController>();
      expect(instance, isA<Controller>());
      (instance as Controller).increment();

      expect((Get.find<DisposableController>() as Controller).count, 1);
      Get.delete<DisposableController>();
      expect((Get.find<DisposableController>() as Controller).count, 0);
    });
  });

  group('Get.findOrNull test', () {
    tearDown(Get.reset);
    test('checking results', () async {
      Get.put<int>(1);
      int? result = Get.findOrNull<int>();
      expect(result, 1);

      Get.delete<int>();
      result = Get.findOrNull<int>();
      expect(result, null);
    });
  });

  group('Fenix re-initialization and lifecycle state', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('Get.replace works over an initialized fenix registration', () async {
      Get.lazyPut<ParentController>(() => ParentController(), fenix: true);
      final old = Get.find<ParentController>();

      Get.replace<ParentController>(ChildController());

      final current = Get.find<ParentController>();
      expect(current, isA<ChildController>());
      expect(identical(current, old), false);
      expect(old.close, 1);
      expect(current.init, 1);
      Get.reset();
    });

    test(
      'Get.replace works over a never-initialized fenix registration',
      () async {
        Get.lazyPut<ParentController>(() => ParentController(), fenix: true);

        Get.replace<ParentController>(ChildController());

        expect(Get.find<ParentController>(), isA<ChildController>());
        Get.reset();
      },
    );

    test('Get.lazyReplace works over a fenix registration and the new builder '
        'resurrects', () async {
      Get.lazyPut<ParentController>(() => ParentController(), fenix: true);
      final old = Get.find<ParentController>();

      Get.lazyReplace<ParentController>(() => ChildController(), fenix: true);

      final current = Get.find<ParentController>();
      expect(current, isA<ChildController>());
      expect(old.close, 1);
      current.increment();
      expect(Get.find<ParentController>().count, 1);

      Get.delete<ParentController>();
      final resurrected = Get.find<ParentController>();
      expect(resurrected, isA<ChildController>());
      expect(identical(resurrected, current), false);
      expect(resurrected.count, 0);
      Get.reset();
    });

    test('Get.replace works while a lateRemove chain is pending', () async {
      final first = Get.put<ParentController>(ParentController());
      Get.markAsDirty<ParentController>();
      final second = Get.put<ParentController>(ParentController());
      expect(identical(first, second), false);

      final replacement = ChildController();
      Get.replace<ParentController>(replacement);

      expect(first.close, 1);
      expect(second.close, 1);
      expect(identical(Get.find<ParentController>(), replacement), true);
      Get.reset();
    });

    test('Get.replace disposes and replaces a GetxService', () async {
      final old = Get.put(ParentService());

      Get.replace<ParentService>(ChildService());

      expect(old.close, 1);
      expect(Get.find<ParentService>(), isA<ChildService>());
      Get.reset();
    });
  });

  group('Lazy put factory instance recycling', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('Get.reloadAll calls onClose before clearing instances', () async {
      Get.lazyPut<ReloadController>(() => ReloadController());
      final first = Get.find<ReloadController>();
      first.increment();
      expect(first.count, 1);
      expect(first.close, 0);

      Get.reloadAll();

      expect(first.close, 1);
      expect(Get.isRegistered<ReloadController>(), true);

      final second = Get.find<ReloadController>();
      expect(identical(second, first), false);
      expect(second.count, 0);
      expect(second.init, 1);
      Get.reset();
    });

    test('Get.reloadAll skips GetxService unless forced', () async {
      final service = Get.put(ReloadService());

      Get.reloadAll();
      expect(service.close, 0);
      expect(identical(Get.find<ReloadService>(), service), true);

      Get.reloadAll(force: true);
      expect(service.close, 1);
      Get.reset();
    });

    test('Get.reloadAll skips permanent instances unless forced', () async {
      final controller = Get.put(ReloadController(), permanent: true);

      Get.reloadAll();
      expect(controller.close, 0);
      expect(identical(Get.find<ReloadController>(), controller), true);

      Get.reloadAll(force: true);
      expect(controller.close, 1);
      Get.reset();
    });
  });

  group('Tag registration and duplicate instance replacement', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test('registration with an explicit nullable generic shares the '
        'non-nullable key', () async {
      final instance = Get.put<KeyController?>(KeyController());

      expect(Get.isRegistered<KeyController>(), true);
      expect(identical(Get.find<KeyController>(), instance), true);
      expect(identical(Get.find<KeyController?>(), instance), true);
      expect(instance!.init, 1);

      Get.delete<KeyController>();
      expect(Get.isRegistered<KeyController>(), false);
      expect(Get.isRegistered<KeyController?>(), false);
      Get.reset();
    });

    test('registration inferred from a nullable context shares the '
        'non-nullable key', () async {
      // The nullable context type can make Dart infer S as `KeyController?`,
      // which previously registered under the divergent key "KeyController?".
      KeyController? instance = Get.put(KeyController());

      expect(Get.isRegistered<KeyController>(), true);
      expect(identical(Get.find<KeyController>(), instance), true);
      Get.reset();
    });

    test('lazyPut with a nullable generic is found with the non-nullable '
        'type', () async {
      Get.lazyPut<KeyController?>(() => KeyController());

      expect(Get.isRegistered<KeyController>(), true);
      final instance = Get.find<KeyController>();
      expect(instance.init, 1);
      Get.reset();
    });
  });

  group('Async dependency put and registration parity', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    test(
      'Get.putAsync registers and initializes the awaited instance',
      () async {
        final instance = await Get.putAsync<AsyncController>(() async {
          final controller = AsyncController();
          await controller.setup();
          return controller;
        });

        expect(instance.ready, true);
        expect(instance.init, 1);
        expect(Get.isRegistered<AsyncController>(), true);
        expect(identical(Get.find<AsyncController>(), instance), true);

        Get.delete<AsyncController>();
        expect(instance.close, 1);
        Get.reset();
      },
    );

    test('Get.putAsync supports tags', () async {
      final one = await Get.putAsync<AsyncController>(
        () async => AsyncController(),
        tag: 'one',
      );
      final two = await Get.putAsync<AsyncController>(
        () async => AsyncController(),
        tag: 'two',
      );

      expect(identical(one, two), false);
      expect(identical(Get.find<AsyncController>(tag: 'one'), one), true);
      expect(identical(Get.find<AsyncController>(tag: 'two'), two), true);
      Get.reset();
    });

    test('Get.putAsync supports permanent instances', () async {
      final instance = await Get.putAsync<AsyncController>(
        () async => AsyncController(),
        permanent: true,
      );

      Get.delete<AsyncController>();
      expect(Get.isRegistered<AsyncController>(), true);
      expect(instance.close, 0);

      Get.delete<AsyncController>(force: true);
      expect(Get.isRegistered<AsyncController>(), false);
      expect(instance.close, 1);
      Get.reset();
    });
  });

  group('Late removal service deletion lifecycle', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    //
    // When a route is popped, its dependencies are marked dirty
    // (`Get.markAsDirty`). If the same route is pushed again before the old
    // route disposes, the binding re-registers the key and the superseded
    // factory is kept in `lateRemove`. When the old route finally disposes,
    // `Get.delete` must dispose ONLY the superseded instance and keep the
    // fresh registration (and its live controller) untouched.
    test('delete disposes only the superseded (lateRemove) instance and '
        'keeps the fresh registration alive', () async {
      Get.lazyPut(LifecycleController.new);
      final first = Get.find<LifecycleController>();
      expect(first.inits, 1);

      // Simulates `reportRouteWillDispose` on pop.
      Get.markAsDirty<LifecycleController>();

      // Simulates the binding of the re-pushed route plus the page
      // resolving the controller again.
      Get.lazyPut(LifecycleController.new);
      final second = Get.find<LifecycleController>();
      expect(identical(first, second), false);
      expect(second.inits, 1);

      // Simulates the old route disposing (`_removeDependencyByRoute`).
      final removed = Get.delete<LifecycleController>();

      expect(
        removed,
        false,
        reason: 'the key must stay registered for the new route',
      );
      expect(first.closes, 1);
      expect(second.closes, 0);
      expect(Get.isRegistered<LifecycleController>(), true);
      expect(identical(Get.find<LifecycleController>(), second), true);

      // A later, regular delete (the new route disposing) removes the
      // remaining registration for good.
      final removedAgain = Get.delete<LifecycleController>();
      expect(removedAgain, true);
      expect(second.closes, 1);
      expect(Get.isRegistered<LifecycleController>(), false);

      Get.reset();
    });

    // Same protocol, but with two supersessions in flight (the route was
    // popped and re-pushed twice before any old route disposed). Every
    // pending disposal must peel off the oldest superseded instance; the
    // live controller is only removed by the last delete.
    test('nested lateRemove chain is disposed oldest-first', () async {
      Get.lazyPut(LifecycleController.new);
      final first = Get.find<LifecycleController>();

      Get.markAsDirty<LifecycleController>();
      Get.lazyPut(LifecycleController.new);
      final second = Get.find<LifecycleController>();

      Get.markAsDirty<LifecycleController>();
      Get.lazyPut(LifecycleController.new);
      final third = Get.find<LifecycleController>();

      // First route disposes: only the first instance goes away.
      expect(Get.delete<LifecycleController>(), false);
      expect(first.closes, 1);
      expect(second.closes, 0);
      expect(third.closes, 0);

      // Second route disposes: only the second instance goes away.
      expect(Get.delete<LifecycleController>(), false);
      expect(second.closes, 1);
      expect(third.closes, 0);
      expect(Get.isRegistered<LifecycleController>(), true);
      expect(identical(Get.find<LifecycleController>(), third), true);

      // Third (live) route disposes: the registration is removed.
      expect(Get.delete<LifecycleController>(), true);
      expect(third.closes, 1);
      expect(Get.isRegistered<LifecycleController>(), false);

      Get.reset();
    });

    // delete keeps the factory for resurrection, so it must also clear the
    // dirty flag. Otherwise a later re-registration of the same key would
    // treat the retained factory as stale, chain it in `lateRemove`, and the
    // resurrected live controller would never receive `onClose`.
    test(
      'fenix delete resets the dirty flag so the factory can be reused',
      () async {
        Get.lazyPut(LifecycleController.new, fenix: true);
        final first = Get.find<LifecycleController>();

        Get.markAsDirty<LifecycleController>();
        Get.delete<LifecycleController>();

        expect(first.closes, 1);
        expect(Get.isRegistered<LifecycleController>(), true);

        // Simulates re-entering the route: the binding registers the key
        // again and the page resolves the controller.
        Get.lazyPut(LifecycleController.new, fenix: true);
        final second = Get.find<LifecycleController>();
        expect(identical(first, second), false);
        expect(second.inits, 1);

        // Popping the route again must close the resurrected instance.
        Get.markAsDirty<LifecycleController>();
        Get.delete<LifecycleController>();

        expect(second.closes, 1);
        expect(Get.isRegistered<LifecycleController>(), true);

        Get.reset();
      },
    );
  });
}

class PermanentService extends GetxService {}

class Controller extends DisposableController {
  int init = 0;
  int close = 0;
  int count = 0;
  @override
  void onInit() {
    init++;
    super.onInit();
  }

  @override
  void onClose() {
    close++;
    super.onClose();
  }

  void increment() {
    count++;
  }
}
