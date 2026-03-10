import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crop_your_image/crop_your_image.dart';
import '../../controllers/image_preprocessing_controller.dart';
import '../../../core/constants/app_colors.dart';

// Animated 3-dot loader widget with smooth continuous animation
class _AnimatedDotsLoader extends StatefulWidget {
  const _AnimatedDotsLoader();

  @override
  State<_AnimatedDotsLoader> createState() => _AnimatedDotsLoaderState();
}

class _AnimatedDotsLoaderState extends State<_AnimatedDotsLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Stagger the animation for each dot (0.0, 0.33, 0.66)
              final delay = index * 0.33;
              final animationValue = (_controller.value + delay) % 1.0;
              
              // Create a smooth wave effect
              final opacity = (0.3 + (0.7 * (1 - (animationValue * 2 - 1).abs()))).clamp(0.3, 1.0);
              final scale = (0.8 + (0.2 * (1 - (animationValue * 2 - 1).abs()))).clamp(0.8, 1.0);
              
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
                transform: Matrix4.identity()..scale(scale),
              );
            },
          );
        }),
      ),
    );
  }
}

class ImagePreprocessingView extends GetView<ImagePreprocessingController> {
  const ImagePreprocessingView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<ImagePreprocessingController>()) {
      Get.put(ImagePreprocessingController());
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopNavigationBar(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleSection(),
                    const SizedBox(height: 8),
                    Obx(() {
                      // Show error state if there's an error
                      if (controller.errorMessage.value != null) {
                        return _buildErrorState();
                      }
                      
                      // Show image preview (image loads in background)
                      return Obx(() {
                        // When loading, show only blurred background + loading overlay
                        // When not loading, show normal preview
                        if (controller.showUxLoading.value) {
                          return SizedBox(
                            height: 400,
                            child: Stack(
                              children: [
                                // Completely blurred preview background
                                _buildBlurredBackground(),
                                // UX Loading overlay
                                _buildUxLoadingOverlay(),
                              ],
                            ),
                          );
                        } else {
                          // Normal unblurred preview
                          return _buildImagePreview();
                        }
                      });
                    }),
                  ],
                ),
              ),
            ),
            _buildContinueButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavigationBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.ink),
            onPressed: () => Get.back(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const Spacer(),
          Text(
            'preview_title'.tr,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.tune,
              color: AppColors.ink,
            ),
            onPressed: () => _showPreprocessingSettings(context),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'preprocessing_settings'.tr,
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'preview_title_rich'.tr,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'preview_subtitle'.tr,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLoadingState() {
    // Full-screen loading overlay with smooth animations
    return Container(
      key: const ValueKey('loading_state'),
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.9, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Animated 3-dot loader
                      _buildAnimatedDots(),
                      const SizedBox(height: 20),
                      Obx(() => Text(
                        controller.processingMessage.value.isNotEmpty
                            ? controller.processingMessage.value
                            : 'loading_image'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Animated 3-dot loader widget
  Widget _buildAnimatedDots() {
    return const _AnimatedDotsLoader();
  }

  Widget _buildUxLoadingOverlay() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        onEnd: () {
          // When overlay disappears, trigger unblur
        },
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: scale,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with icon, title, and percentage
                      Row(
                        children: [
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.ink),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'msg_extracting_details'.tr,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          Obx(() => Text(
                            '${(controller.uxLoadingProgress.value * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.successGreen,
                            ),
                          )),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Progress bar
                      Obx(() => ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: controller.uxLoadingProgress.value,
                          backgroundColor: Colors.grey.shade200,
                          minHeight: 8,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color.lerp(
                              AppColors.primaryBlue,
                              AppColors.successGreen,
                              controller.uxLoadingProgress.value,
                            )!,
                          ),
                        ),
                      )),
                      const SizedBox(height: 20),
                      // Progress steps
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildProgressStep('lbl_step_uploading'.tr, 0),
                          _buildProgressStep('lbl_step_reading'.tr, 1),
                          _buildProgressStep('lbl_step_finalizing'.tr, 2),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Current activity detail
                      Obx(() {
                        String detail = '';
                        if (controller.uxLoadingStep.value == 0) {
                          detail = 'msg_step_uploading_detail'.tr;
                        } else if (controller.uxLoadingStep.value == 1) {
                          detail = 'msg_step_reading_detail'.tr;
                        } else {
                          detail = 'msg_step_finalizing_detail'.tr;
                        }
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            detail,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressStep(String label, int stepIndex) {
    return Obx(() {
      final isActive = controller.uxLoadingStep.value == stepIndex;
      final isComplete = controller.uxLoadingStep.value > stepIndex;
      
      return Column(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isComplete
                  ? AppColors.successGreen
                  : isActive
                      ? AppColors.primaryBlue
                      : Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive || isComplete
                  ? AppColors.ink
                  : Colors.grey.shade600,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              controller.errorMessage.value ?? 'error'.tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => controller.reloadImage(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'retry'.tr,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurredBackground() {
    // Show completely blurred preview as background (preview content not visible)
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.white.withValues(alpha: 0.3),
            child: _buildImagePreviewContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreviewContent() {
    return Obx(() {
      final imageBytes = controller.originalImageBytes.value;

      if (imageBytes == null) {
        return Container(
          height: 400,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          imageBytes,
          fit: BoxFit.contain,
        ),
      );
    });
  }

  Widget _buildImagePreview() {
    return Obx(() {
      if (controller.showComparison.value) {
        return _buildComparisonView();
      }

      // Show original image if toggle is on, otherwise show preprocessed
      final imageBytes = controller.showOriginalImage.value
          ? controller.originalImageBytes.value
          : (controller.preprocessedImageBytes.value ??
              controller.originalImageBytes.value);

      if (imageBytes == null) {
        return SizedBox(
          height: 400,
          child: _buildLoadingState(),
        );
      }
      
      // Use Crop widget when crop handles are shown
      if (controller.showCropHandles.value) {
        return Container(
          height: 400,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Builder(
              builder: (context) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: AppColors.primaryBlue,
                    secondary: AppColors.primaryBlue,
                  ),
                ),
                child: Crop(
                  image: imageBytes,
                  controller: controller.cropController.value,
                  aspectRatio: null, // Allow free-form cropping
                  cornerDotBuilder: (size, edgeAlignment) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  onCropped: (result) {
                    // Handle cropped image when crop is applied
                    // Pass CropResult to controller which will extract bytes
                    controller.handleCroppedImage(result);
                  },
                ),
              ),
            ),
          ),
        );
      }

      return Container(
        height: 400,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.memory(
              imageBytes,
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildComparisonView() {
    return Obx(() {
      final originalBytes = controller.originalImageBytes.value;
      final processedBytes = controller.preprocessedImageBytes.value ??
          controller.originalImageBytes.value;

      if (originalBytes == null || processedBytes == null) {
        return Center(
          child: Text('msg_no_image_available'.tr),
        );
      }

      return Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  width: double.infinity,
                  child: Text(
                    'before'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
                Expanded(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.memory(
                      originalBytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 2,
            color: Colors.grey.shade300,
          ),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  color: AppColors.successGreen.withValues(alpha: 0.1),
                  width: double.infinity,
                  child: Text(
                    'after'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.successGreen,
                    ),
                  ),
                ),
                Expanded(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.memory(
                      processedBytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }



  void _showPreprocessingSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPreprocessingSettingsPanel(),
    );
  }

  Widget _buildPreprocessingSettingsPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.tune,
                      color: AppColors.primaryBlue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'preprocessing_settings'.tr,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildSettingToggle(
                      'edge_detection',
                      'edge_detection'.tr,
                      'msg_edge_detection_desc'.tr,
                      controller.enableEdgeDetection.value,
                      Icons.crop_free,
                    ),
                    _buildSettingToggle(
                      'auto_crop',
                      'auto_crop'.tr,
                      'msg_auto_crop_desc'.tr,
                      controller.enableAutoCrop.value,
                      Icons.crop,
                    ),
                    _buildSettingToggle(
                      'perspective_correction',
                      'perspective_correction'.tr,
                      'msg_perspective_desc'.tr,
                      controller.enablePerspectiveCorrection.value,
                      Icons.transform,
                    ),
                    _buildSettingToggle(
                      'grayscale',
                      'grayscale_conversion'.tr,
                      'msg_grayscale_desc'.tr,
                      controller.enableGrayscale.value,
                      Icons.invert_colors,
                    ),
                    _buildSettingToggle(
                      'contrast_enhancement',
                      'contrast_enhancement'.tr,
                      'msg_contrast_desc'.tr,
                      controller.enableContrastEnhancement.value,
                      Icons.contrast,
                    ),
                    _buildSettingToggle(
                      'noise_reduction',
                      'noise_reduction'.tr,
                      'msg_noise_reduction_desc'.tr,
                      controller.enableNoiseReduction.value,
                      Icons.auto_fix_high,
                    ),
                    _buildSettingToggle(
                      'sharpening',
                      'sharpening'.tr,
                      'msg_sharpening_desc'.tr,
                      controller.enableSharpening.value,
                      Icons.auto_awesome,
                    ),
                    _buildSettingToggle(
                      'binarization',
                      'binarization'.tr,
                      'Convert to black and white (Otsu threshold)',
                      controller.enableBinarization.value,
                      Icons.filter_b_and_w,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSettingToggle(
    String key,
    String title,
    String description,
    bool value,
    IconData icon,
  ) {
    return Obx(() {
      final isEnabled = _getToggleValue(key);
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.primaryBlue.withValues(alpha: 0.05)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled
                ? AppColors.primaryBlue.withValues(alpha: 0.3)
                : Colors.grey.shade200,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isEnabled
                    ? AppColors.primaryBlue.withValues(alpha: 0.1)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isEnabled ? AppColors.primaryBlue : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isEnabled ? AppColors.ink : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: isEnabled,
              onChanged: (newValue) => controller.togglePreprocessing(key),
              activeColor: AppColors.primaryBlue,
            ),
          ],
        ),
      );
    });
  }

  bool _getToggleValue(String key) {
    switch (key) {
      case 'edge_detection':
        return controller.enableEdgeDetection.value;
      case 'auto_crop':
        return controller.enableAutoCrop.value;
      case 'perspective_correction':
        return controller.enablePerspectiveCorrection.value;
      case 'grayscale':
        return controller.enableGrayscale.value;
      case 'contrast_enhancement':
        return controller.enableContrastEnhancement.value;
      case 'noise_reduction':
        return controller.enableNoiseReduction.value;
      case 'sharpening':
        return controller.enableSharpening.value;
      case 'binarization':
        return controller.enableBinarization.value;
      default:
        return false;
    }
  }

  Widget _buildContinueButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: Obx(() {
          final isProcessing = controller.showUxLoading.value || controller.isLoading.value;
          final progressComplete = controller.uxLoadingProgress.value >= 1.0;
          final isContinuing = controller.isContinuing.value;
          final isEnabled = !isProcessing && progressComplete && !isContinuing;
          
          return ElevatedButton(
            onPressed: isEnabled ? () async {
              print('🔘 Continue button pressed');
              try {
                // Apply crop if crop handles are shown
                if (controller.showCropHandles.value) {
                  print('✂️ Applying crop...');
                  await controller.applyCropFromController();
                  print('✅ Crop applied');
                }
                print('🚀 Calling applyAndContinue()...');
                await controller.applyAndContinue();
                print('✅ applyAndContinue() completed');
              } catch (e, stackTrace) {
                print('❌ Continue button error: $e');
                print('❌ Stack trace: $stackTrace');
              }
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isEnabled ? AppColors.primaryBlue : Colors.grey.shade400,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isProcessing || isContinuing
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isContinuing ? 'loading'.tr : 'processing'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Text(
                    progressComplete ? 'apply_continue'.tr : 'processing'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          );
        }),
      ),
    );
  }
}

