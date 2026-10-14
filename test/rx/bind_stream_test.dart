import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

void main() {
  test(
    'bindStream survives downstream listener unsubscribe and resubscribe',
    () async {
      final controller = StreamController<int>.broadcast();
      final rx = 0.obs..bindStream(controller.stream);

      // First listener subscribes then unsubscribes
      final sub1 = rx.stream.listen((_) {});
      controller.add(1);
      await pumpEventQueue();
      expect(rx.value, 1);
      await sub1.cancel();

      // Rx now has 0 listeners; verify upstream stream still updates rx.value
      controller.add(2);
      await pumpEventQueue();
      expect(rx.value, 2);

      // Second listener subscribes
      final received = <int>[];
      final sub2 = rx.stream.listen(received.add);
      controller.add(3);
      await pumpEventQueue();

      expect(received, contains(3));
      await sub2.cancel();
      rx.close();
      await controller.close();
    },
  );

  test(
    'bindStreamBuilder pauses on 0 listeners and resumes on new listener',
    () async {
      int factoryInvocations = 0;
      StreamController<int>? currentController;

      final rx = 0.obs
        ..bindStreamBuilder(() {
          factoryInvocations++;
          currentController = StreamController<int>();
          return currentController!.stream;
        });

      expect(factoryInvocations, 1);

      final sub1 = rx.stream.listen((_) {});
      currentController?.add(10);
      await pumpEventQueue();
      expect(rx.value, 10);

      // Drops to 0 listeners -> stream should cancel
      await sub1.cancel();
      expect(currentController?.hasListener, isFalse);

      // New listener -> factory should be invoked again
      final sub2 = rx.stream.listen((_) {});
      expect(factoryInvocations, 2);
      currentController?.add(20);
      await pumpEventQueue();
      expect(rx.value, 20);

      await sub2.cancel();
      rx.close();
    },
  );

  test('bindStream forwards errors to Rx subject stream', () async {
    final controller = StreamController<int>();
    final rx = 0.obs..bindStream(controller.stream);

    Object? caughtError;
    final sub = rx.stream.listen(
      (_) {},
      onError: (Object err) {
        caughtError = err;
      },
    );

    controller.addError(Exception('stream-error'));
    await pumpEventQueue();

    expect(caughtError, isA<Exception>());
    expect(caughtError.toString(), contains('stream-error'));

    await sub.cancel();
    rx.close();
    await controller.close();
  });

  test(
    'bindStream on already disposed Rx returns safely without throwing',
    () async {
      final rx = 0.obs;
      rx.close();

      final controller = StreamController<int>.broadcast();
      final sub = rx.bindStream(controller.stream);

      expect(sub, isNotNull);
      controller.add(42);
      await pumpEventQueue();
      expect(rx.value, 0);

      await controller.close();
    },
  );

  testWidgets('bindStream is not cancelled when Obx widget unmounts', (
    tester,
  ) async {
    final controller = StreamController<int>.broadcast();
    final rx = 0.obs;

    // Build Obx widget that lazily binds the stream during build
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Obx(() {
          // Binding stream during Obx build should NOT be hijacked by unmountDisposers
          if (rx.value == 0) {
            rx.bindStream(controller.stream);
          }
          return Text('val: ${rx.value}');
        }),
      ),
    );

    expect(find.text('val: 0'), findsOneWidget);

    controller.add(1);
    await tester.pump();
    await tester.pump();
    expect(find.text('val: 1'), findsOneWidget);

    // Unmount the widget tree completely
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    // Stream should STILL be bound and functional on rx
    controller.add(2);
    await tester.pump();
    expect(rx.value, 2);

    rx.close();
    await controller.close();
  });
}
