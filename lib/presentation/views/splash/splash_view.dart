import 'package:flutter/material.dart';

import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../controllers/splash_controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is found or created
    if (!Get.isRegistered<SplashController>()) {
      Get.put(SplashController());
    }
    final controller = Get.find<SplashController>();
    
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    
    // Responsive sizing with clamp constraints (following pattern from other views)
    final horizontalPadding = (screenWidth * 0.05).clamp(16.0, 32.0);
    final verticalPadding = (screenHeight * 0.03).clamp(20.0, 32.0);
    
    // Logo sizing - responsive to orientation
    final logoContainerWidth = isLandscape 
        ? (screenWidth * 0.25).clamp(120.0, 180.0)
        : (screenWidth * 0.42).clamp(120.0, 200.0);
    final logoImageWidth = logoContainerWidth * 0.95;
    final logoImageHeight = logoContainerWidth * 1.07;
    final logoBorderRadius = (screenWidth * 0.04).clamp(12.0, 20.0);
    
    // Font sizes with clamp constraints
    final headlineFontSize = (screenWidth * 0.048).clamp(16.0, 24.0);
    final subheadlineFontSize = (screenWidth * 0.038).clamp(12.0, 18.0);
    final copyrightFontSize = (screenWidth * 0.035).clamp(10.0, 14.0);
    
    // Language panel responsive sizing
    final panelTitleFontSize = (screenWidth * 0.055).clamp(18.0, 24.0);
    final panelSubtitleFontSize = (screenWidth * 0.038).clamp(13.0, 16.0);
    final panelOptionTitleFontSize = (screenWidth * 0.042).clamp(14.0, 18.0);
    final panelOptionDescFontSize = (screenWidth * 0.032).clamp(11.0, 14.0);
    final panelButtonFontSize = (screenWidth * 0.042).clamp(14.0, 18.0);
    final panelButtonHeight = (screenHeight * 0.06).clamp(48.0, 56.0);
    final panelIconSize = (screenWidth * 0.08).clamp(28.0, 40.0);
    final panelWidth = (screenWidth * 0.9).clamp(320.0, 500.0);
    final panelBorderRadius = (screenWidth * 0.05).clamp(16.0, 24.0);
    final panelOptionBorderRadius = (screenWidth * 0.03).clamp(10.0, 14.0);
    final panelButtonBorderRadius = (screenWidth * 0.03).clamp(10.0, 14.0);
    
    // Responsive spacing
    final spacingSmall = (screenHeight * 0.01).clamp(6.0, 10.0);
    final spacingMedium = (screenHeight * 0.02).clamp(12.0, 18.0);
    final spacingLarge = (screenHeight * 0.04).clamp(24.0, 36.0);
    
    // Responsive shadows
    final shadowOffsetY = (screenHeight * 0.003).clamp(1.0, 4.0);
    final shadowBlurRadius = (screenWidth * 0.03).clamp(8.0, 20.0);
    final shadowBlurRadiusLarge = (screenWidth * 0.05).clamp(12.0, 24.0);
    final panelShadowBlur = (screenWidth * 0.05).clamp(16.0, 24.0);
    final panelShadowOffsetY = (screenHeight * 0.012).clamp(8.0, 12.0);
    
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/logo/bg_sp_sc.jpg'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
            onError: (exception, stackTrace) {
              debugPrint('Error loading splash background: $exception');
            },
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0A1929).withValues(alpha: 0.91), // Very dark navy blue
                const Color(0xFF1E3A8A).withValues(alpha: 0.89), // Dark blue
                const Color(0xFF1E40AF).withValues(alpha: 0.88), // Deep blue
                const Color(0xFF2563EB).withValues(alpha: 0.89), // Medium blue
                const Color(0xFF1E3A8A).withValues(alpha: 0.90), // Dark blue
              ],
              stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
              
              // --- 1. Original Splash Content ---
              // Logo and taglines at top, copyright at bottom
              Column(
                children: [
                  // Top spacing - responsive to orientation
                  SizedBox(height: isLandscape ? screenHeight * 0.05 : screenHeight * 0.10),
                  
                  // Logo
                  Container(
                    width: logoContainerWidth,
                    padding: EdgeInsets.symmetric(
                      horizontal: logoContainerWidth * 0.043,
                      vertical: screenHeight * 0.019,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 252, 251, 251),
                      borderRadius: BorderRadius.circular(logoBorderRadius),
                      boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: shadowBlurRadiusLarge,
                            spreadRadius: (screenWidth * 0.02).clamp(2.0, 6.0),
                            offset: Offset(-(screenWidth * 0.03).clamp(-8.0, -4.0), 0),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: shadowBlurRadiusLarge,
                            spreadRadius: (screenWidth * 0.02).clamp(2.0, 6.0),
                            offset: Offset((screenWidth * 0.03).clamp(4.0, 8.0), 0),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: shadowBlurRadiusLarge,
                            offset: Offset(0, shadowOffsetY * 3),
                          ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo - responsive sizing
                        SizedBox(
                          width: logoImageWidth,
                          height: logoImageHeight,
                          child: Image.asset(
                            'assets/logo/fineye_logo.png',
                            fit: BoxFit.contain,
                            alignment: Alignment.center,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.image,
                                color: Colors.grey,
                                size: logoImageWidth * 0.3,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.04),
                  
                  // Tagline Text
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08), // Responsive padding
                    child: Column(
                      children: [
                        // Headline - responsive with clamp
                        Text(
                          'splash_headline'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: headlineFontSize,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.3,
                            shadows: [
                              Shadow(
                                offset: Offset(0, shadowOffsetY),
                                blurRadius: shadowBlurRadius,
                                color: Colors.black.withValues(alpha: 0.5),
                              ),
                              Shadow(
                                offset: Offset(0, shadowOffsetY * 2),
                                blurRadius: shadowBlurRadiusLarge,
                                color: Colors.black.withValues(alpha: 0.3),
                              ),
                              Shadow(
                                offset: Offset(0, shadowOffsetY * 0.5),
                                blurRadius: shadowBlurRadius * 0.33,
                                color: Colors.black.withValues(alpha: 0.6),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: spacingSmall),
                        
                        // Subheadline - responsive with clamp
                        Text(
                          'splash_subheadline'.tr,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: subheadlineFontSize,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.95),
                            height: 1.5,
                            shadows: [
                              Shadow(
                                offset: Offset(0, shadowOffsetY * 0.5),
                                blurRadius: shadowBlurRadius * 0.67,
                                color: Colors.black.withValues(alpha: 0.4),
                              ),
                              Shadow(
                                offset: Offset(0, shadowOffsetY),
                                blurRadius: shadowBlurRadius,
                                color: Colors.black.withValues(alpha: 0.25),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Spacer to push copyright to bottom
                  const Spacer(),
                  
                  // Copyright Text at bottom
                  Padding(
                    padding: EdgeInsets.only(bottom: screenHeight * 0.037),
                    child: Obx(() => AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: controller.showLanguagePanel.value ? 0.0 : 1.0,
                      child: Text(
                        '© 2025 FinEye Technologies',
                        style: TextStyle(
                          fontSize: copyrightFontSize,
                          color: Colors.white.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )),
                  ),
                ],
              ),

              // --- 2. Language Selection Panel Overlay ---
              Obx(() => controller.showLanguagePanel.value
                  ? Container(
                      color: Colors.black54, // Dim background
                      alignment: Alignment.center,
                      child: Container(
                        width: panelWidth,
                        margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        padding: EdgeInsets.all(verticalPadding),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(panelBorderRadius),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: panelShadowBlur,
                              offset: Offset(0, panelShadowOffsetY),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon/Header
                            Container(
                              padding: EdgeInsets.all(panelIconSize * 0.3),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.language,
                                color: AppColors.primaryBlue,
                                size: panelIconSize,
                              ),
                            ),
                            SizedBox(height: spacingMedium),
                            
                            // Title
                            Text(
                              'lang_onboarding_title'.tr,
                              style: TextStyle(
                                fontSize: panelTitleFontSize,
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: spacingSmall),
                            
                            // Subtitle
                            Text(
                              'lang_onboarding_subtitle'.tr,
                              style: TextStyle(
                                fontSize: panelSubtitleFontSize,
                                color: AppColors.mutedText,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: spacingLarge),
                            
                            // Options
                            _buildLanguageOption(
                              context,
                              controller,
                              code: 'en',
                              title: 'lang_option_en_title'.tr,
                              desc: 'lang_option_en_desc'.tr,
                              optionTitleFontSize: panelOptionTitleFontSize,
                              optionDescFontSize: panelOptionDescFontSize,
                              borderRadius: panelOptionBorderRadius,
                            ),
                            SizedBox(height: spacingMedium),
                            _buildLanguageOption(
                              context,
                              controller,
                              code: 'ar',
                              title: 'lang_option_ar_title'.tr,
                              desc: 'lang_option_ar_desc'.tr,
                              optionTitleFontSize: panelOptionTitleFontSize,
                              optionDescFontSize: panelOptionDescFontSize,
                              borderRadius: panelOptionBorderRadius,
                            ),
                            
                            SizedBox(height: spacingLarge),
                            
                            // Continue Button
                            SizedBox(
                              width: double.infinity,
                              height: panelButtonHeight,
                              child: ElevatedButton(
                                onPressed: controller.tempLanguageSelection.value.isNotEmpty
                                    ? () => controller.confirmLanguage()
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryBlue,
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(panelButtonBorderRadius),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'lang_onboarding_continue'.tr,
                                  style: TextStyle(
                                    fontSize: panelButtonFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink()
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context,
    SplashController controller, {
    required String code,
    required String title,
    required String desc,
    required double optionTitleFontSize,
    required double optionDescFontSize,
    required double borderRadius,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final iconSize = (screenWidth * 0.06).clamp(20.0, 28.0);
    final padding = (screenWidth * 0.04).clamp(12.0, 20.0);
    final textSpacing = (screenHeight * 0.004).clamp(2.0, 6.0);
    
    return Obx(() {
      final isSelected = controller.tempLanguageSelection.value == code;
      return GestureDetector(
        onTap: () => controller.selectLanguage(code),
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.05) : Colors.white,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: optionTitleFontSize,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.primaryBlue : AppColors.ink,
                      ),
                    ),
                    SizedBox(height: textSpacing),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: optionDescFontSize,
                        color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.8) : AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: AppColors.primaryBlue, size: iconSize)
              else
                Icon(Icons.radio_button_unchecked, color: Colors.grey.shade400, size: iconSize),
            ],
          ),
        ),
      );
    });
  }
}

// Custom painter for subtle noise texture
class NoisePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1;

    // Create a subtle speckled pattern
    for (int i = 0; i < 500; i++) {
      final x = (i * 37) % size.width;
      final y = (i * 73) % size.height;
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
