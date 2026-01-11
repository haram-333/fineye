import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../controllers/reset_password_controller.dart';

class ResetPasswordView extends GetView<ResetPasswordController> {
  const ResetPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ResetPasswordController>()) {
      Get.put(ResetPasswordController());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Get.back(),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'set_new_password_title'.tr,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'set_new_password_subtitle'.tr,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        toolbarHeight: 90,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Form(
            key: controller.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNewPasswordField(),
                const SizedBox(height: 8),
                _buildPasswordStrengthIndicator(),
                const SizedBox(height: 24),
                _buildConfirmPasswordField(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
                const SizedBox(height: 24),
                _buildSecurityNotice(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'new_password_label'.tr,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => TextFormField(
          controller: controller.newPasswordController,
          obscureText: controller.obscureNewPassword.value,
          onChanged: controller.updatePasswordStrength,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'new_password_placeholder'.tr,
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryBlue),
            suffixIcon: IconButton(
              icon: Icon(
                controller.obscureNewPassword.value
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey,
              ),
              onPressed: controller.toggleNewPasswordVisibility,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: controller.validateNewPassword,
        )),
        const SizedBox(height: 6),
        Text(
          'password_requirements_detail'.tr,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.mutedText,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return Obx(() {
      if (controller.passwordStrengthValue.value == 0) return const SizedBox.shrink();
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: controller.passwordStrengthValue.value,
                  backgroundColor: Colors.grey.shade200,
                  color: controller.passwordStrengthColor.value,
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
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
      );
    });
  }

  Widget _buildConfirmPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'confirm_new_password_label'.tr,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => TextFormField(
          controller: controller.confirmPasswordController,
          obscureText: controller.obscureConfirmPassword.value,
          onChanged: (value) {
            // Trigger validation when confirm password changes
            if (controller.formKey.currentState != null) {
              controller.formKey.currentState!.validate();
            }
          },
          decoration: InputDecoration(
            hintText: 'confirm_new_password_placeholder'.tr,
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryBlue),
            suffixIcon: IconButton(
              icon: Icon(
                controller.obscureConfirmPassword.value
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey,
              ),
              onPressed: controller.toggleConfirmPasswordVisibility,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          validator: controller.validateConfirmPassword,
        )),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Obx(() => SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: controller.isLoading.value ? null : controller.submitNewPassword,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: controller.isLoading.value
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'set_password_button'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    ));
  }

  Widget _buildSecurityNotice() {
    return Column(
      children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.security, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'security_notice_reuse'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        const SizedBox(height: 4),
        Text(
          'security_notice_stored'.tr,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
