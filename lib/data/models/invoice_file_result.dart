// Conditional import for File
import 'dart:io' show File if (dart.library.html) 'package:fineye/presentation/controllers/file_stub.dart' show File;
import 'dart:typed_data';

/// File type enum for invoice files
enum InvoiceFileType {
  image,
  pdf,
}

/// Result model returned by InvoiceInputService
class InvoiceFileResult {
  final File? file; // For mobile platforms
  final Uint8List? imageBytes; // For web platform
  final InvoiceFileType type;

  const InvoiceFileResult({
    this.file,
    this.imageBytes,
    required this.type,
  }) : assert(
          (file != null && imageBytes == null) || (file == null && imageBytes != null),
          'Either file or imageBytes must be provided, but not both',
        );

  /// Check if the file is an image
  bool get isImage => type == InvoiceFileType.image;

  /// Check if the file is a PDF
  bool get isPdf => type == InvoiceFileType.pdf;
}

