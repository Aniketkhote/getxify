import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';
import 'utils/wrapper.dart';

final log = <String>[];

class RedirectPriorityMiddleware extends GetMiddleware {
  RedirectPriorityMiddleware(this.tag, {required super.priority, this.target});

  final String tag;
  final String? target;

  @override
  RouteSettings? redirect(String? route) {
    log.add(tag);
    return target == null ? null : RouteSettings(name: target);
  }
}

class DelegateOrderMiddleware extends GetMiddleware {
  DelegateOrderMiddleware(this.tag, {required super.priority});

  final String tag;

  @override
  FutureOr<RouteDecoder?> redirectDelegate(RouteDecoder route) {
    log.add(tag);
    return route;
  }
}

class N0Home extends StatelessWidget {
  const N0Home({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('home'));
  }
}

class MultiScreen extends StatelessWidget {
  const MultiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('multi'));
  }
}

class AScreen extends StatelessWidget {
  const AScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('a'));
  }
}

class BScreen extends StatelessWidget {
  const BScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('b'));
  }
}

//
// Pushing a route with Transition.downToUp used to play the previous
// page's secondary (parallax) animation, sliding it away and revealing the
// navigator's black background behind both pages while the new page was
// still rising from the bottom. The outgoing page must stay in place, the
// same way it does for a fullscreen dialog.
GetMaterialApp n1BuildApp() {
  return GetMaterialApp(
    initialRoute: '/first',
    getPages: [
      GetPage(
        name: '/first',
        // Cupertino plays a horizontal parallax on the outgoing page, which
        // is exactly what revealed the background in the report.
        transition: Transition.cupertino,
        page: () => const Scaffold(body: Text('first')),
      ),
      GetPage(
        name: '/second',
        transition: Transition.downToUp,
        transitionDuration: const Duration(milliseconds: 300),
        page: () => const Scaffold(body: Text('second')),
      ),
    ],
  );
}

// returning the same widget type produce the same auto-generated route
// name, and the second Get.to used to rebuild the first page ("nothing
// happens") because the route tree lookup resolved to the stale first
// registration.

class FirstBody extends StatelessWidget {
  const FirstBody({super.key});

  @override
  Widget build(BuildContext context) => const Text('first body');
}

class SecondBody extends StatelessWidget {
  const SecondBody({super.key});

  @override
  Widget build(BuildContext context) => const Text('second body');
}

GetMaterialApp n3BuildApp() {
  return GetMaterialApp(
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
        transition: Transition.leftToRight,
        page: () => const Scaffold(body: Text('second')),
      ),
    ],
  );
}

//
// SnackbarController.closeCurrentSnackbar and cancelAllSnackbars now accept
// a withAnimations flag, forwarded to SnackbarController.close, so the
// current snackbar can be dismissed without playing its exit animation.

class _PingIntent extends Intent {
  const _PingIntent();
}

// anchored at the same route shares one nested-delegate GlobalKey, so two
// simultaneously mounted outlets for that anchor (duplicate shell pages
// stacked in the root navigator) crashed with "Multiple widgets used the
// same GlobalKey" as soon as both rebuilt in the same frame. The shared key
// is now attached to the most recently mounted outlet only.

Widget shell() {
  return Scaffold(
    body: Column(
      children: [
        const Text('shell'),
        Expanded(
          child: GetRouterOutlet(
            anchorRoute: '/home',
            initialRoute: '/home/tab1',
          ),
        ),
      ],
    ),
  );
}

GetMaterialApp n7BuildApp() {
  return GetMaterialApp(
    initialRoute: '/home',
    getPages: [
      GetPage(
        name: '/home',
        participatesInRootNavigator: true,
        page: shell,
        children: [
          GetPage(name: '/tab1', page: () => const Text('tab1-view')),
          GetPage(name: '/tab2', page: () => const Text('tab2-view')),
        ],
      ),
    ],
  );
}

/// The navigators currently carrying the shared nested key for `/home`.
Iterable<Navigator> sharedKeyNavigators(WidgetTester tester) {
  final sharedKey = Get.nestedKey('/home')!.navigatorKey;
  return tester
      .widgetList<Navigator>(find.bySubtype<Navigator>(skipOffstage: false))
      .where((navigator) => navigator.key == sharedKey);
}

// a GetRouterOutlet without anchorRoute keyed its nested navigator with the
// ROOT delegate's GlobalKey (Get.nestedKey(null) returns the root delegate),
// so the same GlobalKey was mounted by two navigators at once — an immediate
// duplicate-GlobalKey failure.

class NullOnPageCalledMiddleware extends GetMiddleware {
  @override
  GetPage? onPageCalled(GetPage? page) => null;
}

class N9Home extends StatelessWidget {
  const N9Home({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('home'));
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('main'));
  }
}

class BlockingMiddleware extends GetMiddleware {
  @override
  Future<RouteDecoder?> redirectDelegate(RouteDecoder route) async => null;
}

class GuardedScreen extends StatelessWidget {
  const GuardedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('guarded'));
  }
}

class OtherScreen extends StatelessWidget {
  const OtherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('other'));
  }
}

//
// GetSnackBar used physical EdgeInsets.only(left:, right:) for the
// title/message and action-button paddings, so under RTL the small
// icon-adjacent inset ended up on the wrong physical side, doubling the
// visual gap between the icon and the text.

//
// Transition.predictiveBack opts a single route into Flutter's
// PredictiveBackPageTransitionsBuilder without configuring the theme's
// pageTransitionsTheme, mirroring how Transition.native delegates to the
// theme builders.
GetMaterialApp n14BuildApp() {
  return GetMaterialApp(
    initialRoute: '/first',
    getPages: [
      GetPage(
        name: '/first',
        page: () => const Scaffold(body: Text('first')),
      ),
      GetPage(
        name: '/second',
        transition: Transition.predictiveBack,
        page: () => const Scaffold(body: Text('second')),
      ),
    ],
  );
}

// a nested page marked with participatesInRootNavigator: true was rendered
// by the root navigator AND picked by the GetRouterOutlet anchored on its
// parent, mounting the page (and its controllers) twice.

GetMaterialApp n15BuildApp() {
  return GetMaterialApp(
    initialRoute: '/',
    getPages: [
      GetPage(
        name: '/',
        participatesInRootNavigator: true,
        page: () => Scaffold(
          body: Column(
            children: [
              const Text('root-shell'),
              Expanded(
                child: GetRouterOutlet(anchorRoute: '/', initialRoute: '/home'),
              ),
            ],
          ),
        ),
        children: [
          GetPage(name: '/home', page: () => const Text('home-view')),
          GetPage(
            name: '/settings',
            participatesInRootNavigator: true,
            page: () => const Text('settings-view'),
          ),
        ],
      ),
    ],
  );
}

// Get.dialog should expose a transitionBuilder so a custom animation can
// be used without dropping down to Get.generalDialog.
class _DialogContent extends StatelessWidget {
  const _DialogContent();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 50, height: 50);
  }
}

//
// Transition.circularReveal hardcoded maxRadius: 800, so on screens whose
// half-diagonal exceeds 800 logical pixels (iPad Pro 12.9, large desktop
// windows) the reveal circle never covered the corners, leaving them
// permanently clipped (black). The clipper must fall back to its computed
// maximum radius so the circle always covers the full page.

/// Mirrors the issue's repro: the middleware requires a `tabUID` query
/// parameter and redirects to the same location with the parameter added.
/// The redirect can only settle when the parameters added by the redirect
/// are visible through `Get.parameters` on the next middleware pass.
class TabUidMiddleware extends GetMiddleware {
  int attempts = 0;
  String? seenTabUid;
  String? seenId;

  @override
  RouteSettings? redirect(String? route) {
    attempts++;
    if (attempts > 6) {
      // Safety valve: a stale-parameters regression would otherwise loop
      // forever; give up so the test fails with assertions instead of
      // hanging.
      return null;
    }
    seenId ??= Get.parameters['id'];
    final tabUid = Get.parameters['tabUID'];
    if (tabUid == null) {
      return const RouteSettings(name: '/page2/2333?tabUID=abc123');
    }
    seenTabUid = tabUid;
    return null;
  }
}

class N18Home extends StatelessWidget {
  const N18Home({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('home'));
  }
}

class Page2 extends StatelessWidget {
  const Page2({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('page2'));
  }
}

