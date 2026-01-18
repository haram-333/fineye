import 'dart:typed_data';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:pdfx/pdfx.dart';
import 'package:crop_your_image/crop_your_image.dart';
import '../../data/models/invoice_file_result.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/snackbar_service.dart';
import 'ocr_controller.dart';
import '../../data/services/invoice_data_extractor.dart';

// Conditional imports for platform-specific packages
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart' if (dart.library.html) 'package:fineye/presentation/controllers/gal_stub.dart';

// Import File conditionally  
import 'dart:io' show File if (dart.library.html) 'package:fineye/presentation/controllers/file_stub.dart' show File;

class ImagePreprocessingController extends GetxController {
  // File and image state
  final originalFile = Rx<File?>(null);
  final originalImageBytes = Rx<Uint8List?>(null);
  final preprocessedImageBytes = Rx<Uint8List?>(null);
  final fileType = Rx<InvoiceFileType?>(null);
  final isPdf = false.obs;
  final pdfPageCount = 0.obs;

  // Processing state
  final isLoading = false.obs;
  final processingMessage = ''.obs;
  final errorMessage = Rx<String?>(null);

  // Preprocessing toggles
  final enableEdgeDetection = true.obs;
  final enableAutoCrop = true.obs;
  final enablePerspectiveCorrection = true.obs;
  final enableGrayscale = false.obs;
  final enableContrastEnhancement = true.obs;
  final enableNoiseReduction = true.obs;
  final enableSharpening = true.obs;
  final enableBinarization = false.obs;

  // Crop state
  final showCropHandles = false.obs;
  final cropController = CropController().obs;
  final lastCroppedImageBytes = Rx<Uint8List?>(null);
  final hasUnsavedCropChanges = false.obs;

  // Comparison view
  final showComparison = false.obs;
  
  // Show original image view
  final showOriginalImage = false.obs;
  
  // Active button state (mutually exclusive)
  final activeButton = Rx<String?>('none'); // 'crop', 'auto', 'original', 'download', 'none'
  
  // UX Loading overlay (fake progress for user experience)
  final showUxLoading = true.obs;
  final uxLoadingProgress = 0.0.obs;
  final uxLoadingStep = 0.obs; // 0: Uploading, 1: Reading totals, 2: Final checks
  Timer? _uxLoadingTimer;
  
  // Loading state when Continue button is clicked
  final isContinuing = false.obs;
  
  // Debouncing for preprocessing toggles
  Timer? _preprocessingDebounceTimer;
  bool _isProcessing = false;

  // Image dimensions
  final imageWidth = 0.obs;
  final imageHeight = 0.obs;

  @override
  void onInit() {
    super.onInit();
    cropController.value = CropController(); // Initialize here
    _loadFileFromArguments();
    _startUxLoadingAnimation();
  }
  
  void _startUxLoadingAnimation() {
    // Start UX loading animation (3 seconds)
    const duration = Duration(milliseconds: 3000); // 3 seconds
    const totalSteps = 100;
    final stepDuration = duration.inMilliseconds / totalSteps;
    
    uxLoadingProgress.value = 0.0;
    uxLoadingStep.value = 0;
    
    _uxLoadingTimer = Timer.periodic(Duration(milliseconds: stepDuration.toInt()), (timer) {
      if (uxLoadingProgress.value >= 1.0) {
        timer.cancel();
        // Complete with pop-out animation - delay to show completion
        Future.delayed(const Duration(milliseconds: 500), () {
          showUxLoading.value = false; // This will trigger unblur
        });
        return;
      }
      
      // Update progress
      uxLoadingProgress.value += 1.0 / totalSteps;
      
      // Update step based on progress
      if (uxLoadingProgress.value < 0.35) {
        uxLoadingStep.value = 0; // Uploading
      } else if (uxLoadingProgress.value < 0.75) {
        uxLoadingStep.value = 1; // Reading totals
      } else {
        uxLoadingStep.value = 2; // Final checks
      }
    });
  }
  
  @override
  void onClose() {
    _uxLoadingTimer?.cancel();
    _preprocessingDebounceTimer?.cancel();
    // Clean up resources
    originalImageBytes.value = null;
    preprocessedImageBytes.value = null;
    super.onClose();
  }

  void _loadFileFromArguments() {
    final args = Get.arguments;
    if (args != null && args is Map) {
      // On web, accept Uint8List directly; on mobile, accept File
      if (kIsWeb) {
        final imageBytes = args['imageBytes'] as Uint8List?;
        final type = args['type'] as InvoiceFileType?;
        if (imageBytes != null && type != null) {
          originalImageBytes.value = imageBytes;
          fileType.value = type;
          isPdf.value = type == InvoiceFileType.pdf;
          _loadImage();
        } else {
          // Missing required arguments on web
          _handleMissingArguments();
        }
      } else {
        final file = args['file'] as File?;
        final type = args['type'] as InvoiceFileType?;
        if (file != null && type != null) {
          originalFile.value = file;
          fileType.value = type;
          isPdf.value = type == InvoiceFileType.pdf;
          _loadImage();
        } else {
          // Missing required arguments on mobile
          _handleMissingArguments();
        }
      }
    } else {
      // No arguments provided
      _handleMissingArguments();
    }
  }

