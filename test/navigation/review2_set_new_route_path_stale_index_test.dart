// reported route BEFORE awaiting the pop-veto surface (_isPopVetoed) and
// used it afterwards without re-validation. A willPop callback that
// navigates during that await left the index pointing into a mutated
// history, so the pop loop removed unrelated pages. The delegate must
// re-locate the target entry after the await (mirroring popRoute's
// post-await guard) and bail out when it is gone.
import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

/// Simulates the platform (browser back/forward button or a deep link)
/// reporting a new route to the app.
Future<void> simulatePlatformRoute(WidgetTester tester, String location) async {
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

List<String?> names(GetDelegate delegate) =>
    delegate.activePages.map((e) => e.pageSettings?.name).toList();

void main() {
  tearDown(() {
    Get.reset();
  });

  testWidgets(
    'a willPop callback navigating during the platform-back veto check '
    'must not make setNewRoutePath pop unrelated pages',
    (tester) async {
      final vetoEntered = Completer<void>();
      final vetoRelease = Completer<bool>();

      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/home',
          getPages: [
            GetPage(name: '/home', page: () => const Text('home')),
            GetPage(name: '/first', page: () => const Text('first')),
            GetPage(
              name: '/guarded',
              // ignore: deprecated_member_use
              page: () => WillPopScope(
                onWillPop: () {
                  if (!vetoEntered.isCompleted) vetoEntered.complete();
                  return vetoRelease.future;
                },
                child: const Text('guarded'),
              ),
            ),
            GetPage(name: '/a', page: () => const Text('a')),
            GetPage(name: '/b', page: () => const Text('b')),
            GetPage(name: '/c', page: () => const Text('c')),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/first');
      await tester.pumpAndSettle();
      Get.toNamed('/guarded');
      await tester.pumpAndSettle();

      final delegate = Get.rootController.rootDelegate;
      expect(names(delegate), ['/home', '/first', '/guarded']);

      // The platform reports '/first' (browser back): exactly one page
      // would be popped, so setNewRoutePath awaits the willPop veto
      // surface of '/guarded', which blocks on [vetoRelease].
      unawaited(simulatePlatformRoute(tester, '/first'));
      await tester.pump();
      expect(vetoEntered.isCompleted, isTrue);

      // While the veto check is pending, replace the whole history. Only
      // microtasks are flushed (tester.idle), no frame is built, so the
      // navigator's visual top route is unchanged and the in-flight
      // setNewRoutePath proceeds past its own top-route identity check.
      Get.offAllNamed('/a');
      await tester.idle();
      Get.toNamed('/b');
      await tester.idle();
      Get.toNamed('/c');
      await tester.idle();
      expect(names(delegate), ['/a', '/b', '/c']);

      // Allow the pop: the veto callback returns true, resuming
      // setNewRoutePath against the mutated history.
      vetoRelease.complete(true);
      await tester.idle();
      await tester.pumpAndSettle();

      // The reported '/first' entry is gone, so setNewRoutePath must be a
      // no-op. Before the fix the stale index popped '/c'.
      expect(names(delegate), ['/a', '/b', '/c']);
      expect(find.text('c'), findsOneWidget);
    },
  );

  testWidgets(
    'platform back still pops one page when the willPop callback allows it '
    'and does not navigate',
    (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/home',
          getPages: [
            GetPage(name: '/home', page: () => const Text('home')),
            GetPage(name: '/first', page: () => const Text('first')),
            GetPage(
              name: '/guarded',
              // ignore: deprecated_member_use
              page: () => WillPopScope(
                onWillPop: () async => true,
                child: const Text('guarded'),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/first');
      await tester.pumpAndSettle();
      Get.toNamed('/guarded');
      await tester.pumpAndSettle();

      await simulatePlatformRoute(tester, '/first');
      await tester.pumpAndSettle();

      final delegate = Get.rootController.rootDelegate;
      expect(names(delegate), ['/home', '/first']);
      expect(find.text('first'), findsOneWidget);
    },
  );
}
