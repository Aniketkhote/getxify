import 'package:material_ui/material_ui.dart';
import 'package:getxify/getxify.dart';

import '../../../../services/cart_service.dart';
import '../../cart/views/cart_bottom_sheet.dart';
import '../controllers/product_details_controller.dart';

/// Product details screen view
/// Demonstrates navigation with route parameters (/products/:productId)
class ProductDetailsView extends GetView<ProductDetailsController> {
  const ProductDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    final product = controller.product;
    final cartService = CartService.to;

    return Scaffold(
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    cartService.addToCart(
                      product,
                      quantity: controller.quantity.value,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Add to Cart'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    cartService.addToCart(
                      product,
                      quantity: controller.quantity.value,
                    );
                    showCartBottomSheet();
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Buy Now'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Navigation & Action Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Get.back(),
                ),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Obx(() {
                  final isFav = cartService.isWishlisted(product.id);
                  return IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : null,
                    ),
                    onPressed: () => cartService.toggleWishlist(product.id),
                  );
                }),
              ],
            ),
            const SizedBox(height: 12),

            // Product Hero Banner
            Container(
              height: 240,
              width: double.infinity,
              decoration: BoxDecoration(
                color: product.themeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Hero(
                    tag: 'product-${product.id}',
                    child: Icon(
                      product.iconData,
                      size: 110,
                      color: product.themeColor,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        product.badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Product Name & Category
            Text(
              product.category.toUpperCase(),
              style: TextStyle(
                color: Colors.indigo.shade400,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              product.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // Rating & Price Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${product.rating}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '(${product.reviewCount} reviews)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    if (product.oldPrice > product.price)
                      Text(
                        '₹${product.oldPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Quantity Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Quantity:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.4),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: controller.decrementQuantity,
                      ),
                      Obx(
                        () => Text(
                          '${controller.quantity.value}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: controller.incrementQuantity,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // Description Section
            const Text(
              'Product Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              product.description,
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),

            const SizedBox(height: 20),

            // Route Parameter Info Box showcasing GetXify feature
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: Colors.indigo),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Loaded dynamically via GetXify route parameter: /products/${controller.productId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
