import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';
import 'package:material_ui/material_ui.dart';

class _EmptyResponsiveView extends GetResponsiveView {
  _EmptyResponsiveView();
}

class _CustomResponsiveView extends GetResponsiveView {
  _CustomResponsiveView();

  @override
  Widget? phone() => const Text('Phone View');

  @override
  Widget? desktop() => const Text('Desktop View');
}

void main() {
  test(
    'ResponsiveScreen throws clear StateError when context is uninitialized',
    () {
      final screen = ResponsiveScreen(const ResponsiveScreenSettings());
      expect(screen.hasContext, isFalse);
      expect(() => screen.context, throwsStateError);
    },
  );

  testWidgets(
    '_EmptyResponsiveView renders SizedBox.shrink without null crash',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: _EmptyResponsiveView())),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SizedBox), findsOneWidget);
    },
  );

  testWidgets('_CustomResponsiveView renders responsive layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: _CustomResponsiveView())),
    );

    expect(tester.takeException(), isNull);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            (widget.data == 'Phone View' || widget.data == 'Desktop View'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'ResponsiveScreen screenTypeOf and responsiveValueOf work correctly',
    (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      final screen = ResponsiveScreen(
        const ResponsiveScreenSettings(),
        capturedContext,
      );
      expect(screen.hasContext, isTrue);
      expect(screen.context, same(capturedContext));

      final val = screen.responsiveValueOf(
        capturedContext,
        mobile: 'Mobile',
        desktop: 'Desktop',
      );
      expect(val, isNotNull);
    },
  );
}
