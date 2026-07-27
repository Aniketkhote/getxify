import 'package:flutter/material.dart';
import 'package:getxify/getxify.dart';

import '../../../../services/auth_service.dart';
import '../../../../services/cart_service.dart';
import '../../../routes/app_pages.dart';
import '../../cart/views/cart_bottom_sheet.dart';
import '../controllers/root_controller.dart';

class DrawerWidget extends GetView<RootController> {
  const DrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService.to;
    final cartService = CartService.to;

    return Drawer(
      child: Column(
        children: [
          Obx(() {
            final isLoggedIn = authService.isLoggedInValue;
            return UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo, Colors.deepPurple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  isLoggedIn ? Icons.person : Icons.person_outline,
                  size: 40,
                  color: Colors.indigo,
                ),
              ),
              accountName: Text(
                isLoggedIn ? authService.userName.value : 'Guest User',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              accountEmail: Text(
                isLoggedIn
                    ? authService.userEmail.value
                    : 'Sign in to access profile',
              ),
            );
          }),
          ListTile(
            leading: const Icon(Icons.storefront_outlined),
            title: const Text('Home / Dashboard'),
            onTap: () {
              Get.toNamed(Routes.home);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.grid_view),
            title: const Text('Store Products'),
            onTap: () {
              Get.toNamed(Routes.products);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: const Text('Shopping Cart'),
            trailing: Obx(
              () => Chip(
                label: Text('${cartService.itemCount}'),
                backgroundColor: Colors.indigo.withValues(alpha: 0.1),
              ),
            ),
            onTap: () {
              Navigator.of(context).pop();
              showCartBottomSheet();
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('My Profile'),
            subtitle: const Text('Protected route'),
            onTap: () {
              Get.toNamed(Routes.profile);
              Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Get.toNamed(Routes.settings);
              Navigator.of(context).pop();
            },
          ),
          const Divider(),
          Obx(() {
            final isLoggedIn = authService.isLoggedInValue;
            if (isLoggedIn) {
              return ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  Get.defaultDialog(
                    title: 'Logout',
                    middleText: 'Are you sure you want to sign out?',
                    textConfirm: 'Sign Out',
                    confirmTextColor: Colors.white,
                    onConfirm: () {
                      authService.logout();
                      Get.back();
                      Get.toNamed(Routes.home);
                    },
                  );
                },
              );
            } else {
              return ListTile(
                leading: const Icon(Icons.login, color: Colors.indigo),
                title: const Text(
                  'Login',
                  style: TextStyle(color: Colors.indigo),
                ),
                onTap: () {
                  Get.toNamed(Routes.login);
                  Navigator.of(context).pop();
                },
              );
            }
          }),
        ],
      ),
    );
  }
}