  void _handleMissingArguments() {
    SnackbarService.to.showError(
      'Error',
      'No image file provided. Please try again.',
    );
    // Navigate back to upload screen after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      Get.back();
    });
  }

  Future<void> reloadImage() async {
    await _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      isLoading.value = true;
      processingMessage.value = 'loading_image'.tr;
      errorMessage.value = null;

      if (fileType.value == InvoiceFileType.pdf) {
        await _extractPdfFirstPage();
      } else {
        await _loadImageFile();
      }

      if (originalImageBytes.value != null) {
        // Decode image to get dimensions
        final decoded = img.decodeImage(originalImageBytes.value!);
        if (decoded != null) {
          imageWidth.value = decoded.width;
          imageHeight.value = decoded.height;
        }
        
        // Reset unsaved crop changes when new image is loaded
        hasUnsavedCropChanges.value = false;
        
        // Show image immediately, then process in background
        // This makes the UI more responsive
        isLoading.value = false;
        
        // Apply preprocessing asynchronously without blocking UI
        // Run in a microtask to ensure UI updates first
        Future.microtask(() => _applyPreprocessing());
        
        // Initialize crop controller with centered default area when image is loaded
        if (showCropHandles.value) {
          _initializeCropController();
        }
      } else {
        isLoading.value = false;
      }
    } catch (e) {
      isLoading.value = false;
      errorMessage.value = 'error_loading_image'.tr;
      SnackbarService.to.showError(
        'error'.tr,
        'error_loading_image'.tr,
      );
    }
  }

  Future<void> _extractPdfFirstPage() async {
    try {
      processingMessage.value = 'extracting_pdf'.tr;

      PdfDocument pdf;
      if (kIsWeb) {
        // On web, use openData instead of openFile
        if (originalImageBytes.value == null) {
          throw Exception('No PDF data available on web');
        }
        pdf = await PdfDocument.openData(originalImageBytes.value!);
      } else {
        pdf = await PdfDocument.openFile(originalFile.value!.path);
      }
      pdfPageCount.value = pdf.pagesCount;

      // Render first page to image
      final page = await pdf.getPage(1);
      final pageImage = await page.render(
        width: 2000,
        height: 2000,
      );
      await page.close();

      if (pageImage != null) {
        // PdfPageImage.bytes is already Uint8List
        originalImageBytes.value = pageImage.bytes;
        final decoded = img.decodeImage(pageImage.bytes);
        if (decoded != null) {
          imageWidth.value = decoded.width;
          imageHeight.value = decoded.height;
        }
      }

      await pdf.close();
    } catch (e) {
      throw Exception('Failed to extract PDF: $e');
    }
  }

  Future<void> _loadImageFile() async {
    try {
      processingMessage.value = 'loading_image'.tr;
      
      Uint8List bytes;
      // On web, imageBytes should already be loaded
      if (kIsWeb) {
        if (originalImageBytes.value == null) {
          throw Exception('No image data available on web');
        }
        bytes = originalImageBytes.value!;
      } else {
        // Load file bytes asynchronously to prevent blocking
        bytes = await originalFile.value!.readAsBytes();
        originalImageBytes.value = bytes;
      }

      // Get dimensions asynchronously to prevent UI blocking
      // Decode in a separate microtask to avoid blocking
      await Future.microtask(() {
        try {
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            imageWidth.value = decoded.width;
            imageHeight.value = decoded.height;
          }
        } catch (e) {
          // If decoding fails, dimensions will remain 0
          debugPrint('Error getting image dimensions: $e');
        }
      });
    } catch (e) {
      throw Exception('Failed to load image: $e');
    }
  }

  Future<void> _applyPreprocessing() async {
    if (originalImageBytes.value == null || _isProcessing) return;
    
    _isProcessing = true;
    
    try {
      // Show processing indicator only if image is already visible
      // This prevents stuck loading when image loads quickly
      processingMessage.value = 'processing_image'.tr;

      // Decode image - preserve original resolution to prevent pixelation
      img.Image? processed = img.decodeImage(originalImageBytes.value!);
      if (processed == null) return;

      // Balance quality and performance: use 2500px for preview processing
      // This prevents pixelation while keeping processing fast enough for real-time updates
      // Final output in applyAndContinue uses full resolution
      final maxDimension = 2500;
      if (processed.width > maxDimension || processed.height > maxDimension) {
        if (processed.width > processed.height) {
          processed = img.copyResize(processed, width: maxDimension);
        } else {
          processed = img.copyResize(processed, height: maxDimension);
        }
      }

      // Apply preprocessing steps in order
      // IMPORTANT: Don't auto-detect edges when crop handles are shown (user is manually adjusting)
      if ((enableEdgeDetection.value || enableAutoCrop.value) && !showCropHandles.value) {
        processingMessage.value = 'edge_detection'.tr;
        await _detectEdges(processed);
      }

      // Don't apply crop during preview - only when user clicks "Apply & Continue"
      // This prevents crashes from processing on every drag

      if (enablePerspectiveCorrection.value) {
        processingMessage.value = 'perspective_correction'.tr;
        processed = await _correctPerspective(processed);
      }

      // Apply preprocessing steps in optimized order for better quality
      // Step 1: Grayscale conversion (if enabled)
      if (enableGrayscale.value) {
        processingMessage.value = 'grayscale_conversion'.tr;
        processed = img.grayscale(processed);
      }

      // Step 2: Light noise reduction (if enabled and needed)
      if (enableNoiseReduction.value) {
        processingMessage.value = 'noise_reduction'.tr;
        processed = await _reduceNoise(processed);
      }

      // Step 3: Contrast enhancement (gentle, adaptive - if enabled)
      if (enableContrastEnhancement.value) {
        processingMessage.value = 'contrast_enhancement'.tr;
        processed = await _enhanceContrast(processed);
      }

      // Step 4: Sharpening (subtle, edge-focused - if enabled)
      if (enableSharpening.value) {
        processingMessage.value = 'sharpening'.tr;
        processed = await _sharpen(processed);
      }

      // Step 5: Binarization (only if explicitly enabled)
      if (enableBinarization.value) {
        processingMessage.value = 'binarization'.tr;
        processed = await _binarize(processed);
      }

      // Encode processed image with high quality to preserve text clarity
      // Only encode if we actually processed something
      final hasProcessing = enableGrayscale.value ||
          enableContrastEnhancement.value ||
          enableNoiseReduction.value ||
          enableSharpening.value ||
          enableBinarization.value;
      
      if (hasProcessing) {
        // Use JPEG with quality 95 to preserve text clarity and prevent compression artifacts
        preprocessedImageBytes.value = Uint8List.fromList(
          img.encodeJpg(processed, quality: 95),
        );
      } else {
        // No processing applied, use original
        preprocessedImageBytes.value = originalImageBytes.value;
      }
    } catch (e) {
      errorMessage.value = 'error_processing_image'.tr;
      SnackbarService.to.showError(
        'error'.tr,
        'error_processing_image'.tr,
      );
    } finally {
      isLoading.value = false;
      _isProcessing = false;
    }
  }

  Future<img.Image> _detectEdges(img.Image image) async {
    // Edge detection is now handled by crop_image_widget
    // This method is kept for compatibility but does nothing
    return image;
  }

  // Old auto-detect corners removed - using image_cropper now
  @Deprecated('No longer used - image_cropper handles this')
  Future<void> _autoDetectCorners(img.Image image) async {
    try {
      // Use very small image for fast edge detection (300px max)
      final small = img.copyResize(image, width: 300);
      final gray = img.grayscale(small);
      final blurred = img.gaussianBlur(gray, radius: 1);
      
      final width = blurred.width;
      final height = blurred.height;
      
      // Simplified edge detection - sample fewer pixels for speed
      int topEdge = 0;
      int bottomEdge = height - 1;
      int leftEdge = 0;
      int rightEdge = width - 1;
      
      // Sample every 5th pixel for speed
      final sampleStep = 5;
      
      // Find top edge (scan from top, sample pixels)
      for (int y = 0; y < height ~/ 4; y += 2) {
        int darkPixels = 0;
        int samples = 0;
        for (int x = 0; x < width; x += sampleStep) {
          final pixel = blurred.getPixel(x, y);
          final intensity = (pixel.r + pixel.g + pixel.b) / 3;
          if (intensity < 180) {
            darkPixels++;
          }
          samples++;
        }
        if (darkPixels > samples * 0.15) {
          topEdge = y;
          break;
        }
      }
      
      // Find bottom edge
      for (int y = height - 1; y > height * 3 ~/ 4; y -= 2) {
        int darkPixels = 0;
        int samples = 0;
        for (int x = 0; x < width; x += sampleStep) {
          final pixel = blurred.getPixel(x, y);
          final intensity = (pixel.r + pixel.g + pixel.b) / 3;
          if (intensity < 180) {
            darkPixels++;
          }
          samples++;
        }
        if (darkPixels > samples * 0.15) {
          bottomEdge = y;
          break;
        }
      }
      
      // Find left edge
      for (int x = 0; x < width ~/ 4; x += 2) {
        int darkPixels = 0;
        int samples = 0;
        for (int y = 0; y < height; y += sampleStep) {
          final pixel = blurred.getPixel(x, y);
          final intensity = (pixel.r + pixel.g + pixel.b) / 3;
          if (intensity < 180) {
            darkPixels++;
          }
          samples++;
        }
        if (darkPixels > samples * 0.15) {
          leftEdge = x;
          break;
        }
      }
      
      // Find right edge
      for (int x = width - 1; x > width * 3 ~/ 4; x -= 2) {
        int darkPixels = 0;
        int samples = 0;
        for (int y = 0; y < height; y += sampleStep) {
          final pixel = blurred.getPixel(x, y);
          final intensity = (pixel.r + pixel.g + pixel.b) / 3;
          if (intensity < 180) {
            darkPixels++;
          }
          samples++;
        }
        if (darkPixels > samples * 0.15) {
          rightEdge = x;
          break;
        }
      }
      
      // Old code removed - image_cropper handles this now
    } catch (e) {
      // Auto-detection removed
    }
  }

  @Deprecated('No longer used - image_cropper handles this')
  Future<img.Image> _applyCrop(img.Image image) async {
    // Crop is now handled by image_cropper package
    return image;
  }

  Future<img.Image> _correctPerspective(img.Image image) async {
    // Perspective correction using the crop corners
    // This is a simplified version - for production, consider using opencv_dart
    return image;
  }

  Future<img.Image> _enhanceContrast(img.Image image) async {
    // Use optimized contrast enhancement - faster for large images
    // For very large images, use simpler histogram-based approach
    // For smaller images, use the more sophisticated gamma correction
    
    final totalPixels = image.width * image.height;
    final useFastMethod = totalPixels > 1000000; // > 1MP use faster method
    
    if (useFastMethod) {
      // Fast method: Simple histogram stretching for large images
      // Find min and max values
      int minVal = 255;
      int maxVal = 0;
      
      // Sample pixels for speed (every 10th pixel)
      for (int y = 0; y < image.height; y += 10) {
        for (int x = 0; x < image.width; x += 10) {
          final pixel = image.getPixel(x, y);
          final val = pixel.r.toInt();
          if (val < minVal) minVal = val;
          if (val > maxVal) maxVal = val;
        }
      }
      
      // Apply simple linear stretch with limits to avoid over-enhancement
      final range = (maxVal - minVal).clamp(50, 255);
      final scale = 255.0 / range;
      final offset = minVal.toDouble();
      
      final enhanced = img.Image(width: image.width, height: image.height);
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final val = pixel.r.toInt();
          final stretched = ((val - offset) * scale).clamp(0, 255).toInt();
          enhanced.setPixelRgba(x, y, stretched, stretched, stretched, pixel.a.toInt());
        }
      }
      return enhanced;
    } else {
      // Slower but better method: Gamma correction for smaller images
      // Step 1: Detect if background is dark (for inversion)
      int sampleStep = 50;
      int sampleCount = 0;
      int sum = 0;
      for (int y = 0; y < image.height; y += sampleStep) {
        for (int x = 0; x < image.width; x += sampleStep) {
          final pixel = image.getPixel(x, y);
          sum += pixel.r.toInt();
          sampleCount++;
        }
      }
      final mean = sum / sampleCount;
      
      // Step 2: Invert if dark background
      img.Image workingImage = img.Image.from(image);
      if (mean < 127) {
        for (int y = 0; y < workingImage.height; y++) {
          for (int x = 0; x < workingImage.width; x++) {
            final pixel = workingImage.getPixel(x, y);
            final inverted = (255 - pixel.r.toInt()).clamp(0, 255);
            workingImage.setPixelRgba(x, y, inverted, inverted, inverted, pixel.a.toInt());
          }
        }
      }
      
      // Step 3: Apply gentle gamma correction
      const gamma = 0.88;
      for (int y = 0; y < workingImage.height; y++) {
        for (int x = 0; x < workingImage.width; x++) {
          final pixel = workingImage.getPixel(x, y);
          final normalized = pixel.r / 255.0;
          final enhanced = (255 * math.pow(normalized, 1.0 / gamma)).clamp(0, 255).toInt();
          workingImage.setPixelRgba(x, y, enhanced, enhanced, enhanced, pixel.a.toInt());
        }
      }
      
      return workingImage;
    }
  }

  Future<img.Image> _reduceNoise(img.Image image) async {
    // Apply very light noise reduction to preserve detail
    // Use minimal blur radius to avoid pixelation
    // Only apply if image actually has noticeable noise
    return img.gaussianBlur(image, radius: 1);
  }

  Future<img.Image> _sharpen(img.Image image) async {
    // Apply unsharp masking for text clarity
    // Skip sharpening for very large images to maintain performance
    // Sharpening is computationally expensive and can be skipped for preview
    final totalPixels = image.width * image.height;
    if (totalPixels > 1500000) { // > 1.5MP skip sharpening for speed
      return image;
    }
    
    // Step 1: Create a slightly blurred version
    final blurred = img.gaussianBlur(image, radius: 1);
    
    // Step 2: Apply unsharp masking: sharpened = original + (original - blurred) * amount
    // Use amount around 0.3 for subtle sharpening
    const amount = 0.3;
    
    final sharpened = img.Image(width: image.width, height: image.height);
    
    // Process in chunks to allow UI updates for large images
    const chunkSize = 100; // Process 100 rows at a time
    for (int startY = 0; startY < image.height; startY += chunkSize) {
      final endY = (startY + chunkSize).clamp(0, image.height);
      
      for (int y = startY; y < endY; y++) {
        for (int x = 0; x < image.width; x++) {
          final originalPixel = image.getPixel(x, y);
          final blurredPixel = blurred.getPixel(x, y);
          
          // Calculate difference
          final diff = originalPixel.r.toInt() - blurredPixel.r.toInt();
          
          // Apply unsharp mask formula
          final sharpenedValue = (originalPixel.r.toInt() + diff * amount).clamp(0, 255).toInt();
          
          sharpened.setPixelRgba(x, y, sharpenedValue, sharpenedValue, sharpenedValue, originalPixel.a.toInt());
        }
      }
      
      // Yield to event loop every chunk to keep UI responsive
      if (startY + chunkSize < image.height) {
        await Future.delayed(const Duration(milliseconds: 1));
      }
    }
    
    return sharpened;
  }

  Future<img.Image> _binarize(img.Image image) async {
    // Apply Otsu's method for adaptive thresholding
    return img.grayscale(image);
  }

  void togglePreprocessing(String key) {
    // Update toggle state immediately for instant UI feedback
    switch (key) {
      case 'edge_detection':
        enableEdgeDetection.value = !enableEdgeDetection.value;
        break;
      case 'auto_crop':
        enableAutoCrop.value = !enableAutoCrop.value;
        break;
      case 'perspective_correction':
        enablePerspectiveCorrection.value = !enablePerspectiveCorrection.value;
        break;
      case 'grayscale':
        enableGrayscale.value = !enableGrayscale.value;
        break;
      case 'contrast_enhancement':
        enableContrastEnhancement.value = !enableContrastEnhancement.value;
        break;
      case 'noise_reduction':
        enableNoiseReduction.value = !enableNoiseReduction.value;
        break;
      case 'sharpening':
        enableSharpening.value = !enableSharpening.value;
        break;
      case 'binarization':
        enableBinarization.value = !enableBinarization.value;
        break;
    }
    
    // Debounce preprocessing to prevent crashes from rapid option changes
    // Cancel previous timer if user toggles again quickly
    _preprocessingDebounceTimer?.cancel();
    
    // Only reprocess if crop handles are NOT shown (to prevent crashes)
    if (!showCropHandles.value) {
      // Debounce for 300ms - process after user stops toggling
      _preprocessingDebounceTimer = Timer(const Duration(milliseconds: 300), () {
        _applyPreprocessing();
      });
    }
  }

  void toggleCropHandles() {
    // Update state immediately for instant feedback
    if (activeButton.value == 'crop') {
      // If already active, apply crop and then deactivate
      if (showCropHandles.value) {
        // Trigger crop - onCropped callback will handle updating originalImageBytes
        // Deactivate crop handles after a small delay to allow crop to complete
        cropController.value.crop();
        // Delay deactivation slightly to ensure crop completes
        Future.delayed(const Duration(milliseconds: 100), () {
          showCropHandles.value = false;
          activeButton.value = 'none';
        });
      } else {
        showCropHandles.value = false;
        activeButton.value = 'none';
      }
    } else {
      // Activate crop and deactivate others - update state immediately
      activeButton.value = 'crop';
      showCropHandles.value = true;
      showOriginalImage.value = false;
      // Reinitialize crop controller with centered default crop area
      // Do this after state update using post-frame callback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeCropController();
      });
    }
  }
  
  void _initializeCropController() {
    // Create new crop controller
    // The crop_your_image package will center the crop area by default
    // We'll create it fresh each time to ensure proper initialization
    cropController.value = CropController();
    
    // Note: crop_your_image centers the crop area automatically
    // The initial crop will be centered and user can adjust from there
  }
  
  void handleCroppedImage(dynamic cropResult) {
    try {
      Uint8List croppedBytes;
      
      // Handle CropResult from crop_your_image 2.0.0
      // Try to extract bytes using dynamic access since API may vary
      if (cropResult is Uint8List) {
        croppedBytes = cropResult;
      } else {
        // Try to access bytes property dynamically
        final dynamic result = cropResult;
        final bytes = result.bytes;
        if (bytes is Uint8List) {
          croppedBytes = bytes;
        } else {
          throw Exception('Could not extract bytes from CropResult');
        }
      }
      
      if (croppedBytes.isEmpty) {
        return;
      }
      
      // Store the cropped image
      lastCroppedImageBytes.value = croppedBytes;
      originalImageBytes.value = croppedBytes;
      
      // Decode to get dimensions
      final decoded = img.decodeImage(croppedBytes);
      if (decoded != null) {
        imageWidth.value = decoded.width;
        imageHeight.value = decoded.height;
      }
      
      // Reset unsaved changes flag since crop is now saved
      hasUnsavedCropChanges.value = false;
      
      // Reapply preprocessing to the new cropped image
      _applyPreprocessing();
    } catch (e) {
      SnackbarService.to.showError(
        'error'.tr,
        'error_processing_image'.tr,
      );
    }
  }
  
  Future<void> applyCropFromController() async {
    if (originalImageBytes.value == null) return;
    
    // Trigger crop - the onCropped callback in the view will handle the result
    cropController.value.crop();
  }


  void resetPreprocessing() {
    enableEdgeDetection.value = true;
    enableAutoCrop.value = true;
    enablePerspectiveCorrection.value = true;
    enableGrayscale.value = false;
    enableContrastEnhancement.value = true;
    enableNoiseReduction.value = true;
    enableSharpening.value = true;
    enableBinarization.value = false;
    showCropHandles.value = false;
    _applyPreprocessing();
  }

  void toggleComparison() {
    showComparison.value = !showComparison.value;
  }

  void toggleOriginalImage() {
    // Check for unsaved crop changes before switching
    if (showCropHandles.value && hasUnsavedCropChanges.value) {
      _showCropSaveDialog(
        onSave: () async {
          await _saveCropChanges();
          await Future.delayed(const Duration(milliseconds: 200));
          // Activate original after saving
          activeButton.value = 'original';
          showOriginalImage.value = true;
          showCropHandles.value = false;
        },
        onDiscard: () async {
          await _discardCropChanges();
          // Activate original after discarding
          activeButton.value = 'original';
          showOriginalImage.value = true;
          showCropHandles.value = false;
        },
      );
      return;
    }
    
    // Update state immediately
    if (activeButton.value == 'original') {
      // If already active, deactivate
      showOriginalImage.value = false;
      activeButton.value = 'none';
    } else {
      // Activate original and deactivate others
      activeButton.value = 'original';
      showOriginalImage.value = true;
      showCropHandles.value = false;
    }
  }
  
  void activateAutoButton() {
    // Check for unsaved crop changes before switching
    if (showCropHandles.value && hasUnsavedCropChanges.value) {
      _showCropSaveDialog(
        onSave: () async {
          await _saveCropChanges();
          await Future.delayed(const Duration(milliseconds: 200));
          // Activate auto after saving
          activeButton.value = 'auto';
          showCropHandles.value = false;
          showOriginalImage.value = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            resetPreprocessing();
          });
        },
        onDiscard: () async {
          await _discardCropChanges();
          // Activate auto after discarding
          activeButton.value = 'auto';
          showCropHandles.value = false;
          showOriginalImage.value = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            resetPreprocessing();
          });
        },
      );
      return;
    }
    
    // Update state immediately, do heavy operations in background
    if (activeButton.value == 'auto') {
      activeButton.value = 'none';
    } else {
      activeButton.value = 'auto';
      showCropHandles.value = false;
      showOriginalImage.value = false;
      // Run resetPreprocessing in background after state update
      WidgetsBinding.instance.addPostFrameCallback((_) {
        resetPreprocessing();
      });
    }
  }
  
  Future<void> downloadImage() async {
    // Check for unsaved crop changes before switching
    if (showCropHandles.value && hasUnsavedCropChanges.value) {
      _showCropSaveDialog(
        onSave: () async {
          await _saveCropChanges();
          await Future.delayed(const Duration(milliseconds: 200));
          // Continue with download after saving
          await _performDownload();
        },
        onDiscard: () async {
          await _discardCropChanges();
          // Continue with download after discarding
          await _performDownload();
        },
      );
      return;
    }
    
    // Continue with normal download flow
    await _performDownload();
  }
  
  Future<void> _performDownload() async {
    // Update state immediately
    if (activeButton.value == 'download') {
      activeButton.value = 'none';
      return;
    }
    
    activeButton.value = 'download';
    
    // Show confirmation dialog
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Save to Gallery'),
        content: const Text('Do you want to save the current image to your gallery?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    
    if (result != true) {
      activeButton.value = 'none';
      return;
    }
    
    try {
      isLoading.value = true;
      processingMessage.value = 'Saving to gallery...';
      
      // Determine which image to save
      Uint8List? imageBytes;
      
      // If crop handles are active, save the cropped version if available
      // Otherwise save based on current view mode
      if (showCropHandles.value) {
        // When crop handles are shown, if user has previously cropped, use that
        // Otherwise, save the original image (crop is preview-only until applied)
        imageBytes = lastCroppedImageBytes.value ?? originalImageBytes.value;
      } else if (showOriginalImage.value) {
        imageBytes = originalImageBytes.value;
      } else {
        imageBytes = preprocessedImageBytes.value ?? originalImageBytes.value;
      }
      
      if (imageBytes == null) {
        SnackbarService.to.showError(
          'Error',
          'No image available to save',
        );
        activeButton.value = 'none';
        isLoading.value = false;
        return;
      }
      
      // Save to gallery using gal package (mobile only)
      if (kIsWeb) {
        // On web, show message that download feature is not fully implemented
        // Users can use browser's save image functionality
        isLoading.value = false;
        activeButton.value = 'none';
        
        SnackbarService.to.showInfo(
          'Info',
          'Please use your browser\'s save image feature (right-click > Save image)',
          duration: const Duration(seconds: 3),
        );
      } else {
        // Request permission first
        await Gal.requestAccess();
        
        // Save the image bytes directly to gallery
        await Gal.putImageBytes(imageBytes);
        
        isLoading.value = false;
        activeButton.value = 'none';
        
        SnackbarService.to.showSuccess(
          'Success',
          'Image saved to gallery',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      isLoading.value = false;
      activeButton.value = 'none';
      SnackbarService.to.showError(
        'Error',
        'Failed to save image: $e',
      );
    }
  }

  Future<void> _showCropSaveDialog({
    required Future<void> Function() onSave,
    required Future<void> Function() onDiscard,
  }) async {
    final result = await Get.dialog<bool>(
      barrierDismissible: false,
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text(
          'Save Changes?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        content: const Text(
          'You have unsaved crop changes. Do you want to save them before continuing?',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.mutedText,
          ),
        ),
        actions: [
          // Cancel button
          TextButton(
            onPressed: () => Get.back(result: null),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.mutedText,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Don't Save button
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text(
              'Don\'t Save',
              style: TextStyle(
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Save Changes button
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Save Changes',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    
    if (result == true) {
      // User chose to save
      await onSave();
    } else if (result == false) {
      // User chose to discard
      await onDiscard();
    }
    // If result is null, user canceled - do nothing
  }
  
  Future<void> _saveCropChanges() async {
    if (originalImageBytes.value == null) return;
    
    try {
      // Trigger crop operation
      cropController.value.crop();
      // Wait for crop to complete (handleCroppedImage will be called via onCropped callback)
      await Future.delayed(const Duration(milliseconds: 300));
      // hasUnsavedCropChanges is set to false in handleCroppedImage
    } catch (e) {
      SnackbarService.to.showError(
        'Error',
        'Failed to save crop changes: $e',
      );
    }
  }
  
  Future<void> _discardCropChanges() async {
    try {
      // Reset crop controller to original state
      _initializeCropController();
      // Reset unsaved changes flag
      hasUnsavedCropChanges.value = false;
    } catch (e) {
      debugPrint('Error discarding crop changes: $e');
    }
  }

  Future<void> applyAndContinue() async {
    // Prevent multiple clicks
    if (isContinuing.value) {
      return;
    }
    
    isContinuing.value = true;
    
    // Save preprocessed image to temp file
    try {
      isLoading.value = true;
      processingMessage.value = 'processing_image'.tr;
      
      // Get image bytes (may be cropped if user used the cropper)
      Uint8List? imageBytes = originalImageBytes.value;
      
      // COMMENTED OUT: Let ML Kit handle preprocessing internally
      // ML Kit does its own preprocessing, so we don't need to do it here
      // This prevents double preprocessing which can degrade image quality
      
      // Decode image for preprocessing
      // img.Image? finalImage;
      // if (imageBytes != null) {
      //   final decoded = img.decodeImage(imageBytes);
      //   if (decoded != null) {
      //     // Resize for processing (max 1500px)
      //     final maxDim = 1500;
      //     img.Image processed = decoded;
      //     if (processed.width > maxDim || processed.height > maxDim) {
      //       if (processed.width > processed.height) {
      //         processed = img.copyResize(processed, width: maxDim);
      //       } else {
      //         processed = img.copyResize(processed, height: maxDim);
      //       }
      //     }
      //     
      //     // Apply other preprocessing
      //     if (enableGrayscale.value) {
      //       processed = img.grayscale(processed);
      //     }
      //     if (enableContrastEnhancement.value) {
      //       processingMessage.value = 'contrast_enhancement'.tr;
      //       processed = await _enhanceContrast(processed);
      //     }
      //     if (enableNoiseReduction.value) {
      //       processed = img.gaussianBlur(processed, radius: 1);
      //     }
      //     if (enableSharpening.value) {
      //       // Skip sharpening for now (too slow)
      //     }
      //     if (enableBinarization.value) {
      //       processed = img.grayscale(processed);
      //     }
      //     
      //     finalImage = processed;
      //   }
      // }
      
      // Use original image bytes directly (ML Kit will handle preprocessing)
      Uint8List bytesToSave;
      if (imageBytes != null) {
        bytesToSave = imageBytes;
      } else {
        throw Exception('No image bytes available');
      }
      
      // OLD CODE: Save preprocessed image
      // if (finalImage != null) {
      //   // Save as JPEG for smaller file size and faster encoding
      //   final bytesToSave = Uint8List.fromList(img.encodeJpg(finalImage, quality: 90));

      isLoading.value = false;
      
      // Run OCR processing (optional - continue even if it fails)
      String? rawOcrText;
      dynamic extractedData;
      Map<String, dynamic>? ocrResult;

      try {
        // Initialize OCR controller if not already registered
        if (!Get.isRegistered<OCRController>()) {
          Get.put(OCRController());
        }
        final ocrController = Get.find<OCRController>();
        
        // Process image with OCR (silently fail if error occurs)
        if (kIsWeb) {
          try {
            print('🔍 OCR (web): Starting OCR processing with bytes (${bytesToSave.length} bytes)...');
            ocrResult =
                await ocrController.processInvoiceImage(imageBytes: bytesToSave);
            if (ocrResult != null) {
              rawOcrText = ocrResult['rawText'] as String?;
              extractedData = ocrResult['extractedData'];
              print('✅ OCR (web): Processing completed. Raw text length: ${rawOcrText?.length ?? 0}');
              print('✅ OCR (web): Structured fields: ${extractedData != null ? 'extracted' : 'none'}');
            } else {
              print('⚠️ OCR (web): OCR returned null result');
            }
          } catch (ocrError, stackTrace) {
            print('❌ OCR (web) processing failed (non-critical): $ocrError');
            print('❌ OCR (web) stack trace: $stackTrace');
            rawOcrText = null;
            extractedData = null;
          }
        } else {
          // Mobile: save temp file then call OCR with file
          try {
            final tempDir = await getTemporaryDirectory();
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final outputFile = File('${tempDir.path}/preprocessed_$timestamp.jpg');
            await outputFile.writeAsBytes(bytesToSave);
            
            // Check if file exists before processing
            if (await outputFile.exists()) {
              print('🔍 OCR: Starting OCR processing (mobile)...');
              ocrResult =
                  await ocrController.processInvoiceImage(imageFile: outputFile as dynamic);
              if (ocrResult != null) {
                rawOcrText = ocrResult['rawText'] as String?;
                extractedData = ocrResult['extractedData'];
                print('✅ OCR: Processing completed. Raw text length: ${rawOcrText?.length ?? 0}');
                print('✅ OCR: Structured fields: ${extractedData != null ? 'extracted' : 'none'}');
              }
            } else {
              print('❌ OCR: Temp file does not exist: ${outputFile.path}');
            }
          } catch (ocrError, stackTrace) {
            print('❌ OCR processing failed (non-critical): $ocrError');
            print('❌ OCR stack trace: $stackTrace');
            // Don't show error to user - OCR is optional
            // User can still enter data manually
            rawOcrText = null;
            extractedData = null;
          }
        }
      } catch (e, stackTrace) {
        print('❌❌❌ OCR INITIALIZATION ERROR ❌❌❌');
        print('❌ Error Type: ${e.runtimeType}');
        print('❌ Error Message: $e');
        print('❌ Stack Trace:');
        print(stackTrace);
        debugPrint('❌❌❌ OCR INITIALIZATION ERROR ❌❌❌');
        debugPrint('❌ Error Type: ${e.runtimeType}');
        debugPrint('❌ Error Message: $e');
        debugPrint('❌ Stack Trace: $stackTrace');
        // Continue even if OCR fails - user can enter manually
        rawOcrText = null;
        extractedData = null;
      }
        
      // Navigate with raw OCR text AND structured data
      print('🚀 Image Preprocessing: About to navigate. Raw OCR text length: ${rawOcrText?.length ?? 0}');
      print('🚀 Image Preprocessing: Extracted data: ${extractedData != null}');
      
      try {
        if (kIsWeb) {
          // On web, navigate directly to Invoice Details with bytes
          print('📤 Image Preprocessing: Web platform - navigating directly to Invoice Details');
          final result = {
            'imageBytes': bytesToSave,
            'type': fileType.value,
            'rawOcrText': rawOcrText,
            'extractedData': extractedData,
            'rawDocumentAI': ocrResult?['rawDocumentAI'],
          };
          print('📤 Image Preprocessing: Result map keys (web): ${result.keys}');
          Get.offNamed(AppRoutes.invoiceDetails, arguments: result);
          print('✅ Image Preprocessing: Navigated to Invoice Details with result (web)');
        } else {
          // On mobile, save to file and return File object
            print('📤 Image Preprocessing: Mobile platform - saving file');
          final tempDir = await getTemporaryDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final outputFile = File('${tempDir.path}/preprocessed_$timestamp.jpg');
            print('📁 Image Preprocessing: Writing ${bytesToSave.length} bytes to ${outputFile.path}');
          await outputFile.writeAsBytes(bytesToSave);
          
            if (await outputFile.exists()) {
              print('✅ Image Preprocessing: File saved successfully');
            } else {
              print('❌ Image Preprocessing: File was not created!');
            }
            
            print('📤 Image Preprocessing: Returning result with rawOcrText length: ${rawOcrText?.length ?? 0}');
            print('📤 Image Preprocessing: Extracted data: ${extractedData != null}');
            print('📤 Image Preprocessing: File path: ${outputFile.path}');
            print('📤 Image Preprocessing: File exists: ${await outputFile.exists()}');
            print('📤 Image Preprocessing: File type: ${fileType.value}');
            
            final result = {
            'file': outputFile,
            'type': fileType.value,
            'rawOcrText': rawOcrText,
            'extractedData': extractedData,
            'rawDocumentAI': ocrResult?['rawDocumentAI'],
            };
            
            print('📤 Image Preprocessing: Result map keys: ${result.keys}');
            print('📤 Image Preprocessing: Navigating directly to OCR preview...');
            
            // Navigate directly to Invoice Details instead of OCR preview
            // This ensures the result is always passed correctly
            Get.offNamed(AppRoutes.invoiceDetails, arguments: result);
            print('✅ Image Preprocessing: Navigated to Invoice Details with result');
          }
            } catch (navError, navStack) {
          print('❌❌❌ IMAGE PREPROCESSING NAVIGATION ERROR ❌❌❌');
          print('❌ Error Type: ${navError.runtimeType}');
          print('❌ Error Message: $navError');
          print('❌ Stack Trace:');
          print(navStack);
          debugPrint('❌❌❌ IMAGE PREPROCESSING NAVIGATION ERROR ❌❌❌');
          debugPrint('❌ Error Type: ${navError.runtimeType}');
          debugPrint('❌ Error Message: $navError');
          debugPrint('❌ Stack Trace: $navStack');
          isLoading.value = false;
          // Try to navigate anyway
          try {
            Get.back(result: {
              'file': null,
              'type': fileType.value,
              'rawOcrText': rawOcrText,
              'extractedData': extractedData,
            });
          } catch (e) {
            print('❌ Image Preprocessing: Failed to navigate even with error handling: $e');
          }
        }
      // REMOVED: else clause for finalImage check (no longer needed since we use original bytes)
    } catch (e, stackTrace) {
      print('❌❌❌ IMAGE PREPROCESSING ERROR ❌❌❌');
      print('❌ Error Type: ${e.runtimeType}');
      print('❌ Error Message: $e');
      print('❌ Stack Trace:');
      print(stackTrace);
      debugPrint('❌❌❌ IMAGE PREPROCESSING ERROR ❌❌❌');
      debugPrint('❌ Error Type: ${e.runtimeType}');
      debugPrint('❌ Error Message: $e');
      debugPrint('❌ Stack Trace: $stackTrace');
      isLoading.value = false;
      SnackbarService.to.showError(
        'error'.tr,
        'error_saving_image'.tr,
      );
    } finally {
      isContinuing.value = false;
      isLoading.value = false;
    }
  }

}


