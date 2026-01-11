import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/pressable_text.dart';
import '../../controllers/auth_controller.dart';
import '../../../core/constants/app_routes.dart';
import 'package:flutter/gestures.dart';

class RegisterView extends GetView<AuthController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller is injected via parent AuthView binding

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              // Header
              Text(
                'register_title'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'register_subtitle'.tr,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 24),

              // Full Name
              _buildLabel('full_name_label'.tr),
              const SizedBox(height: 6),
              _buildTextField(
                controller: controller.fullNameController,
                hintText: 'full_name_hint'.tr,
              ),
              const SizedBox(height: 16),

              // Work Email
              _buildLabel('work_email_label'.tr),
              const SizedBox(height: 6),
              _buildTextField(
                controller: controller.emailController,
                hintText: 'work_email_hint'.tr,
                bottomText: 'work_email_helper'.tr,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Mobile Number
              _buildLabel('mobile_number_label'.tr),
              const SizedBox(height: 6),
              Row(
                children: [
                  // Country Code Field
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: controller.countryCodeController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '+971',
                        hintMaxLines: 1,
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        fillColor: AppColors.lightWhite,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Phone Number Field
                  Expanded(
                    child: TextField(
                      controller: controller.mobileNumberController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'phone_hint_uae'.tr,
                        hintMaxLines: 1,
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                        fillColor: AppColors.lightWhite,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Password Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLabel('password_label'.tr),
                        const SizedBox(height: 6),
                        Obx(() => _buildTextField(
                          controller: controller.passwordController,
                          hintText: 'password_hint'.tr,
                          isPassword: true,
                          isObscured: !controller.isRegisterPasswordVisible.value,
                          onToggleVisibility: controller.toggleRegisterPasswordVisibility,
                          onChanged: controller.updatePasswordStrength,
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildLabel('confirm_password_label'.tr),
                        const SizedBox(height: 6),
                        Obx(() => _buildTextField(
                          controller: controller.confirmPasswordController,
                          hintText: 'confirm_password_hint'.tr,
                          isPassword: true,
                          isObscured: !controller.isConfirmPasswordVisible.value,
                          onToggleVisibility: controller.toggleConfirmPasswordVisibility,
                        )),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Password Strength Indicator
              Obx(() => _buildPasswordStrengthIndicator(controller)),
              
              // Password Requirement Hint
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.primaryBlue),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'password_requirement_hint'.tr,
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),

              // Company Name (Required)
              _buildLabel('${'company_name_label'.tr} *'),
              const SizedBox(height: 6),
              _buildTextField(
                controller: controller.companyNameController,
                hintText: 'company_optional_hint'.tr,
              ),
              
              const SizedBox(height: 24),

              // Data Encryption Notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightWhite,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.shield_outlined, size: 18, color: AppColors.mutedText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'data_encryption_notice'.tr,
                        style: const TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Create Account Button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    // Call register - OTP screen will be shown automatically
                    controller.register();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Obx(() => controller.isLoading.value 
                    ? const SizedBox(
                        width: 20, 
                        height: 20, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : Text(
                        'create_account_button'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Footer Link
              Align(
                alignment: Alignment.center,
                child: PressableText(
                  onTap: () {
                    // Switch to login tab
                    DefaultTabController.of(context).animateTo(0);
                    // Scroll to top after a small delay to ensure tab switch completes
                    Future.delayed(const Duration(milliseconds: 100), () {
                      // Find the NestedScrollView's ScrollController and scroll to top
                      final scrollController = PrimaryScrollController.of(context);
                      if (scrollController.hasClients) {
                        scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                  },
                  text: 'already_have_account'.tr,
                  style: const TextStyle(color: AppColors.mutedText),
                  secondText: 'login_link'.tr,
                  secondStyle: const TextStyle(
                    color: AppColors.successGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Generic Footer
              Center(
                child: Text.rich(
                  TextSpan(
                    text: 'by_continuing_agree'.tr,
                    style: const TextStyle(color: AppColors.mutedText, fontSize: 11, height: 1.5),
                    children: [
                      TextSpan(
                        text: 'terms_link'.tr,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Get.toNamed(AppRoutes.termsConditions),
                      ),
                      TextSpan(text: 'and'.tr),
                      TextSpan(
                        text: 'privacy_policy_link'.tr,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontWeight: FontWeight.bold,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => Get.toNamed(AppRoutes.privacyPolicy),
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ... _buildLabel ...

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? bottomText,
    bool isPassword = false,
    bool isObscured = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: isPassword ? isObscured : false,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintMaxLines: 1,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            fillColor: AppColors.lightWhite,
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isObscured ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.mutedText,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
          ),
        ),
        if (bottomText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, left: 2.0),
            child: Text(
              bottomText,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator(AuthController controller) {
    if (controller.passwordStrengthValue.value == 0) {
      return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: controller.passwordStrengthValue.value,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      controller.passwordStrengthColor.value,
                    ),
                    minHeight: 4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                controller.passwordStrength.value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: controller.passwordStrengthColor.value,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
