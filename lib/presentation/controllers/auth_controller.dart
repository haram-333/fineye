import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/activity_tracking_service.dart';
import '../../core/services/snackbar_service.dart';
import '../../core/utils/validation_utils.dart';
import 'status_bar_controller.dart';
import '../../../data/services/otp_api_service.dart';
import '../../../data/services/auth_service.dart';
import '../views/auth/otp_view.dart';

class AuthController extends GetxController {
  final _authService = AuthService();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Registration Controllers
  final fullNameController = TextEditingController();
  final countryCodeController = TextEditingController(
    text: '+971',
  ); // Default to UAE
  final mobileNumberController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final companyNameController = TextEditingController();

  // OTP Logic
  final otpCode = ''.obs;
  final timerSeconds = 42.obs;
  final isTimerRunning = false.obs;

  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isRegisterPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;

  // Password Strength Indicator
  final RxString passwordStrength = ''.obs;
  final RxDouble passwordStrengthValue = 0.0.obs;
  final Rx<Color> passwordStrengthColor = Colors.grey.obs;

  // User Data
  final phoneNumber = '1234....11'.obs;
  final registrationEmail = ''.obs;

  // Splash Overlay Logic
  final showSplashOverlay = false.obs;
  final splashOffset = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    Get.find<StatusBarController>().setSolidBlue();

    // Reset state when controller initializes
    _resetState();

