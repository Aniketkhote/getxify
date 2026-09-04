import 'package:material_ui/material_ui.dart';
import 'package:getxify/getxify.dart';

import '../../../../services/cart_service.dart';
import '../../../routes/app_pages.dart';
import '../../cart/views/cart_bottom_sheet.dart';
import '../controllers/root_controller.dart';
import 'drawer.dart';

/// Root navigator view
/// Manages top-level navigation, global drawer, reactive cart badge, and router outlet
class RootView extends GetView<RootController> {
  const RootView({super.key});

  @override
  Widget build(BuildContext context) {
    final cartService = CartService.to;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      drawer: const DrawerWidget(),
      appBar: AppBar(
        title: RouterListener(
          builder: (context) {
            final loc = context.location;
            return Text(switch (loc) {
              String l when l.contains('/products') => 'Store Catalog',
              String l when l.contains('/profile') => 'My Profile',
              String l when l.contains('/settings') => 'Settings',
              String l when l.contains('/login') => 'Account Login',
              _ => 'GetXify Store',
            });
          },
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle Theme',
            onPressed: () {
              Get.changeThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
            },
          ),
          Obx(() {
            final count = cartService.itemCount;
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  tooltip: 'View Shopping Cart',
                  onPressed: () {
                    showCartBottomSheet();
                  },
                ),
                if (count > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            );
          }),
          const SizedBox(width: 8),
        ],
      ),
      body: GetRouterOutlet(initialRoute: Routes.home, anchorRoute: '/'),
    );
  }
}
