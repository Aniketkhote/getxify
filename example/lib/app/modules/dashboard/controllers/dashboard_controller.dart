import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:getxify/getxify.dart';

import '../../../../models/demo_product.dart';

/// Controller for the dashboard screen
/// Demonstrates reactive state, workers, and GetXify overlays
class DashboardController extends GetxController {
  /// Observable current time
  final now = DateTime.now().obs;

  /// Observable selected category
  final selectedCategory = 'All'.obs;

  /// Featured products list
  final featuredProducts = <DemoProduct>[].obs;

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    featuredProducts.assignAll(
      DemoProduct.sampleProducts.where((p) => p.isFeatured).toList(),
    );
  }

  @override
  void onReady() {
    super.onReady();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = DateTime.now();
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  String get countdownString {
    final seconds = 3600 - (now.value.second + now.value.minute * 60) % 3600;
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '02:$m:$s';
  }

  void showQuickSnackbar() {
    Get.snackbar(
      'GetXify Power',
      'Triggered Get.snackbar() without requiring BuildContext!',
      snackPosition: SnackPosition.top,
      backgroundColor: Colors.indigo,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      icon: const Icon(Icons.bolt, color: Colors.yellow),
    );
  }

  void showQuickDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: Colors.indigo),
            SizedBox(width: 8),
            Text('GetXify Dialog'),
          ],
        ),
        content: const Text(
          'Get.dialog() works from anywhere in your business logic without BuildContext!',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Awesome')),
        ],
      ),
    );
  }

  void showQuickBottomSheet() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'GetXify BottomSheet Showcase',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Displayed seamlessly without context using Get.bottomSheet().',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showQuickDefaultDialog() {
    Get.defaultDialog(
      title: 'Get.defaultDialog()',
      middleText: 'Zero-boilerplate dialog popup with built-in action buttons!',
      textConfirm: 'Great',
      confirmTextColor: Colors.white,
      onConfirm: () => Get.back(),
    );
  }
}
