// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

class Issue2123Controller extends GetxController {
  int onInitCalls = 0;

  int onCloseCalls = 0;

  @override
  void onInit() {
    onInitCalls++;

    super.onInit();
  }

  @override
  void onClose() {
    onCloseCalls++;

    super.onClose();
  }
}

class _TogglePage extends StatefulWidget {
  const _TogglePage({required this.controller, this.autoRemove = true});

  final Issue2123Controller controller;

  final bool autoRemove;

  @override
  State<_TogglePage> createState() => _TogglePageState();
}

class _TogglePageState extends State<_TogglePage> {
  bool showBuilder = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(
          onPressed: () => setState(() => showBuilder = !showBuilder),

          child: const Text('toggle'),
        ),

        if (showBuilder)
          GetBuilder<Issue2123Controller>(
            global: false,

            autoRemove: widget.autoRemove,

            init: widget.controller,

            builder: (controller) => const Text('local builder'),
          ),
      ],
    );
  }
}

class NamedController extends GetxController {
  NamedController(this.name);

  String name;

  bool closed = false;

  @override
  void onClose() {
    closed = true;

    super.onClose();
  }
}

class ParentController with GetLifeCycleMixin {
  int init = 0;

  int close = 0;

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

class Issue2354Controller extends GetxController {
  int counter = 0;

  void increment() {
    counter++;

    update();
  }
}

class Issue2393Controller extends GetxController {
  int onInitCalls = 0;

  int onCloseCalls = 0;

  int counter = 0;

  @override
  void onInit() {
    onInitCalls++;

    super.onInit();
  }

  @override
  void onClose() {
    onCloseCalls++;

    super.onClose();
  }

  void increment() {
    counter++;

    update();
  }
}

/// Mimics the issue's responsive page: the tree shape around the

/// GetBuilder changes with the available width, so the old BindElement

/// cannot be reused and a new one is inflated while the page stays

/// visible.

class _ResponsivePage extends StatelessWidget {
  const _ResponsivePage();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final builder = GetBuilder<Issue2393Controller>(
          init: Issue2393Controller(),

          builder: (controller) => Text('counter: ${controller.counter}'),
        );

        if (constraints.maxWidth > 500) {
          return Row(children: [builder]);
        }

        return Scaffold(body: builder);
      },
    );
  }
}

class SingleTickController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late final Ticker ticker;

  final tick = 0.obs;

  @override
  void onInit() {
    super.onInit();

    ticker = createTicker((_) {});

    ticker.start();
  }

  @override
  void onClose() {
    ticker.dispose();

    super.onClose();
  }
}

class MultiTickController extends GetxController
    with GetTickerProviderStateMixin {
  late final Ticker firstTicker;

  late final Ticker secondTicker;

  @override
  void onInit() {
    super.onInit();

    firstTicker = createTicker((_) {});

    secondTicker = createTicker((_) {});

    firstTicker.start();

    secondTicker.start();
  }

  @override
  void onClose() {
    firstTicker.dispose();

    secondTicker.dispose();

    super.onClose();
  }
}

class _TickerModeHost extends StatefulWidget {
  const _TickerModeHost({required this.child});

  final Widget child;

  @override
  State<_TickerModeHost> createState() => _TickerModeHostState();
}

class _TickerModeHostState extends State<_TickerModeHost> {
  bool _enabled = true;

  // ignore: use_setters_to_change_properties

  void setEnabled(bool value) {
    setState(() => _enabled = value);
  }

  @override
  Widget build(BuildContext context) {
    return TickerMode(enabled: _enabled, child: widget.child);
  }
}

class TaggedController extends GetxController {
  int counter = 0;
}

class TickerMixinController extends GetxController
    with GetSingleTickerProviderStateMixin {}

class MultiTickerMixinController extends GetxController
    with GetTickerProviderStateMixin {}

class AsyncInitController extends GetxController {
  AsyncInitController(this.value);

  final int value;

  int init = 0;

  @override
  void onInit() {
    init++;

    super.onInit();
  }
}

