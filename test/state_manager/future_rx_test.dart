import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

void main() {
  test('Future.toRx tracks loading and success states', () async {
    final future = Future.delayed(
      const Duration(milliseconds: 20),
      () => 'Async Result',
    );
    final rx = future.toRx();

    expect(rx.value.isLoading, isTrue);

    await future;
    // Allow microtasks to complete
    await Future.delayed(const Duration(milliseconds: 5));

    expect(rx.value.isSuccess, isTrue);
    expect(rx.value.data, 'Async Result');
  });

  test('Future.toRx tracks error state on exception', () async {
    final future = Future<String>.error('network failure');
    final rx = future.toRx();

    // Catch the error to prevent uncaught test zone error
    try {
      await future;
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 5));

    expect(rx.value.isError, isTrue);
    expect(rx.value.errorMessage, 'network failure');
  });
}
