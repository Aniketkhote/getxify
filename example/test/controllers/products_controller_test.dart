import 'package:example/app/modules/products/controllers/products_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductsController', () {
    late ProductsController controller;

    setUp(() {
      controller = ProductsController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('onInit populates sample products and sets success status', () {
      controller.onInit();
      expect(controller.products, isNotEmpty);
      expect(controller.status.isSuccess, isTrue);
    });

    test(
      'setting search query to non-matching string updates status to empty',
      () async {
        controller.onInit();
        controller.searchQuery.value = 'non_matching_product_name_xyz';
        await Future.delayed(const Duration(milliseconds: 350));
        expect(controller.filteredProducts, isEmpty);
        expect(controller.status.isEmpty, isTrue);
      },
    );
  });
}
