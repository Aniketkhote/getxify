import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';
import 'utils/wrapper.dart';

// a pop through GetDelegate played the forward/push animation instead of a
// pop animation whenever the pop surfaced to a navigator as a page
// *replacement* — the norm for nested GetRouterOutlet stacks, which render
// only the current tree branch — because the DefaultTransitionDelegate marks
// the incoming page for push and instantly completes the leaving page.
// Additionally, a PopMode.page pop of the only history entry pushed the
// parent branch ON TOP of the leaf instead of replacing the entry.

const _duration = Duration(milliseconds: 300);
const _halfway = Duration(milliseconds: 150);

/// Starts the transition triggered by a preceding navigation call and pumps
/// to its halfway point.
///
/// The delegate mutates its history in a microtask (first pump), the router
/// rebuild applies the page diff and starts the transition (second pump),
/// and newly inserted route content becomes visible on the following frame
/// (the halfway pump).
Future<void> pumpHalfwayThroughTransition(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(_halfway);
}

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('shell-view'),
          Expanded(
            child: GetRouterOutlet(
              anchorRoute: '/home',
              initialRoute: '/home/first',
            ),
          ),
        ],
      ),
    );
  }
}

GetMaterialApp buildOutletApp() {
  return GetMaterialApp(
    initialRoute: '/home/first',
    getPages: [
      GetPage(
        name: '/home',
        participatesInRootNavigator: true,
        page: () => const Shell(),
        children: [
          GetPage(
            name: '/first',
            page: () => const Text('first-view'),
            transition: Transition.rightToLeft,
            transitionDuration: _duration,
          ),
          GetPage(
            name: '/second',
            page: () => const Text('second-view'),
            transition: Transition.rightToLeft,
            transitionDuration: _duration,
          ),
        ],
      ),
    ],
  );
}

GetMaterialApp buildNestedBranchApp() {
  return GetMaterialApp(
    initialRoute: '/home/details',
    getPages: [
      GetPage(
        name: '/home',
        page: () => const Text('home-view'),
        children: [
          GetPage(
            name: '/details',
            page: () => const Text('details-view'),
            transition: Transition.rightToLeft,
            transitionDuration: _duration,
          ),
        ],
      ),
    ],
  );
}

GetMaterialApp buildFlatApp() {
  return GetMaterialApp(
    initialRoute: '/a',
    getPages: [
      GetPage(name: '/a', page: () => const Text('a-view')),
      GetPage(
        name: '/b',
        page: () => const Text('b-view'),
        transition: Transition.rightToLeft,
        transitionDuration: _duration,
      ),
    ],
  );
}

// (Get extension wrappers)
//
// Get.closeCurrentSnackbar and Get.closeAllSnackbars forward the
// [withAnimations] flag to the SnackbarController statics, so the current
// snackbar can be dismissed without playing its exit animation from the
// Get facade as well. This file fails to compile without the fix
// (no such named parameter), proving the additive API.

// Get.close / Get.closeDialog / Get.closeBottomSheet must also close
// overlays opened with Flutter's native showDialog/showModalBottomSheet,
// which do not set GetX's routing flags.

class N5Home extends StatelessWidget {
  const N5Home({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('home'));
  }
}

