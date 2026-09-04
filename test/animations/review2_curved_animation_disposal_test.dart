// initState and a replacement in didUpdateWidget without disposing either
// (each registers a listener on the controller, flagged by leak_tracker).
// The state must own the CurvedAnimation, dispose the replaced one on
// updates, and dispose the final one before the controller.
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

void main() {
  Widget build({
    required double end,
    required Curve curve,
    required ValueChanged<double> onValue,
    ValueSetter<AnimationController>? onStart,
  }) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GetAnimatedBuilder<double>(
        duration: const Duration(milliseconds: 100),
        delay: Duration.zero,
        tween: Tween<double>(begin: 0.0, end: end),
        idleValue: 0.0,
        curve: curve,
        onStart: onStart,
        builder: (context, value, child) {
          onValue(value);
          return const SizedBox.shrink();
        },
        child: const SizedBox.shrink(),
      ),
    );
  }

  testWidgets('rebuilding with a changed curve and tween swaps the animation, '
      'still renders correct values, and disposes cleanly', (tester) async {
    double? lastValue;

    await tester.pumpWidget(
      build(end: 1.0, curve: Curves.linear, onValue: (v) => lastValue = v),
    );
    await tester.pumpAndSettle();
    expect(lastValue, 1.0);

    // Changing curve and tween exercises the didUpdateWidget replacement
    // path: the old CurvedAnimation is disposed and the new tween/curve
    // pair drives the builder (the controller stayed completed, so the
    // new tween's end value must flow through).
    await tester.pumpWidget(
      build(end: 2.0, curve: Curves.easeIn, onValue: (v) => lastValue = v),
    );
    await tester.pumpAndSettle();
    expect(lastValue, 2.0);

    // Changing only the curve exercises the replacement path once more.
    await tester.pumpWidget(
      build(end: 2.0, curve: Curves.easeOut, onValue: (v) => lastValue = v),
    );
    await tester.pumpAndSettle();
    expect(lastValue, 2.0);

    // Unmount: dispose() must tear down the CurvedAnimation and the
    // controller without throwing (double-dispose or use-after-dispose).
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('every CurvedAnimation created by the builder is disposed', (
    tester,
  ) async {
    final created = <Object>{};
    final disposed = <Object>{};
    void listener(ObjectEvent event) {
      if (event.object is CurvedAnimation) {
        if (event is ObjectCreated) created.add(event.object);
        if (event is ObjectDisposed) disposed.add(event.object);
      }
    }

    FlutterMemoryAllocations.instance.addListener(listener);
    addTearDown(() {
      FlutterMemoryAllocations.instance.removeListener(listener);
    });

    await tester.pumpWidget(
      build(end: 1.0, curve: Curves.linear, onValue: (_) {}),
    );
    await tester.pumpAndSettle();

    // Two updates exercise the didUpdateWidget replacement path twice.
    await tester.pumpWidget(
      build(end: 2.0, curve: Curves.easeIn, onValue: (_) {}),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      build(end: 2.0, curve: Curves.easeOut, onValue: (_) {}),
    );
    await tester.pumpAndSettle();

    // Unmount so dispose() runs.
    await tester.pumpWidget(const SizedBox.shrink());

    // initState + two replacements.
    expect(created.length, 3);
    expect(
      disposed.containsAll(created),
      isTrue,
      reason:
          'every CurvedAnimation created by GetAnimatedBuilder must be '
          'disposed (${created.length} created, ${disposed.length} disposed)',
    );
  });

  testWidgets('animation replays correctly after an update', (tester) async {
    double? lastValue;
    AnimationController? controller;

    await tester.pumpWidget(
      build(
        end: 1.0,
        curve: Curves.linear,
        onValue: (v) => lastValue = v,
        onStart: (c) => controller = c,
      ),
    );
    await tester.pumpAndSettle();
    expect(lastValue, 1.0);
    expect(controller, isNotNull);

    await tester.pumpWidget(
      build(
        end: 4.0,
        curve: Curves.linear,
        onValue: (v) => lastValue = v,
        onStart: (c) => controller = c,
      ),
    );
    await tester.pump();

    // Replaying through the controller must use the NEW CurvedAnimation:
    // halfway through a linear 0->4 tween the value is 2.
    controller!.value = 0.5;
    await tester.pump();
    expect(lastValue, 2.0);

    controller!.value = 1.0;
    await tester.pumpAndSettle();
    expect(lastValue, 4.0);
  });
}
