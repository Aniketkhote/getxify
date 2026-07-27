import 'package:getxify/getxify.dart';

import '../../../../models/demo_product.dart';

/// Controller for the products screen using GetXify StateMixin & GetStatus
/// Manages product list, status states (loading, success, empty, error), search workers, filtering, and sorting
class ProductsController extends GetxController
    with StateMixin<List<DemoProduct>> {
  /// Master list of products
  final products = <DemoProduct>[].obs;

  /// Observable search query
  final searchQuery = ''.obs;

  /// Observable category filter
  final selectedCategory = 'All'.obs;

  /// Sort criteria
  final sortBy = 'Featured'.obs;

  /// Available categories
  final categories = ['All', 'Electronics', 'Fashion', 'Accessories'];

  @override
  void onInit() {
    super.onInit();
    fetchCatalog();

    // Reactively update filter status when search, category, or sort changes
    debounce(
      searchQuery,
      (_) => _applyFilterAndStatus(),
      time: const Duration(milliseconds: 300),
    );

    ever(selectedCategory, (_) => _applyFilterAndStatus());
    ever(sortBy, (_) => _applyFilterAndStatus());
  }

  /// Load catalog products and update status
  void fetchCatalog() {
    change(null, status: GetStatus.loading());
    products.assignAll(DemoProduct.sampleProducts);
    _applyFilterAndStatus();
  }

  /// Applies filters and sets appropriate GetStatus (empty vs success)
  void _applyFilterAndStatus() {
    final list = filteredProducts;
    if (list.isEmpty) {
      change(list, status: GetStatus.empty());
    } else {
      change(list, status: GetStatus.success(list));
    }
  }

  /// Filtered and sorted product list using modern Dart 3 Switch Expression
  List<DemoProduct> get filteredProducts {
    final filtered = products.where((item) {
      final matchesCategory =
          selectedCategory.value == 'All' ||
          item.category == selectedCategory.value;
      final matchesSearch =
          item.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          item.description.toLowerCase().contains(
            searchQuery.value.toLowerCase(),
          );
      return matchesCategory && matchesSearch;
    }).toList();

    return switch (sortBy.value) {
      'Price: Low to High' =>
        filtered..sort((a, b) => a.price.compareTo(b.price)),
      'Price: High to Low' =>
        filtered..sort((a, b) => b.price.compareTo(a.price)),
      'Rating' => filtered..sort((a, b) => b.rating.compareTo(a.rating)),
      _ => filtered,
    };
  }
}
