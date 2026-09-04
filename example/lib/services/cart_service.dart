import 'package:material_ui/material_ui.dart';
import 'package:getxify/getxify.dart';

import '../models/demo_product.dart';

/// Item stored inside the reactive shopping cart
class CartItem {
  final DemoProduct product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;
}

/// Global Cart & Wishlist Service using GetxService with modern Dart 3 features
class CartService extends GetxService {
  static CartService get to => Get.find();

  /// Reactive list of cart items
  final cartItems = <CartItem>[].obs;

  /// Reactive set of wishlisted product IDs
  final wishlistIds = <String>{}.obs;

  /// Promo discount code and percentage
  final appliedPromo = ''.obs;
  final discountPercent = 0.0.obs;

  /// Total count of items in cart
  int get itemCount => cartItems.fold(0, (sum, item) => sum + item.quantity);

  /// Subtotal before discount and tax
  double get subtotal =>
      cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  /// Discount amount
  double get discountAmount => subtotal * (discountPercent.value / 100);

  /// Tax (8% estimation)
  double get taxAmount => (subtotal - discountAmount) * 0.08;

  /// Total amount
  double get totalAmount => (subtotal - discountAmount) + taxAmount;

  /// Modern Dart 3 Record returning complete financial breakdown (subtotal, discount, tax, total)
  (double subtotal, double discount, double tax, double total) get cartSummary {
    final sub = subtotal;
    final disc = discountAmount;
    final tax = (sub - disc) * 0.08;
    final tot = (sub - disc) + tax;
    return (sub, disc, tax, tot);
  }

  @override
  void onInit() {
    super.onInit();
    // React to cart empty state with worker
    ever(cartItems, (items) {
      if (items.isEmpty) {
        appliedPromo.value = '';
        discountPercent.value = 0.0;
      }
    });
  }

  /// Get quantity of specific product in cart
  int getQuantityInCart(String productId) {
    final index = cartItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) return cartItems[index].quantity;
    return 0;
  }

  /// Add product to cart or increment quantity
  void addToCart(
    DemoProduct product, {
    int quantity = 1,
    bool showSnackbar = true,
  }) {
    final index = cartItems.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      cartItems[index].quantity += quantity;
      cartItems.refresh();
    } else {
      cartItems.add(CartItem(product: product, quantity: quantity));
    }

    if (showSnackbar && Get.key.currentContext != null) {
      Get.snackbar(
        'Added to Cart',
        '${product.name} (x$quantity) added to your shopping cart.',
        snackPosition: SnackPosition.top,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(12),
        icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
        backgroundColor: Colors.indigo.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }
  }

  /// Update item quantity
  void updateQuantity(String productId, int delta) {
    final index = cartItems.indexWhere((item) => item.product.id == productId);
    if (index < 0) return;

    final newQty = cartItems[index].quantity + delta;
    if (newQty <= 0) {
      cartItems.removeAt(index);
    } else {
      cartItems[index].quantity = newQty;
      cartItems.refresh();
    }
  }

  /// Remove item from cart
  void removeFromCart(String productId) {
    cartItems.removeWhere((item) => item.product.id == productId);
  }

  /// Toggle product wishlist state
  void toggleWishlist(String productId) {
    if (wishlistIds.contains(productId)) {
      wishlistIds.remove(productId);
      if (Get.key.currentContext != null) {
        Get.snackbar(
          'Wishlist',
          'Removed from your favorites',
          snackPosition: SnackPosition.bottom,
          duration: const Duration(seconds: 1),
          margin: const EdgeInsets.all(12),
        );
      }
    } else {
      wishlistIds.add(productId);
      if (Get.key.currentContext != null) {
        Get.snackbar(
          'Wishlist',
          'Saved to your favorites!',
          snackPosition: SnackPosition.bottom,
          duration: const Duration(seconds: 1),
          margin: const EdgeInsets.all(12),
        );
      }
    }
  }

  /// Check if product is wishlisted
  bool isWishlisted(String productId) => wishlistIds.contains(productId);

  /// Apply promo code using Dart 3 pattern matching
  bool applyPromoCode(String code) {
    final clean = code.trim().toUpperCase();
    return switch (clean) {
      'GETXIFY20' => () {
        appliedPromo.value = clean;
        discountPercent.value = 20.0;
        if (Get.key.currentContext != null) {
          Get.snackbar(
            'Promo Applied!',
            '20% GetXify discount applied successfully.',
            snackPosition: SnackPosition.top,
            backgroundColor: Colors.green.shade700,
            colorText: Colors.white,
          );
        }
        return true;
      }(),
      _ => () {
        if (Get.key.currentContext != null) {
          Get.snackbar(
            'Invalid Code',
            'Try using promo code: GETXIFY20',
            snackPosition: SnackPosition.top,
            backgroundColor: Colors.red.shade700,
            colorText: Colors.white,
          );
        }
        return false;
      }(),
    };
  }

  /// Clear the entire cart
  void clearCart() {
    cartItems.clear();
  }
}
