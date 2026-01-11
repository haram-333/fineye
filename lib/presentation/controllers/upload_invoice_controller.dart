import 'package:get/get.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Conditional import for File
import 'dart:io' show File if (dart.library.html) 'package:fineye/presentation/controllers/file_stub.dart' show File;
import '../../data/services/invoice_input_service.dart';
import '../../data/models/invoice_file_result.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/snackbar_service.dart';

class UploadInvoiceController extends GetxController {
  // Reactive state variables
  final isProcessing = false.obs;
  final uploadProgress = 0.0.obs;
  final processingMessage = ''.obs;
  final selectedFile = Rx<File?>(null);
  final selectedFileType = Rx<InvoiceFileType?>(null);

  final InvoiceInputService _invoiceInputService = InvoiceInputService();

  /// Capture invoice using camera
  Future<void> scanWithCamera() async {
    try {
      final result = await _invoiceInputService.pickFromCamera();

      if (result == null) {
        // User cancelled or permission denied
        return;
      }

      selectedFile.value = result.file;
      selectedFileType.value = result.type;
      
      // Navigate to preview screen - it will navigate directly to OCR preview
      // On web, pass imageBytes; on mobile, pass file
      if (kIsWeb && result.imageBytes != null) {
        print('📤 Upload Controller: Navigating to preprocessing with ${result.imageBytes!.length} bytes');
        await Get.toNamed(
          AppRoutes.imagePreprocessing,
          arguments: {
            'imageBytes': result.imageBytes,
            'type': result.type,
          },
        );
        print('✅ Upload Controller: Navigation to preprocessing completed (web)');
      } else if (!kIsWeb && result.file != null) {
        print('📤 Upload Controller: Navigating to preprocessing with file: ${result.file!.path}');
        await Get.toNamed(
          AppRoutes.imagePreprocessing,
          arguments: {
            'file': result.file,
            'type': result.type,
          },
        );
        print('✅ Upload Controller: Navigation to preprocessing completed (mobile)');
      } else {
        print('❌ Upload Controller: Missing required data - imageBytes: ${result.imageBytes != null}, file: ${result.file != null}');
        SnackbarService.to.showError(
          'Error',
          'Failed to load image. Please try again.',
        );
        return;
      }
    } catch (e) {
      SnackbarService.to.showError(
        'Camera Error',
        'Failed to capture invoice: ${e.toString()}',
      );
    }
  }

  /// Select invoice file from device storage (images or PDFs)
  Future<void> uploadFile() async {
    try {
      final result = await _invoiceInputService.pickFromFiles();

      if (result == null) {
        // User cancelled or permission denied
        return;
      }

      selectedFile.value = result.file;
      selectedFileType.value = result.type;
      
      // Navigate to preview screen - it will navigate directly to OCR preview
      // On web, pass imageBytes; on mobile, pass file
      if (kIsWeb && result.imageBytes != null) {
        print('📤 Upload Controller: Navigating to preprocessing with ${result.imageBytes!.length} bytes');
        await Get.toNamed(
          AppRoutes.imagePreprocessing,
          arguments: {
            'imageBytes': result.imageBytes,
            'type': result.type,
          },
        );
        print('✅ Upload Controller: Navigation to preprocessing completed (web)');
      } else if (!kIsWeb && result.file != null) {
        print('📤 Upload Controller: Navigating to preprocessing with file: ${result.file!.path}');
        await Get.toNamed(
          AppRoutes.imagePreprocessing,
          arguments: {
            'file': result.file,
            'type': result.type,
          },
        );
        print('✅ Upload Controller: Navigation to preprocessing completed (mobile)');
      } else {
        print('❌ Upload Controller: Missing required data - imageBytes: ${result.imageBytes != null}, file: ${result.file != null}');
        SnackbarService.to.showError(
          'Error',
          'Failed to load image. Please try again.',
        );
        return;
      }
    } catch (e) {
      SnackbarService.to.showError(
        'File Selection Error',
        'Failed to select file: ${e.toString()}',
      );
    }
  }

  // Simulate OCR processing with progress updates
  // Note: This method is kept for future use when OCR processing is implemented
  // ignore: unused_element
  Future<void> _simulateProcessing(String initialMessage) async {
    isProcessing.value = true;
    processingMessage.value = initialMessage;
    uploadProgress.value = 0.0;

    // Simulate upload progress
    for (int i = 0; i <= 100; i += 10) {
      await Future.delayed(const Duration(milliseconds: 200));
      uploadProgress.value = i / 100;
      
      if (i == 30) {
        processingMessage.value = 'Extracting invoice details...';
      } else if (i == 60) {
        processingMessage.value = 'Reading totals, VAT, and supplier info';
      } else if (i == 90) {
        processingMessage.value = 'Final checks';
      }
    }

    // Complete
    await Future.delayed(const Duration(milliseconds: 300));
    resetState();
    
    // In real implementation, navigate to OCR preview
    // Get.to(() => OCRPreview(), arguments: extractedData);
  }

  // Reset state (for pull-to-refresh)
  void resetState() {
    isProcessing.value = false;
    uploadProgress.value = 0.0;
    processingMessage.value = '';
    selectedFile.value = null;
  }
}
