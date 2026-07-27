import 'package:getxify/getxify.dart';

/// User profile model for authentication service
class UserProfile {
  final String name;
  final String email;
  final String tier;
  final int totalOrders;

  const UserProfile({
    required this.name,
    required this.email,
    required this.tier,
    required this.totalOrders,
  });
}

/// Authentication service
/// Manages user authentication state and profile details across the app
class AuthService extends GetxService {
  static AuthService get to => Get.find();

  /// Observable authentication state
  final isLoggedIn = false.obs;

  /// Observable user profile details
  final userName = 'Alex Dev'.obs;
  final userEmail = 'alex.developer@getxify.dev'.obs;
  final userTier = 'VIP Platinum'.obs;
  final orderCount = 12.obs;

  /// Get the current authentication state
  bool get isLoggedInValue => isLoggedIn.value;

  /// Log the user in
  void login({String? email, String? name}) {
    if (email != null && email.isNotEmpty) {
      userEmail.value = email;
    }
    if (name != null && name.isNotEmpty) {
      userName.value = name;
    }
    isLoggedIn.value = true;
  }

  /// Update user details
  void updateProfile({required String name, required String email}) {
    userName.value = name;
    userEmail.value = email;
  }

  /// Log the user out
  void logout() {
    isLoggedIn.value = false;
  }
}
