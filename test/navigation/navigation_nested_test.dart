import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

// (and its duplicate #2011): navigating from a nested child to an unrelated
// top-level route removed the nested shell (a page marked with
// participatesInRootNavigator: true) from the root navigator, destroying its
// state and its nested navigator; popping back rebuilt it from scratch.

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static int initCount = 0;
  static int disposeCount = 0;

  static void resetCounters() {
    initCount = 0;
    disposeCount = 0;
  }

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  @override
  void initState() {
    super.initState();
    HomeShell.initCount++;
  }

  @override
  void dispose() {
    HomeShell.disposeCount++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const Text('home-shell'),
          Expanded(
            child: GetRouterOutlet(
              anchorRoute: '/home',
              initialRoute: '/home/login',
            ),
          ),
        ],
      ),
    );
  }
}

GetMaterialApp n0BuildApp() {
  return GetMaterialApp(
    initialRoute: '/home/login',
    getPages: [
      GetPage(
        name: '/home',
        participatesInRootNavigator: true,
        page: () => const HomeShell(),
        children: [
          GetPage(name: '/login', page: () => const Text('login-view')),
          GetPage(name: '/news', page: () => const Text('news-view')),
        ],
      ),
      GetPage(name: '/setting', page: () => const Text('setting-view')),
    ],
  );
}

// (and its duplicate #2638): with doubly nested GetRouterOutlets, the outer
// outlet leaked the pages hosted by the deeper outlet into its own
// navigator, stacking them over the deeper outlet's host page so the inner
// router (and its surrounding chrome) disappeared.

Widget homeShell() {
  return Column(
    children: [
      const Text('home-shell'),
      Expanded(
        child: GetRouterOutlet(
          anchorRoute: '/home',
          initialRoute: '/home/settings',
        ),
      ),
    ],
  );
}

Widget settingsShell() {
  return Column(
    children: [
      const Text('settings-shell'),
      Expanded(
        child: GetRouterOutlet(
          anchorRoute: '/home/settings',
          initialRoute: '/home/settings/profile',
        ),
      ),
    ],
  );
}

GetMaterialApp n1BuildApp() {
  return GetMaterialApp(
    initialRoute: '/home/settings',
    getPages: [
      GetPage(
        name: '/home',
        participatesInRootNavigator: true,
        page: () => Scaffold(body: homeShell()),
        children: [
          GetPage(
            name: '/settings',
            page: settingsShell,
            children: [
              GetPage(name: '/profile', page: () => const Text('profile-view')),
              GetPage(name: '/account', page: () => const Text('account-view')),
            ],
          ),
        ],
      ),
    ],
  );
}

// navigator attached the HeroController installed by MaterialApp.router's
// HeroControllerScope — the same controller already attached to the root
// navigator — triggering Flutter's "A HeroController can not be shared by
// multiple Navigators" report and corrupting hero flights. Each outlet
// navigator now lives under its own persistent HeroControllerScope.

const n2ShuttleKey = ValueKey('hero-flight-shuttle');

Widget n2ShuttleBuilder(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  return const SizedBox(key: n2ShuttleKey, width: 100, height: 100);
}

Widget heroBox(double size) {
  return Hero(
    tag: 'hero',
    flightShuttleBuilder: n2ShuttleBuilder,
    child: SizedBox(width: size, height: size),
  );
}

