import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:getxify/getxify.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Engine.instance returns initialized WidgetsBinding', () {
    final binding = Engine.instance;
    expect(binding, isNotNull);
    expect(binding, isA<WidgetsBinding>());
    expect(binding, same(WidgetsBinding.instance));
  });
}