class CountingMiddleware extends GetMiddleware {
  int builtCount = 0;
  int disposeCount = 0;
  final guardedRoutes = <String?>[];

  @override
  RouteSettings? redirect(String? route) {
    guardedRoutes.add(route);
    return null;
  }

  @override
  Widget onPageBuilt(Widget page) {
    builtCount++;
    return page;
  }

  @override
  void onPageDispose() {
    disposeCount++;
  }
}

class ParentScreen extends StatelessWidget {
  const ParentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('parent'));
  }
}

class ChildScreen extends StatelessWidget {
  const ChildScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('child'));
  }
}

// Get.defaultDialog should accept a canPop argument that blocks the
// system back gesture/button from dismissing the dialog.

//
// The iOS back swipe was accepted anywhere on screen by default, hijacking
// horizontal gestures (sliders, carousels...). By default the drag must now
// only start near the edge the page entered from, like the native iOS
// back gesture. Routes that explicitly opt in with `popGesture: true` keep
// the historical full-screen swipe area.
GetMaterialApp n21BuildApp({
  bool? routePopGesture,
  double Function(BuildContext)? gestureWidth,
}) {
  return GetMaterialApp(
    // Cupertino keeps the same transition subtree while a user gesture is
    // in progress; the default Android builders swap subtrees mid-gesture.
    defaultTransition: Transition.cupertino,
    popGesture: true,
    initialRoute: '/first',
    getPages: [
      GetPage(
        name: '/first',
        page: () => const Scaffold(body: Text('first')),
      ),
      GetPage(
        name: '/second',
        popGesture: routePopGesture,
        gestureWidth: gestureWidth,
        page: () => const Scaffold(body: Text('second')),
      ),
    ],
  );
}

// root GetDelegate applies the path URL strategy; doing so more than once
// per process (remounting GetRoot, hot restart) crashed with the engine
// assertion "Cannot set URL strategy a second time or after the app has
// been initialized". Run with: flutter test --platform chrome
// A single tester.pumpWidget of a GetMaterialApp must already render the
// initial page (v4 behavior), instead of requiring an extra pump for the
// router to asynchronously resolve the initial route.

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('home'));
  }
}

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('login'));
  }
}

class RedirectMiddleware extends GetMiddleware {
  @override
  Future<RouteDecoder?> redirectDelegate(RouteDecoder route) async {
    return RouteDecoder.fromRoute('/login');
  }
}

// The very first route information report after startup must be sent to
// the engine with replace semantics. Reporting it as a push creates a
// phantom browser history entry on plain page load (the Safari/Chrome back
// button lights up on accessing index.html).

class N24FirstPage extends StatelessWidget {
  const N24FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('first'));
  }
}

class N24SecondPage extends StatelessWidget {
  const N24SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('second'));
  }
}

GetMaterialApp n24BuildApp() {
  return GetMaterialApp(
    initialRoute: '/first',
    getPages: [
      GetPage(name: '/first', page: () => const N24FirstPage()),
      GetPage(name: '/second', page: () => const N24SecondPage()),
    ],
  );
}

/// Captures the `routeInformationUpdated` messages the framework sends to
/// the engine (the same messages that drive the browser history on web).
List<Map<dynamic, dynamic>> n24CaptureRouteInformationUpdates(
  WidgetTester tester,
) {
  final updates = <Map<dynamic, dynamic>>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.navigation,
    (call) async {
      if (call.method == 'routeInformationUpdated') {
        updates.add(call.arguments as Map<dynamic, dynamic>);
      }
      return null;
    },
  );
  addTearDown(() {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.navigation,
      null,
    );
  });
  return updates;
}

const markerKey = ValueKey('custom-page-transitions-builder');

/// A [PageTransitionsBuilder] that tags the transition subtree with
/// [markerKey], so tests can detect whether the app theme's
/// [PageTransitionsTheme] was actually consulted.
class MarkerPageTransitionsBuilder extends PageTransitionsBuilder {
  const MarkerPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return KeyedSubtree(key: markerKey, child: child);
  }
}

GetMaterialApp n25BuildApp() {
  return GetMaterialApp(
    theme: ThemeData(
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const MarkerPageTransitionsBuilder(),
        },
      ),
    ),
    initialRoute: '/first',
    getPages: [
      GetPage(
        name: '/first',
        page: () => const Scaffold(body: Text('first')),
      ),
      GetPage(
        name: '/second',
        page: () => const Scaffold(body: Text('second')),
      ),
    ],
  );
}

// GetPage/GetPageRoute must expose PageRoute.allowSnapshotting so route
// transition snapshotting can be disabled per page (e.g. for pages whose
// content keeps animating during transitions).

BuildContext? capturedContext;

class SnapshotlessPage extends StatelessWidget {
  const SnapshotlessPage({super.key});

  @override
  Widget build(BuildContext context) {
    capturedContext = context;
    return const Scaffold(body: Text('snapshotless'));
  }
}

class N27Home extends StatelessWidget {
  const N27Home({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('home'));
  }
}

class Second extends StatelessWidget {
  const Second({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('second'));
  }
}

class RedirectToUnregisteredMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    return const RouteSettings(name: '/route-that-is-not-registered');
  }
}

class N28FirstScreen extends StatelessWidget {
  const N28FirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('first'));
  }
}

class N28SecondScreen extends StatelessWidget {
  const N28SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('second'));
  }
}

class N29FirstPage extends StatelessWidget {
  const N29FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('first'));
  }
}

class N29SecondPage extends StatelessWidget {
  const N29SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('second'));
  }
}

class N29ThirdPage extends StatelessWidget {
  const N29ThirdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('third'));
  }
}

GetMaterialApp n29BuildApp() {
  return GetMaterialApp(
    initialRoute: '/first',
    getPages: [
      GetPage(name: '/first', page: () => const N29FirstPage()),
      GetPage(name: '/second', page: () => const N29SecondPage()),
      GetPage(name: '/third', page: () => const N29ThirdPage()),
    ],
  );
}

/// Captures the `routeInformationUpdated` messages the framework sends to
/// the engine (the same messages that drive the browser history on web).
List<Map<dynamic, dynamic>> n29CaptureRouteInformationUpdates(
  WidgetTester tester,
) {
  final updates = <Map<dynamic, dynamic>>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.navigation,
    (call) async {
      if (call.method == 'routeInformationUpdated') {
        updates.add(call.arguments as Map<dynamic, dynamic>);
      }
      return null;
    },
  );
  addTearDown(() {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.navigation,
      null,
    );
  });
  return updates;
}

