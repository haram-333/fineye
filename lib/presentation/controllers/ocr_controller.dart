import 'dart:io' if (dart.library.html) 'package:fineye/presentation/controllers/file_stub.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../data/services/ocr_service.dart';
import '../../data/services/document_ai_service.dart';
import '../../data/services/invoice_data_extractor.dart';
import '../../core/services/snackbar_service.dart';

/// Controller for OCR processing using Document AI
/// Extracts both raw text AND structured fields (date, supplier, amounts, VAT)
class OCRController extends GetxController {
  late OCRService _ocrService;
  final InvoiceDataExtractor _dataExtractor = InvoiceDataExtractor();

  // Processing state
  final isProcessing = false.obs;
  final processingMessage = ''.obs;
  final processingProgress = 0.0.obs;

  // Raw OCR text
  final rawText = RxString('');
  
  // Extracted structured data
  final extractedData = Rx<ExtractedInvoiceData?>(null);

  @override
  void onInit() {
    super.onInit();
    _ocrService = OCRService();
  }

  /// Process image and extract both raw text AND structured fields
  /// Returns map with 'rawText' and 'extractedData'
  Future<Map<String, dynamic>?> processInvoiceImage({
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    if (imageFile == null && imageBytes == null) {
      debugPrint('OCR: No image file or bytes provided');
      return null;
    }

    try {
      isProcessing.value = true;
      processingMessage.value = 'analyzing_invoice'.tr;
      processingProgress.value = 0.2;

      // Initialize OCR service if needed
      processingMessage.value = 'initializing_ocr'.tr;
      processingProgress.value = 0.3;
      await _ocrService.initialize();

      // Process image with ML Kit
      processingMessage.value = 'extracting_text'.tr;
      processingProgress.value = 0.5;

      print('🔍 OCR: Starting text recognition...');
      
      String extractedText = '';
      ExtractedInvoiceData? structuredData;
      
      // ALWAYS use Document AI ONLY - it supports Arabic, ML Kit does NOT
      // ML Kit fallback removed - it doesn't support Arabic and would break Arabic invoices
      print('🌐 OCR: Using Document AI ONLY (supports Arabic + English)...');
      print('🌐 OCR: ML Kit fallback DISABLED (does not support Arabic)');
      
      final docAIResult = await _tryDocumentAI(imageFile: imageFile, imageBytes: imageBytes);
      
      if (docAIResult != null && docAIResult['rawText'] != null) {
        extractedText = docAIResult['rawText'] as String;
        structuredData = docAIResult['extractedData'] as ExtractedInvoiceData?;
        
        if (extractedText.isNotEmpty) {
          final containsArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(extractedText);
          print('✅ OCR: Document AI result (${extractedText.length} chars)');
          print('📊 OCR: Contains Arabic: $containsArabic');
          print('📊 OCR: Extracted ${structuredData?.extractedFieldCount ?? 0} structured fields');
          
          if (containsArabic) {
            print('✅ OCR: Arabic text detected! Document AI is working correctly.');
          } else {
            print('ℹ️ OCR: No Arabic text detected (invoice might be English-only)');
          }
        } else {
          print('❌ Document AI returned empty text!');
          print('❌ Check backend logs and Document AI configuration');
          extractedText = '';
        }
      } else {
        print('❌ Document AI failed completely!');
        print('❌ Check:');
        print('   1. Backend API is running: https://fineye-one.vercel.app/api/ocr/document-ai');
        print('   2. DOCUMENT_AI_SERVICE_ACCOUNT is set in Vercel');
        print('   3. DOCUMENT_AI_PROJECT_ID, LOCATION, PROCESSOR_ID are set');
        print('   4. Service account has Document AI permissions');
        extractedText = '';
      }

      processingProgress.value = 0.9;

      if (extractedText.isEmpty) {
        print('⚠️ OCR: No text found in image');
        isProcessing.value = false;
        rawText.value = '';
        extractedData.value = null;
        return null;
      }

      // Check for Arabic characters (expanded range)
      final arabicPattern = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
      final containsArabic = arabicPattern.hasMatch(extractedText);
      
      print('✅ OCR: Successfully processed invoice');
      print('📊 OCR: Final text length: ${extractedText.length}');
      print('📊 OCR: Contains Arabic: $containsArabic');
      print('📊 OCR: Structured fields extracted: ${structuredData?.extractedFieldCount ?? 0}');
      
      if (containsArabic) {
        final arabicChars = extractedText.split('').where((c) => arabicPattern.hasMatch(c)).length;
        print('✅ OCR: Found $arabicChars Arabic characters!');
        print('📝 OCR: Arabic text preview: ${extractedText.substring(0, extractedText.length > 100 ? 100 : extractedText.length)}');
      } else {
        print('ℹ️ OCR: No Arabic characters detected. Invoice might be English-only.');
        print('📝 OCR: Text preview: ${extractedText.length > 200 ? extractedText.substring(0, 200) + "..." : extractedText}');
      }

      rawText.value = extractedText;
      extractedData.value = structuredData;
      processingProgress.value = 1.0;
      isProcessing.value = false;

      // Show success message
      final fieldCount = structuredData?.extractedFieldCount ?? 0;
      if (fieldCount > 0) {
        SnackbarService.to.showSuccess(
          'ocr_success_title'.tr,
          'ocr_success_message'.trParams({'count': fieldCount.toString()}),
        );
      } else {
        SnackbarService.to.showSuccess(
          'ocr_success_title'.tr,
          'ocr_text_extracted'.trParams({'length': extractedText.length.toString()}),
        );
      }

      return {
        'rawText': extractedText,
        'extractedData': structuredData,
      };
    } catch (e, stackTrace) {
      isProcessing.value = false;
      print('❌❌❌ OCR PROCESSING ERROR ❌❌❌');
      print('❌ Error Type: ${e.runtimeType}');
      print('❌ Error Message: $e');
      print('❌ Stack Trace:');
      print(stackTrace);
      print('❌ Image File: ${imageFile?.path ?? "null"}');
      print('❌ Image Bytes: ${imageBytes?.length ?? 0} bytes');
      debugPrint('❌❌❌ OCR PROCESSING ERROR ❌❌❌');
      debugPrint('❌ Error Type: ${e.runtimeType}');
      debugPrint('❌ Error Message: $e');
      debugPrint('❌ Stack Trace: $stackTrace');
      rawText.value = '';
      // Don't show error to user - OCR is optional
      return null;
    }
  }

  /// Use Document AI for Arabic support
  /// Returns map with 'rawText' and 'extractedData'
  Future<Map<String, dynamic>?> _tryDocumentAI({
    File? imageFile,
    Uint8List? imageBytes,
  }) async {
    try {
      processingMessage.value = 'extracting_text_with_document_ai'.tr;
      processingProgress.value = 0.7;
      
      print('🌐 Document AI: Attempting to extract text (supports Arabic)...');
      print('🌐 Document AI: Image file: ${imageFile?.path ?? "null"}');
      print('🌐 Document AI: Image bytes length: ${imageBytes?.length ?? 0}');
      
      final result = await DocumentAIService.processInvoice(
        imageFile: imageFile,
        imageBytes: imageBytes,
      );

      print('📥 Document AI: Response received');
      print('📥 Document AI: Success: ${result['success']}');
      print('📥 Document AI: Error: ${result['error'] ?? "none"}');
      print('📥 Document AI: Full response keys: ${result.keys}');

      if (result['success'] == true) {
        final docAIData = result['data'];
        final fullText = docAIData['fullText'] as String? ?? '';
        final entities = docAIData['entities'] as List? ?? [];
        final detectedLanguages = docAIData['detectedLanguages'] as List? ?? [];
        
        print('📊 Document AI: Full text length: ${fullText.length}');
        print('📊 Document AI: Entities count: ${entities.length}');
        
        // Log detected languages from Document AI
        if (detectedLanguages.isNotEmpty) {
          print('🌐 Document AI: Detected languages:');
          for (final lang in detectedLanguages) {
            final code = lang['languageCode'] ?? 'unknown';
            final confidence = (lang['confidence'] ?? 0.0) * 100;
            print('   - $code (${confidence.toStringAsFixed(1)}% confidence)');
          }
        } else {
          print('🌐 Document AI: No languages detected by Document AI');
        }
        
        if (fullText.isNotEmpty) {
          // Check for Arabic characters (includes Arabic, Persian, Urdu, etc.)
          final arabicPattern = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
          final containsArabic = arabicPattern.hasMatch(fullText);
          
          // Check if Document AI detected Arabic
          final hasArabicLanguage = detectedLanguages.any((lang) {
            final code = lang['languageCode'] ?? '';
            return code.toLowerCase().startsWith('ar'); // ar, ar-AE, ar-SA, etc.
          });
          
          // Show preview of extracted text
          final textPreview = fullText.length > 200 
              ? fullText.substring(0, 200) + '...' 
              : fullText;
          
          print('✅ Document AI: Extracted ${fullText.length} characters (supports Arabic)');
          print('📊 Document AI: Contains Arabic (regex): $containsArabic');
          print('📊 Document AI: Detected Arabic language: $hasArabicLanguage');
          print('📝 Document AI: Text preview: $textPreview');
          
          if (containsArabic || hasArabicLanguage) {
            // Count Arabic characters
            final arabicChars = fullText.split('').where((c) => arabicPattern.hasMatch(c)).length;
            print('✅ Document AI: Found $arabicChars Arabic characters in text!');
            if (hasArabicLanguage) {
              print('✅ Document AI: Document AI confirmed Arabic language detection!');
            }
          }
          
          // Parse structured data from Document AI entities
          processingMessage.value = 'parsing_invoice_data'.tr;
          processingProgress.value = 0.8;
          
          ExtractedInvoiceData structuredData;
          if (entities.isNotEmpty) {
            // Use Document AI entities if available
            print('📊 Document AI: Parsing ${entities.length} entities');
            structuredData = _parseDocumentAIEntities(fullText, entities);
          } else {
            // Fallback: Parse from raw text using regex patterns
            print('⚠️ Document AI: No entities found, parsing from raw text');
            structuredData = await _parseRawTextToStructuredData(fullText);
          }
          
          return {
            'rawText': fullText.trim(),
            'extractedData': structuredData,
          };
        } else {
          print('⚠️ Document AI: Success but empty text extracted');
          print('⚠️ This might mean:');
          print('   1. Image has no text');
          print('   2. Document AI processor is not configured correctly');
          print('   3. Image quality is too poor');
        }
      } else {
        final errorMsg = result['error'] ?? 'Unknown error';
        print('❌ Document AI: Backend returned success=false');
        print('❌ Error message: $errorMsg');
        print('❌ Full result: $result');
      }
      
      print('❌ Document AI: Returning null - OCR failed');
      return null;
    } catch (e, stackTrace) {
      print('❌❌❌ DOCUMENT AI ERROR IN _tryDocumentAI ❌❌❌');
      print('❌ Error Type: ${e.runtimeType}');
      print('❌ Error Message: $e');
      print('❌ Stack Trace:');
      print(stackTrace);
      print('❌ Image File: ${imageFile?.path ?? "null"}');
      print('❌ Image Bytes: ${imageBytes?.length ?? 0} bytes');
      debugPrint('❌❌❌ DOCUMENT AI ERROR IN _tryDocumentAI ❌❌❌');
      debugPrint('❌ Error Type: ${e.runtimeType}');
      debugPrint('❌ Error Message: $e');
      debugPrint('❌ Stack Trace: $stackTrace');
      return null;
    }
  }
  
  /// Parse Document AI entities into ExtractedInvoiceData
  ExtractedInvoiceData _parseDocumentAIEntities(String fullText, List<dynamic> entities) {
    // Helper to find entity by type
    dynamic findEntity(String type) {
      try {
        return entities.firstWhere(
          (e) => e['type'] == type,
          orElse: () => null,
        );
      } catch (e) {
        return null;
      }
    }
    
    // Extract supplier name
    final supplierEntity = findEntity('supplier_name') ?? findEntity('supplier');
    final supplierName = supplierEntity != null 
        ? ExtractedField<String>(
            value: supplierEntity['value'] ?? supplierEntity['mentionText'],
            confidence: (supplierEntity['confidence'] as num?)?.toDouble() ?? 0.8,
            rawText: supplierEntity['value'] ?? supplierEntity['mentionText'],
          )
        : ExtractedField<String>.empty();
    
    // Extract invoice number
    final invoiceNumberEntity = findEntity('invoice_id') ?? findEntity('invoice_number');
    final invoiceNumber = invoiceNumberEntity != null
        ? ExtractedField<String>(
            value: invoiceNumberEntity['value'] ?? invoiceNumberEntity['mentionText'],
            confidence: (invoiceNumberEntity['confidence'] as num?)?.toDouble() ?? 0.8,
            rawText: invoiceNumberEntity['value'] ?? invoiceNumberEntity['mentionText'],
          )
        : ExtractedField<String>.empty();
    
    // Extract invoice date
    ExtractedField<DateTime> invoiceDate;
    final dateEntity = findEntity('invoice_date');
    if (dateEntity != null) {
      final dateStrRaw = dateEntity['value'] ?? dateEntity['mentionText'];
      final dateStr = (dateStrRaw as String?)?.trim() ?? '';
      print('📅 OCR: Extracted date string: "$dateStr"');
      DateTime? parsedDate;

      // 1) Try Dart's built-in parser first (handles ISO-like formats)
      parsedDate = DateTime.tryParse(dateStr);
      if (parsedDate != null) {
        print('✅ OCR: Parsed date using DateTime.tryParse: ${parsedDate.toString()}');
      }

      // 2) Try a set of common invoice date formats if built-in fails.
      if (parsedDate == null && dateStr.isNotEmpty) {
        final candidates = <String>[
          // Full year formats first
          'dd/MM/yyyy',
          'MM/dd/yyyy',
          'dd-MM-yyyy',
          'MM-dd-yyyy',
          'dd.MM.yyyy',
          'MM.dd.yyyy',
          'yyyy-MM-dd',
          'yyyy/MM/dd',
          'yyyy.MM.dd',
          // Text month formats with full year
          'dd MMM yyyy',
          'd MMM yyyy',
          'MMM dd yyyy',
          'MMM d yyyy',
          'MMM dd, yyyy',
          'MMM d, yyyy',
          'dd-MMM-yyyy',
          'd-MMM-yyyy',
          // Two-digit year formats (handle carefully)
          'MMM-dd-yy',   // Dec-25-13 -> Dec 25, 2013
          'MMM-d-yy',    // Dec-5-13 -> Dec 5, 2013
          'MMM dd yy',   // Dec 25 13 -> Dec 25, 2013
          'MMM d yy',    // Dec 5 13 -> Dec 5, 2013
          'MMM dd, yy',  // Dec 25, 13 -> Dec 25, 2013
          'MMM d, yy',   // Dec 5, 13 -> Dec 5, 2013
          'dd-MMM-yy',   // 25-Dec-13 -> Dec 25, 2013
          'd-MMM-yy',    // 5-Dec-13 -> Dec 5, 2013
        ];

        for (final pattern in candidates) {
          try {
            final formatter = DateFormat(pattern);
            final tempDate = formatter.parseStrict(dateStr);
            
            // For 2-digit years, adjust to reasonable century
            if (pattern.contains('yy') && !pattern.contains('yyyy')) {
              final year = tempDate.year;
              // If year is 0-50, assume 2000-2050
              // If year is 51-99, assume 1951-1999
              if (year < 50) {
                parsedDate = DateTime(2000 + year, tempDate.month, tempDate.day);
              } else if (year < 100) {
                parsedDate = DateTime(1900 + year, tempDate.month, tempDate.day);
              } else {
                parsedDate = tempDate;
              }
            } else {
              parsedDate = tempDate;
            }
            
            print('✅ Parsed date "$dateStr" as ${parsedDate.toString()} using pattern "$pattern"');
            break;
          } catch (e) {
            // Ignore and try next pattern
            print('⚠️ Failed to parse "$dateStr" with pattern "$pattern": $e');
          }
        }
      }

      if (parsedDate != null) {
        invoiceDate = ExtractedField<DateTime>(
          value: parsedDate,
          confidence: (dateEntity['confidence'] as num?)?.toDouble() ?? 0.8,
          rawText: dateStr,
        );
      } else {
        // If we completely fail to parse, leave the date empty so UI defaults apply.
        invoiceDate = ExtractedField<DateTime>.empty();
      }
    } else {
      invoiceDate = ExtractedField<DateTime>.empty();
    }
    
    // Extract amounts
    double? parseAmount(dynamic entity) {
      if (entity == null) return null;
      final valueStr = entity['value'] ?? entity['mentionText'] ?? '';
      if (valueStr.isEmpty) return null;
      try {
        // Remove currency symbols and whitespace
        final cleaned = valueStr.toString().replaceAll(RegExp(r'[^\d.,-]'), '').replaceAll(',', '');
        return double.parse(cleaned);
      } catch (e) {
        return null;
      }
    }
    
    final grossEntity = findEntity('total_amount') ?? findEntity('total');
    final grossAmount = parseAmount(grossEntity);
    
    final netEntity = findEntity('net_amount') ?? findEntity('net');
    final netAmount = parseAmount(netEntity);
    
    final vatEntity = findEntity('tax_amount') ?? findEntity('vat_amount');
    final vatAmount = parseAmount(vatEntity);
    
    // Calculate overall confidence
    final confidences = <double>[
      supplierName.confidence,
      invoiceNumber.confidence,
      invoiceDate.confidence,
    ];
    if (grossAmount != null) confidences.add(0.8);
    if (netAmount != null) confidences.add(0.8);
    if (vatAmount != null) confidences.add(0.8);
    
    final overallConfidence = confidences.isEmpty 
        ? 0.0 
        : confidences.reduce((a, b) => a + b) / confidences.length;
    
    return ExtractedInvoiceData(
      supplierName: supplierName,
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      netAmount: netAmount,
      vatAmount: vatAmount,
      grossAmount: grossAmount,
      overallConfidence: overallConfidence,
    );
  }
  
  /// Parse raw text to structured data using regex patterns (fallback)
  Future<ExtractedInvoiceData> _parseRawTextToStructuredData(String fullText) async {
    // Create a mock OCRResult from the text
    final lines = fullText.split('\n').where((l) => l.trim().isNotEmpty).toList();
    
    // Use InvoiceDataExtractor to parse the text
    // We'll create a simple OCRResult-like structure
    try {
      // Split text into lines for parsing
      final ocrResult = OCRResult(
        fullText: fullText,
        blocks: [],
        lines: lines.map((line) => OCRTextLine(
          text: line,
          boundingBox: const Rect.fromLTWH(0, 0, 0, 0),
          confidence: 0.8,
        )).toList(),
        confidence: 0.7,
      );
      
      return await _dataExtractor.extractInvoiceData(ocrResult);
    } catch (e) {
      print('❌ Error parsing raw text: $e');
      return ExtractedInvoiceData.empty();
    }
  }

  /// Reset OCR state
  void reset() {
    rawText.value = '';
    extractedData.value = null;
    isProcessing.value = false;
    processingMessage.value = '';
    processingProgress.value = 0.0;
  }

  @override
  void onClose() {
    _ocrService.dispose();
    super.onClose();
  }
}

