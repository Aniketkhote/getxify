import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/common/obx_error.dart';
import 'package:getxify/getxify.dart';

void main() {
  testWidgets("GetxController smoke test", (tester) async {
    final controller = Get.put(Controller());
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            Obx(
              () => Column(
                children: [
                  Text('Count: ${controller.counter.value}'),
                  Text('Double: ${controller.doubleNum.value}'),
                  Text('String: ${controller.string.value}'),
                  Text('List: ${controller.list.length}'),
                  Text('Bool: ${controller.boolean.value}'),
                  Text('Map: ${controller.map.length}'),
                  TextButton(
                    onPressed: controller.increment,
                    child: const Text("increment"),
                  ),
                  Obx(() => Text('Obx: ${controller.map.length}')),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    expect(find.text("Count: 0"), findsOneWidget);
    expect(find.text("Double: 0.0"), findsOneWidget);
    expect(find.text("String: string"), findsOneWidget);
    expect(find.text("Bool: true"), findsOneWidget);
    expect(find.text("List: 0"), findsOneWidget);
    expect(find.text("Map: 0"), findsOneWidget);
    expect(find.text("Obx: 0"), findsOneWidget);

    Controller.to.increment();

    await tester.pump();

    expect(find.text("Count: 1"), findsOneWidget);

    await tester.tap(find.text('increment'));

    await tester.pump();

    expect(find.text("Count: 2"), findsOneWidget);
  });

  testWidgets(
    "Obx reacts to bindStream across multiple rebuilds without dropping stream",
    (tester) async {
      final controller = StreamController<int>();
      final count = 0.obs;
      count.bindStream(controller.stream);

      await tester.pumpWidget(
        MaterialApp(home: Obx(() => Text('Value: ${count.value}'))),
      );

      expect(find.text('Value: 0'), findsOneWidget);

      // First rebuild
      controller.add(1);
      await tester.pump();
      await tester.pump();
      expect(find.text('Value: 1'), findsOneWidget);

      // Second rebuild - should still receive events from the stream
      controller.add(2);
      await tester.pump();
      await tester.pump();
      expect(find.text('Value: 2'), findsOneWidget);

      // Third rebuild
      controller.add(3);
      await tester.pump();
      await tester.pump();
      expect(find.text('Value: 3'), findsOneWidget);

      await controller.close();
      count.close();
    },
  );

  testWidgets("Obx does not leak duplicate listeners across rebuilds", (
    tester,
  ) async {
    final count = 0.obs;

    await tester.pumpWidget(
      MaterialApp(home: Obx(() => Text('Count: ${count.value}'))),
    );

    // Initial build: exactly 1 subscriber
    expect(count.hasSubscribers, isTrue);

    // Rebuild multiple times
    for (var i = 1; i <= 5; i++) {
      count.value = i;
      await tester.pump();
      expect(find.text('Count: $i'), findsOneWidget);
    }

    // Unmount widget
    await tester.pumpWidget(const SizedBox());

    // All listeners should be cleaned up on unmount
    expect(count.hasSubscribers, isFalse);
    count.close();
  });

  testWidgets("Obx handles dynamic conditional dependencies correctly", (
    tester,
  ) async {
    final showFirst = true.obs;
    final first = 'first'.obs;
    final second = 'second'.obs;

    await tester.pumpWidget(
      MaterialApp(
        home: Obx(() => Text(showFirst.value ? first.value : second.value)),
      ),
    );

    expect(find.text('first'), findsOneWidget);
    expect(first.hasSubscribers, isTrue);
    expect(second.hasSubscribers, isFalse);

    // Switch to second
    showFirst.value = false;
    await tester.pump();

    expect(find.text('second'), findsOneWidget);
    // first should have been unsubscribed, second subscribed
    expect(first.hasSubscribers, isFalse);
    expect(second.hasSubscribers, isTrue);

    // Updating second triggers rebuild
    second.value = 'second updated';
    await tester.pump();
    expect(find.text('second updated'), findsOneWidget);

    // Updating first does NOT trigger rebuild
    first.value = 'first updated';
    await tester.pump();
    expect(find.text('second updated'), findsOneWidget);

    // Switch back to first
    showFirst.value = true;
    await tester.pump();
    expect(find.text('first updated'), findsOneWidget);
    expect(first.hasSubscribers, isTrue);
    expect(second.hasSubscribers, isFalse);
  });

  testWidgets("Obx throws ObxError when no reactive variable is accessed", (
    tester,
  ) async {
    expect(() => Obx(() => const Text('Static text')), returnsNormally);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Obx(() => const Text('No reactive variable'));
          },
        ),
      ),
    );

    expect(tester.takeException(), isA<ObxError>());
  });
}

class Controller extends GetxController {
  static Controller get to => Get.find();

  RxInt counter = 0.obs;
  RxDouble doubleNum = 0.0.obs;
  RxString string = "string".obs;
  RxList list = [].obs;
  RxMap map = {}.obs;
  RxBool boolean = true.obs;

  void increment() {
    counter.value++;
  }
}
