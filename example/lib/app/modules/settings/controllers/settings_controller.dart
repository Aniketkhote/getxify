import 'package:material_ui/material_ui.dart';
import 'package:getxify/getxify.dart';

/// Controller for the settings screen
class SettingsController extends GetxController {
  final count = 0.obs;
  final isDarkMode = false.obs;
  final pushNotifications = true.obs;
  final autoSync = true.obs;

  @override
  void onInit() {
    super.onInit();
    if (Get.context != null) {
      isDarkMode.value = Theme.of(Get.context!).brightness == Brightness.dark;
    }
  }

  void increment() => count.value++;

  void toggleDarkMode(bool value) {
    isDarkMode.value = value;
    Get.changeThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  void toggleNotifications(bool value) => pushNotifications.value = value;
  void toggleAutoSync(bool value) => autoSync.value = value;

  void resetAppState() {
    Get.defaultDialog(
      title: 'Reset Preferences',
      middleText: 'Are you sure you want to reset all app preferences?',
      textConfirm: 'Reset',
      confirmTextColor: Colors.white,
      onConfirm: () {
        count.value = 0;
        pushNotifications.value = true;
        autoSync.value = true;
        Get.back();
        Get.snackbar(
          'Settings Reset',
          'App preferences restored to default state.',
          snackPosition: SnackPosition.top,
        );
      },
    );
  }
}
