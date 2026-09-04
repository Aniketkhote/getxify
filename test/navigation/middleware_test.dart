import 'get_main_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';
import 'utils/wrapper.dart';

class RedirectMiddleware extends GetMiddleware {
  @override
  Future<RouteDecoder?> redirectDelegate(RouteDecoder route) async {
    return RouteDecoder.fromRoute('/second');
  }
}

class Redirect2Middleware extends GetMiddleware {
  @override
  Future<RouteDecoder?> redirectDelegate(RouteDecoder route) async {
    return RouteDecoder.fromRoute('/first');
  }
}

class RedirectMiddlewareNull extends GetMiddleware {
  @override
  Future<RouteDecoder?> redirectDelegate(RouteDecoder route) async {
    return null;
  }
}

class RedirectBypassMiddleware extends GetMiddleware {
  @override
  Future<RouteDecoder?> redirectDelegate(RouteDecoder route) async {
    return route;
  }
}

// GetRouterOutlet's initialRoute is resolved during build, so an
// asynchronous GetMiddleware.redirectDelegate result was ignored entirely —
// the guarded page stayed visible no matter what the middleware decided.
// The full pipeline is now resolved out-of-band
// (GetDelegate.resolveOutletInitialPageAsync) and the outlet rebuilds with
// the resolved page.

class AsyncRedirectGuard extends GetMiddleware {
  static int calls = 0;

  @override
  Future<RouteDecoder?> redirectDelegate(RouteDecoder route) async {
    calls++;
    return RouteDecoder.fromRoute('/home/allowed');
  }
}

class AsyncStopGuard extends GetMiddleware {
  @override
  Future<RouteDecoder?> redirectDelegate(RouteDecoder route) async => null;
}

class AsyncPassGuard extends GetMiddleware {
  @override
  Future<RouteDecoder?> redirectDelegate(RouteDecoder route) async => route;
}

GetMaterialApp n0BuildApp({required List<GetMiddleware> middlewares}) {
  return GetMaterialApp(
    initialRoute: '/home',
    getPages: [
      GetPage(
        name: '/home',
        page: () => Scaffold(
          body: GetRouterOutlet(
            anchorRoute: '/home',
            initialRoute: '/home/guarded',
          ),
        ),
        children: [
          GetPage(
            name: '/guarded',
            page: () => const Text('guarded-view'),
            middlewares: middlewares,
          ),
          GetPage(name: '/allowed', page: () => const Text('allowed-view')),
        ],
      ),
    ],
  );
}

// the iOS back-swipe gesture could never pop between sibling routes inside
// a GetRouterOutlet. The outlet navigator rendered only the current tree
// branch, so after navigating from one sibling to another it contained a
// single route — and a route that is alone in its navigator (route.isFirst)
// never enables the pop gesture. The outlet now stacks the sibling pages of
// every history entry sharing its anchor (previous siblings stay mounted
// beneath, retaining their state), and a pop performed imperatively on the
// outlet navigator — the exact call the gesture's dragEnd makes — pops the
// matching history entry through GetDelegate.didRemoveOutletPage.

class Tab1View extends StatefulWidget {
  const Tab1View({super.key});

  static int initCount = 0;
  static int disposeCount = 0;

  static void resetCounters() {
    initCount = 0;
    disposeCount = 0;
  }

  @override
  State<Tab1View> createState() => _Tab1ViewState();
}

class _Tab1ViewState extends State<Tab1View> {
  @override
  void initState() {
    super.initState();
    Tab1View.initCount++;
  }

  @override
  void dispose() {
    Tab1View.disposeCount++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Text('tab1-view');
  }
}

GetMaterialApp n1BuildApp({String initialRoute = '/home/tab1'}) {
  return GetMaterialApp(
    initialRoute: initialRoute,
    getPages: [
      GetPage(
        name: '/home',
        participatesInRootNavigator: true,
        page: () => Scaffold(
          body: Column(
            children: [
              const Text('home-shell'),
              Expanded(
                child: GetRouterOutlet(
                  anchorRoute: '/home',
                  initialRoute: '/home/tab1',
                ),
              ),
            ],
          ),
        ),
        children: [
          GetPage(name: '/tab1', page: () => const Tab1View()),
          GetPage(name: '/tab2', page: () => const Text('tab2-view')),
          GetPage(
            name: '/products',
            page: () => const Text('products-view'),
            children: [
              GetPage(name: '/details', page: () => const Text('details-view')),
            ],
          ),
        ],
      ),
    ],
  );
}

NavigatorState outletNavigator() =>
    Get.nestedKey('/home')!.navigatorKey.currentState!;

Route<dynamic> topOutletRoute() {
  Route<dynamic>? top;
  outletNavigator().popUntil((route) {
    top = route;
    return true;
  });
  return top!;
}

// Arguments passed to Get.dialog were stored in the dialog route's
// settings but Get.arguments kept returning the underlying page's
// arguments, so the dialog could never read its own.

// Get.to with a constructor tear-off (e.g. `Get.to(MyPage.new)`) must
// generate a clean route name like '/MyPage' instead of leaking the
// tear-off's parameter list into the route name/URL.

class TearOffPage extends StatelessWidget {
  const TearOffPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('tearoff'));
  }
}

//
// A snackbar closed while still waiting in the queue must never mount its
// overlay when the queue reaches it, and the queue must keep working.

// within the same action (same frame), each page must observe its own
// arguments and parameters while it builds, instead of the arguments of
// whatever route ended up on top of the stack.

