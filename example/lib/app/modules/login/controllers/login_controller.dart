import 'package:material_ui/material_ui.dart';
import 'package:getxify/getxify.dart';

import '../../../../services/auth_service.dart';

/// Controller for the login screen
class LoginController extends GetxController {
  final emailController = TextEditingController(
    text: 'alex.developer@getxify.dev',
  );
  final passwordController = TextEditingController(text: 'secret123');

  final isLoading = false.obs;
  final obscureText = true.obs;

  AuthService get authService => AuthService.to;

  void toggleObscureText() => obscureText.value = !obscureText.value;

  void fillDemoCredentials() {
    emailController.text = 'alex.developer@getxify.dev';
    passwordController.text = 'secret123';
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  Future<void> login() async {
    await submitLogin();
  }

  Future<bool> submitLogin() async {
    final email = emailController.text.trim();
    if (!_isValidEmail(email)) {
      Get.snackbar(
        'Invalid Email',
        'Please enter a valid email address.',
        snackPosition: SnackPosition.top,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return false;
    }

    if (passwordController.text.length < 4) {
      Get.snackbar(
        'Short Password',
        'Password must be at least 4 characters long.',
        snackPosition: SnackPosition.top,
        backgroundColor: Colors.red.shade700,
        colorText: Colors.white,
      );
      return false;
    }

    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 600));
    authService.login(email: email, name: 'Alex Dev');
    isLoading.value = false;
    return true;
  }
}
