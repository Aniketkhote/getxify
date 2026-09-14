import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';
import 'package:material_ui/material_ui.dart';

class SharedController extends GetxController {}

void main() {
  tearDown(Get.reset);

  testWidgets('closing second route keeps first route shared controller', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/a',
        getPages: [
          GetPage(
            name: '/a',
            page: () => const Scaffold(body: Text('a')),
            bindings: [
              Binding.builder(() {
                Get.lazyPut<SharedController>(SharedController.new);
              }),
            ],
          ),
          GetPage(
            name: '/b',
            page: () => const Scaffold(body: Text('b')),
            bindings: [
              Binding.builder(() {
                Get.lazyPut<SharedController>(SharedController.new);
              }),
            ],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final original = Get.find<SharedController>();

    unawaited(Get.toNamed<void>('/b'));
    await tester.pumpAndSettle();
    expect(identical(original, Get.find<SharedController>()), isTrue);

    Get.back<void>();
    await tester.pumpAndSettle();

    // This should pass - the controller registered by route /a should still be available
    expect(Get.isRegistered<SharedController>(), isTrue);
    expect(original.isClosed, isFalse);
  });
}
