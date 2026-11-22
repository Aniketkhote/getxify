import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

class _TestService extends GetxService {
  bool closed = false;
  @override
  void onClose() {
    closed = true;
    super.onClose();
  }
}

void main() {
  test('GetContainer put and find work in isolation', () {
    final container = GetContainer();
    final service = _TestService();

    container.put<_TestService>(service);
    expect(container.isRegistered<_TestService>(), isTrue);
    expect(container.isPrepared<_TestService>(), isTrue);
    expect(container.find<_TestService>(), same(service));

    // Global Get should NOT contain it
    expect(Get.isRegistered<_TestService>(), isFalse);
  });

  test('GetContainer lazyPut initializes on first find', () {
    final container = GetContainer();
    container.lazyPut<_TestService>(() => _TestService());

    expect(container.isRegistered<_TestService>(), isTrue);
    expect(container.isPrepared<_TestService>(), isFalse);

    final service = container.find<_TestService>();
    expect(container.isPrepared<_TestService>(), isTrue);
    expect(service, isA<_TestService>());
  });

  test('GetContainer reset invokes onDelete lifecycle', () {
    final container = GetContainer();
    final service = _TestService();
    container.put<_TestService>(service);

    container.reset();
    expect(service.closed, isTrue);
    expect(container.isRegistered<_TestService>(), isFalse);
  });
}
