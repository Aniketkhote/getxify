import 'package:material_ui/material_ui.dart';
import 'package:getxify/getxify.dart';

import '../../../../services/cart_service.dart';
import '../../../routes/app_pages.dart';
import '../controllers/products_controller.dart';

/// Products screen view
/// Demonstrates catalog grid, reactive status handling with controller.obx (loading, empty, success, error), parameter routing, and interactive in-card cart toggles
class ProductsView extends GetView<ProductsController> {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    final cartService = CartService.to;

    return Scaffold(
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => controller.searchQuery.value = val,
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: Obx(
                            () => controller.searchQuery.value.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () =>
                                        controller.searchQuery.value = '',
                                  )
                                : const SizedBox.shrink(),
                          ),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.4),
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: PopupMenuButton<String>(
                        icon: const Icon(Icons.sort, color: Colors.indigo),
                        tooltip: 'Sort Products',
                        onSelected: (value) => controller.sortBy.value = value,
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'Featured',
                            child: Text('Featured'),
                          ),
                          const PopupMenuItem(
                            value: 'Price: Low to High',
                            child: Text('Price: Low to High'),
                          ),
                          const PopupMenuItem(
                            value: 'Price: High to Low',
                            child: Text('Price: High to Low'),
                          ),
                          const PopupMenuItem(
                            value: 'Rating',
                            child: Text('Highest Rating'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: controller.categories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final cat = controller.categories[index];
                      return Obx(() {
                        final isSelected =
                            controller.selectedCategory.value == cat;
                        return FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: Colors.indigo.withValues(alpha: 0.2),
                          onSelected: (_) =>
                              controller.selectedCategory.value = cat,
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Reactive Status Handler using GetXify controller.obx API
          Expanded(
            child: controller.obx(
              (list) => RefreshIndicator(
                onRefresh: () async {
                  controller.fetchCatalog();
                },
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final item = list[index];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Get.toNamed(Routes.PRODUCT_DETAILS(item.id));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: item.themeColor.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Hero(
                                        tag: 'product-${item.id}',
                                        child: Icon(
                                          item.iconData,
                                          size: 52,
                                          color: item.themeColor,
                                        ),
                                      ),
                                      Positioned(
                                        top: 6,
                                        left: 6,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.indigo,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            item.badge,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 6,
                                        right: 6,
                                        child: Obx(() {
                                          final isFav = cartService
                                              .isWishlisted(item.id);
                                          return InkWell(
                                            onTap: () => cartService
                                                .toggleWishlist(item.id),
                                            child: Icon(
                                              isFav
                                                  ? Icons.favorite
                                                  : Icons.favorite_border,
                                              color: isFav
                                                  ? Colors.red
                                                  : Colors.grey,
                                              size: 20,
                                            ),
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${item.rating}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    ' (${item.reviewCount})',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '₹${item.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.indigo,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Interactive In-Card Quantity Toggle
                              Obx(() {
                                final qty = cartService.getQuantityInCart(
                                  item.id,
                                );
                                if (qty == 0) {
                                  return SizedBox(
                                    width: double.infinity,
                                    height: 32,
                                    child: ElevatedButton.icon(
                                      onPressed: () =>
                                          cartService.addToCart(item),
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        backgroundColor: Colors.indigo,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.add_shopping_cart,
                                        size: 14,
                                      ),
                                      label: const Text(
                                        'Add to Cart',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  );
                                }

                                return Container(
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.indigo.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.indigo.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 28,
                                        ),
                                        icon: const Icon(
                                          Icons.remove,
                                          size: 16,
                                          color: Colors.indigo,
                                        ),
                                        onPressed: () => cartService
                                            .updateQuantity(item.id, -1),
                                      ),
                                      Text(
                                        '$qty',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 28,
                                        ),
                                        icon: const Icon(
                                          Icons.add,
                                          size: 16,
                                          color: Colors.indigo,
                                        ),
                                        onPressed: () => cartService
                                            .updateQuantity(item.id, 1),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              onLoading: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Loading store catalog...'),
                  ],
                ),
              ),
              onEmpty: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('No matching products found'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        controller.searchQuery.value = '';
                        controller.selectedCategory.value = 'All';
                      },
                      child: const Text('Reset Filters'),
                    ),
                  ],
                ),
              ),
              onError: (error) =>
                  Center(child: Text('Error loading catalog: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
