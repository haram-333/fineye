import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/pressable_text.dart';
import '../../widgets/otp_input_row.dart';
import '../../controllers/forgot_password_controller.dart';

class ForgotPasswordOtpView extends GetView<ForgotPasswordController> {
  const ForgotPasswordOtpView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure timer starts when view opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!controller.isTimerRunning.value) {
        controller.startTimer();
      }
    });

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final safeAreaBottom = mediaQuery.padding.bottom;

    // Responsive sizing
    final horizontalPadding = (screenWidth * 0.05).clamp(16.0, 24.0);
    final verticalPadding = (screenHeight * 0.03).clamp(20.0, 28.0);
    final titleFontSize = (screenWidth * 0.055).clamp(18.0, 24.0);
    final bodyFontSize = (screenWidth * 0.038).clamp(13.0, 16.0);
    final smallFontSize = (screenWidth * 0.03).clamp(10.0, 13.0);
    final buttonFontSize = (screenWidth * 0.042).clamp(14.0, 18.0);
    final borderRadius = (screenWidth * 0.05).clamp(16.0, 24.0);
    final buttonBorderRadius = (screenWidth * 0.03).clamp(10.0, 14.0);
    final buttonHeight = (screenHeight * 0.06).clamp(44.0, 52.0);
    final iconSize = (screenWidth * 0.05).clamp(16.0, 22.0);
    final backButtonPadding = (screenWidth * 0.02).clamp(6.0, 10.0);

    // Responsive spacing
    final spacingSmall = (screenHeight * 0.01).clamp(6.0, 10.0);
    final spacingMedium = (screenHeight * 0.02).clamp(12.0, 18.0);
    final spacingLarge = (screenHeight * 0.04).clamp(24.0, 36.0);
    final spacingXLarge = (screenHeight * 0.05).clamp(28.0, 40.0);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(borderRadius),
            topRight: Radius.circular(borderRadius),
          ),
        ),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding,
            top: verticalPadding,
            bottom: keyboardHeight > 0 
                ? verticalPadding + keyboardHeight 
                : verticalPadding + safeAreaBottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Wrap content height
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Back Button
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: () => Get.back(),
                child: Container(
                  padding: EdgeInsets.all(backButtonPadding),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.lightWhite,
                  ),
                  child: Icon(Icons.close, size: iconSize, color: AppColors.ink),
                ),
              ),
            ),
            
            SizedBox(height: spacingMedium),
            
            // Header
            Text(
              'enter_otp_title'.tr,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: spacingSmall),
            Text(
              'otp_subtitle'.tr,
              style: TextStyle(
                fontSize: bodyFontSize,
                color: AppColors.mutedText,
                height: 1.5,
              ),
            ),
            SizedBox(height: spacingSmall),
            Obx(() => RichText(
              text: TextSpan(
                text: 'otp_code_sent_to'.tr,
                style: TextStyle(color: AppColors.mutedText, fontSize: bodyFontSize),
                children: [
                  TextSpan(
                    text: controller.forgotPasswordEmail.value.isNotEmpty 
                        ? controller.forgotPasswordEmail.value 
                        : controller.emailController.text,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )),
            
            SizedBox(height: spacingXLarge),
            
            // Input Fields
            OtpInputRow(
              onCodeChanged: (code) {
                controller.otpCode.value = code;
              },
            ),
            
            SizedBox(height: spacingLarge),
            
            // Timer and Resend
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 320) {
                  // Stack vertically on very small screens
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() => Text(
                        '${controller.formattedTimer}${'otp_remaining'.tr}',
                        style: TextStyle(
                          color: AppColors.successGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: bodyFontSize,
                        ),
                      )),
                      SizedBox(height: spacingSmall),
                      Wrap(
                        children: [
                          Text(
                            'otp_not_received'.tr,
                            style: TextStyle(color: AppColors.mutedText, fontSize: bodyFontSize),
                          ),
                          PressableText(
                            text: 'otp_resend_action'.tr,
                            onTap: controller.resendOtp,
                            style: TextStyle(
                              color: AppColors.successGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: bodyFontSize,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Obx(() => Text(
                        '${controller.formattedTimer}${'otp_remaining'.tr}',
                        style: TextStyle(
                          color: AppColors.successGreen,
                          fontWeight: FontWeight.w600,
                          fontSize: bodyFontSize,
                        ),
                        overflow: TextOverflow.ellipsis,
                      )),
                    ),
                    Flexible(
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        children: [
                          Text(
                            'otp_not_received'.tr,
                            style: TextStyle(color: AppColors.mutedText, fontSize: bodyFontSize),
                          ),
                          PressableText(
                            text: 'otp_resend_action'.tr,
                            onTap: controller.resendOtp,
                            style: TextStyle(
                              color: AppColors.successGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: bodyFontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            
            SizedBox(height: spacingXLarge),
            
            // Submit Button
            Obx(() => SizedBox(
              height: buttonHeight,
              child: ElevatedButton(
                onPressed: controller.isLoading.value 
                    ? null 
                    : () => controller.verifyOtp(controller.otpCode.value),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(buttonBorderRadius),
                  ),
                  elevation: 0,
                ),
                child: controller.isLoading.value 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                  'check_otp_button'.tr,
                  style: TextStyle(
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            )),
            
            SizedBox(height: spacingXLarge),
            
            // Footer
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Text(
                    'otp_wrong_email'.tr,
                    style: TextStyle(color: AppColors.mutedText, fontSize: bodyFontSize),
                  ),
                  PressableText(
                    text: 'otp_change_email'.tr,
                    onTap: () => Get.back(),
                    style: TextStyle(
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: bodyFontSize,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: spacingLarge),
            
            Center(
              child: Text(
                'otp_disclaimer_email'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: smallFontSize,
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: spacingXLarge), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }
}
