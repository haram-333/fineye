import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../views/auth/forgot_password_otp_view.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/snackbar_service.dart';
import '../../../data/services/otp_api_service.dart';
import '../../../data/services/auth_service.dart';
import 'auth_controller.dart';

class ForgotPasswordController extends GetxController {
  final _authService = AuthService();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  
  final RxBool isLoading = false.obs;

  final RxBool isEmailSent = false.obs;
  
  // OTP Logic
  final otpCode = ''.obs;
  final timerSeconds = 600.obs; // 10 minutes (600 seconds)
  final isTimerRunning = false.obs;
  final forgotPasswordEmail = ''.obs; // Store email for OTP verification

  @override
  void onClose() {
    emailController.dispose();
    isTimerRunning.value = false;
    super.onClose();
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'email_error_empty'.tr;
    }
    if (!GetUtils.isEmail(value) && !GetUtils.isPhoneNumber(value) && !GetUtils.isUsername(value)) {
       if (!value.contains('@') && value.length < 3) {
         return 'email_error_invalid'.tr;
       }
    }
    return null;
  }

  Future<void> sendOtp() async {
    if (formKey.currentState!.validate()) {
      // Validate email format
      if (!GetUtils.isEmail(emailController.text)) {
        SnackbarService.to.showError(
          'title_error'.tr,
          'email_error_invalid'.tr,
        );
        return;
      }
      
      isLoading.value = true;
      
      // Send OTP to email
      final email = emailController.text.trim();
      forgotPasswordEmail.value = email;
      
      // Pass 'forgot_password' purpose to validate user exists before sending OTP
      final result = await OtpApiService.sendOtp(email, purpose: 'forgot_password');
      
      isLoading.value = false;
      
      if (result['success'] == true) {
        isEmailSent.value = true;
        
        // Start timer
        timerSeconds.value = result['expiresIn'] ?? 600;
        startTimer();
        
        // Show OTP Bottom Sheet
        Get.bottomSheet(
          const ForgotPasswordOtpView(),
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          isDismissible: false,
          enableDrag: false,
        );
        
        // Show snackbar after a small delay to avoid UI conflicts
        Future.delayed(const Duration(milliseconds: 300), () {
          SnackbarService.to.showSuccess(
            'title_success'.tr,
            result['message'] ?? 'OTP sent successfully',
            duration: const Duration(seconds: 2),
          );
        });
      } else {
        SnackbarService.to.showError(
          'title_error'.tr,
          result['message'] ?? 'Failed to send OTP',
        );
      }
    }
  }

  void startTimer() {
    timerSeconds.value = 600; // 10 minutes
    isTimerRunning.value = true;
    _runTimer();
  }

  void _runTimer() async {
    while (timerSeconds.value > 0 && isTimerRunning.value) {
      await Future.delayed(const Duration(seconds: 1));
      if (isTimerRunning.value && timerSeconds.value > 0) {
        timerSeconds.value--;
      }
    }
    if (isTimerRunning.value) {
      isTimerRunning.value = false;
    }
  }
  
  String get formattedTimer {
    final minutes = timerSeconds.value ~/ 60;
    final seconds = timerSeconds.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> verifyOtp(String code) async {
    if (forgotPasswordEmail.value.isEmpty) {
      SnackbarService.to.showError(
        'title_error'.tr,
        'Email not found',
      );
      return;
    }
    
    if (code.length != 6) {
      SnackbarService.to.showError(
        'title_error'.tr,
        'Please enter 6-digit OTP',
      );
      return;
    }
    
    isLoading.value = true;
    
    // First verify OTP
    final otpResult = await OtpApiService.verifyOtp(forgotPasswordEmail.value, code);
    
    if (otpResult['success'] != true) {
      isLoading.value = false;
      SnackbarService.to.showError(
        'title_error'.tr,
        otpResult['message'] ?? 'Invalid OTP',
      );
      return;
    }

    // OTP verified, send Firebase password reset email (same approach as change password)
    isLoading.value = true;
    
    final resetResult = await _authService.sendPasswordResetEmail(forgotPasswordEmail.value);
    
    isLoading.value = false;
    
    Get.back(); // Close OTP bottom sheet
    
    if (resetResult['success'] == true) {
      // Clear all controllers and state
      emailController.clear();
      forgotPasswordEmail.value = '';
      otpCode.value = '';
      isEmailSent.value = false;
      isTimerRunning.value = false;
      timerSeconds.value = 600;
      
      // Show success message
      SnackbarService.to.showSuccess(
        'title_success'.tr,
        resetResult['message'] ?? 'Password reset email sent. Please check your inbox and click the link to reset your password.',
      );
      
      // Wait a bit for snackbar to show, then navigate
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Navigate back to login and reset auth controller
      Get.offAllNamed(AppRoutes.auth);
      
      // Reset auth controller state
      if (Get.isRegistered<AuthController>()) {
        final authController = Get.find<AuthController>();
        authController.emailController.clear();
        authController.passwordController.clear();
        authController.isPasswordVisible.value = false;
        authController.isLoading.value = false;
      }
    } else {
      // Show error
      SnackbarService.to.showError(
        'title_error'.tr,
        resetResult['error'] ?? 'Failed to send password reset email. Please try again.',
    );
    }
  }

  Future<void> resendOtp() async {
    if (forgotPasswordEmail.value.isEmpty) {
      SnackbarService.to.showError(
        'title_error'.tr,
        'Email not found',
      );
      return;
    }
    
    isLoading.value = true;
    // Pass 'forgot_password' purpose to validate user exists before sending OTP
    final result = await OtpApiService.sendOtp(forgotPasswordEmail.value, purpose: 'forgot_password');
    isLoading.value = false;
    
    if (result['success'] == true) {
      timerSeconds.value = result['expiresIn'] ?? 600;
      startTimer();
      SnackbarService.to.showSuccess(
        'title_success'.tr,
        result['message'] ?? 'OTP resent successfully',
      );
    } else {
      SnackbarService.to.showError(
        'title_error'.tr,
        result['message'] ?? 'Failed to resend OTP',
      );
    }
  }


}