void main() {
  Get.lazyPut<Controller2>(() => Controller2());
  testWidgets("GetxController smoke test", (test) async {
    await test.pumpWidget(
      MaterialApp(
        home: GetBuilder<Controller>(
          init: Controller(),
          builder: (controller) => Column(
            children: [
              Text('${controller.counter}'),
              TextButton(
                child: const Text("increment"),
                onPressed: () => controller.increment(),
              ),
              TextButton(
                child: const Text("incrementWithId"),
                onPressed: () => controller.incrementWithId(),
              ),
              GetBuilder<Controller>(
                id: '1',
                didChangeDependencies: (_) {
                  // print("didChangeDependencies called");
                },
                builder: (controller) {
                  return Text('id ${controller.counter}');
                },
              ),
              GetBuilder<Controller2>(
                builder: (controller) {
                  return Text('lazy ${controller.test}');
                },
              ),
              GetBuilder<ControllerNonGlobal>(
                init: ControllerNonGlobal(),
                global: false,
                builder: (controller) {
                  return Text('single ${controller.nonGlobal}');
                },
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text("0"), findsOneWidget);

    Controller.to.increment();

    await test.pump();

    expect(find.text("1"), findsOneWidget);

    await test.tap(find.text('increment'));

    await test.pump();

    expect(find.text("2"), findsOneWidget);

    await test.tap(find.text('incrementWithId'));

    await test.pump();

    expect(find.text("id 3"), findsOneWidget);
    expect(find.text("lazy 0"), findsOneWidget);
    expect(find.text("single 0"), findsOneWidget);
  });

  group('GetBuilder local and autoRemove controller lifecycle', () {
    testWidgets(
      'GetBuilder(global: false) controller receives onClose exactly once '
      'when the widget is removed from the tree',
      (tester) async {
        final controller = Issue2123Controller();

        await tester.pumpWidget(
          MaterialApp(home: _TogglePage(controller: controller)),
        );

        expect(find.text('local builder'), findsOneWidget);
        expect(controller.onInitCalls, 1);
        expect(controller.onCloseCalls, 0);
        expect(
          Get.isRegistered<Issue2123Controller>(),
          isFalse,
          reason: 'a non-global controller must not enter the DI registry',
        );

        await tester.tap(find.text('toggle'));
        await tester.pumpAndSettle();

        expect(find.text('local builder'), findsNothing);
        expect(controller.onCloseCalls, 1);
        expect(controller.isClosed, isTrue);
      },
    );

    testWidgets(
      'GetBuilder(global: false) controller receives onClose when the whole '
      'app is torn down',
      (tester) async {
        final controller = Issue2123Controller();

        await tester.pumpWidget(
          MaterialApp(
            home: GetBuilder<Issue2123Controller>(
              global: false,
              init: controller,
              builder: (controller) => const Text('local builder'),
            ),
          ),
        );

        expect(controller.onInitCalls, 1);

        await tester.pumpWidget(const SizedBox());

        expect(controller.onCloseCalls, 1);
      },
    );

    testWidgets(
      'GetBuilder(global: false, autoRemove: false) does not close the '
      'controller on unmount',
      (tester) async {
        final controller = Issue2123Controller();

        await tester.pumpWidget(
          MaterialApp(
            home: _TogglePage(controller: controller, autoRemove: false),
          ),
        );

        await tester.tap(find.text('toggle'));
        await tester.pumpAndSettle();

        expect(controller.onCloseCalls, 0);
        expect(controller.isClosed, isFalse);

        controller.onDelete();
        expect(controller.onCloseCalls, 1);
      },
    );

    testWidgets(
      'GetBuilder(global: false) with the same controller instance in two '
      'builders closes it only after the last one unmounts',
      (tester) async {
        final controller = Issue2123Controller();

        Widget buildApp({required bool showFirst}) {
          return MaterialApp(
            home: Column(
              children: [
                if (showFirst)
                  GetBuilder<Issue2123Controller>(
                    global: false,
                    init: controller,
                    builder: (controller) => const Text('first'),
                  ),
                GetBuilder<Issue2123Controller>(
                  global: false,
                  init: controller,
                  builder: (controller) => const Text('second'),
                ),
              ],
            ),
          );
        }

        await tester.pumpWidget(buildApp(showFirst: true));
        expect(controller.onInitCalls, 1);

        await tester.pumpWidget(buildApp(showFirst: false));
        expect(
          controller.onCloseCalls,
          0,
          reason: 'the second builder still uses the controller',
        );

        await tester.pumpWidget(const SizedBox());
        expect(controller.onCloseCalls, 1);
      },
    );
  });

  group('GetBuilder tag rebinding and disposal', () {
    testWidgets('GetBuilder rebinds to the controller of the new tag', (
      tester,
    ) async {
      final first = Get.put(NamedController('first'), tag: 'first');
      final second = Get.put(NamedController('second'), tag: 'second');
      addTearDown(() {
        Get.delete<NamedController>(tag: 'first', force: true);
        Get.delete<NamedController>(tag: 'second', force: true);
      });

      var tag = 'first';
      late StateSetter setTag;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              setTag = setState;
              return GetBuilder<NamedController>(
                tag: tag,
                builder: (controller) => Text(controller.name),
              );
            },
          ),
        ),
      );

      expect(find.text('first'), findsOneWidget);

      setTag(() => tag = 'second');
      await tester.pump();

      expect(find.text('second'), findsOneWidget);
      expect(find.text('first'), findsNothing);

      // The rebound element listens to the new tag's controller.
      second.name = 'second-updated';
      second.update();
      await tester.pump();
      expect(find.text('second-updated'), findsOneWidget);

      // It no longer rebuilds for the old tag's controller.
      first.name = 'first-updated';
      first.update();
      await tester.pump();
      expect(find.text('first-updated'), findsNothing);
      expect(find.text('second-updated'), findsOneWidget);

      // Externally registered controllers are not disposed by the rebind.
      expect(Get.isRegistered<NamedController>(tag: 'first'), isTrue);
      expect(first.closed, isFalse);
    });

    testWidgets(
      'changing tag disposes an auto-removed controller created under the '
      'old tag and creates one for the new tag',
      (tester) async {
        addTearDown(() {
          Get.delete<NamedController>(tag: 'a', force: true);
          Get.delete<NamedController>(tag: 'b', force: true);
        });

        var tag = 'a';
        late StateSetter setTag;
        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                setTag = setState;
                return GetBuilder<NamedController>(
                  tag: tag,
                  init: NamedController(tag),
                  builder: (controller) => Text(controller.name),
                );
              },
            ),
          ),
        );

        expect(find.text('a'), findsOneWidget);
        final firstInstance = Get.find<NamedController>(tag: 'a');

        setTag(() => tag = 'b');
        await tester.pump();

        expect(find.text('b'), findsOneWidget);
        expect(Get.isRegistered<NamedController>(tag: 'a'), isFalse);
        expect(firstInstance.closed, isTrue);
        expect(Get.isRegistered<NamedController>(tag: 'b'), isTrue);
      },
    );

    testWidgets('rebuild with an unchanged tag keeps the same controller', (
      tester,
    ) async {
      final controller = Get.put(NamedController('stable'), tag: 'stable');
      addTearDown(
        () => Get.delete<NamedController>(tag: 'stable', force: true),
      );

      late StateSetter rebuild;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return GetBuilder<NamedController>(
                tag: 'stable',
                builder: (c) => Text('${identical(c, controller)}'),
              );
            },
          ),
        ),
      );

      expect(find.text('true'), findsOneWidget);

      rebuild(() {});
      await tester.pump();

      expect(find.text('true'), findsOneWidget);
      expect(controller.closed, isFalse);
      expect(Get.isRegistered<NamedController>(tag: 'stable'), isTrue);
    });
  });

  group('Bind replace and lazyReplace parity over fenix', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    tearDown(Get.reset);

    test('Bind.replace works over an initialized fenix registration', () {
      Bind.lazyPut<ParentController>(ParentController.new, fenix: true);
      final old = Bind.find<ParentController>();

      Bind.replace<ParentController>(ChildController());

      final current = Bind.find<ParentController>();
      expect(current, isA<ChildController>());
      expect(identical(current, old), isFalse);
      expect(old.close, 1);
      expect(current.init, 1);
    });

    test('Bind.replace works over a never-initialized fenix registration', () {
      Bind.lazyPut<ParentController>(ParentController.new, fenix: true);

      Bind.replace<ParentController>(ChildController());

      expect(Bind.find<ParentController>(), isA<ChildController>());
    });

    test('Bind.lazyReplace works over an initialized fenix registration', () {
      Bind.lazyPut<ParentController>(ParentController.new, fenix: true);
      final old = Bind.find<ParentController>();

      Bind.lazyReplace<ParentController>(ChildController.new);

      final current = Bind.find<ParentController>();
      expect(current, isA<ChildController>());
      expect(identical(current, old), isFalse);
      expect(old.close, 1);
    });

    test('Bind.replace still works over a plain put registration', () {
      Bind.put<ParentController>(ParentController());
      final old = Bind.find<ParentController>();

      Bind.replace<ParentController>(ChildController());

      final current = Bind.find<ParentController>();
      expect(current, isA<ChildController>());
      expect(identical(current, old), isFalse);
    });
  });

  group('GetBuilder initState callback controller access and mutation', () {
    testWidgets(
      'GetBuilder initState callback accesses state.controller during init (variant 1) '
      'the controller comes from init',
      (tester) async {
        Issue2354Controller? captured;

        await tester.pumpWidget(
          MaterialApp(
            home: GetBuilder<Issue2354Controller>(
              init: Issue2354Controller(),
              initState: (state) {
                captured = state.controller;
              },
              builder: (controller) => Text('counter: ${controller.counter}'),
            ),
          ),
        );

        expect(captured, isNotNull);
        expect(captured, same(Get.find<Issue2354Controller>()));
        expect(find.text('counter: 0'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'GetBuilder initState callback can access state.controller when '
      'the controller is pre-registered',
      (tester) async {
        final registered = Get.put(Issue2354Controller());
        Issue2354Controller? captured;

        await tester.pumpWidget(
          MaterialApp(
            home: GetBuilder<Issue2354Controller>(
              initState: (state) {
                captured = state.controller;
              },
              builder: (controller) => Text('counter: ${controller.counter}'),
            ),
          ),
        );

        expect(captured, same(registered));

        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'GetBuilder initState callback can mutate the controller before '
      'the first build',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: GetBuilder<Issue2354Controller>(
              init: Issue2354Controller(),
              initState: (state) => state.controller.counter = 42,
              builder: (controller) => Text('counter: ${controller.counter}'),
            ),
          ),
        );

        expect(find.text('counter: 42'), findsOneWidget);

        await tester.pumpWidget(const SizedBox());
      },
    );
  });

  group('LayoutBuilder breakpoint swapping controller preservation', () {
    testWidgets(
      'LayoutBuilder breakpoint swap does not delete the controller the '
      'still-visible page is using',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(const MaterialApp(home: _ResponsivePage()));

        expect(find.text('counter: 0'), findsOneWidget);
        final controller = Get.find<Issue2393Controller>();
        expect(controller.onInitCalls, 1);

        // Cross the breakpoint: Scaffold -> Row swaps the element tree.
        tester.view.physicalSize = const Size(800, 800);
        await tester.pumpAndSettle();

        expect(find.text('counter: 0'), findsOneWidget);
        expect(
          Get.isRegistered<Issue2393Controller>(),
          isTrue,
          reason: 'the controller must survive the element swap',
        );
        expect(controller.onCloseCalls, 0);
        expect(controller.isClosed, isFalse);
        expect(Get.find<Issue2393Controller>(), same(controller));

        // The surviving element must still rebuild on update().
        controller.increment();
        await tester.pump();
        expect(find.text('counter: 1'), findsOneWidget);

        // Swap back across the breakpoint and verify again.
        tester.view.physicalSize = const Size(400, 800);
        await tester.pumpAndSettle();

        expect(find.text('counter: 1'), findsOneWidget);
        expect(controller.onCloseCalls, 0);

        // Once the page actually goes away, the deferred disposal runs.
        await tester.pumpWidget(const SizedBox());
        expect(Get.isRegistered<Issue2393Controller>(), isFalse);
        expect(controller.onCloseCalls, 1);
      },
    );

    testWidgets('single GetBuilder teardown still deletes its controller', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GetBuilder<Issue2393Controller>(
            init: Issue2393Controller(),
            builder: (controller) => Text('counter: ${controller.counter}'),
          ),
        ),
      );

      final controller = Get.find<Issue2393Controller>();

      await tester.pumpWidget(const SizedBox());

      expect(Get.isRegistered<Issue2393Controller>(), isFalse);
      expect(controller.onCloseCalls, 1);
    });
  });

  group('TickerProvider mixin muting under TickerMode', () {
    _TickerModeHostState hostState(WidgetTester tester) =>
        tester.state<_TickerModeHostState>(find.byType(_TickerModeHost));

    testWidgets(
      'GetSingleTickerProviderStateMixin ticker is muted when TickerMode is disabled '
      'disables tickers under GetBuilder',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: _TickerModeHost(
              child: GetBuilder<SingleTickController>(
                init: SingleTickController(),
                builder: (controller) => const SizedBox(),
              ),
            ),
          ),
        );

        final controller = Get.find<SingleTickController>();
        expect(controller.ticker.muted, isFalse);
        expect(controller.ticker.isTicking, isTrue);

        hostState(tester).setEnabled(false);
        await tester.pump();

        expect(controller.ticker.muted, isTrue);
        expect(controller.ticker.isTicking, isFalse);

        hostState(tester).setEnabled(true);
        await tester.pump();

        expect(controller.ticker.muted, isFalse);
        expect(controller.ticker.isTicking, isTrue);

        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets('GetTickerProviderStateMixin tickers are muted when TickerMode '
        'disables tickers under GetBuilder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _TickerModeHost(
            child: GetBuilder<MultiTickController>(
              init: MultiTickController(),
              builder: (controller) => const SizedBox(),
            ),
          ),
        ),
      );

      final controller = Get.find<MultiTickController>();
      expect(controller.firstTicker.muted, isFalse);
      expect(controller.secondTicker.muted, isFalse);

      hostState(tester).setEnabled(false);
      await tester.pump();

      expect(controller.firstTicker.muted, isTrue);
      expect(controller.secondTicker.muted, isTrue);

      hostState(tester).setEnabled(true);
      await tester.pump();

      expect(controller.firstTicker.muted, isFalse);
      expect(controller.secondTicker.muted, isFalse);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
      'GetSingleTickerProviderStateMixin ticker is muted when TickerMode '
      'disables tickers under GetX',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: _TickerModeHost(
              child: GetX<SingleTickController>(
                init: SingleTickController(),
                builder: (controller) => Text('tick: ${controller.tick.value}'),
              ),
            ),
          ),
        );

        final controller = Get.find<SingleTickController>();
        expect(controller.ticker.muted, isFalse);

        hostState(tester).setEnabled(false);
        await tester.pump();

        expect(controller.ticker.muted, isTrue);

        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'ticker created after the controller is bound honors the current '
      'TickerMode',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: _TickerModeHost(
              child: GetBuilder<MultiTickController>(
                init: MultiTickController(),
                builder: (controller) => const SizedBox(),
              ),
            ),
          ),
        );

        final controller = Get.find<MultiTickController>();
        hostState(tester).setEnabled(false);
        await tester.pump();

        final lateTicker = controller.createTicker((_) {});
        expect(lateTicker.muted, isTrue);
        lateTicker.dispose();

        await tester.pumpWidget(const SizedBox());
      },
    );
  });

  group('GetBuilder descriptive error reporting on unregistered tags', () {
    testWidgets(
      'GetBuilder without the registration tag throws a descriptive BindError',
      (tester) async {
        Get.put(TaggedController(), tag: 'my-tag');
        addTearDown(
          () => Get.delete<TaggedController>(tag: 'my-tag', force: true),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: GetBuilder<TaggedController>(
              builder: (controller) => Text('${controller.counter}'),
            ),
          ),
        );

        final exception = tester.takeException();
        expect(exception, isA<BindError>());
        final description = exception.toString();
        expect(description, contains('TaggedController'));
        expect(description, contains('without a tag'));
        expect(description, contains('init'));
        expect(description, contains('Get.put'));
      },
    );

    testWidgets(
      'GetBuilder with an unregistered tag names the tag in the error',
      (tester) async {
        Get.put(TaggedController());
        addTearDown(() => Get.delete<TaggedController>(force: true));

        await tester.pumpWidget(
          MaterialApp(
            home: GetBuilder<TaggedController>(
              tag: 'missing',
              builder: (controller) => Text('${controller.counter}'),
            ),
          ),
        );

        final exception = tester.takeException();
        expect(exception, isA<BindError>());
        expect(exception.toString(), contains('with tag "missing"'));
      },
    );

    testWidgets('GetBuilder with the matching tag keeps working', (
      tester,
    ) async {
      Get.put(TaggedController(), tag: 'my-tag');
      addTearDown(
        () => Get.delete<TaggedController>(tag: 'my-tag', force: true),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GetBuilder<TaggedController>(
            tag: 'my-tag',
            builder: (controller) => Text('${controller.counter}'),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('GetBuilder with init and no registration keeps working', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GetBuilder<TaggedController>(
            init: TaggedController(),
            builder: (controller) => Text('${controller.counter}'),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('0'), findsOneWidget);
    });
  });

  group('Ticker provider mixin public exports and naming', () {
    test('ticker provider mixin file uses the corrected file name', () {
      const base = 'lib/get_state_manager/src/rx_flutter';
      expect(File('$base/rx_ticker_provider_mixin.dart').existsSync(), isTrue);
      expect(File('$base/rx_ticket_provider_mixin.dart').existsSync(), isFalse);
    });

    test('ticker provider mixins remain exported from the public barrel', () {
      final single = TickerMixinController();
      final multi = MultiTickerMixinController();

      expect(single, isA<TickerProvider>());
      expect(multi, isA<TickerProvider>());

      final ticker = single.createTicker((_) {});
      expect(ticker, isA<Ticker>());
      ticker.dispose();

      final firstTicker = multi.createTicker((_) {});
      final secondTicker = multi.createTicker((_) {});
      expect(firstTicker, isNot(same(secondTicker)));
      firstTicker.dispose();
      secondTicker.dispose();
    });
  });

  group('Bind putAsync builder awaiting and tag support', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    tearDown(Get.reset);

    test(
      'Bind.putAsync awaits the builder and registers the instance',
      () async {
        final bind = await Bind.putAsync<AsyncInitController>(() async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return AsyncInitController(42);
        });

        expect(bind, isA<Bind<AsyncInitController>>());
        expect(Get.isRegistered<AsyncInitController>(), isTrue);

        final controller = Bind.find<AsyncInitController>();
        expect(controller.value, 42);
        expect(controller.init, 1);
      },
    );

    test('Bind.putAsync honors tags', () async {
      await Bind.putAsync<AsyncInitController>(
        () async => AsyncInitController(1),
        tag: 'a',
      );
      await Bind.putAsync<AsyncInitController>(
        () async => AsyncInitController(2),
        tag: 'b',
      );

      expect(Bind.find<AsyncInitController>(tag: 'a').value, 1);
      expect(Bind.find<AsyncInitController>(tag: 'b').value, 2);
    });

    test('GetState pattern matching with when() and maybeWhen()', () {
      final GetState<int> loadingState = GetStatus<int>.loading();
      final GetState<int> successState = GetStatus<int>.success(42);
      final GetState<int> errorState = GetStatus<int>.error('Failed');
      final GetState<int> emptyState = GetStatus<int>.empty();

      // Test when()
      expect(
        loadingState.when(
          loading: () => 'loading',
          success: (data) => 'success:$data',
          error: (err) => 'error:$err',
          empty: () => 'empty',
        ),
        'loading',
      );

      expect(
        successState.when(
          loading: () => 'loading',
          success: (data) => 'success:$data',
          error: (err) => 'error:$err',
          empty: () => 'empty',
        ),
        'success:42',
      );

      expect(
        errorState.when(
          loading: () => 'loading',
          success: (data) => 'success:$data',
          error: (err) => 'error:$err',
          empty: () => 'empty',
        ),
        'error:Failed',
      );

      expect(
        emptyState.when(
          loading: () => 'loading',
          success: (data) => 'success:$data',
          error: (err) => 'error:$err',
          empty: () => 'empty',
        ),
        'empty',
      );

      // Test maybeWhen()
      expect(
        successState.maybeWhen(
          success: (data) => 'got $data',
          orElse: () => 'fallback',
        ),
        'got 42',
      );

      expect(
        loadingState.maybeWhen(
          success: (data) => 'got $data',
          orElse: () => 'fallback',
        ),
        'fallback',
      );
    });
  });
}

class Controller extends GetxController {
  static Controller get to => Get.find();

  int counter = 0;

  void increment() {
    counter++;
    update();
  }

  void incrementWithId() {
    counter++;
    update(['1']);
  }
}

class Controller2 extends GetxController {
  int test = 0;
}

class ControllerNonGlobal extends GetxController {
  int nonGlobal = 0;
}
