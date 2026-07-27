import 'package:flutter/material.dart';
import 'package:getxify/getxify.dart';

import '../../../../services/cart_service.dart';
import '../../../routes/app_pages.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = controller.authService;
    final cartService = CartService.to;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: controller.editProfile,
                          tooltip: 'Edit Profile',
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.logout,
                            color: Colors.redAccent,
                          ),
                          onPressed: controller.logout,
                          tooltip: 'Logout',
                        ),
                      ],
                    ),
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.indigo,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => Text(
                        controller.userName.value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Obx(
                      () => Text(
                        controller.userEmail.value,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Obx(
                        () => Text(
                          '🌟 ${authService.userTier.value}',
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Order & Wishlist Stats Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Obx(
                          () => Text(
                            '${authService.orderCount.value}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Total Orders',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    Container(
                      height: 36,
                      width: 1,
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                    Column(
                      children: [
                        Obx(
                          () => Text(
                            '${cartService.wishlistIds.length}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Wishlist Items',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    Container(
                      height: 36,
                      width: 1,
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                    const Column(
                      children: [
                        Text(
                          '4.9 ★',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Buyer Rating',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Account Actions & Options
            const Text(
              'Account Management',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.indigo,
                    ),
                    title: const Text('Recent Orders'),
                    subtitle: const Text(
                      'View order history & track delivery status',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Get.snackbar(
                        'Orders',
                        'Showing ${authService.orderCount.value} past orders.',
                        snackPosition: SnackPosition.top,
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: Colors.indigo,
                    ),
                    title: const Text('Shipping Addresses'),
                    subtitle: const Text('123 Dev Way, Silicon Valley, CA'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Get.snackbar(
                        'Addresses',
                        'Default address: 123 Dev Way, Silicon Valley, CA',
                        snackPosition: SnackPosition.top,
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.credit_card_outlined,
                      color: Colors.indigo,
                    ),
                    title: const Text('Payment Methods'),
                    subtitle: const Text('Visa ending in 4242'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Get.snackbar(
                        'Payment Methods',
                        'Primary Card: Visa **** 4242',
                        snackPosition: SnackPosition.top,
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.settings_outlined,
                      color: Colors.indigo,
                    ),
                    title: const Text('App Settings'),
                    subtitle: const Text('Theme, notifications & preferences'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Get.toNamed(Routes.settings);
                    },
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
