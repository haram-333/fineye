import 'dart:io' if (dart.library.html) 'package:fineye/presentation/controllers/file_stub.dart' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

/// Service for OCR text recognition using Google ML Kit
/// Supports Arabic and English text recognition
class OCRService {
  late TextRecognizer _textRecognizer;
  bool _initialized = false;

  /// Initialize the text recognizer with Arabic + English support
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Don't specify script - use default which supports multiple languages including Arabic
      // TextRecognitionScript.latin might not support Arabic properly
      _textRecognizer = TextRecognizer();
      _initialized = true;
      print('✅ OCR: TextRecognizer initialized successfully');
    } catch (e, stackTrace) {
      print('❌ OCR: Failed to initialize: $e');
      print('❌ OCR: Stack trace: $stackTrace');
      throw Exception('Failed to initialize OCR: $e');
    }
  }

  /// Recognize text from image file
  /// Returns recognized text blocks with confidence scores
  Future<OCRResult> recognizeTextFromFile(File imageFile) async {
    if (kIsWeb) {
      throw UnsupportedError('OCR not supported on web');
    }

    if (!_initialized) {
      await initialize();
    }

    try {
      print('📸 OCR: Creating InputImage from file: ${imageFile.path}');
      final inputImage = InputImage.fromFilePath(imageFile.path);
      print('🔄 OCR: Processing image with TextRecognizer...');
      final recognizedText = await _textRecognizer.processImage(inputImage);
      print('✅ OCR: Processing complete. Blocks found: ${recognizedText.blocks.length}');
      print('📝 OCR: Full text preview: ${recognizedText.text.substring(0, recognizedText.text.length > 200 ? 200 : recognizedText.text.length)}...');

      return _parseOCRResult(recognizedText);
    } catch (e, stackTrace) {
      print('❌ OCR: Processing failed: $e');
      print('❌ OCR: Stack trace: $stackTrace');
      throw Exception('OCR processing failed: $e');
    }
  }

  /// Recognize text from image bytes
  Future<OCRResult> recognizeTextFromBytes(Uint8List imageBytes) async {
    if (kIsWeb) {
      throw UnsupportedError('OCR not supported on web');
    }

    if (!_initialized) {
      await initialize();
    }

    try {
      // Save to temp file and use file path (more reliable than fromBytes)
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/ocr_temp_$timestamp.jpg');
      print('💾 OCR: Saving ${imageBytes.length} bytes to temp file: ${tempFile.path}');
      await tempFile.writeAsBytes(imageBytes);
      
      print('📸 OCR: Creating InputImage from temp file...');
      final inputImage = InputImage.fromFilePath(tempFile.path);
      print('🔄 OCR: Processing image with TextRecognizer...');
      final recognizedText = await _textRecognizer.processImage(inputImage);
      print('✅ OCR: Processing complete. Blocks found: ${recognizedText.blocks.length}');
      print('📝 OCR: Full text preview: ${recognizedText.text.substring(0, recognizedText.text.length > 200 ? 200 : recognizedText.text.length)}...');
      
      // Clean up temp file
      try {
        if (!kIsWeb) {
          await tempFile.delete();
          print('🗑️ OCR: Temp file deleted');
        }
      } catch (e) {
        print('⚠️ OCR: Failed to delete temp file: $e');
        // Ignore cleanup errors
      }
      
      return _parseOCRResult(recognizedText);
    } catch (e, stackTrace) {
      print('❌ OCR: Processing failed: $e');
      print('❌ OCR: Stack trace: $stackTrace');
      throw Exception('OCR processing failed: $e');
    }
  }

  /// Parse OCR result into structured format
  OCRResult _parseOCRResult(RecognizedText recognizedText) {
    final List<OCRTextBlock> blocks = [];
    final List<OCRTextLine> lines = [];
    String fullText = '';

    // Extract all blocks and lines with coordinates
    for (final block in recognizedText.blocks) {
      final blockData = OCRTextBlock(
        text: block.text,
        boundingBox: block.boundingBox,
        confidence: _calculateBlockConfidence(block),
      );

      blocks.add(blockData);

      // Extract lines within block
      for (final line in block.lines) {
        final lineData = OCRTextLine(
          text: line.text,
          boundingBox: line.boundingBox,
          confidence: _calculateLineConfidence(line),
        );
        lines.add(lineData);
        fullText += '${line.text}\n';
      }
    }

    // Sort blocks and lines by position (top to bottom, left to right)
    blocks.sort((a, b) {
      final aTop = a.boundingBox.top;
      final bTop = b.boundingBox.top;
      if ((aTop - bTop).abs() < 20) {
        // Same row, sort by left position
        return a.boundingBox.left.compareTo(b.boundingBox.left);
      }
      return aTop.compareTo(bTop);
    });

    lines.sort((a, b) {
      final aTop = a.boundingBox.top;
      final bTop = b.boundingBox.top;
      if ((aTop - bTop).abs() < 20) {
        // Same row, sort by left position
        return a.boundingBox.left.compareTo(b.boundingBox.left);
      }
      return aTop.compareTo(bTop);
    });

    // Calculate overall confidence
    final overallConfidence = blocks.isEmpty
        ? 0.0
        : blocks.map((b) => b.confidence).reduce((a, b) => a + b) / blocks.length;

    return OCRResult(
      fullText: fullText.trim(),
      blocks: blocks,
      lines: lines,
      confidence: overallConfidence,
    );
  }

  /// Calculate confidence score for a text block
  double _calculateBlockConfidence(TextBlock block) {
    if (block.lines.isEmpty) return 0.0;

    // Average confidence of all lines in block
    double totalConfidence = 0.0;
    int lineCount = 0;

    for (final line in block.lines) {
      for (final element in line.elements) {
        // ML Kit doesn't provide explicit confidence, so we estimate
        // based on text quality (length, character types)
        totalConfidence += _estimateConfidence(element.text);
        lineCount++;
      }
    }

    return lineCount > 0 ? totalConfidence / lineCount : 0.5;
  }

  /// Calculate confidence score for a text line
  double _calculateLineConfidence(TextLine line) {
    if (line.elements.isEmpty) return 0.0;

    double totalConfidence = 0.0;
    for (final element in line.elements) {
      totalConfidence += _estimateConfidence(element.text);
    }

    return totalConfidence / line.elements.length;
  }

  /// Estimate confidence based on text characteristics
  double _estimateConfidence(String text) {
    if (text.isEmpty) return 0.0;

    double confidence = 0.7; // Base confidence

    // Increase confidence for longer text (usually more reliable)
    if (text.length > 5) confidence += 0.1;
    if (text.length > 10) confidence += 0.1;

    // Decrease confidence for text with many special characters
    final specialCharCount = text.split('').where((c) => !RegExp(r'[a-zA-Z0-9\u0600-\u06FF\s]').hasMatch(c)).length;
    if (specialCharCount > text.length * 0.3) confidence -= 0.2;

    // Increase confidence for numbers (usually well recognized)
    if (RegExp(r'^\d+([.,]\d+)?$').hasMatch(text.trim())) confidence += 0.1;

    return confidence.clamp(0.0, 1.0);
  }

  /// Dispose resources
  void dispose() {
    if (_initialized) {
      _textRecognizer.close();
      _initialized = false;
    }
  }
}

/// Result of OCR processing
class OCRResult {
  final String fullText;
  final List<OCRTextBlock> blocks;
  final List<OCRTextLine> lines;
  final double confidence;

  OCRResult({
    required this.fullText,
    required this.blocks,
    required this.lines,
    required this.confidence,
  });

  bool get hasText => fullText.isNotEmpty;
  bool get isHighConfidence => confidence >= 0.7;
  bool get isMediumConfidence => confidence >= 0.5 && confidence < 0.7;
  bool get isLowConfidence => confidence < 0.5;
}

/// Text block with position and confidence
class OCRTextBlock {
  final String text;
  final Rect boundingBox;
  final double confidence;

  OCRTextBlock({
    required this.text,
    required this.boundingBox,
    required this.confidence,
  });
}

/// Text line with position and confidence
class OCRTextLine {
  final String text;
  final Rect boundingBox;
  final double confidence;

  OCRTextLine({
    required this.text,
    required this.boundingBox,
    required this.confidence,
  });
}

