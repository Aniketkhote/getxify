import 'package:flutter/material.dart';
import 'package:getxify/getxify.dart';

import '../controllers/settings_controller.dart';

/// Settings screen view
/// Demonstrates state management, theme switching, and preferences
class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appearance & Theme',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Obx(
                () => SwitchListTile(
                  secondary: Icon(
                    controller.isDarkMode.value
                        ? Icons.dark_mode
                        : Icons.light_mode,
                    color: Colors.indigo,
                  ),
                  title: const Text('Dark Mode'),
                  subtitle: const Text(
                    'Uses Get.changeThemeMode() dynamically',
                  ),
                  value: controller.isDarkMode.value,
                  onChanged: controller.toggleDarkMode,
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Preferences',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  Obx(
                    () => SwitchListTile(
                      secondary: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.indigo,
                      ),
                      title: const Text('Push Notifications'),
                      subtitle: const Text(
                        'Receive promotional offers and order updates',
                      ),
                      value: controller.pushNotifications.value,
                      onChanged: controller.toggleNotifications,
                    ),
                  ),
                  const Divider(height: 1),
                  Obx(
                    () => SwitchListTile(
                      secondary: const Icon(
                        Icons.sync_outlined,
                        color: Colors.indigo,
                      ),
                      title: const Text('Auto Sync Wishlist'),
                      subtitle: const Text(
                        'Keep favorite items updated across devices',
                      ),
                      value: controller.autoSync.value,
                      onChanged: controller.toggleAutoSync,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Reactive State Counter Demo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GetXify State Counter:'),
                        const SizedBox(height: 4),
                        Obx(
                          () => Text(
                            'Count: ${controller.count.value}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: controller.increment,
                      icon: const Icon(Icons.add),
                      label: const Text('Increment'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: controller.resetAppState,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.restore),
                label: const Text('Reset App Preferences'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
