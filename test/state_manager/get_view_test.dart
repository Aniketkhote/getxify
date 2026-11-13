import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';
import 'package:material_ui/material_ui.dart';

class TestViewController extends GetxController {
  final String title;
  TestViewController([this.title = 'Default']);
}

class SampleView extends GetView<TestViewController> {
  const SampleView({super.key, super.tag});

  @override
  Widget build(BuildContext context) {
    return Text(controller.title);
  }
}

class SampleResponsiveView extends GetResponsiveView<TestViewController> {
  SampleResponsiveView({super.key, super.tag});

  @override
  Widget? phone() => Text('Phone: ${controller.title}');

  @override
  Widget? desktop() => Text('Desktop: ${controller.title}');
}

void main() {
  tearDown(Get.reset);

  testWidgets('GetView retrieves default controller when tag is null', (
    tester,
  ) async {
    Get.put(TestViewController('Untagged Controller'));

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SampleView())),
    );

    expect(find.text('Untagged Controller'), findsOneWidget);
  });

  testWidgets('GetView retrieves tagged controller passed via constructor', (
    tester,
  ) async {
    Get.put(TestViewController('Controller A'), tag: 'tagA');
    Get.put(TestViewController('Controller B'), tag: 'tagB');

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SampleView(tag: 'tagA'),
              SampleView(tag: 'tagB'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Controller A'), findsOneWidget);
    expect(find.text('Controller B'), findsOneWidget);
  });

  testWidgets('GetResponsiveView passes constructor tag properly', (
    tester,
  ) async {
    Get.put(TestViewController('Responsive Controller'), tag: 'respTag');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SampleResponsiveView(tag: 'respTag')),
      ),
    );

    expect(find.byType(SampleResponsiveView), findsOneWidget);
  });
}
