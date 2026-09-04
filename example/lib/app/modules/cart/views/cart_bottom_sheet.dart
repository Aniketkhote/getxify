import 'package:material_ui/material_ui.dart';
import 'package:getxify/getxify.dart';

import '../../../../services/auth_service.dart';
import '../../../../services/cart_service.dart';
import '../../../routes/app_pages.dart';

/// Show cart bottom sheet without requiring BuildContext
void showCartBottomSheet() {
  Get.bottomSheet(
    const CartBottomSheet(),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class CartBottomSheet extends StatelessWidget {
  const CartBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final cartService = CartService.to;
    final authService = AuthService.to;
    final promoController = TextEditingController();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.shopping_bag, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text(
                  'Shopping Cart',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Obx(
                  () => Chip(
                    label: Text('${cartService.itemCount} Items'),
                    backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (cartService.cartItems.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.remove_shopping_cart,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Your cart is currently empty',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: cartService.cartItems.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = cartService.cartItems[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: item.product.themeColor.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              item.product.iconData,
                              color: item.product.themeColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.product.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹${item.product.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.indigo,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  cartService.updateQuantity(
                                    item.product.id,
                                    -1,
                                  );
                                },
                              ),
                              Text(
                                '${item.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  cartService.updateQuantity(
                                    item.product.id,
                                    1,
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Obx(() {
              if (cartService.cartItems.isEmpty) return const SizedBox.shrink();

              // Modern Dart 3 Record destructuring
              final (subtotal, discount, tax, total) = cartService.cartSummary;

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: promoController,
                          decoration: InputDecoration(
                            hintText: 'Promo code (e.g. GETXIFY20)',
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          cartService.applyPromoCode(promoController.text);
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text('₹${subtotal.toStringAsFixed(0)}'),
                    ],
                  ),
                  if (discount > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Discount (20%):',
                          style: TextStyle(color: Colors.green),
                        ),
                        Text(
                          '-₹${discount.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimated Tax (8%):'),
                      Text('₹${tax.toStringAsFixed(0)}'),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${total.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        // Check if user is logged in before allowing order checkout
                        if (!authService.isLoggedInValue) {
                          Get.back(); // Close bottom sheet
                          Get.snackbar(
                            'Sign In Required',
                            'Please log in to your account to place an order.',
                            snackPosition: SnackPosition.top,
                            backgroundColor: Colors.amber.shade800,
                            colorText: Colors.white,
                            duration: const Duration(seconds: 3),
                          );
                          Get.toNamed(Routes.LOGIN_THEN(Routes.home));
                          return;
                        }

                        final formattedTotal = total.toStringAsFixed(0);
                        Get.back(); // Close bottom sheet
                        Get.defaultDialog(
                          title: 'Confirm Order',
                          middleText:
                              'Place order for ₹$formattedTotal?\nShipping address: 123 Dev Way, Silicon Valley',
                          textConfirm: 'Place Order',
                          textCancel: 'Cancel',
                          confirmTextColor: Colors.white,
                          onConfirm: () {
                            authService.orderCount.value++;
                            cartService.clearCart();
                            Get.back();
                            Get.snackbar(
                              'Order Placed Successfully! 🎉',
                              'Thank you for shopping with GetXify Store.',
                              snackPosition: SnackPosition.top,
                              backgroundColor: Colors.green.shade700,
                              colorText: Colors.white,
                              duration: const Duration(seconds: 4),
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Proceed to Checkout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
