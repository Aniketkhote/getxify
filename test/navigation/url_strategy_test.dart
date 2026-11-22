import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

void main() {
  test('removeLastHistory completes without infinite recursion', () {
    expect(() => removeLastHistory(null), returnsNormally);
    expect(() => removeLastHistory('/home'), returnsNormally);
  });
}