    if (Get.arguments == true) {
      showSplashOverlay.value = true;
    }
  }

  void _resetState() {
    // Clear text fields
    emailController.clear();
    passwordController.clear();

    // Reset UI state
    isPasswordVisible.value = false;
    isLoading.value = false;
    passwordStrength.value = '';
    passwordStrengthValue.value = 0.0;
    passwordStrengthColor.value = Colors.grey;
  }

  @override
  void onReady() {
    super.onReady();
    if (showSplashOverlay.value) {
      _animateSplashAway();
    }
  }

  void _animateSplashAway() async {
    await Future.delayed(const Duration(milliseconds: 100));
    splashOffset.value = -1.0;

    await Future.delayed(const Duration(milliseconds: 500));
    showSplashOverlay.value = false;
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleRegisterPasswordVisibility() {
    isRegisterPasswordVisible.value = !isRegisterPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  void updatePasswordStrength(String password) {
    if (password.isEmpty) {
      passwordStrength.value = '';
      passwordStrengthValue.value = 0.0;
      passwordStrengthColor.value = Colors.grey;
      return;
    }

    // Calculate strength based on password requirements
    double strength = 0;

    // Length check (8+ characters)
    if (password.length >= 8) strength += 0.25;

    // Uppercase letter check
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.25;

    // Number check
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.25;

    // Special character check
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.25;

    passwordStrengthValue.value = strength;

    // Determine strength level and color
    if (strength <= 0.25) {
      passwordStrength.value = 'password_weak'.tr;
      passwordStrengthColor.value = Colors.red;
    } else if (strength <= 0.5) {
      passwordStrength.value = 'password_moderate'.tr;
      passwordStrengthColor.value = Colors.orange;
    } else if (strength <= 0.75) {
      passwordStrength.value = 'password_moderate'.tr;
      passwordStrengthColor.value = Colors.blue;
    } else {
      passwordStrength.value = 'password_strong'.tr;
      passwordStrengthColor.value = Colors.green;
    }
  }

  Future<void> login() async {
    // Validate email format
    if (!GetUtils.isEmail(emailController.text.trim())) {
      SnackbarService.to.showError('title_error'.tr, 'email_error_invalid'.tr);
      return;
    }

    if (passwordController.text.isEmpty) {
      SnackbarService.to.showError('title_error'.tr, 'field_required'.tr);
      return;
    }

    isLoading.value = true;

    try {
      final result = await _authService.signInWithEmailPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      isLoading.value = false;

      if (result['success'] == true) {
        await ActivityTrackingService.instance.trackAppOpen();
        SnackbarService.to.showSuccess(
          'title_success'.tr,
          'msg_login_success'.tr,
        );
        // Don't clear password on success - let navigation handle it
        Get.offAllNamed(AppRoutes.main);
      } else {
        // Don't clear password on error - user might want to retry
        SnackbarService.to.showError(
          'title_error'.tr,
          result['error'] ?? 'Login failed. Please try again.',
        );
      }
    } catch (e) {
      isLoading.value = false;
      debugPrint('Login error: $e');
      SnackbarService.to.showError(
        'title_error'.tr,
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  Future<void> register() async {
    // Sanitize all inputs
    final fullName = ValidationUtils.sanitizeInput(fullNameController.text);
    final email = emailController.text.trim().toLowerCase();
    final phoneNum =
        mobileNumberController.text.trim(); // Local variable (not RxString)
    final companyName = ValidationUtils.sanitizeInput(
      companyNameController.text,
    );
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    // Production-level validation
    // 1. Validate full name
    final nameError = ValidationUtils.validateFullName(fullName);
    if (nameError != null) {
      SnackbarService.to.showError('title_error'.tr, nameError);
      return;
    }

    // 2. Validate email format
    if (!ValidationUtils.isValidEmail(email)) {
      SnackbarService.to.showError('title_error'.tr, 'email_error_invalid'.tr);
      return;
    }

    // 3. Validate phone number
    if (phoneNum.isEmpty) {
      SnackbarService.to.showError('title_error'.tr, 'msg_phone_required'.tr);
      return;
    }

    if (!ValidationUtils.isValidPhoneNumber(
      phoneNum,
      countryCodeController.text,
    )) {
      SnackbarService.to.showError('title_error'.tr, 'msg_phone_invalid'.tr);
      return;
    }

    // 4. Validate company name
    final companyError = ValidationUtils.validateCompanyName(companyName);
    if (companyError != null) {
      SnackbarService.to.showError('title_error'.tr, companyError);
      return;
    }

    // 5. Validate password strength
    final passwordError = ValidationUtils.validatePassword(password);
    if (passwordError != null) {
      SnackbarService.to.showError('title_error'.tr, passwordError);
      return;
    }

    // 6. Validate password confirmation
    if (password != confirmPassword) {
      SnackbarService.to.showError('title_error'.tr, 'passwords_not_match'.tr);
      return;
    }

    // All validations passed - check if email already exists
    isLoading.value = true;

    try {
      // Check if email already exists in Firebase Auth
      final emailCheck = await _authService.checkEmailExists(email);

      if (emailCheck['exists'] == true) {
        isLoading.value = false;
        SnackbarService.to.showError(
          'title_error'.tr,
          'msg_email_already_exists'.tr,
        );
        return;
      }

      // Email doesn't exist, proceed with OTP
      registrationEmail.value = email;
      phoneNumber.value =
          email; // Show email in OTP screen (class member RxString)

      final result = await OtpApiService.sendOtp(email);

      isLoading.value = false;

      if (result['success'] == true) {
        // Start timer
        timerSeconds.value = result['expiresIn'] ?? 600;
        startTimer();

        // Show OTP screen first
        Get.bottomSheet(
          const OtpView(),
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
          result['message'] ?? 'Failed to send OTP. Please try again.',
        );
      }
    } catch (e) {
      isLoading.value = false;
      debugPrint('Error sending OTP: $e');
      SnackbarService.to.showError(
        'title_error'.tr,
        'An unexpected error occurred. Please try again.',
      );
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

  Future<void> resendOtp() async {
    if (registrationEmail.value.isEmpty) {
      SnackbarService.to.showError('title_error'.tr, 'msg_email_not_found'.tr);
      return;
    }

    isLoading.value = true;
    final result = await OtpApiService.sendOtp(registrationEmail.value);
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

  Future<void> verifyOtp(String code) async {
    if (registrationEmail.value.isEmpty) {
      SnackbarService.to.showError('title_error'.tr, 'msg_email_not_found'.tr);
      return;
    }

    if (code.length != 6) {
      SnackbarService.to.showError('title_error'.tr, 'msg_otp_6_digits'.tr);
      return;
    }

    // Prevent multiple simultaneous verifications
    if (isLoading.value) {
      return;
    }

    isLoading.value = true;

    try {
      // First verify OTP
      final otpResult = await OtpApiService.verifyOtp(
        registrationEmail.value,
        code,
      );

      if (otpResult['success'] != true) {
        isLoading.value = false;
        SnackbarService.to.showError(
          'title_error'.tr,
          otpResult['message'] ?? 'Invalid OTP',
        );
        return;
      }

      // OTP verified successfully, now create Firebase account
      // Format and sanitize phone number for storage
      final formattedPhone = ValidationUtils.formatPhoneNumber(
        mobileNumberController.text.trim(),
        countryCodeController.text,
      );
      final fullPhoneNumber = '${countryCodeController.text}$formattedPhone';

      final firebaseResult = await _authService.registerWithEmailPassword(
        email: registrationEmail.value,
        password: passwordController.text,
        fullName: ValidationUtils.sanitizeInput(fullNameController.text),
        phoneNumber: fullPhoneNumber,
        companyName: ValidationUtils.sanitizeInput(companyNameController.text),
      );

      isLoading.value = false;

      if (firebaseResult['success'] == true) {
        await ActivityTrackingService.instance.trackAppOpen();
        Get.back(); // Close OTP bottom sheet
        SnackbarService.to.showSuccess(
          'title_success'.tr,
          'Registration successful! Please verify your email.',
        );

        // Navigate to main screen
        Get.offAllNamed(AppRoutes.main);
      } else {
        SnackbarService.to.showError(
          'title_error'.tr,
          firebaseResult['error'] ?? 'Registration failed. Please try again.',
        );
      }
    } catch (e, stackTrace) {
      isLoading.value = false;
      debugPrint('Registration error: $e');
      debugPrint('Stack trace: $stackTrace');
      SnackbarService.to.showError(
        'title_error'.tr,
        'An unexpected error occurred. Please try again.',
      );
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    fullNameController.dispose();
    countryCodeController.dispose();
    mobileNumberController.dispose();
    confirmPasswordController.dispose();
    companyNameController.dispose();
    isTimerRunning.value = false;
    super.onClose();
  }
}
