import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';
import 'utils/wrapper.dart';

// back button arrives as a route information report handled by
// GetDelegate.setNewRoutePath, which must honor the top route's pop-veto
// surface (PopScope/WillPopScope/GetPage.canPop) when a single page would
// be popped.

/// Simulates the platform (browser back/forward button or a deep link)
/// reporting a new route to the app.
Future<void> n0SimulatePlatformRoute(
  WidgetTester tester,
  String location,
) async {
  final message = const JSONMethodCodec().encodeMethodCall(
    MethodCall('pushRouteInformation', <String, dynamic>{
      'location': location,
      'state': null,
    }),
  );
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    message,
    (_) {},
  );
}

// #2434 / #2188 / #3140:
// the system back button (GetDelegate.popRoute) must consult the top
// route's pop-veto surface (PopScope, WillPopScope, GetPage.canPop) before
// popping the page declaratively, mirroring NavigatorState.maybePop, and a
// blocked pop must fire onPopInvoked with didPop: false.

/// Simulates the Android system back button / predictive back gesture.
Future<void> simulateSystemBack(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
    (_) {},
  );
}

GetMaterialApp n2BuildApp() {
  return GetMaterialApp(
    // Cupertino keeps the same transition subtree while a user gesture is
    // in progress; the default Android builders swap subtrees mid-gesture,
    // which would end the drag under test for unrelated reasons.
    defaultTransition: Transition.cupertino,
    initialRoute: '/first',
    getPages: [
      GetPage(
        name: '/first',
        popGesture: true,
        page: () => const Scaffold(body: Text('first')),
      ),
      GetPage(
        name: '/second',
        popGesture: true,
        gestureWidth: (context) => 80,
        page: () => const Scaffold(body: Text('second')),
      ),
    ],
  );
}

// Get.back(), the system back gesture and the iOS edge-swipe must pop
// imperatively pushed pageless routes (e.g. OpenContainer, raw
// Navigator.push) instead of removing pages from the delegate history,
// which tore down two screens at once.