void main() {
  // Base snackbar_test.dart tests
  testWidgets("test if Get.isSnackbarOpen works with Get.snackbar", (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        popGesture: true,
        home: ElevatedButton(
          child: const Text('Open Snackbar'),
          onPressed: () {
            Get.snackbar(
              'title',
              "message",
              duration: const Duration(seconds: 1),
              mainButton: TextButton(
                onPressed: () {},
                child: const Text('button'),
              ),
              isDismissible: false,
            );
          },
        ),
      ),
    );

    await tester.pump();

    expect(Get.isSnackbarOpen, false);
    await tester.tap(find.text('Open Snackbar'));

    expect(Get.isSnackbarOpen, true);
    await tester.pump(const Duration(seconds: 1));
    expect(Get.isSnackbarOpen, false);
  });

  testWidgets("Get.rawSnackbar test", (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        popGesture: true,
        home: ElevatedButton(
          child: const Text('Open Snackbar'),
          onPressed: () {
            Get.rawSnackbar(
              title: 'title',
              message: "message",
              onTap: (_) {},
              shouldIconPulse: true,
              icon: const Icon(Icons.alarm),
              showProgressIndicator: true,
              duration: const Duration(seconds: 1),
              isDismissible: true,
              leftBarIndicatorColor: Colors.amber,
              overlayBlur: 1.0,
            );
          },
        ),
      ),
    );

    await tester.pump();

    expect(Get.isSnackbarOpen, false);
    await tester.tap(find.text('Open Snackbar'));

    expect(Get.isSnackbarOpen, true);
    await tester.pump(const Duration(seconds: 1));
    expect(Get.isSnackbarOpen, false);
  });

  testWidgets("test snackbar queue", (tester) async {
    const messageOne = Text('title');

    const messageTwo = Text('titleTwo');

    await tester.pumpWidget(
      GetMaterialApp(
        popGesture: true,
        home: ElevatedButton(
          child: const Text('Open Snackbar'),
          onPressed: () {
            Get.rawSnackbar(
              messageText: messageOne,
              duration: const Duration(seconds: 1),
            );
            Get.rawSnackbar(
              messageText: messageTwo,
              duration: const Duration(seconds: 1),
            );
          },
        ),
      ),
    );

    await tester.pump();

    expect(Get.isSnackbarOpen, false);
    await tester.tap(find.text('Open Snackbar'));
    expect(Get.isSnackbarOpen, true);

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('title'), findsOneWidget);
    expect(find.text('titleTwo'), findsNothing);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('title'), findsNothing);
    expect(find.text('titleTwo'), findsOneWidget);
    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
  });

  testWidgets("test snackbar dismissible", (tester) async {
    const dismissDirection = DismissDirection.down;
    const snackBarTapTarget = Key('snackbar-tap-target');

    const GetSnackBar getBar = GetSnackBar(
      key: ValueKey('dismissible'),
      message: 'bar1',
      duration: Duration(seconds: 2),
      isDismissible: true,
      snackPosition: SnackPosition.bottom,
      dismissDirection: dismissDirection,
    );

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Column(
                children: <Widget>[
                  GestureDetector(
                    key: snackBarTapTarget,
                    onTap: () {
                      Get.showSnackbar(getBar);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(height: 100.0, width: 100.0),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.pump();

    expect(Get.isSnackbarOpen, false);
    expect(find.text('bar1'), findsNothing);

    await tester.tap(find.byKey(snackBarTapTarget));
    await tester.pumpAndSettle();

    expect(Get.isSnackbarOpen, true);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byWidget(getBar), findsOneWidget);
    await tester.ensureVisible(find.byWidget(getBar));
    await tester.drag(find.byType(Dismissible), const Offset(0.0, 50.0));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 500));
    expect(Get.isSnackbarOpen, false);
  });

  testWidgets("test snackbar onTap", (tester) async {
    const dismissDirection = DismissDirection.vertical;
    const snackBarTapTarget = Key('snackbar-tap-target');
    var counter = 0;

    late final GetSnackBar getBar;

    late final SnackbarController getBarController;

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Column(
                children: <Widget>[
                  GestureDetector(
                    key: snackBarTapTarget,
                    onTap: () {
                      getBar = GetSnackBar(
                        message: 'bar1',
                        onTap: (_) {
                          counter++;
                        },
                        duration: const Duration(seconds: 2),
                        isDismissible: true,
                        dismissDirection: dismissDirection,
                      );
                      getBarController = Get.showSnackbar(getBar);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(height: 100.0, width: 100.0),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(Get.isSnackbarOpen, false);
    expect(find.text('bar1'), findsNothing);

    await tester.tap(find.byKey(snackBarTapTarget));
    await tester.pumpAndSettle();

    expect(Get.isSnackbarOpen, true);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byWidget(getBar), findsOneWidget);
    await tester.ensureVisible(find.byWidget(getBar));
    await tester.tap(find.byWidget(getBar));
    expect(counter, 1);
    await tester.pump(const Duration(milliseconds: 3000));
    await getBarController.close(withAnimations: false);
  });

  testWidgets("Get test actions and icon", (tester) async {
    const icon = Icon(Icons.alarm);
    final action = TextButton(onPressed: () {}, child: const Text('button'));

    late final GetSnackBar getBar;

    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));

    await tester.pump();

    expect(Get.isSnackbarOpen, false);
    expect(find.text('bar1'), findsNothing);

    getBar = GetSnackBar(
      message: 'bar1',
      icon: icon,
      mainButton: action,
      leftBarIndicatorColor: Colors.yellow,
      showProgressIndicator: true,
      // maxWidth: 100,
      borderColor: Colors.red,
      duration: const Duration(seconds: 1),
      isDismissible: false,
    );
    Get.showSnackbar(getBar);

    expect(Get.isSnackbarOpen, true);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byWidget(getBar), findsOneWidget);
    expect(find.byWidget(icon), findsOneWidget);
    expect(find.byWidget(action), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));

    expect(Get.isSnackbarOpen, false);
  });

  group('1883', () {
    tearDown(Get.reset);

    testWidgets(
      'popping inside a GetRouterOutlet plays the pop animation, not a push',
      (tester) async {
        await tester.pumpWidget(buildOutletApp());
        await tester.pumpAndSettle();
        expect(find.text('first-view'), findsOneWidget);

        Get.rootController.rootDelegate.toNamed('/home/second');
        await pumpHalfwayThroughTransition(tester);
        // Forward navigation still plays the forward animation inside the
        // outlet: the entering page is mid slide-in from the right.
        expect(find.text('second-view'), findsOneWidget);
        expect(tester.getTopLeft(find.text('second-view')).dx, greaterThan(1));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('second-view')).dx, lessThan(1));

        Get.rootController.rootDelegate.back();
        await pumpHalfwayThroughTransition(tester);
        // The pop surfaces to the outlet navigator as a replacement
        // ([second] -> [first]). Before the fix the leaving page was removed
        // instantly and the revealed page slid in with the forward animation.
        expect(
          find.text('second-view'),
          findsOneWidget,
          reason: 'the popped page must animate out instead of vanishing',
        );
        expect(
          tester.getTopLeft(find.text('second-view')).dx,
          greaterThan(1),
          reason: 'the popped page must be mid slide-out to the right',
        );
        expect(find.text('first-view'), findsOneWidget);
        expect(
          tester.getTopLeft(find.text('first-view')).dx,
          lessThan(1),
          reason: 'the revealed page must appear in place, not slide in',
        );

        await tester.pumpAndSettle();
        expect(find.text('second-view'), findsNothing);
        expect(find.text('first-view'), findsOneWidget);
      },
    );

    testWidgets(
      'PopMode.page pop of the only history entry replaces it with the '
      'parent branch and plays the pop animation',
      (tester) async {
        await tester.pumpWidget(buildNestedBranchApp());
        await tester.pumpAndSettle();
        final delegate = Get.rootController.rootDelegate;
        expect(find.text('details-view'), findsOneWidget);
        expect(delegate.activePages.length, 1);

        delegate.popRoute(popMode: PopMode.page);
        await pumpHalfwayThroughTransition(tester);
        // Before the fix the parent was PUSHED on top of the leaf (history
        // became [details, home]) and slid in with the forward animation.
        expect(find.text('details-view'), findsOneWidget);
        expect(
          tester.getTopLeft(find.text('details-view')).dx,
          greaterThan(1),
          reason: 'the popped leaf must be mid slide-out to the right',
        );
        expect(find.text('home-view'), findsOneWidget);
        expect(
          tester.getTopLeft(find.text('home-view')).dx,
          lessThan(1),
          reason: 'the revealed parent must appear in place, not slide in',
        );

        await tester.pumpAndSettle();
        expect(find.text('details-view'), findsNothing);
        expect(find.text('home-view'), findsOneWidget);
        expect(delegate.activePages.length, 1);
        expect(delegate.activePages.last.route?.name, '/home');
      },
    );

    testWidgets(
      'offNamed (a replacement not caused by a pop) keeps the forward '
      'push animation',
      (tester) async {
        await tester.pumpWidget(buildFlatApp());
        await tester.pumpAndSettle();
        expect(find.text('a-view'), findsOneWidget);

        Get.rootController.rootDelegate.offNamed('/b');
        await pumpHalfwayThroughTransition(tester);
        expect(find.text('b-view'), findsOneWidget);
        expect(
          tester.getTopLeft(find.text('b-view')).dx,
          greaterThan(1),
          reason: 'a replace-style navigation must still slide in',
        );

        await tester.pumpAndSettle();
        expect(find.text('a-view'), findsNothing);
        expect(find.text('b-view'), findsOneWidget);
      },
    );

    testWidgets('a genuine removal pop at the root still animates out', (
      tester,
    ) async {
      await tester.pumpWidget(buildFlatApp());
      await tester.pumpAndSettle();

      Get.rootController.rootDelegate.toNamed('/b');
      await tester.pumpAndSettle();
      expect(find.text('b-view'), findsOneWidget);

      Get.rootController.rootDelegate.back();
      await pumpHalfwayThroughTransition(tester);
      expect(find.text('b-view'), findsOneWidget);
      expect(tester.getTopLeft(find.text('b-view')).dx, greaterThan(1));
      expect(find.text('a-view'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('b-view'), findsNothing);
      expect(find.text('a-view'), findsOneWidget);
    });
  });

  group('2334', () {
    testWidgets(
      "Get.previousRoute survives opening and closing a bottomsheet (issue #2334)",
      (tester) async {
        await tester.pumpWidget(
          WrapperNamed(
            initialRoute: '/first',
            namedRoutes: [
              GetPage(page: () => const Text('first'), name: '/first'),
              GetPage(page: () => const Text('second'), name: '/second'),
            ],
          ),
        );
        await tester.pumpAndSettle();

        Get.toNamed('/second');
        await tester.pumpAndSettle();

        expect(Get.currentRoute, '/second');
        expect(Get.previousRoute, '/first');

        Get.bottomSheet(const Text('sheet'));
        await tester.pumpAndSettle();

        expect(Get.isBottomSheetOpen, true);
        expect(Get.currentRoute, '/second');
        expect(Get.previousRoute, '/first');

        Get.backLegacy();
        await tester.pumpAndSettle();

        expect(Get.isBottomSheetOpen, false);
        expect(Get.currentRoute, '/second');
        expect(Get.previousRoute, '/first');
      },
    );

    testWidgets(
      "Get.previousRoute survives opening and closing a dialog (issue #2334)",
      (tester) async {
        await tester.pumpWidget(
          WrapperNamed(
            initialRoute: '/first',
            namedRoutes: [
              GetPage(page: () => const Text('first'), name: '/first'),
              GetPage(page: () => const Text('second'), name: '/second'),
            ],
          ),
        );
        await tester.pumpAndSettle();

        Get.toNamed('/second');
        await tester.pumpAndSettle();

        Get.dialog(const Text('dialog'));
        await tester.pumpAndSettle();

        expect(Get.isDialogOpen, true);
        expect(Get.currentRoute, '/second');
        expect(Get.previousRoute, '/first');

        Get.backLegacy();
        await tester.pumpAndSettle();

        expect(Get.isDialogOpen, false);
        expect(Get.currentRoute, '/second');
        expect(Get.previousRoute, '/first');
      },
    );
  });

  group('2400 Extension', () {
    testWidgets(
      'Get.closeCurrentSnackbar(withAnimations: false) closes immediately',
      (tester) async {
        await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));

        Get.rawSnackbar(message: 'hello', duration: const Duration(seconds: 5));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('hello'), findsOneWidget);

        await Get.closeCurrentSnackbar(withAnimations: false);
        await tester.pump();

        expect(find.text('hello'), findsNothing);
        expect(Get.isSnackbarOpen, false);
      },
    );

    testWidgets('Get.closeCurrentSnackbar() still animates by default', (
      tester,
    ) async {
      await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));

      Get.rawSnackbar(message: 'hello', duration: const Duration(seconds: 5));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('hello'), findsOneWidget);

      Get.closeCurrentSnackbar();
      await tester.pump();

      // Mid exit animation the snackbar is still on screen.
      expect(find.text('hello'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsNothing);
      expect(Get.isSnackbarOpen, false);
    });

    testWidgets(
      'Get.closeAllSnackbars(withAnimations: false) closes immediately',
      (tester) async {
        await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));

        Get.rawSnackbar(message: 'hello', duration: const Duration(seconds: 5));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('hello'), findsOneWidget);

        Get.closeAllSnackbars(withAnimations: false);
        await tester.pump();

        expect(find.text('hello'), findsNothing);
        expect(Get.isSnackbarOpen, false);
      },
    );
  });

  group('3342 Native Overlays', () {
    testWidgets("Get.close closes a native showDialog dialog", (tester) async {
      await tester.pumpWidget(Wrapper(child: Container()));
      await tester.pump();

      showDialog(
        context: Get.context!,
        builder: (_) => const Text('native dialog'),
      );
      await tester.pumpAndSettle();
      expect(find.text('native dialog'), findsOneWidget);

      Get.close();
      await tester.pumpAndSettle();

      expect(find.text('native dialog'), findsNothing);
    });

    testWidgets("Get.closeDialog closes a native showDialog dialog", (
      tester,
    ) async {
      await tester.pumpWidget(Wrapper(child: Container()));
      await tester.pump();

      showDialog(
        context: Get.context!,
        builder: (_) => const Text('native dialog'),
      );
      await tester.pumpAndSettle();
      expect(find.text('native dialog'), findsOneWidget);

      Get.closeDialog();
      await tester.pumpAndSettle();

      expect(find.text('native dialog'), findsNothing);
    });

    testWidgets("Get.close closes a native showModalBottomSheet sheet", (
      tester,
    ) async {
      await tester.pumpWidget(Wrapper(child: Container()));
      await tester.pump();

      showModalBottomSheet(
        context: Get.context!,
        builder: (_) => const Text('native sheet'),
      );
      await tester.pumpAndSettle();
      expect(find.text('native sheet'), findsOneWidget);

      Get.close();
      await tester.pumpAndSettle();

      expect(find.text('native sheet'), findsNothing);
    });

    testWidgets("Get.closeBottomSheet closes a native sheet", (tester) async {
      await tester.pumpWidget(Wrapper(child: Container()));
      await tester.pump();

      showModalBottomSheet(
        context: Get.context!,
        builder: (_) => const Text('native sheet'),
      );
      await tester.pumpAndSettle();
      expect(find.text('native sheet'), findsOneWidget);

      Get.closeBottomSheet();
      await tester.pumpAndSettle();

      expect(find.text('native sheet'), findsNothing);
    });

    testWidgets("Get.closeBottomSheet does not close native dialogs", (
      tester,
    ) async {
      await tester.pumpWidget(Wrapper(child: Container()));
      await tester.pump();

      showDialog(
        context: Get.context!,
        builder: (_) => const Text('native dialog'),
      );
      await tester.pumpAndSettle();

      Get.closeBottomSheet();
      await tester.pumpAndSettle();

      expect(find.text('native dialog'), findsOneWidget);
    });
  });

  group('3343', () {
    testWidgets("close() on an already-dismissed snackbar is a no-op", (
      tester,
    ) async {
      late SnackbarController controller;

      await tester.pumpWidget(
        GetMaterialApp(
          home: ElevatedButton(
            child: const Text('Open Snackbar'),
            onPressed: () {
              controller = Get.rawSnackbar(
                title: 'title',
                message: "message",
                duration: const Duration(seconds: 1),
              );
            },
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.text('Open Snackbar'));
      expect(Get.isSnackbarOpen, true);

      // Let the duration timer expire and the snackbar fully dismiss.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(Get.isSnackbarOpen, false);

      // Closing again must not assert "Cannot remove entry from a
      // disposed snackbar".
      await controller.close();
      await controller.close(withAnimations: false);
      expect(tester.takeException(), isNull);
    });

    testWidgets("double close() does not assert", (tester) async {
      late SnackbarController controller;

      await tester.pumpWidget(
        GetMaterialApp(
          home: ElevatedButton(
            child: const Text('Open Snackbar'),
            onPressed: () {
              controller = Get.rawSnackbar(
                title: 'title',
                message: "message",
                duration: const Duration(seconds: 5),
              );
            },
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.text('Open Snackbar'));
      await tester.pumpAndSettle();
      expect(Get.isSnackbarOpen, true);

      final firstClose = controller.close();
      final secondClose = controller.close();
      await tester.pumpAndSettle();
      await firstClose;
      await secondClose;

      expect(Get.isSnackbarOpen, false);
      expect(tester.takeException(), isNull);
    });

    testWidgets("duration timer firing after close(withAnimations: false) "
        "does not assert", (tester) async {
      late SnackbarController controller;

      await tester.pumpWidget(
        GetMaterialApp(
          home: ElevatedButton(
            child: const Text('Open Snackbar'),
            onPressed: () {
              controller = Get.rawSnackbar(
                title: 'title',
                message: "message",
                duration: const Duration(seconds: 1),
              );
            },
          ),
        ),
      );

      await tester.pump();
      await tester.tap(find.text('Open Snackbar'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(Get.isSnackbarOpen, true);

      await controller.close(withAnimations: false);
      await tester.pump();
      expect(Get.isSnackbarOpen, false);

      // If the duration timer was not cancelled, it fires _removeEntry on the
      // disposed controller here.
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  });

  group('3371', () {
    tearDown(Get.reset);

    testWidgets(
      'rebuilding GetMaterialApp with a new theme updates the MaterialApp theme',
      (tester) async {
        const firstColor = Color(0xFF123456);
        const secondColor = Color(0xFF654321);

        final themeNotifier = ValueNotifier<ThemeData>(
          ThemeData(primaryColor: firstColor),
        );
        addTearDown(themeNotifier.dispose);

        await tester.pumpWidget(
          ValueListenableBuilder<ThemeData>(
            valueListenable: themeNotifier,
            builder: (context, themeData, _) {
              return GetMaterialApp(
                theme: themeData,
                getPages: [GetPage(name: '/', page: () => const N5Home())],
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        final homeContext = tester.element(find.byType(N5Home));
        expect(Theme.of(homeContext).primaryColor, firstColor);

        themeNotifier.value = ThemeData(primaryColor: secondColor);
        await tester.pumpAndSettle();

        final updatedContext = tester.element(find.byType(N5Home));
        expect(Theme.of(updatedContext).primaryColor, secondColor);
      },
    );

    testWidgets(
      'rebuilding GetMaterialApp with a new themeMode switches light/dark',
      (tester) async {
        final modeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);
        addTearDown(modeNotifier.dispose);

        final lightTheme = ThemeData(brightness: Brightness.light);
        final darkTheme = ThemeData(brightness: Brightness.dark);

        await tester.pumpWidget(
          ValueListenableBuilder<ThemeMode>(
            valueListenable: modeNotifier,
            builder: (context, mode, _) {
              return GetMaterialApp(
                theme: lightTheme,
                darkTheme: darkTheme,
                themeMode: mode,
                getPages: [GetPage(name: '/', page: () => const N5Home())],
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        final homeContext = tester.element(find.byType(N5Home));
        expect(Theme.of(homeContext).brightness, Brightness.light);

        modeNotifier.value = ThemeMode.dark;
        await tester.pumpAndSettle();

        final updatedContext = tester.element(find.byType(N5Home));
        expect(Theme.of(updatedContext).brightness, Brightness.dark);
      },
    );

    testWidgets('Get.changeTheme still applies runtime theme changes', (
      tester,
    ) async {
      const startColor = Color(0xFF111111);
      const runtimeColor = Color(0xFF222222);

      await tester.pumpWidget(
        GetMaterialApp(
          theme: ThemeData(primaryColor: startColor),
          getPages: [GetPage(name: '/', page: () => const N5Home())],
        ),
      );

      Get.changeTheme(ThemeData(primaryColor: runtimeColor));
      await tester.pumpAndSettle();

      final homeContext = tester.element(find.byType(N5Home));
      expect(Theme.of(homeContext).primaryColor, runtimeColor);
    });
  });
}
