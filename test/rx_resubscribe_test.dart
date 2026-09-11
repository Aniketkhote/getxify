import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

void main() {
  test(
    'Rx emits after its last listener cancels and a new one subscribes',
    () async {
      final rx = 0.obs;
      final first = rx.stream.listen((_) {});
      await Future<void>.delayed(Duration.zero);
      await first.cancel();

      final values = <int>[];
      final second = rx.stream.listen(values.add);
      rx.value = 42;
      await Future<void>.delayed(Duration.zero);

      await second.cancel();
      rx.close();
      expect(values, contains(42));
    },
  );
}
