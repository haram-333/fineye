import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/utils/validation_utils.dart';
import '../../../data/services/auth_service.dart';

class ChangePasswordController extends GetxController {
  final _authService = AuthService();
  final formKey = GlobalKey<FormState>();

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final RxBool obscureCurrentPassword = true.obs;
  final RxBool obscureNewPassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;

  final RxString passwordStrength = ''.obs; // 'Weak', 'Moderate', 'Strong'
  final RxDouble passwordStrengthValue = 0.0.obs; // 0.0 to 1.0
  final Rx<Color> passwordStrengthColor = Colors.grey.obs;

  final RxBool isLoading = false.obs;

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void toggleCurrentPasswordVisibility() {
    obscureCurrentPassword.value = !obscureCurrentPassword.value;
  }

  void toggleNewPasswordVisibility() {
    obscureNewPassword.value = !obscureNewPassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    obscureConfirmPassword.value = !obscureConfirmPassword.value;
  }

  void updatePasswordStrength(String password) {
    if (password.isEmpty) {
      passwordStrength.value = '';
      passwordStrengthValue.value = 0.0;
      passwordStrengthColor.value = Colors.grey;
      return;
    }

    double strength = 0;
    if (password.length >= 8) strength += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[!@#\$&*~]').hasMatch(password)) strength += 0.25;

    passwordStrengthValue.value = strength;

    if (strength <= 0.25) {
      passwordStrength.value = 'password_weak'.tr;
      passwordStrengthColor.value = Colors.red;
    } else if (strength <= 0.75) {
      passwordStrength.value = 'password_moderate'.tr;
      passwordStrengthColor.value = Colors.orange;
    } else {
      passwordStrength.value = 'password_strong'.tr;
      passwordStrengthColor.value = Colors.green;
    }
  }

  String? validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'current_password_hint'.tr; // Using hint as error for required
    }
    // Mock validation: In a real app, this might check against a stored hash or wait for API
    return null;
  }

  String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'new_password_hint'.tr;
    }
    
    // Use ValidationUtils for password strength validation
    final passwordError = ValidationUtils.validatePassword(value);
    if (passwordError != null) {
      return passwordError;
    }
    
    if (value == currentPasswordController.text) {
      return 'password_same_as_current'.tr;
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'confirm_new_password_hint'.tr;
    }
    if (value != newPasswordController.text) {
      return 'passwords_not_match'.tr;
    }
    return null;
  }

  Future<void> changePassword() async {
    if (formKey.currentState!.validate()) {
      isLoading.value = true;
      
      try {
        // Change password using Firebase Auth
        final result = await _authService.changePassword(
          currentPassword: currentPasswordController.text,
          newPassword: newPasswordController.text,
        );
        
        isLoading.value = false;
        
        if (result['success'] == true) {
          // Clear password fields
          currentPasswordController.clear();
          newPasswordController.clear();
          confirmPasswordController.clear();
          passwordStrength.value = '';
          passwordStrengthValue.value = 0.0;
          
          Get.back(); // Close screen
          SnackbarService.to.showSuccess(
            'title_success'.tr,
            result['message'] ?? 'password_changed_success'.tr,
          );
        } else {
          SnackbarService.to.showError(
            'title_error'.tr,
            result['error'] ?? 'Failed to change password. Please try again.',
          );
        }
      } catch (e) {
        isLoading.value = false;
        debugPrint('Change password error: $e');
        SnackbarService.to.showError(
          'title_error'.tr,
          'An unexpected error occurred. Please try again.',
        );
      }
    }
  }

  void forgotPassword() {
    // Navigate to forgot password flow
    Get.toNamed(AppRoutes.forgotPassword);
  }
}
