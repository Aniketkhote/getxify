import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

void main() {
  test(
    'rxComputed derives initial value and updates when dependency changes',
    () {
      final firstName = 'John'.obs;
      final lastName = 'Doe'.obs;

      final fullName = rxComputed(() => '${firstName.value} ${lastName.value}');
      expect(fullName.value, 'John Doe');

      firstName.value = 'Jane';
      expect(fullName.value, 'Jane Doe');

      lastName.value = 'Smith';
      expect(fullName.value, 'Jane Smith');

      fullName.close();
    },
  );

  test('rxComputed memoizes result and cleans up on close', () {
    final counter = 0.obs;
    var computeCount = 0;

    final doubled = rxComputed(() {
      computeCount++;
      return counter.value * 2;
    });

    expect(computeCount, 1);
    expect(doubled.value, 0);
    // Reading multiple times does NOT recompute
    expect(doubled.value, 0);
    expect(computeCount, 1);

    counter.value = 5;
    expect(doubled.value, 10);
    expect(computeCount, 2);

    doubled.close();
    counter.value = 10;
    // After close, no further updates occur
    expect(computeCount, 2);
  });
}
