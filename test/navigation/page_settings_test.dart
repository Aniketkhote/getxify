import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

void main() {
  testWidgets('context.settings returns null when context has no ModalRoute', (
    tester,
  ) async {
    RouteSettings? settings;
    PageSettings? pageSettings;
    Object? arguments;

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          settings = context.settings;
          pageSettings = context.pageSettings;
          arguments = context.arguments;
          return const SizedBox.shrink();
        },
      ),
    );

    expect(settings, isNull);
    expect(pageSettings, isNull);
    expect(arguments, isNull);
  });
}
