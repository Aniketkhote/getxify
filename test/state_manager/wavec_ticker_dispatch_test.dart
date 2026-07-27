import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

class _SingleController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late final Ticker ticker;

  @override
  void onInit() {
    super.onInit();
    ticker = createTicker((_) {});
  }

  @override
  void onClose() {
    ticker.dispose();
    super.onClose();
  }
}

class _MultiController extends GetxController with GetTickerProviderStateMixin {
  late final Ticker ticker;
  final count = 0.obs;

  @override
  void onInit() {
    super.onInit();
    ticker = createTicker((_) {});
  }

  @override
  void onClose() {
    ticker.dispose();
    super.onClose();
  }
}

void main() {
  test('both ticker mixins implement the shared GetTickerProvider '
      'interface', () {
    expect(_SingleController(), isA<GetTickerProvider>());
    expect(_MultiController(), isA<GetTickerProvider>());
    expect(_SingleController(), isA<TickerProvider>());
    expect(_MultiController(), isA<TickerProvider>());
  });

  testWidgets(
    'GetBuilder forwards TickerMode to a GetSingleTickerProviderStateMixin '
    'controller through the single GetTickerProvider dispatch',
    (tester) async {
      await tester.pumpWidget(
        TickerMode(
          enabled: false,
          child: GetBuilder<_SingleController>(
            init: _SingleController(),
            builder: (_) => const SizedBox(),
          ),
        ),
      );

      final controller = Get.find<_SingleController>();
      expect(controller.ticker.muted, isTrue);

      await tester.pumpWidget(
        TickerMode(
          enabled: true,
          child: GetBuilder<_SingleController>(
            builder: (_) => const SizedBox(),
          ),
        ),
      );
      expect(controller.ticker.muted, isFalse);

      await tester.pumpWidget(const SizedBox());
      expect(Get.isRegistered<_SingleController>(), isFalse);
    },
  );

  testWidgets(
    'GetBuilder forwards TickerMode to a GetTickerProviderStateMixin controller '
    'through the single GetTickerProvider dispatch',
    (tester) async {
      await tester.pumpWidget(
        TickerMode(
          enabled: false,
          child: GetBuilder<_MultiController>(
            init: _MultiController(),
            builder: (c) =>
                Text('${c.count.value}', textDirection: TextDirection.ltr),
          ),
        ),
      );

      final controller = Get.find<_MultiController>();
      expect(controller.ticker.muted, isTrue);

      await tester.pumpWidget(
        TickerMode(
          enabled: true,
          child: GetBuilder<_MultiController>(
            builder: (c) =>
                Text('${c.count.value}', textDirection: TextDirection.ltr),
          ),
        ),
      );
      expect(controller.ticker.muted, isFalse);

      await tester.pumpWidget(const SizedBox());
      expect(Get.isRegistered<_MultiController>(), isFalse);
    },
  );
}
