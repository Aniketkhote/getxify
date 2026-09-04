import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

class SampleController {
  final String title = 'Hello GetXify';
}

void main() {
  testWidgets('ContextExt theme, mediaQuery and responsive properties', (
    tester,
  ) async {
    late BuildContext savedContext;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: ThemeMode.light,
        home: Builder(
          builder: (context) {
            savedContext = context;
            return const SizedBox(width: 400, height: 800);
          },
        ),
      ),
    );

    expect(savedContext.theme, isA<ThemeData>());
    expect(savedContext.isDarkMode, isFalse);
    expect(savedContext.mediaQuerySize, isA<Size>());
    expect(savedContext.height, equals(savedContext.mediaQuerySize.height));
    expect(savedContext.width, equals(savedContext.mediaQuerySize.width));
    expect(savedContext.isPhoneOrLess, isFalse);
    expect(savedContext.isPhoneOrWider, isTrue);
  });

  testWidgets('ContextExt find dependency lookup works', (tester) async {
    Get.put(SampleController());
    late BuildContext savedContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            savedContext = context;
            return const Text('Test');
          },
        ),
      ),
    );

    final controller = savedContext.find<SampleController>();
    expect(controller, isNotNull);
    expect(controller.title, equals('Hello GetXify'));

    Get.resetInstance();
  });

  testWidgets('ContextExt showDialog and showSnackbar', (tester) async {
    late BuildContext savedContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              savedContext = context;
              return ElevatedButton(
                onPressed: () {
                  savedContext.showSnackbar(
                    const SnackBar(content: Text('Snackbar Test')),
                  );
                },
                child: const Text('Button'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.text('Snackbar Test'), findsOneWidget);
  });
}
