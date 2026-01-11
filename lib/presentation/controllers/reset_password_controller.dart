import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/snackbar_service.dart';
import '../../core/utils/validation_utils.dart';
import '../../../data/services/otp_api_service.dart';

class ResetPasswordController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  final RxBool isLoading = false.obs;
  final RxBool obscureNewPassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;
  
  String? resetEmail; // Email for password reset

  // Strength Indicator
  final RxString passwordStrength = ''.obs; 
  final RxDouble passwordStrengthValue = 0.0.obs;
  final Rx<Color> passwordStrengthColor = Colors.grey.obs;

  @override
  void onInit() {
    super.onInit();
    // Get email from route arguments
    if (Get.arguments != null && Get.arguments is String) {
      resetEmail = Get.arguments as String;
    }
  }

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
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

  String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'new_password_placeholder'.tr;
    }
    
    // Use ValidationUtils for consistent password validation
    final passwordError = ValidationUtils.validatePassword(value);
    if (passwordError != null) {
      return passwordError;
    }
    
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'confirm_new_password_placeholder'.tr;
    }
    if (value != newPasswordController.text) {
      return 'passwords_not_match'.tr;
    }
    return null;
  }

  Future<void> submitNewPassword() async {
    // Double-check passwords match before submitting
    if (newPasswordController.text != confirmPasswordController.text) {
      SnackbarService.to.showError(
        'title_error'.tr,
        'passwords_not_match'.tr,
      );
      return;
    }
    
    if (formKey.currentState!.validate()) {
      if (resetEmail == null || resetEmail!.isEmpty) {
          SnackbarService.to.showError(
          'title_error'.tr,
          'Email not found. Please restart the password reset process.',
        );
        Get.offAllNamed(AppRoutes.auth);
        return;
      }
      
      isLoading.value = true;
      
      try {
        // Reset password directly using backend endpoint after OTP verification
        // OTP is sufficient security - no need for email confirmation
        final result = await OtpApiService.resetPassword(
          email: resetEmail!,
          newPassword: newPasswordController.text,
        );
        
        isLoading.value = false;
        
        if (result['success'] == true) {
          // Password reset successful
          newPasswordController.clear();
          confirmPasswordController.clear();
          passwordStrength.value = '';
          passwordStrengthValue.value = 0.0;
          
          SnackbarService.to.showSuccess(
            'title_success'.tr,
            result['message'] ?? 'Password reset successful. You can now log in with your new password.',
          );
          
          Get.offAllNamed(AppRoutes.auth);
        } else {
          // Show detailed error message
          final errorMessage = result['message'] ?? 'Failed to reset password. Please try again.';
          debugPrint('Password reset failed: $errorMessage');
          debugPrint('Status code: ${result['statusCode']}');
          debugPrint('Full result: $result');
          
          SnackbarService.to.showError(
            'title_error'.tr,
            errorMessage,
          );
        }
      } catch (e) {
        isLoading.value = false;
        debugPrint('Password reset exception: $e');
        debugPrint('Exception type: ${e.runtimeType}');
        SnackbarService.to.showError(
          'title_error'.tr,
          'An unexpected error occurred: ${e.toString()}',
        );
      }
    }
  }
}
