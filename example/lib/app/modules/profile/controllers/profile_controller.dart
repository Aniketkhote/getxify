import 'package:material_ui/material_ui.dart';
import 'package:getxify/getxify.dart';

import '../../../../services/auth_service.dart';
import '../../../routes/app_pages.dart';

/// Controller for the profile screen
class ProfileController extends GetxController {
  AuthService get authService => AuthService.to;

  RxString get userName => authService.userName;
  RxString get userEmail => authService.userEmail;

  void editProfile() {
    final nameController = TextEditingController(text: userName.value);
    final emailController = TextEditingController(text: userEmail.value);

    Get.dialog(
      AlertDialog(
        title: const Text('Edit Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              authService.updateProfile(
                name: nameController.text,
                email: emailController.text,
              );
              Get.back();
              Get.snackbar(
                'Profile Updated',
                'Profile changes saved successfully.',
                snackPosition: SnackPosition.top,
                backgroundColor: Colors.indigo,
                colorText: Colors.white,
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void showTestDialogInOutlet() {
    Get.defaultDialog(
      title: 'Outlet Dialog Demo',
      middleText:
          'This dialog is scoped to the Home router outlet (id: Routes.home)',
      barrierDismissible: true,
      id: Routes.home,
    );
  }

  void logout() {
    Get.defaultDialog(
      title: 'Confirm Logout',
      middleText: 'Are you sure you want to log out of GetXify Mart?',
      textConfirm: 'Log Out',
      confirmTextColor: Colors.white,
      onConfirm: () {
        authService.logout();
        Get.back();
        Get.offNamed(Routes.home);
      },
    );
  }
}
