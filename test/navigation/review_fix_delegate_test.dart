import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('first'));
  }
}

class SecondPage extends StatelessWidget {
  const SecondPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('second'));
  }
}

class ThirdPage extends StatelessWidget {
  const ThirdPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Text('third'));
  }
}

GetMaterialApp buildApp() {
  return GetMaterialApp(
    initialRoute: '/first',
    getPages: [
      GetPage(name: '/first', page: () => const FirstPage()),
      GetPage(name: '/second', page: () => const SecondPage()),
      GetPage(name: '/third', page: () => const ThirdPage()),
    ],
  );
}

/// Captures the `routeInformationUpdated` messages the framework sends to
/// the engine (the same messages that drive the browser history on web).
List<Map<dynamic, dynamic>> captureRouteInformationUpdates(
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

void main() {
  tearDown(Get.reset);

  group('setNewRoutePath with duplicate same-name entries', () {
    testWidgets(
      'platform back from a duplicated top route pops to the lower duplicate',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        Get.toNamed('/second');
        await tester.pumpAndSettle();

        // Build a stack containing two '/second' entries, as produced by
        // pushes with duplicate prevention disabled. A distinct page key is
        // used so the Navigator accepts both entries.
        final delegate = Get.rootController.rootDelegate;
        final duplicate = RouteDecoder.fromRoute('/second');
        duplicate.route = duplicate.route!.copyWith(key: UniqueKey());
        delegate.activePages.add(duplicate);

        expect(delegate.activePages.length, 3);
        expect(delegate.activePages[1].pageSettings?.name, '/second');
        expect(delegate.activePages[2].pageSettings?.name, '/second');

        // Browser back: the platform history moves from the top '/second'
        // to the lower '/second' and reports that name. The app stack must
        // pop to the lower duplicate instead of ignoring the report.
        await simulatePlatformRoute(tester, '/second');
        await tester.pumpAndSettle();

        expect(delegate.activePages.length, 2);
        expect(delegate.activePages.last.pageSettings?.name, '/second');
        expect(delegate.activePages.first.pageSettings?.name, '/first');
        expect(find.text('second'), findsOneWidget);
      },
    );

    testWidgets(
      're-reporting the current top route without a lower duplicate is a no-op',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        Get.toNamed('/second');
        await tester.pumpAndSettle();

        final delegate = Get.rootController.rootDelegate;
        expect(delegate.activePages.length, 2);

        await simulatePlatformRoute(tester, '/second');
        await tester.pumpAndSettle();

        expect(delegate.activePages.length, 2);
        expect(delegate.activePages.last.pageSettings?.name, '/second');
      },
    );

    testWidgets('platform back to a distinct lower route still pops to it', (
      tester,
    ) async {
      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      Get.toNamed('/second');
      await tester.pumpAndSettle();
      Get.toNamed('/third');
      await tester.pumpAndSettle();

      final delegate = Get.rootController.rootDelegate;
      expect(delegate.activePages.length, 3);

      await simulatePlatformRoute(tester, '/first');
      await tester.pumpAndSettle();

      expect(delegate.activePages.length, 1);
      expect(find.text('first'), findsOneWidget);
    });
  });

  group('pending replace report coalescing', () {
    testWidgets(
      'an ordinary push after a same-frame replace navigation is reported '
      'as a push, not a replace',
      (tester) async {
        final updates = captureRouteInformationUpdates(tester);

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();
        updates.clear();

        // Replace-style navigation immediately followed by an ordinary push
        // in the same frame: the single coalesced report is for '/third'
        // and must carry push semantics (the last navigation wins).
        Get.offNamed('/second');
        Get.toNamed('/third');
        await tester.pumpAndSettle();

        expect(updates, isNotEmpty);
        expect(updates.last['uri'], '/third');
        expect(updates.last['replace'], isFalse);

        final delegate = Get.rootController.rootDelegate;
        expect(delegate.activePages.map((e) => e.pageSettings?.name), [
          '/second',
          '/third',
        ]);
      },
    );

    testWidgets('offUntil is still reported as a history replace', (
      tester,
    ) async {
      final updates = captureRouteInformationUpdates(tester);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();

      Get.toNamed('/second');
      await tester.pumpAndSettle();
      updates.clear();

      // offUntil delegates to [to] internally; the internal push must not
      // cancel the pending replace report set by offUntil.
      Get.offUntil(() => const ThirdPage(), (route) => route.name == '/first');
      await tester.pumpAndSettle();

      expect(updates, isNotEmpty);
      expect(updates.last['replace'], isTrue);
    });

    testWidgets('a plain toNamed is still reported as a history push', (
      tester,
    ) async {
      final updates = captureRouteInformationUpdates(tester);

      await tester.pumpWidget(buildApp());
      await tester.pumpAndSettle();
      updates.clear();

      Get.toNamed('/second');
      await tester.pumpAndSettle();

      expect(updates, isNotEmpty);
      expect(updates.last['uri'], '/second');
      expect(updates.last['replace'], isFalse);
    });
  });
}
