import 'package:flutter/material.dart';
import 'package:getxify/getxify.dart';

import '../../../routes/app_pages.dart';
import '../controllers/home_controller.dart';

/// Home screen view
/// Demonstrates nested routing with bottom navigation and router outlets
class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetRouterOutlet.builder(
      route: Routes.home,
      builder: (context) {
        return Scaffold(
          body: GetRouterOutlet(
            initialRoute: Routes.dashboard,
            anchorRoute: Routes.home,
          ),
          bottomNavigationBar: IndexedRouteBuilder(
            routes: const [Routes.dashboard, Routes.products, Routes.profile],
            builder: (context, routes, index) {
              final delegate = context.delegate;
              return NavigationBar(
                selectedIndex: index,
                onDestinationSelected: (value) =>
                    delegate.toNamed(routes[value]),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard, color: Colors.indigo),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.storefront_outlined),
                    selectedIcon: Icon(Icons.storefront, color: Colors.indigo),
                    label: 'Catalog',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person, color: Colors.indigo),
                    label: 'Profile',
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