class ArgsRecorder extends StatelessWidget {
  const ArgsRecorder({super.key, required this.tag, required this.seen});

  final String tag;
  final Map<String, Object?> seen;

  @override
  Widget build(BuildContext context) {
    seen[tag] = Get.arguments;
    return Text('page-$tag');
  }
}

class ParamsRecorder extends StatelessWidget {
  const ParamsRecorder({super.key, required this.tag, required this.seen});

  final String tag;
  final Map<String, String?> seen;

  @override
  Widget build(BuildContext context) {
    seen[tag] = Get.parameters['who'];
    return Text('page-$tag');
  }
}

// Get.back should report whether the back navigation actually happened,
// so callers (e.g. after a deep link landed on the only page in the
// stack) can detect the ignored back and navigate elsewhere instead.

//
// Get.to, Get.off and Get.offAll accept a [customTransition] that is
// forwarded through GetDelegate into the GetPage they build, so imperative
// navigation can use the same CustomTransition engine support that
// GetPage/named routes always had. This file fails to compile without the
// fix (no such named parameter), proving the additive API.

const _marker = ValueKey('custom-transition-marker');

class _MarkerTransition extends CustomTransition {
  int buildCount = 0;

  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    buildCount++;
    return KeyedSubtree(
      key: _marker,
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}

//
// GetPage used to fail with an opaque assertion when the route name did
// not start with '/'. The assert message now states the offending name
// and that route names must start with a slash, pointing to the fix.

//
// The left bar indicator (and the progress indicator strip) bled over the
// snackbar's rounded corners because the content was never clipped to the
// background's borderRadius.

//
// Closing a snackbar that was still waiting in the queue (its animation
// controller not yet created) crashed with a null-check error, the modern
// form of the reported LateInitializationError on `_controller`.

class AuthRedirectMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    return const RouteSettings(name: '/login');
  }
}

class ArgsRedirectMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    return RouteSettings(name: '/login', arguments: {'callbackUrl': route});
  }
}

class StopDelegateMiddleware extends GetMiddleware {
  @override
  Future<RouteDecoder?> redirectDelegate(RouteDecoder route) async => null;
}

class N12Home extends StatelessWidget {
  const N12Home({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('home'));
  }
}

class ProtectedScreen extends StatelessWidget {
  const ProtectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('protected'));
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('login'));
  }
}

GetMaterialApp n12BuildApp({List<GetMiddleware>? protectedMiddlewares}) {
  return GetMaterialApp(
    initialRoute: '/',
    getPages: [
      GetPage(name: '/', page: () => const N12Home()),
      GetPage(
        name: '/protected',
        page: () => const ProtectedScreen(),
        middlewares: protectedMiddlewares ?? [AuthRedirectMiddleware()],
      ),
      GetPage(name: '/login', page: () => const LoginScreen()),
    ],
  );
}

// preventDuplicates was dead code in the Navigator 2.0 push pipeline —
// neither GetPage(preventDuplicates: false) nor the flag passed to
// Get.toNamed / Get.to could ever push a duplicate route.

class DupPage extends StatelessWidget {
  const DupPage({super.key});

  @override
  Widget build(BuildContext context) => const Text('dup');
}

// preventDuplicateHandlingMode, so the mode set on a GetPage (or passed to
// Get.to) was reset to the default reorderRoutes before _push consulted it.

class N15ForwardArgumentsMiddleware extends GetMiddleware {
  @override
  Future<RouteDecoder?> redirectDelegate(RouteDecoder route) async {
    return RouteDecoder.fromRoute('/second', arguments: route.args);
  }
}

class N15Home extends StatelessWidget {
  const N15Home({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('home'));
  }
}

class N15FirstScreen extends StatelessWidget {
  const N15FirstScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('first'));
  }
}

class N15SecondScreen extends StatelessWidget {
  const N15SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('second'));
  }
}

class N15CaptureArgsMiddleware extends GetMiddleware {
  N15CaptureArgsMiddleware(this.onArgs);

  final void Function(Object? args) onArgs;

  @override
  Future<RouteDecoder?> redirectDelegate(RouteDecoder route) async {
    onArgs(route.args);
    return route;
  }
}

