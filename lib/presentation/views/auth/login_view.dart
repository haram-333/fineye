import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/pressable_text.dart';
import '../../controllers/auth_controller.dart';
import 'package:flutter/gestures.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {


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
          
          // Email Field
          _buildLabel('email_or_mobile_label'.tr),
          const SizedBox(height: 6),
          const SizedBox(height: 4),
          TextField(
            controller: controller.emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofocus: false,
            enableInteractiveSelection: true,
            decoration: InputDecoration(
              hintText: 'work_email_hint'.tr,
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
          
          const SizedBox(height: 16),
          
          // Password Field
          _buildLabel('password_label'.tr),
          const SizedBox(height: 6),
          Obx(() {
            return TextField(
              controller: controller.passwordController,
              obscureText: !controller.isPasswordVisible.value,
              keyboardType: TextInputType.visiblePassword,
              textInputAction: TextInputAction.done,
              enableInteractiveSelection: true,
              onSubmitted: (_) => controller.login(),
              decoration: InputDecoration(
                hintText: 'password_hint'.tr,
                hintMaxLines: 1,
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                fillColor: AppColors.lightWhite,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.isPasswordVisible.value 
                      ? Icons.visibility 
                      : Icons.visibility_off,
                    color: AppColors.mutedText,
                  ),
                  onPressed: () {
                    // Save current state before toggle
                    final text = controller.passwordController.text;
                    final selection = controller.passwordController.selection;
                    
                    controller.togglePasswordVisibility();
                    
                    // Restore text immediately after toggle to prevent loss
                    Future.microtask(() {
                      if (controller.passwordController.text != text) {
                        controller.passwordController.value = TextEditingValue(
                          text: text,
                          selection: selection.isValid 
                            ? selection 
                            : TextSelection.collapsed(offset: text.length),
                        );
                      }
                    });
                  },
                ),
              ),
            );
          }),

          const SizedBox(height: 16),
          
          // Forgot Password link
          Align(
            alignment: Alignment.centerRight,
            child: PressableText(
              onTap: () => Get.toNamed(AppRoutes.forgotPassword),
              text: 'forgot_password_title'.tr,
              style: const TextStyle(
                color: AppColors.successGreen,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Helper text
          Text(
            'new_device_notice'.tr,
            style: const TextStyle(
              color: AppColors.mutedText,
              fontSize: 12,
            ),
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
          
          // Continue Button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: controller.login,
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
                    'continue_button'.tr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Don't have an account - centered
          Center(
            child: Text.rich(
              TextSpan(
                text: 'dont_have_account'.tr,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: 'register_link'.tr,
                    style: const TextStyle(
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        DefaultTabController.of(context).animateTo(1);
                      },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Generic Footer
          Center(
            child: Text.rich(
              TextSpan(
                text: 'by_continuing_agree'.tr,
                style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
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
            ),
          ),

          ],
        ),
      ),
    ));
  }

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
}
