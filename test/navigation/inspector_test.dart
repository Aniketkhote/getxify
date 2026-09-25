import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

class InspectorController extends GetxController {
  int closeCount = 0;

  @override
  void onClose() {
    closeCount++;
    super.onClose();
  }
}

class HomeController extends InspectorController {}

class DetailController extends InspectorController {}

void main() {
  tearDown(() {
    WidgetsBinding.instance.debugShowWidgetInspectorOverride = false;
    Get.reset();
  });

  testWidgets('Inspector preserves controllers in a multi-route stack', (
    tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: '/home',
        getPages: [
          GetPage(
            name: '/home',
            page: () => const Scaffold(body: Text('Home')),
            bindings: [Binding.lazyPut<HomeController>(HomeController.new)],
          ),
          GetPage(
            name: '/detail',
            page: () => const Scaffold(body: Text('Detail')),
            bindings: [Binding.lazyPut<DetailController>(DetailController.new)],
          ),
        ],
        builder: (context, child) => Stack(
          fit: StackFit.expand,
          children: [
            child!,
            const Positioned.fill(
              child: IgnorePointer(child: SizedBox.expand()),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final home = Get.find<HomeController>();

    unawaited(Get.toNamed<void>('/detail'));
    await tester.pumpAndSettle();

    final detail = Get.find<DetailController>();

    for (var i = 0; i < 5; i++) {
      WidgetsBinding.instance.debugShowWidgetInspectorOverride = true;
      await tester.pumpAndSettle();

      WidgetsBinding.instance.debugShowWidgetInspectorOverride = false;
      await tester.pumpAndSettle();
    }

    expect(Get.currentRoute, '/detail');
    expect(Get.find<HomeController>(), same(home));
    expect(Get.find<DetailController>(), same(detail));
    expect(home.closeCount, 0);
    expect(detail.closeCount, 0);

    Get.back<void>();
    await tester.pumpAndSettle();

    expect(detail.closeCount, 1);
    expect(detail.isClosed, isTrue);
    expect(Get.isRegistered<DetailController>(), isFalse);
    expect(Get.find<HomeController>(), same(home));
  });
}