void main() {
  // Base middleware_test.dart tests
  tearDown(() {
    Get.reset();
  });

  testWidgets("Middleware should redirect to second screen", (tester) async {
    // Test setup
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const Home()),
          GetPage(
            name: '/first',
            page: () => const FirstScreen(),
            middlewares: [RedirectMiddleware()],
          ),
          GetPage(name: '/second', page: () => const SecondScreen()),
          GetPage(name: '/third', page: () => const ThirdScreen()),
        ],
      ),
    );

    // Act
    Get.toNamed('/first');
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(SecondScreen), findsOneWidget);
    expect(find.byType(FirstScreen), findsNothing);
    expect(Get.currentRoute, '/second');
  });

  testWidgets("Middleware should stop navigation", (tester) async {
    // Test setup
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const Home()),
          GetPage(
            name: '/first',
            page: () => const FirstScreen(),
            middlewares: [RedirectMiddlewareNull()],
          ),
          GetPage(name: '/second', page: () => const SecondScreen()),
          GetPage(name: '/third', page: () => const ThirdScreen()),
        ],
      ),
    );

    // Act
    await tester.pumpAndSettle();
    Get.toNamed('/first');
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(Home), findsOneWidget);
    expect(find.byType(FirstScreen), findsNothing);
    expect(Get.currentRoute, '/');
  });

  testWidgets("Middleware should be bypassed", (tester) async {
    // Test setup
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const Home()),
          GetPage(
            name: '/first',
            page: () => const FirstScreen(),
            middlewares: [RedirectBypassMiddleware()],
          ),
          GetPage(name: '/second', page: () => const SecondScreen()),
          GetPage(name: '/third', page: () => const ThirdScreen()),
        ],
      ),
    );

    // Act
    await tester.pumpAndSettle();
    Get.toNamed('/first');
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(FirstScreen), findsOneWidget);
    expect(find.byType(SecondScreen), findsNothing);
    expect(find.byType(Home), findsNothing);
    expect(Get.currentRoute, '/first');
  });

  testWidgets("Middleware should redirect twice", (tester) async {
    // Test setup
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const Home()),
          GetPage(
            name: '/first',
            page: () => const FirstScreen(),
            middlewares: [RedirectMiddleware()],
          ),
          GetPage(name: '/second', page: () => const SecondScreen()),
          GetPage(name: '/third', page: () => const ThirdScreen()),
          GetPage(
            name: '/fourth',
            page: () => const FourthScreen(),
            middlewares: [Redirect2Middleware()],
          ),
        ],
      ),
    );

    // Act
    Get.toNamed('/fourth');
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(SecondScreen), findsOneWidget);
    expect(find.byType(FirstScreen), findsNothing);
    expect(Get.currentRoute, '/second');
  });

  testWidgets("Navigation history should be correct after redirects", (
    tester,
  ) async {
    // Test setup
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const Home()),
          GetPage(
            name: '/first',
            page: () => const FirstScreen(),
            middlewares: [RedirectMiddleware()],
          ),
          GetPage(name: '/second', page: () => const SecondScreen()),
        ],
      ),
    );

    // Act
    Get.toNamed('/first');
    await tester.pumpAndSettle();

    // Assert
    expect(Get.currentRoute, '/second');
    expect(Get.previousRoute, '/');

    // Act: go back
    Get.back();
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(Home), findsOneWidget);
    expect(Get.currentRoute, '/');
  });

  group('1978 Async Redirect', () {
    setUp(() => AsyncRedirectGuard.calls = 0);
    tearDown(Get.reset);

    testWidgets(
      'an async redirectDelegate result is applied to an outlet initialRoute',
      (tester) async {
        await tester.pumpWidget(
          n0BuildApp(middlewares: [AsyncRedirectGuard()]),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(AsyncRedirectGuard.calls, greaterThan(0));
        // Before the fix the async result was dropped and the guarded page
        // stayed visible.
        expect(find.text('allowed-view'), findsOneWidget);
        expect(find.text('guarded-view'), findsNothing);
      },
    );

    testWidgets('an async middleware stopping the navigation degrades to the '
        'not-found page', (tester) async {
      await tester.pumpWidget(n0BuildApp(middlewares: [AsyncStopGuard()]));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('guarded-view'), findsNothing);
      expect(find.text('Route not found'), findsOneWidget);
    });

    testWidgets(
      'an async middleware keeping the route settles without a rebuild loop',
      (tester) async {
        await tester.pumpWidget(n0BuildApp(middlewares: [AsyncPassGuard()]));
        // Would time out here if every resolution notified the delegate again.
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('guarded-view'), findsOneWidget);
      },
    );
  });

  group('2107', () {
    setUp(Tab1View.resetCounters);
    tearDown(Get.reset);

    testWidgets(
      'navigating between sibling routes stacks them inside the outlet '
      '(previous sibling stays mounted, pop gesture no longer gated on isFirst)',
      (tester) async {
        await tester.pumpWidget(n1BuildApp());
        await tester.pumpAndSettle();
        expect(find.text('tab1-view'), findsOneWidget);
        expect(topOutletRoute().isFirst, isTrue);

        Get.rootController.rootDelegate.toNamed('/home/tab2');
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('tab2-view'), findsOneWidget);
        // The previous sibling is still mounted beneath the new one (offstage
        // under the opaque top route), retaining its state.
        expect(find.text('tab1-view', skipOffstage: false), findsOneWidget);
        expect(Tab1View.initCount, 1);
        expect(Tab1View.disposeCount, 0);
        // The exact #2107 gating condition: with a single route in the outlet
        // navigator, _isPopGestureEnabled bailed out at route.isFirst. The top
        // sibling now sits on a real stack.
        expect(topOutletRoute().isFirst, isFalse);
      },
    );

    testWidgets(
      'an imperative pop of the outlet navigator (back-gesture code path) '
      'pops the matching history entry and reveals the previous sibling',
      (tester) async {
        await tester.pumpWidget(n1BuildApp());
        await tester.pumpAndSettle();

        final delegate = Get.rootController.rootDelegate;
        var navigationCompleted = false;
        // ignore: unawaited_futures
        delegate.toNamed('/home/tab2').then((_) => navigationCompleted = true);
        await tester.pumpAndSettle();
        expect(find.text('tab2-view'), findsOneWidget);
        expect(delegate.activePages.length, 2);
        expect(navigationCompleted, isFalse);

        // A completed back-swipe ends in GetBackGestureController.dragEnd,
        // which calls navigator.pop() on the outlet's own navigator.
        outletNavigator().pop();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('tab2-view'), findsNothing);
        expect(find.text('tab1-view'), findsOneWidget);
        // The history entry was popped along with the visual route...
        expect(delegate.activePages.length, 1);
        expect(delegate.currentConfiguration?.pageSettings?.name, '/home/tab1');
        // ...its navigation future resolved...
        expect(navigationCompleted, isTrue);
        // ...and the revealed sibling kept its state (it was never disposed).
        expect(Tab1View.initCount, 1);
        expect(Tab1View.disposeCount, 0);
      },
    );

    testWidgets('a declarative back still works and does not double-pop '
        '(feedback-loop guard)', (tester) async {
      await tester.pumpWidget(n1BuildApp());
      await tester.pumpAndSettle();

      final delegate = Get.rootController.rootDelegate;
      delegate.toNamed('/home/tab2');
      await tester.pumpAndSettle();
      delegate.toNamed('/home/products');
      await tester.pumpAndSettle();
      expect(delegate.activePages.length, 3);
      expect(find.text('products-view'), findsOneWidget);

      // Removes the products entry from the history; the outlet navigator
      // then removes its route through a declarative page-list update, which
      // must NOT be reported back as a second pop.
      delegate.back();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('products-view'), findsNothing);
      expect(find.text('tab2-view'), findsOneWidget);
      expect(delegate.activePages.length, 2);
      expect(delegate.currentConfiguration?.pageSettings?.name, '/home/tab2');

      delegate.back();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('tab1-view'), findsOneWidget);
      expect(delegate.activePages.length, 1);
      expect(delegate.currentConfiguration?.pageSettings?.name, '/home/tab1');
    });

    testWidgets('a real back-swipe drag pops between outlet siblings', (
      tester,
    ) async {
      // The Cupertino transition tracks the drag with a horizontal slide
      // (the iOS behavior #2107 is about); the default test-platform zoom
      // transition does not engage the swipe even at the root navigator.
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/home/tab1',
          getPages: [
            GetPage(
              name: '/home',
              participatesInRootNavigator: true,
              page: () => Scaffold(
                body: GetRouterOutlet(
                  anchorRoute: '/home',
                  initialRoute: '/home/tab1',
                ),
              ),
              children: [
                GetPage(
                  name: '/tab1',
                  popGesture: true,
                  transition: Transition.cupertino,
                  page: () =>
                      const Scaffold(body: Center(child: Text('tab1-view'))),
                ),
                GetPage(
                  name: '/tab2',
                  popGesture: true,
                  transition: Transition.cupertino,
                  page: () =>
                      const Scaffold(body: Center(child: Text('tab2-view'))),
                ),
              ],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final delegate = Get.rootController.rootDelegate;
      delegate.toNamed('/home/tab2');
      await tester.pumpAndSettle();
      expect(find.text('tab2-view'), findsOneWidget);
      expect(delegate.activePages.length, 2);

      // Drag the top sibling far past the midpoint and release: the page
      // must track the finger and the release must pop it.
      final gesture = await tester.startGesture(const Offset(200, 300));
      await gesture.moveBy(const Offset(300, 0));
      await tester.pump();
      expect(
        tester.getTopLeft(find.text('tab2-view')).dx,
        greaterThan(300),
        reason: 'the top sibling must track the drag',
      );
      await gesture.moveBy(const Offset(300, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('tab2-view'), findsNothing);
      expect(find.text('tab1-view'), findsOneWidget);
      expect(delegate.activePages.length, 1);
      expect(delegate.currentConfiguration?.pageSettings?.name, '/home/tab1');
    });

    testWidgets(
      'an imperative pop of a deep-linked branch (single history entry) '
      'shortens the branch instead of emptying the history',
      (tester) async {
        await tester.pumpWidget(
          n1BuildApp(initialRoute: '/home/products/details'),
        );
        await tester.pumpAndSettle();

        final delegate = Get.rootController.rootDelegate;
        expect(find.text('details-view'), findsOneWidget);
        expect(delegate.activePages.length, 1);
        // The deep-linked branch already forms a stack inside the outlet.
        expect(topOutletRoute().isFirst, isFalse);

        outletNavigator().pop();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('details-view'), findsNothing);
        expect(find.text('products-view'), findsOneWidget);
        // The only history entry survived with its tree branch shortened.
        expect(delegate.activePages.length, 1);
        expect(delegate.currentConfiguration?.route?.name, '/home/products');
      },
    );
  });

  group('2122', () {
    testWidgets('Get.arguments returns the dialog arguments while it is open '
        'and the page arguments after it closes', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/first',
          getPages: [
            GetPage(page: () => const Text('first'), name: '/first'),
            GetPage(page: () => const Text('second'), name: '/second'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/second', arguments: 'page arguments');
      await tester.pumpAndSettle();
      expect(Get.arguments, 'page arguments');

      Get.dialog(const Text('dialog'), arguments: 'dialog arguments');
      await tester.pumpAndSettle();

      expect(find.text('dialog'), findsOneWidget);
      expect(Get.arguments, 'dialog arguments');

      Get.closeDialog();
      await tester.pumpAndSettle();

      expect(Get.arguments, 'page arguments');
    });

    testWidgets('a dialog opened without arguments keeps exposing the page '
        'arguments', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/first',
          getPages: [
            GetPage(page: () => const Text('first'), name: '/first'),
            GetPage(page: () => const Text('second'), name: '/second'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/second', arguments: 'page arguments');
      await tester.pumpAndSettle();

      Get.dialog(const Text('dialog'));
      await tester.pumpAndSettle();

      expect(Get.arguments, 'page arguments');

      Get.closeDialog();
      await tester.pumpAndSettle();
    });
  });

  group('2144', () {
    // GetMaterialApp/GetCupertinoApp did not expose restorationScopeId,
    // making it impossible to enable state restoration at the app level.

    Finder rootRestorationScopeWithId(String id) => find.byWidgetPredicate(
      (widget) => widget is RootRestorationScope && widget.restorationId == id,
    );

    testWidgets(
      'GetMaterialApp forwards restorationScopeId to MaterialApp (getPages)',
      (tester) async {
        await tester.pumpWidget(
          GetMaterialApp(
            restorationScopeId: 'app',
            initialRoute: '/',
            getPages: [GetPage(name: '/', page: () => const Text('home'))],
          ),
        );
        await tester.pumpAndSettle();

        expect(rootRestorationScopeWithId('app'), findsOneWidget);
      },
    );

    testWidgets('GetMaterialApp forwards restorationScopeId to MaterialApp '
        '(home, imperative navigation)', (tester) async {
      await tester.pumpWidget(
        const GetMaterialApp(restorationScopeId: 'app', home: Text('home')),
      );
      await tester.pumpAndSettle();

      expect(rootRestorationScopeWithId('app'), findsOneWidget);
    });

    testWidgets(
      'GetCupertinoApp forwards restorationScopeId to CupertinoApp (getPages)',
      (tester) async {
        await tester.pumpWidget(
          GetCupertinoApp(
            restorationScopeId: 'app',
            initialRoute: '/',
            getPages: [GetPage(name: '/', page: () => const Text('home'))],
          ),
        );
        await tester.pumpAndSettle();

        expect(rootRestorationScopeWithId('app'), findsOneWidget);
      },
    );

    testWidgets('GetCupertinoApp forwards restorationScopeId to CupertinoApp '
        '(home, imperative navigation)', (tester) async {
      await tester.pumpWidget(
        const GetCupertinoApp(restorationScopeId: 'app', home: Text('home')),
      );
      await tester.pumpAndSettle();

      expect(rootRestorationScopeWithId('app'), findsOneWidget);
    });

    test('router constructors accept restorationScopeId', () {
      const materialRouter = GetMaterialApp.router(restorationScopeId: 'app');
      const cupertinoRouter = GetCupertinoApp.router(restorationScopeId: 'app');

      expect(materialRouter.restorationScopeId, 'app');
      expect(cupertinoRouter.restorationScopeId, 'app');
    });
  });

  group('2245', () {
    tearDown(Get.reset);

    testWidgets('Get.to with a constructor tear-off produces a clean name', (
      tester,
    ) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: Scaffold(body: Text('home'))),
      );
      await tester.pumpAndSettle();

      Get.to(TearOffPage.new);
      await tester.pumpAndSettle();

      expect(find.text('tearoff'), findsOneWidget);
      expect(Get.currentRoute, '/TearOffPage');
    });

    testWidgets('Get.off with a constructor tear-off produces a clean name', (
      tester,
    ) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: Scaffold(body: Text('home'))),
      );
      await tester.pumpAndSettle();

      Get.off(TearOffPage.new);
      await tester.pumpAndSettle();

      expect(find.text('tearoff'), findsOneWidget);
      expect(Get.currentRoute, '/TearOffPage');
    });

    testWidgets('Get.to with a closure keeps its historical name', (
      tester,
    ) async {
      await tester.pumpWidget(
        const GetMaterialApp(home: Scaffold(body: Text('home'))),
      );
      await tester.pumpAndSettle();

      Get.to(() => const TearOffPage());
      await tester.pumpAndSettle();

      expect(find.text('tearoff'), findsOneWidget);
      expect(Get.currentRoute, '/TearOffPage');
    });
  });

  group('2257', () {
    testWidgets('snackbar closed before being shown never mounts', (
      tester,
    ) async {
      await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));

      Get.rawSnackbar(
        message: 'first',
        duration: const Duration(milliseconds: 500),
      );
      final second = Get.showSnackbar(
        const GetSnackBar(
          message: 'second',
          duration: Duration(milliseconds: 500),
        ),
      );

      // Cancel 'second' while it is still waiting behind 'first'.
      await second.close(withAnimations: false);

      await tester.pump();
      expect(find.text('first'), findsOneWidget);

      // Let 'first' expire; the queue then reaches the cancelled 'second' job,
      // which must not be displayed nor crash.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('second'), findsNothing);
      expect(Get.isSnackbarOpen, false);
      expect(tester.takeException(), isNull);

      // The queue keeps working for subsequent snackbars.
      Get.rawSnackbar(
        message: 'third',
        duration: const Duration(milliseconds: 500),
      );
      await tester.pump();
      expect(find.text('third'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(Get.isSnackbarOpen, false);
    });
  });

  group('2286 Arguments', () {
    testWidgets(
      'pages pushed in one action each build with their own arguments',
      (tester) async {
        final seen = <String, Object?>{};

        await tester.pumpWidget(
          Wrapper(
            initialRoute: '/home',
            namedRoutes: [
              GetPage(name: '/home', page: () => const Text('home')),
              GetPage(
                name: '/a',
                page: () => ArgsRecorder(tag: 'a', seen: seen),
              ),
              GetPage(
                name: '/b',
                page: () => ArgsRecorder(tag: 'b', seen: seen),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // Two pushes in the same frame; '/a' builds while '/b' is already the
        // top of the stack.
        Get.toNamed('/a', arguments: 'a-args');
        Get.toNamed('/b', arguments: 'b-args');
        await tester.pumpAndSettle();

        expect(seen['a'], 'a-args');
        expect(seen['b'], 'b-args');

        // Outside of a page build the accessor keeps its top-of-stack behavior.
        expect(Get.arguments, 'b-args');
      },
    );

    testWidgets(
      'pages pushed in one action each build with their own parameters',
      (tester) async {
        final seen = <String, String?>{};

        await tester.pumpWidget(
          Wrapper(
            initialRoute: '/home',
            namedRoutes: [
              GetPage(name: '/home', page: () => const Text('home')),
              GetPage(
                name: '/a',
                page: () => ParamsRecorder(tag: 'a', seen: seen),
              ),
              GetPage(
                name: '/b',
                page: () => ParamsRecorder(tag: 'b', seen: seen),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        Get.toNamed('/a', parameters: {'who': 'alice'});
        Get.toNamed('/b', parameters: {'who': 'bob'});
        await tester.pumpAndSettle();

        expect(seen['a'], 'alice');
        expect(seen['b'], 'bob');
        expect(Get.parameters['who'], 'bob');
      },
    );

    testWidgets('a single navigation still exposes its arguments globally', (
      tester,
    ) async {
      final seen = <String, Object?>{};

      await tester.pumpWidget(
        Wrapper(
          initialRoute: '/home',
          namedRoutes: [
            GetPage(name: '/home', page: () => const Text('home')),
            GetPage(
              name: '/a',
              page: () => ArgsRecorder(tag: 'a', seen: seen),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/a', arguments: {'answer': 42});
      await tester.pumpAndSettle();

      expect(seen['a'], {'answer': 42});
      expect(Get.arguments, {'answer': 42});
    });
  });

  group('2474', () {
    testWidgets('Get.back returns false when there is nothing to go back to '
        'and true when it pops', (tester) async {
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

      expect(find.text('first'), findsOneWidget);

      // Only page in the stack: back must be a detectable no-op.
      final backOnRoot = Get.back();
      await tester.pumpAndSettle();

      expect(backOnRoot, false);
      expect(find.text('first'), findsOneWidget);

      Get.toNamed('/second');
      await tester.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);

      final backFromSecond = Get.back();
      await tester.pumpAndSettle();

      expect(backFromSecond, true);
      expect(find.text('first'), findsOneWidget);
    });

    testWidgets('Get.back returns true when a local history entry handles '
        'the pop', (tester) async {
      final scaffoldKey = GlobalKey<ScaffoldState>();
      await tester.pumpWidget(
        Wrapper(
          child: Scaffold(
            key: scaffoldKey,
            drawer: const Drawer(child: Text('drawer')),
            body: const Text('body'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      scaffoldKey.currentState!.openDrawer();
      await tester.pumpAndSettle();
      expect(find.text('drawer'), findsOneWidget);

      final handled = Get.back();
      await tester.pumpAndSettle();

      expect(handled, true);
      expect(find.text('drawer'), findsNothing);
      expect(find.text('body'), findsOneWidget);
    });
  });

  group('2475', () {
    testWidgets('Get.to applies the given customTransition', (tester) async {
      final transition = _MarkerTransition();
      await tester.pumpWidget(const Wrapper(child: Text('home')));
      await tester.pumpAndSettle();

      expect(find.byKey(_marker, skipOffstage: false), findsNothing);

      Get.to(() => const Text('second'), customTransition: transition);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      // Mid transition the custom transition builder has been applied to the
      // incoming route.
      expect(transition.buildCount, greaterThan(0));
      expect(find.byKey(_marker, skipOffstage: false), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);
      expect(find.byKey(_marker), findsOneWidget);
    });

    testWidgets('Get.off applies the given customTransition', (tester) async {
      final transition = _MarkerTransition();
      await tester.pumpWidget(const Wrapper(child: Text('home')));
      await tester.pumpAndSettle();

      expect(find.byKey(_marker, skipOffstage: false), findsNothing);

      Get.off(() => const Text('second'), customTransition: transition);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(transition.buildCount, greaterThan(0));
      expect(find.byKey(_marker, skipOffstage: false), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);
      expect(find.byKey(_marker), findsOneWidget);
    });

    testWidgets('Get.offAll applies the given customTransition', (
      tester,
    ) async {
      final transition = _MarkerTransition();
      await tester.pumpWidget(const Wrapper(child: Text('home')));
      await tester.pumpAndSettle();

      expect(find.byKey(_marker, skipOffstage: false), findsNothing);

      Get.offAll(() => const Text('second'), customTransition: transition);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(transition.buildCount, greaterThan(0));
      expect(find.byKey(_marker, skipOffstage: false), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);
      expect(find.byKey(_marker), findsOneWidget);
    });

    testWidgets(
      'Get.to without customTransition keeps the default transition',
      (tester) async {
        await tester.pumpWidget(const Wrapper(child: Text('home')));
        await tester.pumpAndSettle();

        Get.to(() => const Text('second'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        expect(find.byKey(_marker, skipOffstage: false), findsNothing);

        await tester.pumpAndSettle();
        expect(find.text('second'), findsOneWidget);
        expect(find.byKey(_marker, skipOffstage: false), findsNothing);
      },
    );
  });

  group('2564', () {
    test('GetPage throws a descriptive AssertionError when the route name '
        'does not start with a slash', () {
      expect(
        () => GetPage(name: 'profile', page: () => const SizedBox()),
        throwsA(
          isA<AssertionError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('"profile"'),
              contains('must start with a slash'),
              contains('/profile'),
            ),
          ),
        ),
      );
    });

    test('GetPage accepts a route name that starts with a slash', () {
      final page = GetPage(name: '/profile', page: () => const SizedBox());
      expect(page.name, '/profile');
    });
  });

  group('2747', () {
    testWidgets('left bar indicator is clipped to the borderRadius', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GetSnackBar(
              message: 'msg',
              leftBarIndicatorColor: Colors.red,
              borderRadius: 12.0,
            ),
          ),
        ),
      );
      // Extra pump so the post-frame callback delivers the background box size
      // and the left bar indicator is built.
      await tester.pump();
      await tester.pump();

      final clip = find.descendant(
        of: find.byType(GetSnackBar),
        matching: find.byType(ClipRRect),
      );
      expect(clip, findsOneWidget);
      expect(
        tester.widget<ClipRRect>(clip).borderRadius,
        BorderRadius.circular(12.0),
      );

      // The left bar indicator must be inside the clipped area.
      final indicator = find.byWidgetPredicate(
        (widget) => widget is Container && widget.color == Colors.red,
      );
      expect(find.descendant(of: clip, matching: indicator), findsOneWidget);
    });

    testWidgets('no clip is added when borderRadius is zero', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GetSnackBar(
              message: 'msg',
              leftBarIndicatorColor: Colors.red,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(GetSnackBar),
          matching: find.byType(ClipRRect),
        ),
        findsNothing,
      );
    });
  });

  group('2761', () {
    testWidgets('closing a queued, not-yet-shown snackbar does not throw', (
      tester,
    ) async {
      await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));

      final first = Get.showSnackbar(
        const GetSnackBar(message: 'first', duration: Duration(seconds: 1)),
      );
      final second = Get.showSnackbar(
        const GetSnackBar(message: 'second', duration: Duration(seconds: 1)),
      );

      // 'second' is still queued behind 'first' and has no animation
      // controller yet; closing it must cancel it instead of crashing.
      await second.close();
      expect(tester.takeException(), isNull);

      await first.close(withAnimations: false);
      await tester.pumpAndSettle();

      expect(find.text('second'), findsNothing);
      expect(Get.isSnackbarOpen, false);
    });
  });

  group('2779', () {
    tearDown(Get.reset);

    testWidgets('v4-style redirect() is honored by toNamed', (tester) async {
      await tester.pumpWidget(n12BuildApp());
      await tester.pumpAndSettle();

      Get.toNamed('/protected');
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(ProtectedScreen), findsNothing);
      expect(Get.currentRoute, '/login');
    });

    testWidgets('redirect() arguments reach the target route', (tester) async {
      await tester.pumpWidget(
        n12BuildApp(protectedMiddlewares: [ArgsRedirectMiddleware()]),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/protected');
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(Get.currentRoute, '/login');
      expect(Get.arguments, {'callbackUrl': '/protected'});
    });

    testWidgets('v4-style redirect() is honored by offAllNamed', (
      tester,
    ) async {
      await tester.pumpWidget(n12BuildApp());
      await tester.pumpAndSettle();

      Get.offAllNamed('/protected');
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(ProtectedScreen), findsNothing);
      expect(Get.currentRoute, '/login');
      expect(Get.rootController.rootDelegate.activePages.length, 1);
    });

    testWidgets(
      'a null redirectDelegate stops replace-style navigation (offAllNamed)',
      (tester) async {
        await tester.pumpWidget(
          n12BuildApp(protectedMiddlewares: [StopDelegateMiddleware()]),
        );
        await tester.pumpAndSettle();

        Get.offAllNamed('/protected');
        await tester.pumpAndSettle();

        expect(find.byType(N12Home), findsOneWidget);
        expect(find.byType(ProtectedScreen), findsNothing);
        expect(Get.currentRoute, '/');
      },
    );
  });

  group('2975 3251 Prevent Duplicates', () {
    testWidgets('GetPage(preventDuplicates: false) allows duplicate pushes', (
      tester,
    ) async {
      await tester.pumpWidget(
        Wrapper(
          initialRoute: '/first',
          namedRoutes: [
            GetPage(name: '/first', page: () => const Text('first')),
            GetPage(
              name: '/dup',
              page: () => const Text('dup'),
              preventDuplicates: false,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/dup');
      await tester.pumpAndSettle();
      Get.toNamed('/dup');
      await tester.pumpAndSettle();

      final delegate = Get.rootController.rootDelegate;
      expect(delegate.activePages.map((e) => e.pageSettings?.name), [
        '/first',
        '/dup',
        '/dup',
      ]);

      // The duplicate instances must carry distinct page keys so the
      // navigator accepts both.
      final keys = delegate.activePages.map((e) => e.route?.key).toList();
      expect(keys.toSet().length, keys.length);

      // Popping the duplicate lands on the first '/dup' instance.
      Get.back();
      await tester.pumpAndSettle();
      expect(find.text('dup'), findsOneWidget);
      expect(delegate.activePages.length, 2);
      expect(delegate.activePages.last.pageSettings?.name, '/dup');
    });

    testWidgets('Get.toNamed(preventDuplicates: false) allows duplicates', (
      tester,
    ) async {
      await tester.pumpWidget(
        Wrapper(
          initialRoute: '/first',
          namedRoutes: [
            GetPage(name: '/first', page: () => const Text('first')),
            GetPage(name: '/second', page: () => const Text('second')),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/second');
      await tester.pumpAndSettle();
      Get.toNamed('/second', preventDuplicates: false);
      await tester.pumpAndSettle();

      final delegate = Get.rootController.rootDelegate;
      expect(delegate.activePages.map((e) => e.pageSettings?.name), [
        '/first',
        '/second',
        '/second',
      ]);
    });

    testWidgets('Get.to(preventDuplicates: false) stacks the same page type', (
      tester,
    ) async {
      await tester.pumpWidget(const Wrapper(child: Text('home')));
      await tester.pumpAndSettle();

      Get.to(() => const DupPage(), preventDuplicates: false);
      await tester.pumpAndSettle();
      Get.to(() => const DupPage(), preventDuplicates: false);
      await tester.pumpAndSettle();

      final delegate = Get.rootController.rootDelegate;
      expect(delegate.activePages.length, 3);
      expect(find.byType(DupPage), findsOneWidget);

      Get.back();
      await tester.pumpAndSettle();
      expect(find.byType(DupPage), findsOneWidget);
      expect(delegate.activePages.length, 2);
    });

    testWidgets('duplicate prevention still applies by default', (
      tester,
    ) async {
      await tester.pumpWidget(
        Wrapper(
          initialRoute: '/first',
          namedRoutes: [
            GetPage(name: '/first', page: () => const Text('first')),
            GetPage(name: '/second', page: () => const Text('second')),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/second');
      await tester.pumpAndSettle();
      Get.toNamed('/second');
      await tester.pumpAndSettle();

      final delegate = Get.rootController.rootDelegate;
      expect(delegate.activePages.map((e) => e.pageSettings?.name), [
        '/first',
        '/second',
      ]);
    });
  });

  group('3261 Prevent Duplicate Mode', () {
    test('copyWith preserves preventDuplicateHandlingMode', () {
      final page = GetPage(
        name: '/a',
        page: () => const Text('a'),
        preventDuplicateHandlingMode: PreventDuplicateHandlingMode.doNothing,
      );

      expect(
        page.copyWith().preventDuplicateHandlingMode,
        PreventDuplicateHandlingMode.doNothing,
      );
      expect(
        page
            .copyWith(
              preventDuplicateHandlingMode:
                  PreventDuplicateHandlingMode.recreate,
            )
            .preventDuplicateHandlingMode,
        PreventDuplicateHandlingMode.recreate,
      );
    });

    testWidgets('GetPage with doNothing ignores a duplicate navigation', (
      tester,
    ) async {
      await tester.pumpWidget(
        Wrapper(
          initialRoute: '/first',
          namedRoutes: [
            GetPage(name: '/first', page: () => const Text('first')),
            GetPage(
              name: '/keep',
              page: () => const Text('keep'),
              preventDuplicateHandlingMode:
                  PreventDuplicateHandlingMode.doNothing,
            ),
            GetPage(name: '/second', page: () => const Text('second')),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/keep');
      await tester.pumpAndSettle();
      Get.toNamed('/second');
      await tester.pumpAndSettle();

      // Duplicate navigation to '/keep': with doNothing the stack must stay
      // untouched instead of reordering '/keep' to the top.
      Get.toNamed('/keep');
      await tester.pumpAndSettle();

      final delegate = Get.rootController.rootDelegate;
      expect(delegate.activePages.map((e) => e.pageSettings?.name), [
        '/first',
        '/keep',
        '/second',
      ]);
      expect(find.text('second'), findsOneWidget);
    });

    testWidgets(
      'GetPage with popUntilOriginalRoute pops back to the original route',
      (tester) async {
        await tester.pumpWidget(
          Wrapper(
            initialRoute: '/first',
            namedRoutes: [
              GetPage(name: '/first', page: () => const Text('first')),
              GetPage(
                name: '/orig',
                page: () => const Text('orig'),
                preventDuplicateHandlingMode:
                    PreventDuplicateHandlingMode.popUntilOriginalRoute,
              ),
              GetPage(name: '/second', page: () => const Text('second')),
            ],
          ),
        );
        await tester.pumpAndSettle();

        Get.toNamed('/orig');
        await tester.pumpAndSettle();
        Get.toNamed('/second');
        await tester.pumpAndSettle();

        // Duplicate navigation to '/orig': the routes above the original
        // entry must be popped, keeping the original instance on top.
        Get.toNamed('/orig');
        await tester.pumpAndSettle();

        final delegate = Get.rootController.rootDelegate;
        expect(delegate.activePages.map((e) => e.pageSettings?.name), [
          '/first',
          '/orig',
        ]);
        expect(find.text('orig'), findsOneWidget);
      },
    );
  });

  group('3408', () {
    tearDown(Get.reset);

    testWidgets('middleware redirect can forward the original arguments', (
      tester,
    ) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => const N15Home()),
            GetPage(
              name: '/first',
              page: () => const N15FirstScreen(),
              middlewares: [N15ForwardArgumentsMiddleware()],
            ),
            GetPage(name: '/second', page: () => const N15SecondScreen()),
          ],
        ),
      );

      Get.toNamed('/first', arguments: {'answer': 42});
      await tester.pumpAndSettle();

      expect(find.byType(N15SecondScreen), findsOneWidget);
      expect(Get.currentRoute, '/second');
      expect(Get.arguments, {'answer': 42});
    });

    testWidgets('arguments of the incoming route are visible in middleware', (
      tester,
    ) async {
      Object? seenArgs;
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => const N15Home()),
            GetPage(
              name: '/first',
              page: () => const N15FirstScreen(),
              middlewares: [
                N15CaptureArgsMiddleware((args) => seenArgs = args),
              ],
            ),
          ],
        ),
      );

      Get.toNamed('/first', arguments: 'payload');
      await tester.pumpAndSettle();

      expect(seenArgs, 'payload');
      expect(Get.arguments, 'payload');
    });
  });
}
