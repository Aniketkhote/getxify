import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

class SampleController extends GetxController {
  final count = 0.obs;
}

class SampleBinding implements Binding {
  @override
  void dependencies() {
    Get.put(SampleController());
  }
}

void main() {
  tearDown(() {
    Get.resetInstance();
  });

  test('SampleBinding registers dependency via dependencies()', () {
    final binding = SampleBinding();
    binding.dependencies();

    expect(Get.isRegistered<SampleController>(), isTrue);
    final controller = Get.find<SampleController>();
    expect(controller.count.value, 0);
  });

  test('Binding.builder registers dependency inline', () {
    final inlineBinding = Binding.builder(() {
      Get.put(SampleController());
    });

    inlineBinding.dependencies();

    expect(Get.isRegistered<SampleController>(), isTrue);
    final controller = Get.find<SampleController>();
    expect(controller.count.value, 0);
  });

  test('Binding.put, Binding.lazyPut, and Binding.builder zero-arg variants work', () {
    final bPut = Binding.put(SampleController());
    bPut.dependencies();
    expect(Get.isRegistered<SampleController>(), isTrue);

    Get.resetInstance();

    final bLazy = Binding.lazyPut(() => SampleController());
    bLazy.dependencies();
    expect(Get.isPrepared<SampleController>(), isTrue);
    expect(Get.find<SampleController>().count.value, 0);

    Get.resetInstance();

    final bZeroArg = Binding.builder(() {
      Get.put(SampleController());
    });
    bZeroArg.dependencies();
    expect(Get.isRegistered<SampleController>(), isTrue);
  });
}
