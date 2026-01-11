// Conditional import for File
import 'dart:io' show File if (dart.library.html) 'package:fineye/presentation/controllers/file_stub.dart' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import '../models/invoice_file_result.dart';

/// Service for capturing and selecting invoice files (images and PDFs)
/// Handles camera capture and file picking with proper permission management
class InvoiceInputService {
  final ImagePicker _imagePicker = ImagePicker();

  /// Capture an invoice photo using the device camera
  /// Returns [InvoiceFileResult] if successful, null if cancelled or error
  Future<InvoiceFileResult?> pickFromCamera() async {
    try {
      if (kIsWeb) {
        // On web, ImagePicker supports camera
        final XFile? photo = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 3000,
          maxHeight: 3000,
        );

        if (photo == null) {
          return null;
        }

        // On web, read bytes from XFile
        final bytes = await photo.readAsBytes();
        return InvoiceFileResult(
          imageBytes: bytes,
          type: InvoiceFileType.image,
        );
      } else {
        // Request camera permission for mobile
        final permissionStatus = await _requestCameraPermission();
        if (!permissionStatus) {
          return null;
        }

        // Pick image from camera
        final XFile? photo = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          preferredCameraDevice: CameraDevice.rear,
          maxWidth: 3000,
          maxHeight: 3000,
        );

        if (photo == null) {
          return null;
        }

        final file = File(photo.path);
        return InvoiceFileResult(
          file: file,
          type: InvoiceFileType.image,
        );
      }
    } catch (e) {
      // Handle any errors (permission denied, camera unavailable, etc.)
      return null;
    }
  }

  /// Select an invoice file from device storage (images or PDFs)
  /// Returns [InvoiceFileResult] if successful, null if cancelled or error
  Future<InvoiceFileResult?> pickFromFiles() async {
    try {
      if (kIsWeb) {
        // On web, use FilePicker with withData: true to get bytes
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
          withData: true, // On web, we need the data as bytes
        );

        if (result == null || result.files.single.bytes == null) {
          return null;
        }

        final bytes = result.files.single.bytes!;
        final extension = result.files.single.extension?.toLowerCase() ?? '';
        final fileType = _determineFileType(extension);

        return InvoiceFileResult(
          imageBytes: bytes,
          type: fileType,
        );
      } else {
        // Request storage permission for mobile
        final permissionStatus = await _requestStoragePermission();
        if (!permissionStatus) {
          return null;
        }

        // Pick file (images or PDFs)
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
          withData: false, // We only need the file path, not the data
        );

        if (result == null || result.files.single.path == null) {
          return null;
        }

        final filePath = result.files.single.path!;
        final file = File(filePath);
        final extension = result.files.single.extension?.toLowerCase() ?? '';
        final fileType = _determineFileType(extension);

        return InvoiceFileResult(
          file: file,
          type: fileType,
        );
      }
    } catch (e) {
      // Handle any errors
      return null;
    }
  }

  /// Request camera permission
  /// Returns true if granted, false otherwise
  Future<bool> _requestCameraPermission() async {
    // Check current status
    var status = await ph.Permission.camera.status;
    
    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      // Request permission
      status = await ph.Permission.camera.request();
      return status.isGranted;
    }

    if (status.isPermanentlyDenied) {
      // Permission permanently denied - user needs to enable in settings
      // Return false, caller should show appropriate message
      return false;
    }

    return false;
  }

  /// Request storage permission (photos/media)
  /// Returns true if granted, false otherwise
  Future<bool> _requestStoragePermission() async {
    // For Android 13+ (API 33+), we need photos permission
    // For older Android, we need storage permission
    // For iOS, we need photos permission
    
    // Check photos permission first (works for both platforms)
    var photosStatus = await ph.Permission.photos.status;
    
    if (photosStatus.isGranted) {
      return true;
    }

    if (photosStatus.isDenied) {
      photosStatus = await ph.Permission.photos.request();
      if (photosStatus.isGranted) {
        return true;
      }
    }

    // For Android < 13, try storage permission
    var storageStatus = await ph.Permission.storage.status;
    if (storageStatus.isGranted) {
      return true;
    }

    if (storageStatus.isDenied) {
      storageStatus = await ph.Permission.storage.request();
      return storageStatus.isGranted;
    }

    // If permanently denied, return false
    return false;
  }

  /// Determine file type from extension
  InvoiceFileType _determineFileType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return InvoiceFileType.pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      default:
        return InvoiceFileType.image;
    }
  }

  /// Check if camera permission is granted
  Future<bool> isCameraPermissionGranted() async {
    final status = await ph.Permission.camera.status;
    return status.isGranted;
  }

  /// Check if storage permission is granted
  Future<bool> isStoragePermissionGranted() async {
    final photosStatus = await ph.Permission.photos.status;
    if (photosStatus.isGranted) return true;
    
    final storageStatus = await ph.Permission.storage.status;
    return storageStatus.isGranted;
  }

  /// Open app settings (useful when permission is permanently denied)
  Future<bool> openAppSettings() async {
    return await ph.openAppSettings();
  }
}

