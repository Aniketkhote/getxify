import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';
import 'utils/wrapper.dart';

class YourDialogWidget extends StatelessWidget {
  const YourDialogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

// Get.defaultDialog declared onCustom, textCustom and custom but never
// used them, so the custom action silently never showed up.

// Get.bottomSheet should accept arguments (and a route name) directly,
// like Get.dialog, instead of forcing callers to build RouteSettings.

// Get.showOverlay only removed its barrier and loading widget in an
// `on Exception` clause, so a non-Exception throw (a String error, or any
// Error) left the overlay on screen forever.

// Get.defaultDialog must expose AlertDialog's scrollable property so that
// tall content scrolls instead of overflowing.

void main() {
  // Base dialog_test.dart tests
  testWidgets("Get.defaultDialog smoke test", (tester) async {
    await tester.pumpWidget(Wrapper(child: Container()));

    await tester.pump();

    Get.defaultDialog(
      onConfirm: () {},
      middleText: "Dialog made in 3 lines of code",
    );

    await tester.pumpAndSettle();

    expect(find.text("Ok"), findsOneWidget);
  });

  testWidgets("Get.dialog smoke test", (tester) async {
    await tester.pumpWidget(Wrapper(child: Container()));

    await tester.pump();

    Get.dialog(const YourDialogWidget());

    await tester.pumpAndSettle();

    expect(find.byType(YourDialogWidget), findsOneWidget);
  });

  group("Get dialog close tests", () {
    /// Set up the test by opening a dialog and checking to ensure state is correct
    Future<void> setUpCloseTest(WidgetTester tester) async {
      await tester.pumpWidget(Wrapper(child: Container()));

      await tester.pump();

      Get.dialog(const YourDialogWidget());
      await tester.pumpAndSettle();

      expect(find.byType(YourDialogWidget), findsOneWidget);
      expect(Get.isDialogOpen, true);
    }

    /// Tear down the test by checking after closing the dialog
    Future<void> tearDownCloseTest(WidgetTester tester) async {
      await tester.pumpAndSettle();

      expect(find.byType(YourDialogWidget), findsNothing);
      expect(Get.isDialogOpen, false);
      await tester.pumpAndSettle();
    }

    testWidgets("Get dialog close - with backLegacy", (tester) async {
      await setUpCloseTest(tester);
      // Close using backLegacy
      Get.backLegacy();
      await tearDownCloseTest(tester);
    });

    testWidgets("Get dialog close - with closeDialog", (tester) async {
      await setUpCloseTest(tester);
      // Close using closeDialog
      Get.closeDialog();
      await tearDownCloseTest(tester);
    });
  });

  group("Get.closeDialog", () {
    testWidgets("Get.closeDialog - closes dialog and returns value", (
      tester,
    ) async {
      await tester.pumpWidget(Wrapper(child: Container()));

      await tester.pump();

      final result = Get.dialog(const YourDialogWidget());
      await tester.pumpAndSettle();

      expect(find.byType(YourDialogWidget), findsOneWidget);
      expect(Get.isDialogOpen, true);

      const dialogResult = "My dialog result";

      Get.closeDialog(result: dialogResult);
      await tester.pumpAndSettle();

      final returnedResult = await result;
      expect(returnedResult, dialogResult);

      expect(find.byType(YourDialogWidget), findsNothing);
      expect(Get.isDialogOpen, false);
      await tester.pumpAndSettle();
    });

    testWidgets("Get.closeDialog - does not close bottomsheets", (
      tester,
    ) async {
      await tester.pumpWidget(Wrapper(child: Container()));

      await tester.pump();

      Get.bottomSheet(const YourDialogWidget());
      await tester.pumpAndSettle();

      expect(find.byType(YourDialogWidget), findsOneWidget);
      expect(Get.isDialogOpen, false);

      Get.closeDialog();
      await tester.pumpAndSettle();

      expect(find.byType(YourDialogWidget), findsOneWidget);
    });
  });

  testWidgets("Get.dialog with all properties smoke test", (tester) async {
    await tester.pumpWidget(Wrapper(child: Container()));
    await tester.pump();

    Get.dialog(
      const YourDialogWidget(),
      barrierDismissible: false,
      barrierColor: Colors.red,
      useSafeArea: false,
      transitionDuration: const Duration(milliseconds: 100),
      transitionCurve: Curves.easeIn,
      name: 'TestDialog',
      id: 'test_id',
    );

    await tester.pumpAndSettle();
    expect(find.byType(YourDialogWidget), findsOneWidget);
    expect(Get.isDialogOpen, true);

    Get.backLegacy();
    await tester.pumpAndSettle();
    expect(Get.isDialogOpen, false);
  });

  group('1716 Default Dialog Custom', () {
    testWidgets("textCustom/onCustom render a tappable custom button", (
      tester,
    ) async {
      await tester.pumpWidget(Wrapper(child: Container()));
      await tester.pumpAndSettle();

      var customPressed = false;
      Get.defaultDialog(
        title: 'Dialog',
        middleText: 'message',
        textConfirm: 'Ok',
        textCustom: 'MyCustomAction',
        onCustom: () => customPressed = true,
      );
      await tester.pumpAndSettle();

      expect(find.text('MyCustomAction'), findsOneWidget);

      await tester.tap(find.text('MyCustomAction'));
      await tester.pumpAndSettle();

      expect(customPressed, isTrue);
      // Like the confirm button, the custom button does not auto-close.
      expect(Get.isDialogOpen, isTrue);
    });

    testWidgets("onCustom alone renders the default 'Custom' label", (
      tester,
    ) async {
      await tester.pumpWidget(Wrapper(child: Container()));
      await tester.pumpAndSettle();

      var customPressed = false;
      Get.defaultDialog(title: 'Dialog', onCustom: () => customPressed = true);
      await tester.pumpAndSettle();

      expect(find.text('Custom'), findsOneWidget);

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();

      expect(customPressed, isTrue);
    });

    testWidgets("a custom widget is shown among the dialog actions", (
      tester,
    ) async {
      await tester.pumpWidget(Wrapper(child: Container()));
      await tester.pumpAndSettle();

      const customKey = Key('custom-action');
      Get.defaultDialog(
        title: 'Dialog',
        middleText: 'message',
        custom: ElevatedButton(
          key: customKey,
          onPressed: () {},
          child: const Text('FromWidget'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(customKey), findsOneWidget);
      expect(find.text('FromWidget'), findsOneWidget);
    });

    testWidgets("custom takes precedence over textCustom/onCustom", (
      tester,
    ) async {
      await tester.pumpWidget(Wrapper(child: Container()));
      await tester.pumpAndSettle();

      Get.defaultDialog(
        title: 'Dialog',
        custom: const Text('WidgetWins'),
        textCustom: 'ButtonLoses',
        onCustom: () {},
      );
      await tester.pumpAndSettle();

      expect(find.text('WidgetWins'), findsOneWidget);
      expect(find.text('ButtonLoses'), findsNothing);
    });
  });

  group('2005', () {
    testWidgets('Get.bottomSheet forwards arguments and name to its route', (
      tester,
    ) async {
      await tester.pumpWidget(Wrapper(child: Container()));
      await tester.pump();

      Object? routeArguments;
      String? routeName;
      Get.bottomSheet(
        Builder(
          builder: (context) {
            final settings = ModalRoute.of(context)!.settings;
            routeArguments = settings.arguments;
            routeName = settings.name;
            return const Text('sheet');
          },
        ),
        arguments: 'sheet arguments',
        name: '/sheet',
      );
      await tester.pumpAndSettle();

      expect(find.text('sheet'), findsOneWidget);
      expect(routeArguments, 'sheet arguments');
      expect(routeName, '/sheet');
      expect(Get.arguments, 'sheet arguments');

      Get.closeBottomSheet();
      await tester.pumpAndSettle();
    });

    testWidgets('an explicit settings wins over the arguments shortcut', (
      tester,
    ) async {
      await tester.pumpWidget(Wrapper(child: Container()));
      await tester.pump();

      Object? routeArguments;
      Get.bottomSheet(
        Builder(
          builder: (context) {
            routeArguments = ModalRoute.of(context)!.settings.arguments;
            return const Text('sheet');
          },
        ),
        arguments: 'ignored',
        settings: const RouteSettings(arguments: 'from settings'),
      );
      await tester.pumpAndSettle();

      expect(routeArguments, 'from settings');

      Get.closeBottomSheet();
      await tester.pumpAndSettle();
    });
  });

  group('2827 Show Overlay Error', () {
    testWidgets(
      "overlay is removed when asyncFunction throws a non-Exception",
      (tester) async {
        await tester.pumpWidget(Wrapper(child: const Text('page')));
        await tester.pumpAndSettle();

        Object? error;
        Get.showOverlay<void>(
          asyncFunction: () => Future<void>.error('boom'),
          loadingWidget: const Text('loading-marker'),
        ).then(
          (_) {},
          onError: (Object e) {
            error = e;
          },
        );
        await tester.pumpAndSettle();

        // The error still propagates to the caller...
        expect(error, 'boom');
        // ...and the barrier/loader must be gone.
        expect(find.text('loading-marker'), findsNothing);
        expect(find.byType(Opacity), findsNothing);
        expect(find.text('page'), findsOneWidget);
      },
    );

    testWidgets("overlay is removed when asyncFunction throws an Error", (
      tester,
    ) async {
      await tester.pumpWidget(Wrapper(child: const Text('page')));
      await tester.pumpAndSettle();

      Object? error;
      Get.showOverlay<void>(
        asyncFunction: () async => throw StateError('bad state'),
        loadingWidget: const Text('loading-marker'),
      ).then(
        (_) {},
        onError: (Object e) {
          error = e;
        },
      );
      await tester.pumpAndSettle();

      expect(error, isA<StateError>());
      expect(find.text('loading-marker'), findsNothing);
    });

    testWidgets("overlay shows while running and result is returned", (
      tester,
    ) async {
      await tester.pumpWidget(Wrapper(child: const Text('page')));
      await tester.pumpAndSettle();

      int? result;
      Get.showOverlay<int>(
        asyncFunction: () async {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          return 42;
        },
        loadingWidget: const Text('loading-marker'),
      ).then((value) => result = value);
      await tester.pump();

      expect(find.text('loading-marker'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(result, 42);
      expect(find.text('loading-marker'), findsNothing);
    });
  });

  group('3330 Default Dialog Scrollable', () {
    testWidgets("Get.defaultDialog forwards scrollable to AlertDialog", (
      tester,
    ) async {
      await tester.pumpWidget(Wrapper(child: Container()));
      await tester.pump();

      Get.defaultDialog(
        scrollable: true,
        onConfirm: () {},
        content: const SizedBox(height: 2000, width: 50),
      );
      await tester.pumpAndSettle();

      final alertDialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(alertDialog.scrollable, true);
      expect(tester.takeException(), isNull);
    });

    testWidgets("Get.defaultDialog is not scrollable by default", (
      tester,
    ) async {
      await tester.pumpWidget(Wrapper(child: Container()));
      await tester.pump();

      Get.defaultDialog(onConfirm: () {});
      await tester.pumpAndSettle();

      final alertDialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(alertDialog.scrollable, false);
    });
  });
}
