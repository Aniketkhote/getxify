import 'dart:async';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';
import 'utils/wrapper.dart';

// Get.bottomSheet threw "No MaterialLocalizations found" under
// GetCupertinoApp, which installs no material localization delegates.
// The sheet must fall back to DefaultMaterialLocalizations instead.

// Get.back() and Get.close() must close an open Scaffold drawer instead of
// doing nothing (single page) or popping the whole page. Drawers are not
// routes: DrawerControllerState registers a LocalHistoryEntry on the
// enclosing page route, so the pop must go through the navigator, which
// consumes the entry and keeps the page.

class _DrawerPage extends StatelessWidget {
  const _DrawerPage({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      drawer: Drawer(child: Text('drawer of $label')),
      body: Text('body of $label'),
    );
  }
}

// Get.closeOverlay() called right after an awaited navigation returns must
// close the bottom sheet instead of popping page routes like Get.back().

// platform route report handled by GetDelegate.setNewRoutePath) with a
// Get.dialog or Get.bottomSheet open must close the overlay instead of
// popping the page it is anchored to.

/// Simulates the platform (browser back/forward button or a deep link)
/// reporting a new route to the app.
Future<void> n3SimulatePlatformRoute(
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

// Get.isOverlaysOpen (and friends) must not throw when called before
// a GetMaterialApp/GetRoot has been mounted.

void main() {
  // Base bottomsheet_test.dart tests
  testWidgets("Get.bottomSheet smoke test", (tester) async {
    await tester.pumpWidget(Wrapper(child: Container()));

    await tester.pump();

    Get.bottomSheet(
      Wrap(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text('Music'),
            onTap: () {},
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.music_note), findsOneWidget);
  });

  testWidgets("Get.bottomSheet close test", (tester) async {
    await tester.pumpWidget(Wrapper(child: Container()));

    await tester.pump();

    Get.bottomSheet(
      Wrap(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text('Music'),
            onTap: () {},
          ),
        ],
      ),
    );

    await tester.pumpAndSettle();

    expect(Get.isBottomSheetOpen, true);

    Get.backLegacy();
    await tester.pumpAndSettle();

    expect(Get.isBottomSheetOpen, false);

    // expect(() => Get.bottomSheet(Container(), isScrollControlled: null),
    //     throwsAssertionError);

    // expect(() => Get.bottomSheet(Container(), isDismissible: null),
    //     throwsAssertionError);

    // expect(() => Get.bottomSheet(Container(), enableDrag: null),
    //     throwsAssertionError);

    await tester.pumpAndSettle();
  });

  testWidgets("Get.bottomSheet with all properties smoke test", (tester) async {
    await tester.pumpWidget(Wrapper(child: Container()));
    await tester.pump();

    Get.bottomSheet(
      const Text('Test BottomSheet'),
      backgroundColor: Colors.red,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      barrierColor: Colors.black54,
      ignoreSafeArea: false,
      isScrollControlled: true,
      useRootNavigator: true,
      isDismissible: false,
      enableDrag: false,
      enterBottomSheetDuration: const Duration(milliseconds: 100),
      exitBottomSheetDuration: const Duration(milliseconds: 100),
      curve: Curves.easeIn,
    );

    await tester.pumpAndSettle();
    expect(find.text('Test BottomSheet'), findsOneWidget);
    expect(Get.isBottomSheetOpen, true);

    Get.backLegacy();
    await tester.pumpAndSettle();
    expect(Get.isBottomSheetOpen, false);
  });

  group('2337 Cupertino Bottomsheet', () {
    testWidgets("Get.bottomSheet works inside GetCupertinoApp", (tester) async {
      await tester.pumpWidget(
        GetCupertinoApp(
          home: const CupertinoPageScaffold(child: Text('cupertino home')),
        ),
      );
      await tester.pumpAndSettle();

      // Sanity check: the app really has no MaterialLocalizations installed.
      expect(
        Localizations.of<MaterialLocalizations>(
          Get.context!,
          MaterialLocalizations,
        ),
        isNull,
      );

      Get.bottomSheet(
        const SizedBox(
          height: 200,
          child: Center(child: Icon(Icons.music_note)),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.music_note), findsOneWidget);
      expect(Get.isBottomSheetOpen, true);

      Get.back();
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.music_note), findsNothing);
      expect(Get.isBottomSheetOpen, false);
      expect(find.text('cupertino home'), findsOneWidget);
    });

    testWidgets("Get.bottomSheet under GetCupertinoApp is dismissible", (
      tester,
    ) async {
      await tester.pumpWidget(
        GetCupertinoApp(
          home: const CupertinoPageScaffold(child: Text('cupertino home')),
        ),
      );
      await tester.pumpAndSettle();

      Get.bottomSheet(
        const SizedBox(height: 200, child: Center(child: Text('sheet'))),
      );
      await tester.pumpAndSettle();
      expect(find.text('sheet'), findsOneWidget);

      // Tap the barrier above the sheet to dismiss it.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.text('sheet'), findsNothing);
      expect(Get.isBottomSheetOpen, false);
    });
  });

  group('3227 Drawer Close', () {
    testWidgets("Get.back closes the drawer of the only page", (tester) async {
      await tester.pumpWidget(
        Wrapper(
          initialRoute: '/home',
          namedRoutes: [
            GetPage(
              name: '/home',
              page: () => const _DrawerPage(label: 'home'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      tester.firstState<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();
      expect(find.text('drawer of home'), findsOneWidget);

      Get.back();
      await tester.pumpAndSettle();

      // The drawer must be closed and the page must survive.
      expect(find.text('drawer of home'), findsNothing);
      expect(find.text('body of home'), findsOneWidget);
      expect(Get.currentRoute, '/home');
    });

    testWidgets("Get.back closes the drawer first, then pops the page", (
      tester,
    ) async {
      await tester.pumpWidget(
        Wrapper(
          initialRoute: '/home',
          namedRoutes: [
            GetPage(
              name: '/home',
              page: () => const _DrawerPage(label: 'home'),
            ),
            GetPage(
              name: '/second',
              page: () => const _DrawerPage(label: 'second'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      Get.toNamed('/second');
      await tester.pumpAndSettle();
      expect(find.text('body of second'), findsOneWidget);

      tester.firstState<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();
      expect(find.text('drawer of second'), findsOneWidget);

      Get.back();
      await tester.pumpAndSettle();

      // First back only closes the drawer.
      expect(find.text('drawer of second'), findsNothing);
      expect(find.text('body of second'), findsOneWidget);
      expect(Get.currentRoute, '/second');

      Get.back();
      await tester.pumpAndSettle();

      // Second back pops the page as usual.
      expect(find.text('body of home'), findsOneWidget);
      expect(Get.currentRoute, '/home');
    });

    testWidgets("Get.close closes an open drawer", (tester) async {
      await tester.pumpWidget(
        Wrapper(
          initialRoute: '/home',
          namedRoutes: [
            GetPage(
              name: '/home',
              page: () => const _DrawerPage(label: 'home'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      tester.firstState<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();
      expect(find.text('drawer of home'), findsOneWidget);

      Get.close();
      await tester.pumpAndSettle();

      expect(find.text('drawer of home'), findsNothing);
      expect(find.text('body of home'), findsOneWidget);
      expect(Get.currentRoute, '/home');
    });

    testWidgets("Get.back still pops a dialog shown above an open drawer", (
      tester,
    ) async {
      await tester.pumpWidget(
        Wrapper(
          initialRoute: '/home',
          namedRoutes: [
            GetPage(
              name: '/home',
              page: () => const _DrawerPage(label: 'home'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      tester.firstState<ScaffoldState>(find.byType(Scaffold)).openDrawer();
      await tester.pumpAndSettle();

      Get.dialog(const Text('dialog above drawer'));
      await tester.pumpAndSettle();
      expect(find.text('dialog above drawer'), findsOneWidget);

      Get.back();
      await tester.pumpAndSettle();

      // The dialog is topmost, so back closes it and leaves the drawer open.
      expect(find.text('dialog above drawer'), findsNothing);
      expect(find.text('drawer of home'), findsOneWidget);

      Get.back();
      await tester.pumpAndSettle();

      expect(find.text('drawer of home'), findsNothing);
      expect(find.text('body of home'), findsOneWidget);
    });
  });

  group('3316 Close Overlay', () {
    testWidgets(
      "Get.closeOverlay after awaited Get.toNamed closes the sheet, not pages",
      (tester) async {
        await tester.pumpWidget(
          Wrapper(
            initialRoute: '/home',
            namedRoutes: [
              GetPage(name: '/home', page: () => const Text('home')),
              GetPage(name: '/second', page: () => const Text('second')),
              GetPage(name: '/third', page: () => const Text('third')),
            ],
          ),
        );
        await tester.pumpAndSettle();

        Get.toNamed('/second');
        await tester.pumpAndSettle();
        expect(find.text('second'), findsOneWidget);

        showModalBottomSheet(
          context: Get.context!,
          builder: (_) => const Text('sheet'),
        );
        await tester.pumpAndSettle();
        expect(find.text('sheet'), findsOneWidget);

        // Mirrors the reporter's flow: navigate from the sheet, and close the
        // sheet as soon as the awaited navigation future completes.
        var closeOverlayCalled = false;
        unawaited(() async {
          await Get.toNamed('/third');
          Get.closeOverlay();
          closeOverlayCalled = true;
        }());
        await tester.pumpAndSettle();
        expect(find.text('third'), findsOneWidget);

        Get.back();
        await tester.pumpAndSettle();

        expect(closeOverlayCalled, true);
        // The sheet must be closed...
        expect(find.text('sheet'), findsNothing);
        // ...and /second must NOT have been popped.
        expect(find.text('second'), findsOneWidget);
        expect(Get.currentRoute, '/second');
      },
    );

    testWidgets("Get.closeOverlay does not pop page routes", (tester) async {
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

      Get.closeOverlay();
      await tester.pumpAndSettle();

      expect(find.text('second'), findsOneWidget);
      expect(Get.currentRoute, '/second');
    });
  });

  group('3322 Browser Back Overlay', () {
    testWidgets('platform back closes an open dialog instead of the page', (
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

      Get.dialog(const Text('my dialog'));
      await tester.pumpAndSettle();
      expect(find.text('my dialog'), findsOneWidget);

      final delegate = Get.rootController.rootDelegate;
      expect(delegate.activePages.length, 2);

      // Browser back: only the dialog must be dismissed.
      await n3SimulatePlatformRoute(tester, '/first');
      await tester.pumpAndSettle();

      expect(find.text('my dialog'), findsNothing);
      expect(find.text('second'), findsOneWidget);
      expect(delegate.activePages.length, 2);
      expect(delegate.activePages.last.pageSettings?.name, '/second');

      // A further back press with no overlay open pops the page.
      await n3SimulatePlatformRoute(tester, '/first');
      await tester.pumpAndSettle();

      expect(find.text('first'), findsOneWidget);
      expect(delegate.activePages.length, 1);
    });

    testWidgets('platform back closes stacked overlays one at a time', (
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

      Get.bottomSheet(const SizedBox(height: 100, child: Text('sheet')));
      await tester.pumpAndSettle();
      Get.dialog(const Text('my dialog'));
      await tester.pumpAndSettle();

      final delegate = Get.rootController.rootDelegate;

      await n3SimulatePlatformRoute(tester, '/first');
      await tester.pumpAndSettle();
      expect(find.text('my dialog'), findsNothing);
      expect(find.text('sheet'), findsOneWidget);
      expect(delegate.activePages.length, 2);

      await n3SimulatePlatformRoute(tester, '/first');
      await tester.pumpAndSettle();
      expect(find.text('sheet'), findsNothing);
      expect(find.text('second'), findsOneWidget);
      expect(delegate.activePages.length, 2);

      await n3SimulatePlatformRoute(tester, '/first');
      await tester.pumpAndSettle();
      expect(find.text('first'), findsOneWidget);
      expect(delegate.activePages.length, 1);
    });
  });

  group('3370 Overlays Open', () {
    test("overlay getters are safe before routing initialization", () {
      expect(() => Get.isOverlaysOpen, returnsNormally);
      expect(Get.isOverlaysOpen, false);
      expect(Get.isOverlaysClosed, true);
      expect(Get.isDialogOpen, isNull);
      expect(Get.isBottomSheetOpen, isNull);
    });
  });
}
