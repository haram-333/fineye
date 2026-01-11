import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../controllers/change_password_controller.dart';

class ChangePasswordView extends GetView<ChangePasswordController> {
  const ChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is registered if not already
    if (!Get.isRegistered<ChangePasswordController>()) {
      Get.put(ChangePasswordController());
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
        toolbarHeight: 90,
        title: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'change_password_title'.tr,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'change_password_subtitle'.tr,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: controller.formKey,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentPasswordField(),
                const SizedBox(height: 24),
                _buildNewPasswordField(),
                const SizedBox(height: 8),
                _buildPasswordStrengthIndicator(),
                const SizedBox(height: 24),
                _buildConfirmPasswordField(),
                const SizedBox(height: 32),
                _buildSubmitButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'current_password'.tr,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => TextFormField(
          controller: controller.currentPasswordController,
          obscureText: controller.obscureCurrentPassword.value,
          decoration: InputDecoration(
            hintText: 'current_password_hint'.tr,
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primaryBlue),
            suffixIcon: IconButton(
              icon: Icon(
                controller.obscureCurrentPassword.value
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.grey,
              ),
              onPressed: controller.toggleCurrentPasswordVisibility,
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
          validator: controller.validateCurrentPassword,
        )),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: controller.forgotPassword,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'forgot_current_password'.tr,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'new_password'.tr,
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
          decoration: InputDecoration(
            hintText: 'new_password_hint'.tr,
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
          'password_requirements'.tr,
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
          'confirm_new_password'.tr,
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
          decoration: InputDecoration(
            hintText: 'confirm_new_password_hint'.tr,
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
        onPressed: controller.isLoading.value ? null : controller.changePassword,
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
                'change_password_button'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    ));
  }
}