GetMaterialApp n2BuildApp() {
  return GetMaterialApp(
    initialRoute: '/home/list',
    getPages: [
      GetPage(
        name: '/home',
        participatesInRootNavigator: true,
        page: () => Scaffold(
          body: GetRouterOutlet(
            anchorRoute: '/home',
            initialRoute: '/home/list',
          ),
        ),
        children: [
          GetPage(
            name: '/list',
            page: () => Scaffold(body: heroBox(100)),
            children: [
              GetPage(
                name: '/detail',
                page: () => Scaffold(body: Center(child: heroBox(50))),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

const n3ShuttleKey = ValueKey('hero-flight-shuttle');

Widget n3ShuttleBuilder(
  BuildContext flightContext,
  Animation<double> animation,
  HeroFlightDirection flightDirection,
  BuildContext fromHeroContext,
  BuildContext toHeroContext,
) {
  return const SizedBox(key: n3ShuttleKey, width: 100, height: 100);
}

GetMaterialApp n3BuildApp() {
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
        page: () => Scaffold(
          body: Hero(
            tag: 'hero',
            transitionOnUserGestures: true,
            flightShuttleBuilder: n3ShuttleBuilder,
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      ),
      GetPage(
        name: '/second',
        popGesture: true,
        page: () => Scaffold(
          body: Center(
            child: Hero(
              tag: 'hero',
              transitionOnUserGestures: true,
              flightShuttleBuilder: n3ShuttleBuilder,
              child: const SizedBox(width: 50, height: 50),
            ),
          ),
        ),
      ),
    ],
  );
}

class UnknownScreen extends StatelessWidget {
  const UnknownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('not found'));
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('root'));
  }
}

class N4SecondScreen extends StatelessWidget {
  const N4SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('second'));
  }
}

void main() {
  group('3336', () {
    setUp(HomeShell.resetCounters);
    tearDown(Get.reset);

    testWidgets('nested shell renders its current child', (tester) async {
      await tester.pumpWidget(n0BuildApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('home-shell'), findsOneWidget);
      expect(find.text('login-view'), findsOneWidget);
      expect(HomeShell.initCount, 1);
    });

    testWidgets(
      'pushing an unrelated top-level route keeps the nested shell mounted',
      (tester) async {
        await tester.pumpWidget(n0BuildApp());
        await tester.pumpAndSettle();

        Get.rootController.rootDelegate.toNamed('/home/news');
        await tester.pumpAndSettle();
        expect(find.text('news-view'), findsOneWidget);

        Get.rootController.rootDelegate.toNamed('/setting');
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('setting-view'), findsOneWidget);
        // Before the fix the root navigator stack was derived only from the
        // current history entry's branch, so pushing /setting unmounted the
        // home shell (and its nested navigator) entirely.
        expect(HomeShell.disposeCount, 0);
        expect(HomeShell.initCount, 1);
      },
    );

    testWidgets(
      'popping back to the nested shell restores its preserved child',
      (tester) async {
        await tester.pumpWidget(n0BuildApp());
        await tester.pumpAndSettle();

        Get.rootController.rootDelegate.toNamed('/home/news');
        await tester.pumpAndSettle();
        Get.rootController.rootDelegate.toNamed('/setting');
        await tester.pumpAndSettle();

        Get.rootController.rootDelegate.back();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // The nested navigator kept the child selected before /setting was
        // pushed; before the fix the shell was recreated and reset to its
        // initialRoute.
        expect(find.text('news-view'), findsOneWidget);
        expect(find.text('setting-view'), findsNothing);
        expect(HomeShell.initCount, 1);
        expect(HomeShell.disposeCount, 0);
      },
    );
  });

  group('3347', () {
    tearDown(Get.reset);

    testWidgets('doubly nested outlets render without errors', (tester) async {
      await tester.pumpWidget(n1BuildApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('home-shell'), findsOneWidget);
      expect(find.text('settings-shell'), findsOneWidget);
      expect(find.text('profile-view'), findsOneWidget);
    });

    testWidgets(
      'navigating inside the deeper outlet keeps the inner router visible',
      (tester) async {
        await tester.pumpWidget(n1BuildApp());
        await tester.pumpAndSettle();

        Get.rootController.rootDelegate.toNamed('/home/settings/account');
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // The deep page must be hosted only by the inner outlet; before the
        // fix it was also pushed inside the outer outlet's navigator, covering
        // the settings shell (the inner router "disappeared").
        expect(find.text('home-shell'), findsOneWidget);
        expect(find.text('settings-shell'), findsOneWidget);
        expect(find.text('account-view'), findsOneWidget);
        expect(find.text('profile-view'), findsNothing);
      },
    );

    testWidgets('navigating back to the first inner child works', (
      tester,
    ) async {
      await tester.pumpWidget(n1BuildApp());
      await tester.pumpAndSettle();

      Get.rootController.rootDelegate.toNamed('/home/settings/account');
      await tester.pumpAndSettle();
      Get.rootController.rootDelegate.toNamed('/home/settings/profile');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('settings-shell'), findsOneWidget);
      expect(find.text('profile-view'), findsOneWidget);
      expect(find.text('account-view'), findsNothing);
    });
  });

  group('3350 Nested Outlet Hero', () {
    tearDown(Get.reset);

    testWidgets('nested outlet navigator owns its own HeroControllerScope', (
      tester,
    ) async {
      await tester.pumpWidget(n2BuildApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      final controllers = tester
          .widgetList<HeroControllerScope>(find.byType(HeroControllerScope))
          .map((scope) => scope.controller)
          .whereType<HeroController>()
          .toList();
      // One scope from MaterialApp.router (root navigator) and one from the
      // nested outlet; sharing a single controller between both navigators is
      // exactly the reported defect.
      expect(controllers.length, greaterThanOrEqualTo(2));
      expect(controllers.toSet().length, controllers.length);
    });

    testWidgets('push inside a nested outlet starts exactly one hero flight', (
      tester,
    ) async {
      await tester.pumpWidget(n2BuildApp());
      await tester.pumpAndSettle();

      Get.rootController.rootDelegate.toNamed('/home/list/detail');
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pump(const Duration(milliseconds: 40));

      expect(tester.takeException(), isNull);
      expect(find.byKey(n2ShuttleKey), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byKey(n2ShuttleKey), findsNothing);
    });
  });

  group('3350', () {
    tearDown(Get.reset);

    test('GetNavigator does not register its own HeroController', () {
      final navigator = GetNavigator(
        pages: const [MaterialPage(child: SizedBox())],
      );
      expect(navigator.observers.whereType<HeroController>(), isEmpty);
    });

    testWidgets('push starts exactly one hero flight', (tester) async {
      await tester.pumpWidget(n3BuildApp());
      await tester.pumpAndSettle();

      Get.toNamed('/second');
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pump(const Duration(milliseconds: 40));

      expect(find.byKey(n3ShuttleKey), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byKey(n3ShuttleKey), findsNothing);
    });

    testWidgets(
      'gesture back starts exactly one hero flight with transitionOnUserGestures',
      (tester) async {
        await tester.pumpWidget(n3BuildApp());
        await tester.pumpAndSettle();

        Get.toNamed('/second');
        await tester.pumpAndSettle();

        final gesture = await tester.startGesture(const Offset(10, 300));
        await gesture.moveBy(const Offset(500, 0));
        await tester.pump();

        expect(find.byKey(n3ShuttleKey), findsOneWidget);

        await gesture.up();
        await tester.pumpAndSettle();
        expect(find.byKey(n3ShuttleKey), findsNothing);
      },
    );

    testWidgets('back gesture reports a user gesture to the navigator', (
      tester,
    ) async {
      await tester.pumpWidget(n3BuildApp());
      await tester.pumpAndSettle();

      Get.toNamed('/second');
      await tester.pumpAndSettle();

      final navigator = tester.state<NavigatorState>(find.byType(GetNavigator));
      expect(navigator.userGestureInProgress, isFalse);

      final gesture = await tester.startGesture(const Offset(10, 300));
      await gesture.moveBy(const Offset(100, 0));
      await tester.pump();

      expect(navigator.userGestureInProgress, isTrue);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(navigator.userGestureInProgress, isFalse);
    });
  });

  group('3352', () {
    tearDown(Get.reset);

    test(
      'matchRoute does not treat a partial ancestor match as a full match',
      () {
        final tree = ParseRouteTree(routes: <GetPage>[]);
        tree.addRoutes([
          GetPage(name: '/', page: () => Container()),
          GetPage(name: '/second', page: () => Container()),
        ]);

        final match = tree.matchRoute('/unknown');
        expect(match.route, isNull);

        final nested = tree.matchRoute('/second/nowhere');
        expect(nested.route, isNull);

        // full matches keep working
        expect(tree.matchRoute('/').route?.name, '/');
        expect(tree.matchRoute('/second').route?.name, '/second');
      },
    );

    testWidgets(
      'unknownRoute is shown for unregistered names even when a "/" page exists',
      (tester) async {
        await tester.pumpWidget(
          GetMaterialApp(
            initialRoute: '/',
            unknownRoute: GetPage(
              name: '/notfound',
              page: () => const UnknownScreen(),
            ),
            getPages: [
              GetPage(name: '/', page: () => const RootScreen()),
              GetPage(name: '/second', page: () => const N4SecondScreen()),
            ],
          ),
        );

        Get.toNamed('/route-that-does-not-exist');
        await tester.pumpAndSettle();

        expect(find.byType(UnknownScreen), findsOneWidget);
        expect(find.byType(RootScreen), findsNothing);
        expect(Get.currentRoute, '/notfound');
      },
    );
  });
}
