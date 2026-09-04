import 'package:material_ui/material_ui.dart';
import 'package:getxify/getxify.dart';

import '../../../../models/demo_product.dart';

/// Controller for the product details screen
/// Manages product lookup via route parameter, quantity state, and cart actions
class ProductDetailsController extends GetxController {
  final String productId;

  /// Selected quantity
  final quantity = 1.obs;

  /// Loaded product instance
  late final DemoProduct product;

  ProductDetailsController(this.productId);

  @override
  void onInit() {
    super.onInit();
    product = DemoProduct.sampleProducts.firstWhere(
      (p) => p.id == productId,
      orElse: () => DemoProduct(
        id: productId,
        name: 'Custom Product ($productId)',
        category: 'Electronics',
        price: 2999.00,
        oldPrice: 3499.00,
        rating: 4.8,
        reviewCount: 42,
        description:
            'Detailed description for item $productId loaded from parameter URL.',
        badge: 'Special',
        iconData: Icons.devices,
        themeColor: Colors.indigo,
        isFeatured: true,
      ),
    );
  }

  void incrementQuantity() => quantity.value++;

  void decrementQuantity() {
    if (quantity.value > 1) quantity.value--;
  }
}
