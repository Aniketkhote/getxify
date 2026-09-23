import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

class TestController extends GetxController {
  int initCount = 0;
  int closeCount = 0;

  @override
  void onInit() {
    super.onInit();
    initCount++;
  }

  @override
  void onClose() {
    super.onClose();
    closeCount++;
  }
}

void main() {
  tearDown(Get.reset);

  testWidgets(
    'Flutter Inspector tree change should not dispose route controllers',
    (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/',
          getPages: [
            GetPage(
              name: '/',
              page: () => const Scaffold(body: Text('Home')),
              bindings: [
                Binding.builder(() {
                  Get.lazyPut<TestController>(TestController.new);
                }),
              ],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final controller = Get.find<TestController>();
      expect(controller.initCount, 1);
      expect(controller.closeCount, 0);

      // Simulate Flutter Inspector wrapping the tree with WidgetInspector
      // This is what happens when "Toggle Select Widget Mode" is enabled
      final originalFinder = find.text('Home');
      expect(originalFinder, findsOneWidget);

      // Force a tree rebuild by wrapping with a Container (simulating Inspector)
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/',
          getPages: [
            GetPage(
              name: '/',
              page: () => const Scaffold(body: Text('Home')),
              bindings: [
                Binding.builder(() {
                  Get.lazyPut<TestController>(TestController.new);
                }),
              ],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Controller should not be disposed and recreated
      expect(
        controller.initCount,
        1,
        reason: 'onInit should not be called again',
      );
      expect(controller.closeCount, 0, reason: 'onClose should not be called');
      expect(controller.isClosed, isFalse);
    },
  );

  testWidgets(
    'GetDependencyScope with GlobalKey preserves state across tree changes',
    (tester) async {
      final scopeKey = GlobalKey<State>();

      await tester.pumpWidget(
        GetMaterialApp(
          home: GetDependencyScope(
            key: scopeKey,
            keys: {'TestController'},
            child: Builder(
              builder: (context) {
                Get.lazyPut<TestController>(TestController.new);
                final controller = Get.find<TestController>();
                return Scaffold(
                  body: Text('Test, init: ${controller.initCount}'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final controller = Get.find<TestController>();
      expect(controller.initCount, 1);
      expect(controller.closeCount, 0);

      // Simulate tree change by rebuilding with different parent
      await tester.pumpWidget(
        GetMaterialApp(
          home: GetDependencyScope(
            key: scopeKey,
            keys: {'TestController'},
            child: Builder(
              builder: (context) {
                final c = Get.find<TestController>();
                return Scaffold(body: Text('Test, init: ${c.initCount}'));
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Controller should not be disposed
      expect(controller.closeCount, 0);
      expect(controller.isClosed, isFalse);
      expect(controller.initCount, 1);
    },
  );
}