void main() {
  group('3121 Web Back Popscope', () {
    testWidgets('platform back is vetoed by PopScope(canPop: false)', (
      tester,
    ) async {
      final popInvocations = <bool>[];

      await tester.pumpWidget(
        Wrapper(
          initialRoute: '/first',
          namedRoutes: [
            GetPage(name: '/first', page: () => const Text('first')),
            GetPage(
              name: '/guarded',
              page: () => PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) =>
                    popInvocations.add(didPop),
                child: const Text('guarded'),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/guarded');
      await tester.pumpAndSettle();

      final delegate = Get.rootController.rootDelegate;
      expect(delegate.activePages.length, 2);

      await n0SimulatePlatformRoute(tester, '/first');
      await tester.pumpAndSettle();

      // The page must survive, stay on the stack and observe the attempt.
      expect(find.text('guarded'), findsOneWidget);
      expect(delegate.activePages.length, 2);
      expect(delegate.activePages.last.pageSettings?.name, '/guarded');
      expect(popInvocations, [false]);
    });

    testWidgets('platform back still pops without a veto', (tester) async {
      await tester.pumpWidget(
        Wrapper(
          initialRoute: '/first',
          namedRoutes: [
            GetPage(name: '/first', page: () => const Text('first')),
            GetPage(
              name: '/open',
              page: () => const PopScope(canPop: true, child: Text('open')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/open');
      await tester.pumpAndSettle();

      await n0SimulatePlatformRoute(tester, '/first');
      await tester.pumpAndSettle();

      final delegate = Get.rootController.rootDelegate;
      expect(find.text('first'), findsOneWidget);
      expect(delegate.activePages.length, 1);
    });
  });

  group('3216 Popscope System Back', () {
    testWidgets('system back is vetoed by PopScope(canPop: false)', (
      tester,
    ) async {
      final popInvocations = <bool>[];

      await tester.pumpWidget(
        Wrapper(
          initialRoute: '/home',
          namedRoutes: [
            GetPage(name: '/home', page: () => const Text('home')),
            GetPage(
              name: '/guarded',
              page: () => PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) =>
                    popInvocations.add(didPop),
                child: const Text('guarded'),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/guarded');
      await tester.pumpAndSettle();
      expect(find.text('guarded'), findsOneWidget);

      await simulateSystemBack(tester);
      await tester.pumpAndSettle();

      // The page must survive and PopScope must observe the blocked attempt.
      expect(find.text('guarded'), findsOneWidget);
      expect(Get.currentRoute, '/guarded');
      expect(popInvocations, [false]);
    });

    testWidgets('system back still pops with PopScope(canPop: true)', (
      tester,
    ) async {
      await tester.pumpWidget(
        Wrapper(
          initialRoute: '/home',
          namedRoutes: [
            GetPage(name: '/home', page: () => const Text('home')),
            GetPage(
              name: '/open',
              page: () => const PopScope(canPop: true, child: Text('open')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/open');
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);

      await simulateSystemBack(tester);
      await tester.pumpAndSettle();

      expect(find.text('open'), findsNothing);
      expect(find.text('home'), findsOneWidget);
      expect(Get.currentRoute, '/home');
    });

    testWidgets('system back is vetoed by a WillPopScope returning false', (
      tester,
    ) async {
      var callbackRuns = 0;

      await tester.pumpWidget(
        Wrapper(
          initialRoute: '/home',
          namedRoutes: [
            GetPage(name: '/home', page: () => const Text('home')),
            GetPage(
              name: '/legacy',
              // ignore: deprecated_member_use
              page: () => WillPopScope(
                onWillPop: () async {
                  callbackRuns++;
                  return false;
                },
                child: const Text('legacy'),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/legacy');
      await tester.pumpAndSettle();

      await simulateSystemBack(tester);
      await tester.pumpAndSettle();

      expect(callbackRuns, 1);
      expect(find.text('legacy'), findsOneWidget);
      expect(Get.currentRoute, '/legacy');
    });

    testWidgets('system back is vetoed by GetPage(canPop: false)', (
      tester,
    ) async {
      await tester.pumpWidget(
        Wrapper(
          initialRoute: '/home',
          namedRoutes: [
            GetPage(name: '/home', page: () => const Text('home')),
            GetPage(
              name: '/locked',
              canPop: false,
              page: () => const Text('locked'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/locked');
      await tester.pumpAndSettle();

      await simulateSystemBack(tester);
      await tester.pumpAndSettle();

      expect(find.text('locked'), findsOneWidget);
      expect(Get.currentRoute, '/locked');
    });

    testWidgets('Get.back keeps Navigator.pop semantics and ignores PopScope', (
      tester,
    ) async {
      await tester.pumpWidget(
        Wrapper(
          initialRoute: '/home',
          namedRoutes: [
            GetPage(name: '/home', page: () => const Text('home')),
            GetPage(
              name: '/guarded',
              page: () => const PopScope(canPop: false, child: Text('guarded')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/guarded');
      await tester.pumpAndSettle();

      // Get.back is documented to pop unconditionally, like Navigator.pop.
      Get.back();
      await tester.pumpAndSettle();

      expect(find.text('guarded'), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });
  });

  group('3373', () {
    tearDown(Get.reset);

    testWidgets('drags beyond the configured gestureWidth do not pop', (
      tester,
    ) async {
      await tester.pumpWidget(n2BuildApp());
      await tester.pumpAndSettle();

      Get.toNamed('/second');
      await tester.pumpAndSettle();

      await tester.flingFrom(
        const Offset(400, 300),
        const Offset(350, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('second'), findsOneWidget);
      expect(find.text('first'), findsNothing);
    });

    testWidgets('drags inside the configured gestureWidth pop the route', (
      tester,
    ) async {
      await tester.pumpWidget(n2BuildApp());
      await tester.pumpAndSettle();

      Get.toNamed('/second');
      await tester.pumpAndSettle();

      await tester.flingFrom(const Offset(40, 300), const Offset(700, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('first'), findsOneWidget);
      expect(find.text('second'), findsNothing);
    });
  });

  group('3436', () {
    testWidgets("Get.back pops only the pageless route pushed over a page", (
      tester,
    ) async {
      await tester.pumpWidget(
        Wrapper(
          initialRoute: '/home',
          namedRoutes: [
            GetPage(name: '/home', page: () => const Text('home')),
            GetPage(name: '/second', page: () => const Text('second')),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/second');
      await tester.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);

      Navigator.of(
        Get.context!,
      ).push(MaterialPageRoute(builder: (_) => const Text('pageless')));
      await tester.pumpAndSettle();
      expect(find.text('pageless'), findsOneWidget);

      Get.back();
      await tester.pumpAndSettle();

      // Only the pageless route must be gone; /second must survive.
      expect(find.text('pageless'), findsNothing);
      expect(find.text('second'), findsOneWidget);
      expect(Get.currentRoute, '/second');

      // A second back still pops pages declaratively.
      Get.back();
      await tester.pumpAndSettle();
      expect(find.text('home'), findsOneWidget);
      expect(Get.currentRoute, '/home');
    });

    testWidgets("Get.back pops a pageless route over the only page", (
      tester,
    ) async {
      await tester.pumpWidget(
        Wrapper(
          initialRoute: '/home',
          namedRoutes: [GetPage(name: '/home', page: () => const Text('home'))],
        ),
      );
      await tester.pumpAndSettle();

      Navigator.of(
        Get.context!,
      ).push(MaterialPageRoute(builder: (_) => const Text('pageless')));
      await tester.pumpAndSettle();
      expect(find.text('pageless'), findsOneWidget);

      Get.back();
      await tester.pumpAndSettle();

      expect(find.text('pageless'), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets("system back pops only the pageless route pushed over a page", (
      tester,
    ) async {
      await tester.pumpWidget(
        Wrapper(
          initialRoute: '/home',
          namedRoutes: [
            GetPage(name: '/home', page: () => const Text('home')),
            GetPage(name: '/second', page: () => const Text('second')),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/second');
      await tester.pumpAndSettle();

      Navigator.of(
        Get.context!,
      ).push(MaterialPageRoute(builder: (_) => const Text('pageless')));
      await tester.pumpAndSettle();
      expect(find.text('pageless'), findsOneWidget);

      // Simulates the Android system back button / predictive back gesture.
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/navigation',
        const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
        (_) {},
      );
      await tester.pumpAndSettle();

      expect(find.text('pageless'), findsNothing);
      expect(find.text('second'), findsOneWidget);
      expect(Get.currentRoute, '/second');
    });

    testWidgets("edge-swipe pops an imperatively pushed GetPageRoute", (
      tester,
    ) async {
      await tester.pumpWidget(
        Wrapper(
          initialRoute: '/home',
          namedRoutes: [GetPage(name: '/home', page: () => const Text('home'))],
        ),
      );
      await tester.pumpAndSettle();

      Navigator.of(Get.context!).push(
        GetPageRoute(
          page: () => const Text('pageless'),
          popGesture: true,
          transition: Transition.rightToLeft,
          routeName: '/pageless',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('pageless'), findsOneWidget);

      // Drag from the left edge past the middle of the screen and release.
      final gesture = await tester.startGesture(const Offset(10, 300));
      await gesture.moveBy(const Offset(500, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('pageless'), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });
  });

  group('3452', () {
    testWidgets('GetPageRoute.canTransitionTo accepts a non-fullscreenDialog '
        'MaterialPageRoute (issue #3452)', (tester) async {
      final getRoute = GetPageRoute<void>(
        page: () => const Scaffold(body: Text('first')),
      );
      final materialRoute = MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('second')),
      );
      final materialDialogRoute = MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const Scaffold(body: Text('dialog')),
      );

      expect(getRoute.canTransitionTo(materialRoute), isTrue);
      expect(getRoute.canTransitionTo(materialDialogRoute), isFalse);
    });

    testWidgets(
      'outgoing GetPageRoute animates (secondaryAnimation runs) when a '
      'MaterialPageRoute is pushed on top (issue #3452)',
      (tester) async {
        await tester.pumpWidget(
          GetMaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const Scaffold(body: Text('second')),
                      ),
                    );
                  },
                  child: const Text('push'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final firstRoute =
            ModalRoute.of(tester.element(find.text('push')))!
                as PageRoute<void>;
        expect(
          firstRoute.secondaryAnimation!.status,
          AnimationStatus.dismissed,
        );

        await tester.tap(find.text('push'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Mid-transition the outgoing route's secondary animation must be
        // driven; if canTransitionTo rejects the MaterialPageRoute it stays
        // dismissed and the previous page appears frozen.
        expect(
          firstRoute.secondaryAnimation!.status,
          isNot(AnimationStatus.dismissed),
        );

        await tester.pumpAndSettle();
        expect(find.text('second'), findsOneWidget);
      },
    );
  });
}