/// Simulates the platform (browser back/forward button or a deep link)
/// reporting a new route to the app.
Future<void> n29SimulatePlatformRoute(
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

void main() {
  // Base routes_test.dart tests
  // testWidgets('Back swipe dismiss interrupted by route push',
  // (tester) async {
  //   // final scaffoldKey = GlobalKey();

  //   await tester.pumpWidget(
  //     GetCupertinoApp(
  //       popGesture: true,
  //       home: CupertinoPageScaffold(
  //         // key: scaffoldKey,
  //         child: Center(
  //           child: CupertinoButton(
  //             onPressed: () {
  //               Get.to(
  //                   () => CupertinoPageScaffold(
  //                         child: Center(child: Text('route')),
  //                       ),
  //                   preventDuplicateHandlingMode:
  //                       PreventDuplicateHandlingMode.Recreate);
  //             },
  //             child: const Text('push'),
  //           ),
  //         ),
  //       ),
  //     ),
  //   );

  //   await tester.pumpAndSettle();

  //   // Check the basic iOS back-swipe dismiss transition. Dragging the pushed
  //   // route halfway across the screen will trigger the iOS dismiss animation

  //   await tester.tap(find.text('push'));
  //   await tester.pumpAndSettle();
  //   expect(find.text('route'), findsOneWidget);
  //   expect(find.text('push'), findsNothing);

  //   var gesture = await tester.startGesture(const Offset(5, 300));
  //   await gesture.moveBy(const Offset(400, 0));
  //   await gesture.up();
  //   await tester.pump();
  //   expect(
  //     // The 'route' route has been dragged to the right, halfway across
  //     // the screen
  //     tester.getTopLeft(find.ancestor(
  //         of: find.text('route'),
  //         matching: find.byType(CupertinoPageScaffold))),
  //     const Offset(400, 0),
  //   );
  //   expect(
  //     // The 'push' route is sliding in from the left.
  //     tester
  //         .getTopLeft(find.ancestor(
  //             of: find.text('push'),
  //             matching: find.byType(CupertinoPageScaffold)))
  //         .dx,
  //     moreOrLessEquals(-(400 / 3), epsilon: 1),
  //   );
  //   await tester.pumpAndSettle();
  //   expect(find.text('push'), findsOneWidget);
  //   expect(
  //     tester.getTopLeft(find.ancestor(
  //         of: find.text('push'),
  // matching: find.byType(CupertinoPageScaffold))),
  //     Offset.zero,
  //   );
  //   expect(find.text('route'), findsNothing);

  //   // Run the dismiss animation 60%, which exposes the route "push" button,
  //   // and then press the button.

  //   await tester.tap(find.text('push'));
  //   await tester.pumpAndSettle();
  //   expect(find.text('route'), findsOneWidget);
  //   expect(find.text('push'), findsNothing);

  //   gesture = await tester.startGesture(const Offset(5, 300));
  //   await gesture.moveBy(const Offset(400, 0)); // Drag halfway.
  //   await gesture.up();
  //   // Trigger the snapping animation.
  //   // Since the back swipe drag was brought to >=50% of the screen, it will
  //   // self snap to finish the pop transition as the gesture is lifted.
  //   //
  //   // This drag drop animation is 400ms when dropped exactly halfway
  //   // (800 / [pixel distance remaining], see
  //   // _CupertinoBackGestureController.dragEnd). It follows a curve that is very
  //   // steep initially.
  //   await tester.pump();
  //   expect(
  //     tester.getTopLeft(find.ancestor(
  //         of: find.text('route'),
  //         matching: find.byType(CupertinoPageScaffold))),
  //     const Offset(400, 0),
  //   );
  //   // Let the dismissing snapping animation go 60%.
  //   await tester.pump(const Duration(milliseconds: 240));
  //   expect(
  //     tester
  //         .getTopLeft(find.ancestor(
  //             of: find.text('route'),
  //             matching: find.byType(CupertinoPageScaffold)))
  //         .dx,
  //     moreOrLessEquals(798, epsilon: 1),
  //   );
  // });

  group('1298', () {
    setUp(log.clear);
    tearDown(Get.reset);

    testWidgets(
      'middlewares run in priority order and the first redirect wins',
      (tester) async {
        await tester.pumpWidget(
          GetMaterialApp(
            initialRoute: '/',
            getPages: [
              GetPage(name: '/', page: () => const N0Home()),
              GetPage(
                name: '/multi',
                page: () => const MultiScreen(),
                // Declared out of priority order on purpose.
                middlewares: [
                  RedirectPriorityMiddleware('p5', priority: 5, target: '/b'),
                  RedirectPriorityMiddleware('p1', priority: 1, target: '/a'),
                ],
              ),
              GetPage(name: '/a', page: () => const AScreen()),
              GetPage(name: '/b', page: () => const BScreen()),
            ],
          ),
        );
        await tester.pumpAndSettle();

        Get.toNamed('/multi');
        await tester.pumpAndSettle();

        // The lowest priority value runs first and its redirect stops the
        // chain, so p5 never runs and the navigation lands on '/a'.
        expect(log, ['p1']);
        expect(find.byType(AScreen), findsOneWidget);
        expect(find.byType(BScreen), findsNothing);
        expect(Get.currentRoute, '/a');
      },
    );

    testWidgets('redirectDelegate also runs in priority order', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => const N0Home()),
            GetPage(
              name: '/multi',
              page: () => const MultiScreen(),
              // Declared out of priority order on purpose.
              middlewares: [
                DelegateOrderMiddleware('d4', priority: 4),
                DelegateOrderMiddleware('d2', priority: 2),
              ],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/multi');
      await tester.pumpAndSettle();

      expect(log, ['d2', 'd4']);
      expect(find.byType(MultiScreen), findsOneWidget);
    });
  });

  group('1560', () {
    tearDown(Get.reset);

    testWidgets(
      'the previous page stays in place while a downToUp route slides in',
      (tester) async {
        await tester.pumpWidget(n1BuildApp());
        await tester.pumpAndSettle();

        final firstTopLeft = tester.getTopLeft(find.text('first'));

        Get.toNamed('/second');
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        // Mid-transition the incoming page is still rising from the bottom...
        expect(tester.getTopLeft(find.text('second')).dy, greaterThan(0));
        // ...and the outgoing page must not have moved sideways, which would
        // reveal the navigator background behind both pages.
        expect(
          tester.getTopLeft(find.text('first')),
          firstTopLeft,
          reason:
              'the previous page must not play a parallax animation '
              'under a downToUp route',
        );

        await tester.pumpAndSettle();
        expect(find.text('second'), findsOneWidget);
      },
    );

    testWidgets(
      'the previous page stays in place while a downToUp route pops',
      (tester) async {
        await tester.pumpWidget(n1BuildApp());
        await tester.pumpAndSettle();

        final firstTopLeft = tester.getTopLeft(find.text('first'));

        Get.toNamed('/second');
        await tester.pumpAndSettle();

        Get.back();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        expect(tester.getTopLeft(find.text('first')), firstTopLeft);

        await tester.pumpAndSettle();
        expect(find.text('first'), findsOneWidget);
        expect(find.text('second'), findsNothing);
      },
    );
  });

  group('2161 Same Wrapper Type', () {
    testWidgets(
      'Get.to navigates when two closures share the same wrapper widget type',
      (tester) async {
        await tester.pumpWidget(const Wrapper(child: Text('home')));
        await tester.pumpAndSettle();

        // Both closures have the static type `Directionality Function()`, so
        // they collide on the same auto-generated route name.
        Get.to(
          () => const Directionality(
            textDirection: TextDirection.ltr,
            child: FirstBody(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('first body'), findsOneWidget);

        Get.to(
          () => const Directionality(
            textDirection: TextDirection.ltr,
            child: SecondBody(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('second body'), findsOneWidget);
        expect(find.text('first body'), findsNothing);
      },
    );

    testWidgets(
      'a superseded Get.to future resolves and cleans its route tree entry',
      (tester) async {
        await tester.pumpWidget(const Wrapper(child: Text('home')));
        await tester.pumpAndSettle();

        final delegate = Get.rootController.rootDelegate;
        final baseline = delegate.registeredRoutes.length;

        var firstResolved = false;
        Get.to(
          () => const Directionality(
            textDirection: TextDirection.ltr,
            child: FirstBody(),
          ),
        )?.then((_) => firstResolved = true);
        await tester.pumpAndSettle();

        Get.to(
          () => const Directionality(
            textDirection: TextDirection.ltr,
            child: SecondBody(),
          ),
        );
        await tester.pumpAndSettle();

        // The first navigation was superseded by the reorder: its future must
        // resolve so its temporary route registration is removed, leaving
        // only the in-flight second one.
        expect(firstResolved, isTrue);
        expect(delegate.registeredRoutes.length, baseline + 1);
      },
    );
  });

  group('2193', () {
    tearDown(Get.reset);

    testWidgets('Transition.leftToRight page follows the finger during a '
        'right-to-left back drag', (tester) async {
      await tester.pumpWidget(n3BuildApp());
      await tester.pumpAndSettle();

      Get.toNamed('/second');
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(const Offset(700, 300));
      await gesture.moveBy(const Offset(-200, 0));
      await tester.pump();

      expect(
        tester.getTopLeft(find.text('second')).dx,
        lessThan(0),
        reason: 'the page must slide towards the leading edge it came from',
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('Transition.leftToRight pops on a right-to-left fling', (
      tester,
    ) async {
      await tester.pumpWidget(n3BuildApp());
      await tester.pumpAndSettle();

      Get.toNamed('/second');
      await tester.pumpAndSettle();

      await tester.flingFrom(
        const Offset(700, 300),
        const Offset(-600, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('first'), findsOneWidget);
      expect(find.text('second'), findsNothing);
    });

    testWidgets('Transition.leftToRight ignores left-to-right drags for pop', (
      tester,
    ) async {
      await tester.pumpWidget(n3BuildApp());
      await tester.pumpAndSettle();

      Get.toNamed('/second');
      await tester.pumpAndSettle();

      await tester.flingFrom(
        const Offset(100, 300),
        const Offset(600, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('second'), findsOneWidget);
      expect(find.text('first'), findsNothing);
    });
  });

  group('2400', () {
    testWidgets(
      'closeCurrentSnackbar(withAnimations: false) closes immediately',
      (tester) async {
        await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));

        Get.rawSnackbar(message: 'hello', duration: const Duration(seconds: 5));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('hello'), findsOneWidget);

        await SnackbarController.closeCurrentSnackbar(withAnimations: false);
        await tester.pump();

        expect(find.text('hello'), findsNothing);
        expect(Get.isSnackbarOpen, false);
      },
    );

    testWidgets('closeCurrentSnackbar() still animates by default', (
      tester,
    ) async {
      await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));

      Get.rawSnackbar(message: 'hello', duration: const Duration(seconds: 5));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('hello'), findsOneWidget);

      SnackbarController.closeCurrentSnackbar();
      await tester.pump();

      // Mid exit animation the snackbar is still on screen.
      expect(find.text('hello'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsNothing);
      expect(Get.isSnackbarOpen, false);
    });

    testWidgets(
      'cancelAllSnackbars(withAnimations: false) closes immediately',
      (tester) async {
        await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));

        Get.rawSnackbar(message: 'hello', duration: const Duration(seconds: 5));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('hello'), findsOneWidget);

        await SnackbarController.cancelAllSnackbars(withAnimations: false);
        await tester.pump();

        expect(find.text('hello'), findsNothing);
        expect(Get.isSnackbarOpen, false);
      },
    );
  });

  group('2597', () {
    testWidgets(
      "Get.currentRoute keeps the page name after dismissing a dialog "
      "stacked over a bottomsheet (issue #2597)",
      (tester) async {
        await tester.pumpWidget(
          WrapperNamed(
            initialRoute: '/home',
            namedRoutes: [
              GetPage(page: () => const Text('home'), name: '/home'),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(Get.currentRoute, '/home');

        Get.bottomSheet(const Text('sheet'));
        await tester.pumpAndSettle();

        Get.dialog(const Text('dialog'));
        await tester.pumpAndSettle();

        expect(Get.isDialogOpen, true);
        expect(Get.isBottomSheetOpen, true);
        expect(Get.currentRoute, '/home');

        Get.backLegacy();
        await tester.pumpAndSettle();

        expect(Get.isDialogOpen, false);
        expect(Get.currentRoute, '/home');
        expect(Get.currentRoute, isNot(startsWith('BOTTOMSHEET')));

        Get.backLegacy();
        await tester.pumpAndSettle();

        expect(Get.isBottomSheetOpen, false);
        expect(Get.currentRoute, '/home');
      },
    );

    testWidgets(
      "Get.currentRoute keeps the page name after dismissing stacked dialogs "
      "(issue #2597)",
      (tester) async {
        await tester.pumpWidget(
          WrapperNamed(
            initialRoute: '/home',
            namedRoutes: [
              GetPage(page: () => const Text('home'), name: '/home'),
            ],
          ),
        );
        await tester.pumpAndSettle();

        Get.dialog(const Text('first dialog'));
        await tester.pumpAndSettle();

        Get.dialog(const Text('second dialog'));
        await tester.pumpAndSettle();

        expect(Get.currentRoute, '/home');

        Get.backLegacy();
        await tester.pumpAndSettle();

        expect(Get.currentRoute, '/home');
        expect(Get.currentRoute, isNot(startsWith('DIALOG')));

        Get.backLegacy();
        await tester.pumpAndSettle();

        expect(Get.isDialogOpen, false);
        expect(Get.currentRoute, '/home');
      },
    );
  });

  group('2615', () {
    tearDown(Get.reset);

    // GetMaterialApp/GetCupertinoApp declared `shortcuts` as
    // Map<LogicalKeySet, Intent>? instead of Map<ShortcutActivator, Intent>?,
    // rejecting SingleActivator/CharacterActivator keys (and
    // WidgetsApp.defaultShortcuts) at compile time even though
    // MaterialApp/CupertinoApp accept the wider type.

    testWidgets(
      'GetMaterialApp accepts Map<ShortcutActivator, Intent> shortcuts',
      (tester) async {
        var pinged = 0;
        final Map<ShortcutActivator, Intent> shortcuts = {
          ...WidgetsApp.defaultShortcuts,
          const SingleActivator(LogicalKeyboardKey.keyP, control: true):
              const _PingIntent(),
        };

        await tester.pumpWidget(
          GetMaterialApp(
            shortcuts: shortcuts,
            home: Scaffold(
              body: Actions(
                actions: {
                  _PingIntent: CallbackAction<_PingIntent>(
                    onInvoke: (_) => pinged++,
                  ),
                },
                child: const Focus(autofocus: true, child: Text('home')),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyP);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyP);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

        expect(pinged, 1);
      },
    );

    testWidgets(
      'GetCupertinoApp accepts Map<ShortcutActivator, Intent> shortcuts',
      (tester) async {
        var pinged = 0;
        final Map<ShortcutActivator, Intent> shortcuts = {
          const CharacterActivator('q'): const _PingIntent(),
        };

        await tester.pumpWidget(
          GetCupertinoApp(
            shortcuts: shortcuts,
            home: Actions(
              actions: {
                _PingIntent: CallbackAction<_PingIntent>(
                  onInvoke: (_) => pinged++,
                ),
              },
              child: const Focus(autofocus: true, child: Text('home')),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.keyQ, character: 'q');

        expect(pinged, 1);
      },
    );

    testWidgets('GetMaterialApp.router forwards ShortcutActivator shortcuts', (
      tester,
    ) async {
      await tester.pumpWidget(
        GetMaterialApp.router(
          shortcuts: <ShortcutActivator, Intent>{
            const SingleActivator(LogicalKeyboardKey.escape):
                const _PingIntent(),
          },
          getPages: [
            GetPage(
              name: '/',
              page: () => const Scaffold(body: Text('router home')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('router home'), findsOneWidget);
    });
  });

  group('2742 Shared Key', () {
    tearDown(Get.reset);

    testWidgets(
      'two simultaneously mounted outlets for the same anchor do not crash '
      'and share the key one at a time',
      (tester) async {
        await tester.pumpWidget(n7BuildApp());
        await tester.pumpAndSettle();
        expect(sharedKeyNavigators(tester).length, 1);

        // Stacks a second, rekeyed instance of the shell page in the root
        // navigator: both shells (and both same-anchor outlets) are mounted.
        Get.rootController.rootDelegate.toNamed(
          '/home',
          preventDuplicates: false,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          tester.widgetList(find.text('shell', skipOffstage: false)).length,
          2,
        );
        expect(sharedKeyNavigators(tester).length, 1);

        // Rebuilds every outlet in the same frame through a delegate
        // notification; before the fix this crashed with "Multiple widgets
        // used the same GlobalKey".
        Get.rootController.rootDelegate.toNamed('/home/tab2');
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('tab2-view'), findsOneWidget);
        expect(sharedKeyNavigators(tester).length, 1);
      },
    );

    testWidgets(
      'the surviving outlet reclaims the shared key after the duplicate '
      'shell is popped',
      (tester) async {
        await tester.pumpWidget(n7BuildApp());
        await tester.pumpAndSettle();
        Get.rootController.rootDelegate.toNamed(
          '/home',
          preventDuplicates: false,
        );
        await tester.pumpAndSettle();
        expect(
          tester.widgetList(find.text('shell', skipOffstage: false)).length,
          2,
        );

        Get.rootController.rootDelegate.back();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(
          tester.widgetList(find.text('shell', skipOffstage: false)).length,
          1,
        );
        // The remaining outlet re-adopted the shared key, so programmatic
        // access through the nested key reaches a live navigator again.
        expect(sharedKeyNavigators(tester).length, 1);
        expect(Get.nestedKey('/home')!.navigatorKey.currentState, isNotNull);
      },
    );
  });

  group('2742', () {
    tearDown(Get.reset);

    testWidgets(
      'anchorless outlet does not reuse the root navigator GlobalKey',
      (tester) async {
        await tester.pumpWidget(
          GetMaterialApp(
            initialRoute: '/',
            getPages: [
              GetPage(
                name: '/',
                page: () =>
                    Scaffold(body: GetRouterOutlet(initialRoute: '/home')),
                children: [
                  GetPage(name: '/home', page: () => const Text('home-view')),
                ],
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('home-view'), findsOneWidget);
        // Exactly one navigator carries the root delegate's GlobalKey.
        final rootKey = Get.rootController.rootDelegate.navigatorKey;
        final keyed = tester
            .widgetList<Navigator>(find.bySubtype<Navigator>())
            .where((navigator) => navigator.key == rootKey);
        expect(keyed.length, 1);
      },
    );
  });

  group('2909', () {
    tearDown(Get.reset);

    testWidgets(
      'onPageCalled returning null does not throw a null check error and '
      'degrades to the not-found page',
      (tester) async {
        await tester.pumpWidget(
          GetMaterialApp(
            initialRoute: '/',
            getPages: [
              GetPage(name: '/', page: () => const N9Home()),
              GetPage(
                name: '/main',
                page: () => const MainScreen(),
                middlewares: [NullOnPageCalledMiddleware()],
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        Get.offAllNamed('/main');
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(MainScreen), findsNothing);
        expect(find.text('Route not found'), findsOneWidget);
      },
    );

    testWidgets('onPageCalled returning null does not crash toNamed either', (
      tester,
    ) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => const N9Home()),
            GetPage(
              name: '/main',
              page: () => const MainScreen(),
              middlewares: [NullOnPageCalledMiddleware()],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/main');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(MainScreen), findsNothing);
    });
  });

  group('2949', () {
    tearDown(Get.reset);

    testWidgets(
      'initial route stopped by a middleware falls back to the not-found '
      'page instead of a permanently blank screen',
      (tester) async {
        await tester.pumpWidget(
          GetMaterialApp(
            initialRoute: '/guarded',
            getPages: [
              GetPage(
                name: '/guarded',
                page: () => const GuardedScreen(),
                middlewares: [BlockingMiddleware()],
              ),
              GetPage(name: '/other', page: () => const OtherScreen()),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(GuardedScreen), findsNothing);
        // The stack must never stay empty: the delegate falls back to its
        // not-found page so the app is not blank.
        expect(Get.rootController.rootDelegate.activePages, isNotEmpty);
        expect(find.text('Route not found'), findsOneWidget);
      },
    );

    testWidgets(
      'a middleware stopping an in-app navigation keeps the current page',
      (tester) async {
        await tester.pumpWidget(
          GetMaterialApp(
            initialRoute: '/other',
            getPages: [
              GetPage(
                name: '/guarded',
                page: () => const GuardedScreen(),
                middlewares: [BlockingMiddleware()],
              ),
              GetPage(name: '/other', page: () => const OtherScreen()),
            ],
          ),
        );
        await tester.pumpAndSettle();

        Get.toNamed('/guarded');
        await tester.pumpAndSettle();

        expect(find.byType(OtherScreen), findsOneWidget);
        expect(find.byType(GuardedScreen), findsNothing);
        expect(Get.currentRoute, '/other');
      },
    );
  });

  group('2995', () {
    testWidgets(
      "widgets beside a width-constrained snackbar stay tappable while the bar stays interactive",
      (tester) async {
        const cornerButtonKey = Key('corner-button');
        var cornerButtonTaps = 0;
        var snackbarTaps = 0;

        await tester.pumpWidget(
          GetMaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 10,
                    width: 100,
                    height: 40,
                    child: ElevatedButton(
                      key: cornerButtonKey,
                      onPressed: () => cornerButtonTaps++,
                      child: const Text('Corner'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();

        final controller = Get.showSnackbar(
          GetSnackBar(
            message: 'bar1',
            maxWidth: 200,
            snackPosition: SnackPosition.top,
            duration: const Duration(seconds: 5),
            onTap: (_) => snackbarTaps++,
          ),
        );
        await tester.pumpAndSettle();

        expect(Get.isSnackbarOpen, true);

        await tester.tap(find.byKey(cornerButtonKey), warnIfMissed: false);
        await tester.pump();

        expect(
          cornerButtonTaps,
          1,
          reason:
              'a tap beside the width-constrained snackbar must reach the button',
        );
        expect(Get.isSnackbarOpen, true);

        await tester.tap(find.text('bar1'));
        expect(
          snackbarTaps,
          1,
          reason: 'the visible snackbar must still receive taps',
        );

        await tester.drag(find.text('bar1'), const Offset(0.0, -50.0));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 500));

        expect(
          Get.isSnackbarOpen,
          false,
          reason: 'the visible snackbar must still be swipe-dismissible',
        );

        await controller.close(withAnimations: false);
        await tester.pumpAndSettle();
      },
    );
  });

  group('3012', () {
    testWidgets(
      "taps in the snackbar margin reach widgets underneath while the bar stays interactive",
      (tester) async {
        const underButtonKey = Key('under-button');
        var underButtonTaps = 0;
        var snackbarTaps = 0;

        await tester.pumpWidget(
          GetMaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    bottom: 100,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ElevatedButton(
                        key: underButtonKey,
                        onPressed: () => underButtonTaps++,
                        child: const Text('Under'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.pump();

        final controller = Get.showSnackbar(
          GetSnackBar(
            message: 'bar1',
            margin: const EdgeInsets.only(left: 8, right: 8, bottom: 300),
            snackPosition: SnackPosition.bottom,
            duration: const Duration(seconds: 5),
            onTap: (_) => snackbarTaps++,
          ),
        );
        await tester.pumpAndSettle();

        expect(Get.isSnackbarOpen, true);

        await tester.tap(find.byKey(underButtonKey), warnIfMissed: false);
        await tester.pump();

        expect(
          underButtonTaps,
          1,
          reason: 'a tap inside the snackbar margin must reach the button',
        );
        expect(Get.isSnackbarOpen, true);

        await tester.tap(find.text('bar1'));
        expect(
          snackbarTaps,
          1,
          reason: 'the visible snackbar must still receive taps',
        );

        await tester.drag(find.text('bar1'), const Offset(0.0, 300.0));
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 500));

        expect(
          Get.isSnackbarOpen,
          false,
          reason: 'the visible snackbar must still be swipe-dismissible',
        );

        await controller.close(withAnimations: false);
        await tester.pumpAndSettle();
      },
    );
  });

  group('3069', () {
    Widget n13BuildApp(TextDirection direction) {
      return MaterialApp(
        home: Directionality(
          textDirection: direction,
          child: const Scaffold(
            body: GetSnackBar(
              title: 'ttl',
              message: 'msg',
              icon: Icon(Icons.info_outline),
              mainButton: TextButton(onPressed: null, child: Text('act')),
            ),
          ),
        ),
      );
    }

    EdgeInsets resolvedPaddingOf(
      WidgetTester tester,
      Finder inner,
      TextDirection direction,
    ) {
      final padding = tester.widget<Padding>(
        find.ancestor(of: inner, matching: find.byType(Padding)).first,
      );
      return padding.padding.resolve(direction);
    }

    testWidgets('LTR: icon-adjacent inset stays on the left', (tester) async {
      await tester.pumpWidget(n13BuildApp(TextDirection.ltr));
      await tester.pump();

      final title = resolvedPaddingOf(
        tester,
        find.text('ttl'),
        TextDirection.ltr,
      );
      final message = resolvedPaddingOf(
        tester,
        find.text('msg'),
        TextDirection.ltr,
      );
      final button = resolvedPaddingOf(
        tester,
        find.byType(TextButton),
        TextDirection.ltr,
      );

      // The icon sits at the start of the row (physical left in LTR), so the
      // small 4.0 inset must be on the left and the 8.0 action-side inset on
      // the right.
      expect(title.left, 4.0);
      expect(title.right, 8.0);
      expect(message.left, 4.0);
      expect(message.right, 8.0);
      expect(button.right, 4.0);
      expect(button.left, 0.0);
    });

    testWidgets('RTL: icon-adjacent inset mirrors to the right', (
      tester,
    ) async {
      await tester.pumpWidget(n13BuildApp(TextDirection.rtl));
      await tester.pump();

      final title = resolvedPaddingOf(
        tester,
        find.text('ttl'),
        TextDirection.rtl,
      );
      final message = resolvedPaddingOf(
        tester,
        find.text('msg'),
        TextDirection.rtl,
      );
      final button = resolvedPaddingOf(
        tester,
        find.byType(TextButton),
        TextDirection.rtl,
      );

      // The icon sits at the start of the row (physical right in RTL), so the
      // small 4.0 inset must mirror to the right and the 8.0 action-side inset
      // to the left.
      expect(title.right, 4.0);
      expect(title.left, 8.0);
      expect(message.right, 4.0);
      expect(message.left, 8.0);
      expect(button.left, 4.0);
      expect(button.right, 0.0);
    });
  });

  group('3109', () {
    tearDown(Get.reset);

    testWidgets('Transition.predictiveBack pushes and pops the route', (
      tester,
    ) async {
      await tester.pumpWidget(n14BuildApp());
      await tester.pumpAndSettle();

      Get.toNamed('/second');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);

      await tester.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);
      expect(find.text('first'), findsNothing);

      Get.back();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('first'), findsOneWidget);
      expect(find.text('second'), findsNothing);
    });

    testWidgets(
      'Transition.predictiveBack does not disturb sibling transitions',
      (tester) async {
        await tester.pumpWidget(n14BuildApp());
        await tester.pumpAndSettle();

        Get.toNamed('/second');
        await tester.pumpAndSettle();

        Get.offNamed('/first');
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('first'), findsOneWidget);
      },
    );
  });

  group('3111', () {
    tearDown(Get.reset);

    testWidgets('outlet shows initialRoute child on start', (tester) async {
      await tester.pumpWidget(n15BuildApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('root-shell'), findsOneWidget);
      expect(find.text('home-view'), findsOneWidget);
    });

    testWidgets(
      'page participating in the root navigator is mounted exactly once',
      (tester) async {
        await tester.pumpWidget(n15BuildApp());
        await tester.pumpAndSettle();

        Get.rootController.rootDelegate.toNamed('/settings');
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('settings-view'), findsOneWidget);
        // Before the fix the outlet anchored at '/' also picked the settings
        // page, mounting a second (offstage) copy inside the root shell.
        expect(find.text('settings-view', skipOffstage: false), findsOneWidget);
      },
    );
  });

  group('3127', () {
    testWidgets('Get.dialog uses the provided custom transitionBuilder', (
      tester,
    ) async {
      await tester.pumpWidget(Wrapper(child: Container()));
      await tester.pump();

      var builderUsed = false;
      Get.dialog(
        const _DialogContent(),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          builderUsed = true;
          return ScaleTransition(scale: animation, child: child);
        },
      );
      await tester.pumpAndSettle();

      expect(builderUsed, true);
      expect(find.byType(_DialogContent), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byType(_DialogContent),
          matching: find.byType(ScaleTransition),
        ),
        findsWidgets,
      );

      Get.closeDialog();
      await tester.pumpAndSettle();
    });

    testWidgets('Get.dialog keeps the default fade when no transitionBuilder '
        'is given', (tester) async {
      await tester.pumpWidget(Wrapper(child: Container()));
      await tester.pump();

      Get.dialog(const _DialogContent());
      await tester.pumpAndSettle();

      expect(
        find.ancestor(
          of: find.byType(_DialogContent),
          matching: find.byType(FadeTransition),
        ),
        findsWidgets,
      );

      Get.closeDialog();
      await tester.pumpAndSettle();
    });
  });

  group('3130', () {
    tearDown(Get.reset);

    testWidgets(
      'CircularRevealTransition covers the corners of an iPad Pro 12.9 screen',
      (tester) async {
        late Widget transition;
        await tester.pumpWidget(
          Builder(
            builder: (context) {
              transition = CircularRevealTransition().buildTransitions(
                context,
                null,
                null,
                const AlwaysStoppedAnimation<double>(1),
                const AlwaysStoppedAnimation<double>(0),
                const SizedBox(),
              );
              return const SizedBox();
            },
          ),
        );

        final clipper =
            (transition as ClipPath).clipper! as CircularRevealClipper;

        // iPad Pro 12.9 logical resolution; its half-diagonal is ~854.
        const size = Size(1024, 1366);
        final path = clipper.getClip(size);

        expect(
          path.contains(Offset.zero),
          isTrue,
          reason: 'the fully revealed circle must cover the top-left corner',
        );
        expect(
          path.contains(const Offset(1023, 1365)),
          isTrue,
          reason:
              'the fully revealed circle must cover the bottom-right corner',
        );
      },
    );

    testWidgets(
      'a settled circularReveal route is fully visible on a large screen',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 1366);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        var cornerTapped = false;

        await tester.pumpWidget(
          GetMaterialApp(
            initialRoute: '/first',
            getPages: [
              GetPage(
                name: '/first',
                page: () => const Scaffold(body: Text('first')),
              ),
              GetPage(
                name: '/second',
                transition: Transition.circularReveal,
                page: () => Scaffold(
                  body: Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () => cornerTapped = true,
                      child: const SizedBox(
                        width: 10,
                        height: 10,
                        child: ColoredBox(color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        Get.toNamed('/second');
        await tester.pumpAndSettle();

        // With the reveal capped at 800 the corner stayed clipped even after
        // the transition settled, so the corner was not hit-testable.
        await tester.tapAt(const Offset(5, 5));
        expect(
          cornerTapped,
          isTrue,
          reason: 'the corner of the revealed page must be interactive',
        );
      },
    );
  });

  group('3139', () {
    tearDown(Get.reset);

    testWidgets(
      'parameters added by a middleware redirect are visible to the next '
      'middleware pass through Get.parameters',
      (tester) async {
        final middleware = TabUidMiddleware();
        await tester.pumpWidget(
          GetMaterialApp(
            initialRoute: '/',
            getPages: [
              GetPage(name: '/', page: () => const N18Home()),
              GetPage(
                name: '/page2/:id',
                page: () => const Page2(),
                middlewares: [middleware],
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        Get.toNamed('/page2/2333');
        await tester.pumpAndSettle();

        // The middleware observed the path parameter of the in-flight
        // navigation and the query parameter added by its own redirect.
        expect(middleware.seenId, '2333');
        expect(middleware.seenTabUid, 'abc123');
        expect(middleware.attempts, lessThanOrEqualTo(6));

        // The navigation settled on the redirected location.
        expect(find.byType(Page2), findsOneWidget);
        expect(Get.parameters['id'], '2333');
        expect(Get.parameters['tabUID'], 'abc123');
      },
    );
  });

  group('3170', () {
    tearDown(Get.reset);

    testWidgets(
      'middleware lifecycle callbacks run once, on the declaring page only',
      (tester) async {
        final parentMiddleware = CountingMiddleware();
        final childMiddleware = CountingMiddleware();

        await tester.pumpWidget(
          GetMaterialApp(
            initialRoute: '/parent',
            getPages: [
              GetPage(
                name: '/parent',
                page: () => const ParentScreen(),
                middlewares: [parentMiddleware],
                children: [
                  GetPage(
                    name: '/child',
                    page: () => const ChildScreen(),
                    middlewares: [childMiddleware],
                  ),
                ],
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(parentMiddleware.builtCount, 1);
        expect(childMiddleware.builtCount, 0);

        Get.toNamed('/parent/child');
        await tester.pumpAndSettle();

        // The child page runs only its own lifecycle callbacks; the parent's
        // middleware must not fire a second time for the child's route.
        expect(find.byType(ChildScreen), findsOneWidget);
        expect(parentMiddleware.builtCount, 1);
        expect(childMiddleware.builtCount, 1);

        // Navigation guards, however, stay inherited: the parent middleware
        // was consulted for the child navigation.
        expect(parentMiddleware.guardedRoutes, contains('/parent/child'));

        Get.back();
        await tester.pumpAndSettle();

        // Disposing the child route disposes only the child's middleware.
        expect(childMiddleware.disposeCount, 1);
        expect(parentMiddleware.disposeCount, 0);
      },
    );

    test('nested pages register once and middlewares are never duplicated', () {
      final ma = CountingMiddleware();
      final mb = CountingMiddleware();
      final mc = CountingMiddleware();
      final tree = ParseRouteTree(routes: <GetPage>[]);
      tree.addRoute(
        GetPage(
          name: '/a',
          page: () => const ParentScreen(),
          middlewares: [ma],
          children: [
            GetPage(
              name: '/b',
              page: () => const ParentScreen(),
              middlewares: [mb],
              children: [
                GetPage(
                  name: '/c',
                  page: () => const ChildScreen(),
                  middlewares: [mc],
                ),
              ],
            ),
          ],
        ),
      );

      expect(tree.routes.where((r) => r.name == '/a/b/c').length, 1);

      final middlewares = tree.matchRoute('/a/b/c').route!.middlewares;
      expect(middlewares.where((m) => identical(m, ma)).length, 1);
      expect(middlewares.where((m) => identical(m, mb)).length, 1);
      expect(middlewares.where((m) => identical(m, mc)).length, 1);

      // Only the middlewares declared on the page itself are its own.
      expect(tree.ownMiddlewaresOf('/a/b/c'), [mc]);
      expect(tree.ownMiddlewaresOf('/a/b'), [mb]);
      expect(tree.ownMiddlewaresOf('/a'), [ma]);
    });
  });

  group('3184', () {
    testWidgets('defaultDialog canPop: false blocks the back gesture/button', (
      tester,
    ) async {
      await tester.pumpWidget(Wrapper(child: Container()));
      await tester.pump();

      Get.defaultDialog(middleText: 'protected dialog', canPop: false);
      await tester.pumpAndSettle();

      expect(find.text('protected dialog'), findsOneWidget);
      expect(Get.isDialogOpen, true);

      // Simulates the system back button/gesture. maybePop returns true
      // because the blocked pop counts as handled, so the dialog staying
      // open is what proves the veto.
      await Get.key.currentState!.maybePop();
      await tester.pumpAndSettle();

      expect(find.text('protected dialog'), findsOneWidget);
      expect(Get.isDialogOpen, true);

      // The dialog can still be closed programmatically.
      Get.closeDialog();
      await tester.pumpAndSettle();

      expect(find.text('protected dialog'), findsNothing);
      expect(Get.isDialogOpen, false);
    });

    testWidgets('defaultDialog canPop: false still reports pop attempts '
        'through onWillPop', (tester) async {
      await tester.pumpWidget(Wrapper(child: Container()));
      await tester.pump();

      bool? reportedDidPop;
      Get.defaultDialog(
        middleText: 'protected dialog',
        canPop: false,
        onWillPop: (didPop, result) => reportedDidPop = didPop,
      );
      await tester.pumpAndSettle();

      await Get.key.currentState!.maybePop();
      await tester.pumpAndSettle();

      expect(reportedDidPop, false);
      expect(find.text('protected dialog'), findsOneWidget);

      Get.closeDialog();
      await tester.pumpAndSettle();
    });

    testWidgets('defaultDialog default keeps back dismissal working', (
      tester,
    ) async {
      await tester.pumpWidget(Wrapper(child: Container()));
      await tester.pump();

      Get.defaultDialog(middleText: 'dismissible dialog');
      await tester.pumpAndSettle();

      expect(find.text('dismissible dialog'), findsOneWidget);

      final popped = await Get.key.currentState!.maybePop();
      await tester.pumpAndSettle();

      expect(popped, true);
      expect(find.text('dismissible dialog'), findsNothing);
      expect(Get.isDialogOpen, false);
    });
  });

  group('3209', () {
    tearDown(Get.reset);

    testWidgets('a drag starting mid-screen does not pop by default', (
      tester,
    ) async {
      await tester.pumpWidget(n21BuildApp());
      await tester.pumpAndSettle();

      Get.toNamed('/second');
      await tester.pumpAndSettle();

      await tester.flingFrom(
        const Offset(300, 300),
        const Offset(400, 0),
        1000,
      );
      await tester.pumpAndSettle();

      expect(find.text('second'), findsOneWidget);
      expect(find.text('first'), findsNothing);
    });

    testWidgets('a drag starting at the leading edge pops by default', (
      tester,
    ) async {
      await tester.pumpWidget(n21BuildApp());
      await tester.pumpAndSettle();

      Get.toNamed('/second');
      await tester.pumpAndSettle();

      await tester.flingFrom(const Offset(10, 300), const Offset(700, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.text('first'), findsOneWidget);
      expect(find.text('second'), findsNothing);
    });

    testWidgets(
      'popGesture: true on the route keeps the full-screen swipe area',
      (tester) async {
        await tester.pumpWidget(n21BuildApp(routePopGesture: true));
        await tester.pumpAndSettle();

        Get.toNamed('/second');
        await tester.pumpAndSettle();

        await tester.flingFrom(
          const Offset(300, 300),
          const Offset(400, 0),
          1000,
        );
        await tester.pumpAndSettle();

        expect(find.text('first'), findsOneWidget);
        expect(find.text('second'), findsNothing);
      },
    );

    testWidgets(
      'a gestureWidth of double.infinity restores full-screen detection',
      (tester) async {
        await tester.pumpWidget(
          n21BuildApp(gestureWidth: (context) => double.infinity),
        );
        await tester.pumpAndSettle();

        Get.toNamed('/second');
        await tester.pumpAndSettle();

        await tester.flingFrom(
          const Offset(300, 300),
          const Offset(400, 0),
          1000,
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('first'), findsOneWidget);
        expect(find.text('second'), findsNothing);
      },
    );
  });

  group('3224 Url Strategy', () {
    test('creating several root GetDelegates sets the URL strategy once', () {
      GetDelegate(
        pages: [GetPage(name: '/', page: () => const SizedBox.shrink())],
      );

      // A second root delegate in the same process must not attempt to set
      // the URL strategy again.
      GetDelegate(
        pages: [GetPage(name: '/', page: () => const SizedBox.shrink())],
      );
    });
  });

  group('3244', () {
    tearDown(Get.reset);

    testWidgets('home is rendered after a single pumpWidget', (tester) async {
      await tester.pumpWidget(const GetMaterialApp(home: HomePage()));

      expect(find.text('home'), findsOneWidget);

      // Flushes the zero-duration onReady future scheduled by GetRoot, which
      // would otherwise be reported as a pending timer when the test ends.
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('the initial route is rendered after a single pumpWidget', (
      tester,
    ) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/home',
          getPages: [
            GetPage(name: '/home', page: () => const HomePage()),
            GetPage(name: '/login', page: () => const LoginPage()),
          ],
        ),
      );

      expect(find.text('home'), findsOneWidget);

      // Flushes the zero-duration onReady future scheduled by GetRoot, which
      // would otherwise be reported as a pending timer when the test ends.
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('a middleware redirect on the initial route still resolves', (
      tester,
    ) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/home',
          getPages: [
            GetPage(
              name: '/home',
              page: () => const HomePage(),
              middlewares: [RedirectMiddleware()],
            ),
            GetPage(name: '/login', page: () => const LoginPage()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('login'), findsOneWidget);
      expect(find.text('home'), findsNothing);
    });
  });

  group('3266', () {
    tearDown(Get.reset);

    testWidgets(
      'the initial route report after startup is a history replace, not a push',
      (tester) async {
        final updates = n24CaptureRouteInformationUpdates(tester);

        // The engine's default location is '/', so resolving the initial
        // route to '/first' produces a URL update on startup.
        await tester.pumpWidget(n24BuildApp());
        await tester.pumpAndSettle();

        expect(updates, isNotEmpty);
        expect(updates.first['uri'], '/first');
        expect(updates.first['replace'], isTrue);
      },
    );

    testWidgets('later push navigations are still reported as pushes', (
      tester,
    ) async {
      final updates = n24CaptureRouteInformationUpdates(tester);

      await tester.pumpWidget(n24BuildApp());
      await tester.pumpAndSettle();
      updates.clear();

      Get.toNamed('/second');
      await tester.pumpAndSettle();

      expect(updates, isNotEmpty);
      expect(updates.last['uri'], '/second');
      expect(updates.last['replace'], isFalse);
    });
  });

  group('3274', () {
    tearDown(Get.reset);

    testWidgets(
      'Get.defaultTransition stays null when the app does not set one',
      (tester) async {
        await tester.pumpWidget(n25BuildApp());
        await tester.pumpAndSettle();

        expect(Get.defaultTransition, isNull);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    testWidgets('routes without an explicit transition honor the theme '
        'pageTransitionsTheme on iOS', (tester) async {
      await tester.pumpWidget(n25BuildApp());
      await tester.pumpAndSettle();

      Get.toNamed('/second');
      await tester.pumpAndSettle();

      expect(find.text('second'), findsOneWidget);
      expect(find.byKey(markerKey), findsWidgets);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  });

  group('3282', () {
    setUp(() => capturedContext = null);
    tearDown(Get.reset);

    test(
      'GetPage defaults allowSnapshotting to true and copyWith keeps it',
      () {
        final page = GetPage(name: '/a', page: Container.new);
        expect(page.allowSnapshotting, isTrue);

        final disabled = GetPage(
          name: '/a',
          page: Container.new,
          allowSnapshotting: false,
        );
        expect(disabled.allowSnapshotting, isFalse);
        expect(disabled.copyWith().allowSnapshotting, isFalse);
        expect(
          disabled.copyWith(allowSnapshotting: true).allowSnapshotting,
          isTrue,
        );
      },
    );

    test('GetPageRoute honors an explicit allowSnapshotting argument', () {
      expect(GetPageRoute(page: Container.new).allowSnapshotting, isTrue);
      expect(
        GetPageRoute(
          page: Container.new,
          allowSnapshotting: false,
        ).allowSnapshotting,
        isFalse,
      );
    });

    testWidgets('GetPage.allowSnapshotting reaches the created route', (
      tester,
    ) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/snapshotless',
          getPages: [
            GetPage(
              name: '/snapshotless',
              page: () => const SnapshotlessPage(),
              allowSnapshotting: false,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final route = ModalRoute.of(capturedContext!)! as PageRoute;
      expect(route, isA<GetPageRoute>());
      expect(route.allowSnapshotting, isFalse);
    });
  });

  group('3323', () {
    tearDown(Get.reset);

    test('Get.key is accessible before GetRoot mounts and is stable', () {
      expect(() => Get.key, returnsNormally);
      expect(Get.key, same(Get.key));
    });

    test('APIs that require a mounted GetRoot still throw before mount', () {
      expect(() => Get.rootController.config, throwsException);
      expect(() => Get.rootController.rootDelegate, throwsException);
    });

    testWidgets('GetMaterialApp(navigatorKey: Get.key) builds and navigates', (
      tester,
    ) async {
      final GlobalKey<NavigatorState> preMountKey = Get.key;

      await tester.pumpWidget(
        GetMaterialApp(
          navigatorKey: preMountKey,
          getPages: [
            GetPage(name: '/', page: () => const N27Home()),
            GetPage(name: '/second', page: () => const Second()),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(Get.key, same(preMountKey));
      expect(preMountKey.currentState, isNotNull);

      Get.toNamed('/second');
      await tester.pumpAndSettle();

      expect(find.byType(Second), findsOneWidget);
    });

    testWidgets('Get.key keeps its identity across mount when not passed in', (
      tester,
    ) async {
      final GlobalKey<NavigatorState> preMountKey = Get.key;

      await tester.pumpWidget(
        GetMaterialApp(
          getPages: [GetPage(name: '/', page: () => const N27Home())],
        ),
      );
      await tester.pumpAndSettle();

      expect(Get.key, same(preMountKey));
      expect(Get.key.currentState, isNotNull);
    });
  });

  group('3367', () {
    tearDown(Get.reset);

    testWidgets(
      'middleware redirect to unregistered route without unknownRoute '
      'does not throw a null check error',
      (tester) async {
        await tester.pumpWidget(
          GetMaterialApp(
            initialRoute: '/second',
            getPages: [
              GetPage(
                name: '/first',
                page: () => const N28FirstScreen(),
                middlewares: [RedirectToUnregisteredMiddleware()],
              ),
              GetPage(name: '/second', page: () => const N28SecondScreen()),
            ],
          ),
        );

        Get.toNamed('/first');
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // falls back to the delegate default not-found page
        expect(find.text('Route not found'), findsOneWidget);
        expect(find.byType(N28FirstScreen), findsNothing);
      },
    );
  });

  group('3372', () {
    tearDown(Get.reset);

    testWidgets('toNamed is reported to the engine as a history push', (
      tester,
    ) async {
      final updates = n29CaptureRouteInformationUpdates(tester);

      await tester.pumpWidget(n29BuildApp());
      await tester.pumpAndSettle();
      updates.clear();

      Get.toNamed('/second');
      await tester.pumpAndSettle();

      expect(updates, isNotEmpty);
      expect(updates.last['uri'], '/second');
      expect(updates.last['replace'], isFalse);
    });

    testWidgets('offAllNamed is reported to the engine as a history replace', (
      tester,
    ) async {
      final updates = n29CaptureRouteInformationUpdates(tester);

      await tester.pumpWidget(n29BuildApp());
      await tester.pumpAndSettle();

      Get.toNamed('/second');
      await tester.pumpAndSettle();
      updates.clear();

      Get.offAllNamed('/third');
      await tester.pumpAndSettle();

      expect(updates, isNotEmpty);
      expect(updates.last['uri'], '/third');
      expect(updates.last['replace'], isTrue);
    });

    testWidgets('offNamed is reported to the engine as a history replace', (
      tester,
    ) async {
      final updates = n29CaptureRouteInformationUpdates(tester);

      await tester.pumpWidget(n29BuildApp());
      await tester.pumpAndSettle();
      updates.clear();

      Get.offNamed('/second');
      await tester.pumpAndSettle();

      expect(updates, isNotEmpty);
      expect(updates.last['uri'], '/second');
      expect(updates.last['replace'], isTrue);
    });

    testWidgets('off is reported to the engine as a history replace', (
      tester,
    ) async {
      final updates = n29CaptureRouteInformationUpdates(tester);

      await tester.pumpWidget(n29BuildApp());
      await tester.pumpAndSettle();
      updates.clear();

      Get.off(() => const N29SecondPage());
      await tester.pumpAndSettle();

      expect(updates, isNotEmpty);
      expect(updates.last['replace'], isTrue);
    });

    testWidgets(
      'platform back to an existing entry pops the stack instead of duplicating it',
      (tester) async {
        await tester.pumpWidget(n29BuildApp());
        await tester.pumpAndSettle();

        Get.toNamed('/second');
        await tester.pumpAndSettle();

        final delegate = Get.rootController.rootDelegate;
        expect(delegate.activePages.length, 2);

        await n29SimulatePlatformRoute(tester, '/first');
        await tester.pumpAndSettle();

        expect(find.text('first'), findsOneWidget);
        expect(delegate.activePages.length, 1);
        expect(delegate.activePages.last.pageSettings?.name, '/first');
      },
    );

    testWidgets(
      'platform back over multiple entries pops back to the matching entry',
      (tester) async {
        await tester.pumpWidget(n29BuildApp());
        await tester.pumpAndSettle();

        Get.toNamed('/second');
        await tester.pumpAndSettle();
        Get.toNamed('/third');
        await tester.pumpAndSettle();

        final delegate = Get.rootController.rootDelegate;
        expect(delegate.activePages.length, 3);

        await n29SimulatePlatformRoute(tester, '/first');
        await tester.pumpAndSettle();

        expect(find.text('first'), findsOneWidget);
        expect(delegate.activePages.length, 1);
      },
    );

    testWidgets('a reported route that is not on the stack is still pushed', (
      tester,
    ) async {
      await tester.pumpWidget(n29BuildApp());
      await tester.pumpAndSettle();

      await n29SimulatePlatformRoute(tester, '/second');
      await tester.pumpAndSettle();

      expect(find.text('second'), findsOneWidget);

      final delegate = Get.rootController.rootDelegate;
      expect(delegate.activePages.length, 2);
      expect(delegate.activePages.last.pageSettings?.name, '/second');
    });
  });

  group('3394', () {
    testWidgets(
      "Routing.previous holds the popped route after Get.back (issue #3394)",
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

        Get.back();
        await tester.pumpAndSettle();

        expect(Get.currentRoute, '/first');
        expect(Get.previousRoute, '/second');
        expect(Get.previousRoute, isNot(equals(Get.currentRoute)));
      },
    );

    testWidgets(
      "previousRoute stays distinct from currentRoute across multiple pops",
      (tester) async {
        await tester.pumpWidget(
          WrapperNamed(
            initialRoute: '/first',
            namedRoutes: [
              GetPage(page: () => const Text('first'), name: '/first'),
              GetPage(page: () => const Text('second'), name: '/second'),
              GetPage(page: () => const Text('third'), name: '/third'),
            ],
          ),
        );
        await tester.pumpAndSettle();

        Get.toNamed('/second');
        await tester.pumpAndSettle();
        Get.toNamed('/third');
        await tester.pumpAndSettle();

        Get.back();
        await tester.pumpAndSettle();

        expect(Get.currentRoute, '/second');
        expect(Get.previousRoute, '/third');

        Get.back();
        await tester.pumpAndSettle();

        expect(Get.currentRoute, '/first');
        expect(Get.previousRoute, '/second');
      },
    );
  });
}
