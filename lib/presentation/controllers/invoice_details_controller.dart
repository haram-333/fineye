import 'dart:io' if (dart.library.html) 'package:fineye/presentation/controllers/file_stub.dart' as io;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/repositories/user_invoice_repository.dart';
import '../../../data/services/section_based_invoice_extractor.dart';
import 'invoice_list_controller.dart';
import 'dashboard_controller.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/services/notification_helper.dart';

class InvoiceDetailsController extends GetxController {
  final UserInvoiceRepository _invoiceRepository = UserInvoiceRepository();

  // Invoice Data
  late Invoice invoice;
  final Invoice? initialInvoice;

  /// Firestore document id for this invoice in `user_invoices`.
  /// This is required so we can update the correct document even if
  /// the human-readable invoice number changes.
  String? invoiceDocId;
  
  /// File containing the invoice image (for new invoices from OCR) - mobile only
  io.File? invoiceImageFile;

  /// Image bytes for web platform (for new invoices from OCR)
  Uint8List? invoiceImageBytes;

  /// Raw Document AI JSON response (for debugging)
  dynamic rawDocumentAI;
  
  /// Flag to indicate if this is a new invoice (from OCR) or editing existing
  bool isNewInvoice = false;

  InvoiceDetailsController({this.initialInvoice});

  // Text Controllers
  final TextEditingController supplierController = TextEditingController();
  final TextEditingController invoiceNumberController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController netAmountController = TextEditingController();
  final TextEditingController additionalChargesController = TextEditingController();

  // Observable State
  final Rx<DateTime?> invoiceDate = Rx<DateTime?>(null); // Nullable - only set if date is detected
  final RxString selectedCategory = ''.obs;
  final RxBool isVatInclusive = true.obs;
  final RxBool isPurchase = true.obs;
  final RxDouble netAmount = 0.0.obs;
  final RxDouble vatAmount = 0.0.obs;
  final RxDouble grossAmount = 0.0.obs;
  final RxDouble additionalCharges = 0.0.obs;
  
  // Computed: Final Total = Gross + Additional
  double get finalTotal => grossAmount.value + additionalCharges.value; // Delivery, service charges, etc.
  final RxBool isCtDeductible = true.obs;
  final RxBool showOriginalInvoice = true.obs;
  
  // Payment Status
  final RxBool isPaid = false.obs; // true = Paid, false = Not Paid
  final Rx<DateTime?> dueDate = Rx<DateTime?>(null); // Due date when not paid

  // Validation
  final RxBool vatValid = true.obs;
  final RxBool isDuplicate = false.obs;
  final RxList<String> missingFields = <String>[].obs;

  // Mock Extraction State
  final RxBool isExtracting = false.obs;
  
  // Saving state
  final RxBool isSaving = false.obs;
  
  // Track if any changes were made
  final RxBool hasChanges = false.obs;

  // Risk flags
  final RxList<InvoiceRisk> risks = <InvoiceRisk>[].obs;

  // Categories
  final List<String> categories = [
    'Office supplies',
    'Utilities',
    'Transport',
    'Subscriptions',
    'Marketing',
    'Professional fees',
    'Rent',
    'Maintenance',
    'Other',
  ];

  @override
  void onInit() {
    super.onInit();
    // 1) Prefer explicitly injected invoice via constructor.
    if (initialInvoice != null) {
      invoice = initialInvoice!;
    } else if (Get.arguments != null) {
      // 2) Support both legacy `Invoice` argument and new map with doc id.
      if (Get.arguments is Invoice) {
        invoice = Get.arguments as Invoice;
      } else if (Get.arguments is Map) {
        final args = Get.arguments as Map;
        
        // Check if coming from image preprocessing (new invoice)
        if (args['file'] != null || args['imageBytes'] != null) {
          isNewInvoice = true;
          // Handle web vs mobile: web uses imageBytes, mobile uses file
          if (kIsWeb && args['imageBytes'] != null) {
            invoiceImageBytes = args['imageBytes'] as Uint8List?;
          } else if (!kIsWeb && args['file'] != null) {
            invoiceImageFile = args['file'] as io.File?;
          }
          
          // Create new invoice from extracted data
          invoice = Invoice(
            id: '',
            supplierName: '',
            category: categories.first,
            date: DateTime.now(),
            grossAmount: 0.0,
            vatAmount: 0.0,
            status: 'Approved',
            taxBadge: 'VAT 5%',
            notes: '',
            isCtDeductible: true,
            vatActivity: 'Low',
          );
          
          // USE structured data from Gemini/Document AI if available
          // This is much more accurate than local regex
          if (args['extractedData'] != null) {
            print('✅ Invoice Details: Loading structured extracted data from backend...');
            _loadExtractedData(args['extractedData']);
          } else if (args['rawOcrText'] != null) {
            // Fallback to raw text parsing ONLY if structured data is missing
            final rawText = args['rawOcrText'] as String;
            print('⚠️ Invoice Details: No structured data, falling back to raw OCR text parsing...');
            _parseRawTextToFields(rawText);
          } else {
            print('❌ Invoice Details: No extraction data available!');
          }
        } else if (args['invoice'] != null && args['invoice'] is Invoice) {
          invoice = args['invoice'] as Invoice;
        } else {
          // Fallback: no invoice provided, create an empty one.
          invoice = Invoice(
            id: '',
            supplierName: '',
            category: categories.first,
            date: DateTime.now(),
            grossAmount: 0.0,
            vatAmount: 0.0,
            status: 'Draft',
            taxBadge: 'VAT 5%',
            notes: '',
            isCtDeductible: true,
            vatActivity: 'Low',
          );
        }

        // Extract Firestore document id when provided (for user_invoices).
        if (args['invoiceDocId'] != null && args['invoiceDocId'] is String) {
          invoiceDocId = args['invoiceDocId'] as String;
        }
      } else {
        // Unsupported argument type; create empty invoice.
        invoice = Invoice(
          id: '',
          supplierName: '',
          category: categories.first,
          date: DateTime.now(),
          grossAmount: 0.0,
          vatAmount: 0.0,
          status: 'Draft',
          taxBadge: 'VAT 5%',
          notes: '',
          isCtDeductible: true,
          vatActivity: 'Low',
        );
      }
    } else {
      // 3) No arguments at all: create a new draft invoice.
      invoice = Invoice(
        id: '',
        supplierName: '',
        category: categories.first,
        date: DateTime.now(),
        grossAmount: 0.0,
        vatAmount: 0.0,
        status: 'Draft',
        taxBadge: 'VAT 5%',
        notes: '',
        isCtDeductible: true,
        vatActivity: 'Low',
      );
    }

    // If invoice was loaded from Firestore, its firestoreDocId should be set.
    // Prioritize that over the one passed via arguments if both exist.
    if (invoice.firestoreDocId != null) {
      invoiceDocId = invoice.firestoreDocId;
    }
    
    // DON'T call _loadInvoiceData() for new invoices - it will overwrite parsed values!
    // Only load if we have an existing invoice with real data
    if (!isNewInvoice) {
      _loadInvoiceData();
      // For existing invoices, reset hasChanges to false after loading
      hasChanges.value = false;
    } else {
      // For new invoices, initialize payment status based on date
      // If date is in the future, set to Not Paid
      final invoiceDateValue = invoiceDate.value;
      if (invoiceDateValue != null && invoiceDateValue.isAfter(DateTime.now())) {
        isPaid.value = false;
      } else {
        // Default to Not Paid for new invoices
        isPaid.value = false;
      }
      // New invoices always have changes (they need to be saved)
      hasChanges.value = true;
    }

    // Setup controller sync with reactive values
    _setupControllerSync();

  // Reactivity - ONLY for non-text-field values
    // DO NOT add listeners that might interfere with text field editing
    ever(invoiceDate, (_) {
      _runRiskAssessment();
      _checkForChanges();
    });
    ever(selectedCategory, (_) {
      _runRiskAssessment();
      _checkForChanges();
    });
    ever(isCtDeductible, (_) => _checkForChanges());
    ever(isPaid, (_) => _checkForChanges());
    ever(dueDate, (_) => _checkForChanges());
    
    // Text field controllers - these are the source of truth
    supplierController.addListener(() {
      _runRiskAssessment();
      _checkForChanges();
    });
    invoiceNumberController.addListener(_checkForChanges);
    notesController.addListener(_checkForChanges);
    
    // Amount controllers - update reactive values ONLY, never touch controller text
    netAmountController.addListener(() {
      final text = netAmountController.text;
      final cleaned = text.replaceAll('AED', '').replaceAll(',', '').replaceAll(' ', '').trim();
      if (cleaned.isEmpty || cleaned == '.') {
        if (netAmount.value != 0.0) {
          netAmount.value = 0.0;
          vatAmount.value = 0.0;
          grossAmount.value = 0.0;
        }
        return;
      }
      final d = double.tryParse(cleaned);
      if (d != null && d >= 0) {
        // Only update reactive value if it's different (prevents infinite loops)
        if ((netAmount.value - d).abs() > 0.01) {
          netAmount.value = d;
          // Calculate VAT from net amount
          final calculatedVat = d * 0.05;
          vatAmount.value = (calculatedVat * 100).roundToDouble() / 100;
          grossAmount.value = d + vatAmount.value;
          _runRiskAssessment();
          _checkForChanges();
        }
      }
    });
    
    additionalChargesController.addListener(() {
      final text = additionalChargesController.text;
      final cleaned = text.replaceAll('AED', '').replaceAll(',', '').replaceAll(' ', '').trim();
      if (cleaned.isEmpty || cleaned == '.') {
        if (additionalCharges.value != 0.0) {
          additionalCharges.value = 0.0;
        }
        return;
      }
      final d = double.tryParse(cleaned);
      if (d != null && d >= 0) {
        // Only update reactive value if it's different (prevents infinite loops)
        if ((additionalCharges.value - d).abs() > 0.01) {
          additionalCharges.value = d;
          _runRiskAssessment();
          _checkForChanges();
        }
      }
    });
  }

  void _setupControllerSync() {
    // DON'T sync from reactive values to controllers - this causes cursor resets
    // The controllers are the source of truth during editing
    // Only initialize them once in _loadInvoiceData
  }

  /// Load structured data from ExtractedInvoiceData
  void _loadExtractedData(dynamic extractedData) {
    if (extractedData == null) return;

    try {
      // Extract supplier name
      if (extractedData.supplierName?.value != null) {
        supplierController.text = extractedData.supplierName.value;
        print('✅ Invoice Details: Loaded supplier: ${extractedData.supplierName.value}');
      }

      // Extract invoice number
      if (extractedData.invoiceNumber?.value != null) {
        invoiceNumberController.text = extractedData.invoiceNumber.value;
        print('✅ Invoice Details: Loaded invoice number: ${extractedData.invoiceNumber.value}');
      }

      // Extract invoice date
      if (extractedData.invoiceDate?.value != null) {
        invoiceDate.value = extractedData.invoiceDate.value;
        print('✅ Invoice Details: Loaded invoice date: ${extractedData.invoiceDate.value}');
      }

      // Extract amounts
      if (extractedData.netAmount != null && extractedData.netAmount > 0) {
        netAmount.value = extractedData.netAmount;
        netAmountController.text = extractedData.netAmount.toStringAsFixed(2);
        print('✅ Invoice Details: Loaded net amount: ${extractedData.netAmount}');
      }

      if (extractedData.vatAmount != null && extractedData.vatAmount > 0) {
        vatAmount.value = extractedData.vatAmount;
        print('✅ Invoice Details: Loaded VAT amount: ${extractedData.vatAmount}');
      }

      if (extractedData.grossAmount != null && extractedData.grossAmount > 0) {
        grossAmount.value = extractedData.grossAmount;
        print('✅ Invoice Details: Loaded gross amount: ${extractedData.grossAmount}');
      }

      // Calculate missing amounts if needed
      if (netAmount.value > 0 && vatAmount.value == 0.0) {
        vatAmount.value = netAmount.value * 0.05;
        print('✅ Invoice Details: Calculated VAT (5%): ${vatAmount.value}');
      }

      if (netAmount.value > 0 && grossAmount.value == 0.0) {
        grossAmount.value = netAmount.value + vatAmount.value;
        print('✅ Invoice Details: Calculated gross amount: ${grossAmount.value}');
      }

      print('📊 Invoice Details: Final loaded values - Net: ${netAmount.value}, VAT: ${vatAmount.value}, Gross: ${grossAmount.value}');
    } catch (e, stackTrace) {
      print('❌❌❌ Invoice Details: ERROR LOADING EXTRACTED DATA ❌❌❌');
      print('❌ Error Type: ${e.runtimeType}');
      print('❌ Error Message: $e');
      print('❌ Stack Trace:');
      print(stackTrace);
      debugPrint('❌❌❌ Invoice Details: ERROR LOADING EXTRACTED DATA ❌❌❌');
      debugPrint('❌ Error Type: ${e.runtimeType}');
      debugPrint('❌ Error Message: $e');
      debugPrint('❌ Stack Trace: $stackTrace');
    }
  }
  
  void _checkForChanges() {
    if (isNewInvoice) {
      hasChanges.value = true; // New invoices always have changes
      return;
    }
    
    // Calculate net amount from invoice for comparison
    final invoiceNetAmount = invoice.grossAmount - invoice.vatAmount - invoice.additionalCharges;
    
    // Compare current values with original invoice - include ALL fields
    hasChanges.value = 
      supplierController.text.trim() != invoice.supplierName.trim() ||
      invoiceNumberController.text.trim() != invoice.id.trim() ||
      (invoiceDate.value != null && !invoiceDate.value!.isAtSameMomentAs(invoice.date)) ||
      (invoiceDate.value == null && invoice.date != DateTime.now()) ||
      selectedCategory.value != invoice.category ||
      (netAmount.value - invoiceNetAmount).abs() > 0.01 || // Allow small floating point differences
      (vatAmount.value - invoice.vatAmount).abs() > 0.01 ||
      (grossAmount.value - invoice.grossAmount).abs() > 0.01 ||
      (additionalCharges.value - invoice.additionalCharges).abs() > 0.01 ||
      isCtDeductible.value != invoice.isCtDeductible ||
      notesController.text.trim() != invoice.notes.trim() ||
      isPaid.value != (invoice.status == 'Paid') ||
      (dueDate.value != null && invoice.dueDate != null && !dueDate.value!.isAtSameMomentAs(invoice.dueDate!)) ||
      (dueDate.value == null && invoice.dueDate != null) ||
      (dueDate.value != null && invoice.dueDate == null);
    
    debugPrint('🔍 Change detection: hasChanges=${hasChanges.value}');
    debugPrint('  Supplier: "${supplierController.text.trim()}" vs "${invoice.supplierName.trim()}"');
    debugPrint('  Invoice #: "${invoiceNumberController.text.trim()}" vs "${invoice.id.trim()}"');
    debugPrint('  Category: "${selectedCategory.value}" vs "${invoice.category}"');
    debugPrint('  Net: ${netAmount.value} vs ${invoiceNetAmount}');
    debugPrint('  VAT: ${vatAmount.value} vs ${invoice.vatAmount}');
    debugPrint('  Gross: ${grossAmount.value} vs ${invoice.grossAmount}');
    debugPrint('  Additional: ${additionalCharges.value} vs ${invoice.additionalCharges}');
    debugPrint('  CT Deductible: ${isCtDeductible.value} vs ${invoice.isCtDeductible}');
    debugPrint('  Notes: "${notesController.text.trim()}" vs "${invoice.notes.trim()}"');
    debugPrint('  Paid: ${isPaid.value} vs ${invoice.status == 'Paid'}');
    debugPrint('  Due Date: ${dueDate.value} vs ${invoice.dueDate}');
  }

  
  /// Parse raw OCR text using section-based extraction
  /// Divides invoice into sections and extracts data from each
  void _parseRawTextToFields(String text) {
    if (text.isEmpty) return;
    
    print('🔍 Invoice Details: Parsing raw OCR text using section-based extraction...');
    print('📄 Raw text length: ${text.length} characters');
    
    // Use section-based extractor
    final result = SectionBasedInvoiceExtractor.extractFromSections(text);
    
    if (result.isEmpty) {
      print('⚠️ No data extracted from sections, falling back to simple parsing...');
      _parseRawTextToFieldsSimple(text);
      return;
    }
    
    print('✅ Section-based extraction results:');
    print('   Supplier: ${result.supplierName ?? "not found"}');
    print('   Invoice #: ${result.invoiceNumber ?? "not found"}');
    print('   Date: ${result.invoiceDate ?? "not found"}');
    print('   Subtotal: ${result.subtotal ?? "not found"}');
    print('   VAT: ${result.vatAmount ?? "not found"}');
    print('   Total: ${result.totalAmount ?? "not found"}');
    
    // Load supplier name (always set if extracted, even if field already has value)
    if (result.supplierName != null && result.supplierName!.isNotEmpty) {
      supplierController.text = result.supplierName!;
      print('✅ Loaded Supplier: ${result.supplierName}');
    } else {
      print('⚠️ Supplier name not extracted from invoice');
      // Fallback: try to extract from first line of raw text
      final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
      if (lines.isNotEmpty && supplierController.text.isEmpty) {
        final firstLine = lines[0];
        // Only use if it's not a date, number, or amount
        if (firstLine.length >= 2 && 
            firstLine.length <= 100 &&
            !RegExp(r'^\d+$').hasMatch(firstLine.replaceAll(',', '').replaceAll('.', '')) &&
            !RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(firstLine)) {
          supplierController.text = firstLine;
          print('✅ Loaded Supplier (fallback from first line): $firstLine');
        }
      }
    }
    
    // Load invoice number (only if empty)
    if (result.invoiceNumber != null && invoiceNumberController.text.isEmpty) {
      invoiceNumberController.text = result.invoiceNumber!;
      print('✅ Loaded Invoice #: ${result.invoiceNumber}');
    }
    
    // Load invoice date (only if empty)
    if (result.invoiceDate != null && invoiceDate.value == null) {
      invoiceDate.value = result.invoiceDate;
      print('✅ Loaded Invoice Date: ${result.invoiceDate}');
    }
    
    // Load amounts (MOST IMPORTANT - subtotal/net amount without VAT)
    // Priority: Subtotal > Net Amount
    if (result.subtotal != null && netAmount.value == 0.0) {
      netAmount.value = result.subtotal!;
      netAmountController.text = result.subtotal!.toStringAsFixed(2);
      print('✅ Loaded Subtotal/Net Amount: ${result.subtotal}');
      
      // Always calculate 5% VAT from subtotal/net amount
      vatAmount.value = result.subtotal! * 0.05;
      print('✅ Calculated VAT (5%): ${vatAmount.value}');
      
      // Calculate Gross = Subtotal + VAT
      grossAmount.value = result.subtotal! + vatAmount.value;
      print('✅ Calculated Gross Amount: ${grossAmount.value}');
    } else if (result.totalAmount != null && netAmount.value == 0.0 && result.subtotal == null) {
      // If only total is found, calculate backwards
      netAmount.value = result.totalAmount! / 1.05;
      netAmountController.text = netAmount.value.toStringAsFixed(2);
      vatAmount.value = result.totalAmount! - netAmount.value;
      grossAmount.value = result.totalAmount!;
      print('✅ Calculated Subtotal and VAT from Total: Subtotal=${netAmount.value}, VAT=${vatAmount.value}');
    } else {
      // If VAT was explicitly found, use it, otherwise calculate 5%
      if (result.vatAmount != null && vatAmount.value == 0.0) {
        vatAmount.value = result.vatAmount!;
        print('✅ Loaded VAT Amount: ${result.vatAmount}');
      } else if (netAmount.value > 0 && vatAmount.value == 0.0) {
        // Calculate 5% VAT from net amount
        vatAmount.value = netAmount.value * 0.05;
        print('✅ Calculated VAT (5%) from Net Amount: ${vatAmount.value}');
      }
      
      // Set gross amount
      if (result.totalAmount != null && grossAmount.value == 0.0) {
        grossAmount.value = result.totalAmount!;
        print('✅ Loaded Gross Amount: ${result.totalAmount}');
      } else if (netAmount.value > 0 && grossAmount.value == 0.0) {
        // Calculate gross from net + VAT
        grossAmount.value = netAmount.value + vatAmount.value;
        print('✅ Calculated Gross Amount: ${grossAmount.value}');
      }
    }
    
    print('📊 FINAL: Net=${netAmount.value}, VAT=${vatAmount.value}, Gross=${grossAmount.value}');
  }
  
  /// Fallback: Simple parsing if section-based extraction fails
  void _parseRawTextToFieldsSimple(String text) {
    if (text.isEmpty) return;
    
    print('🔍 Invoice Details: Using simple parsing fallback...');
    
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    // 1. Supplier: First line usually (always set if not already set)
    if (lines.isNotEmpty && lines[0].trim().isNotEmpty) {
      // Only set if field is empty or if we have a better extraction
      if (supplierController.text.isEmpty) {
        supplierController.text = lines[0].trim();
        print('✅ Supplier (Simple): ${lines[0].trim()}');
      }
    }
    
    // 2. Invoice Number: Multiple patterns
    // Pattern 1: "Bill NO: 54098"
    // Pattern 2: "Check: 406587" or "Check : 406587"
    // Pattern 3: "Invoice No:" or "Invoice Number:"
    String? invoiceNumber;
    
    final patterns = [
      RegExp(r'Bill\s+NO\s*:?\s*(\d+)', caseSensitive: false),
      RegExp(r'Check\s*:?\s*(\d+)', caseSensitive: false),
      RegExp(r'Invoice\s+(?:No|Number)\s*:?\s*(\d+)', caseSensitive: false),
      RegExp(r'Invoice\s*#\s*:?\s*(\d+)', caseSensitive: false),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        invoiceNumber = match.group(1)!;
        print('✅ Invoice #: $invoiceNumber from pattern "${match.group(0)}"');
        break;
      }
    }
    
    if (invoiceNumber != null && invoiceNumberController.text.isEmpty) {
      invoiceNumberController.text = invoiceNumber;
    } else if (invoiceNumber == null) {
      print('⚠️ Invoice number not detected');
    }
    
    // 3. Date: Multiple formats supported
    // Format 1: "02-Apr-25" or "15-Apr-18"
    // Format 2: "15 Apr, 18" or "15 Apr 18" (with or without comma)
    // Format 3: "Date : 15 Apr, 18" (with label)
    DateTime? parsedDate;
    
    // Try format: "15 Apr, 18" or "15 Apr 18" (with space and optional comma)
    // Also handles "Date : 15 Apr, 18"
    final dateMatch1 = RegExp(r'(?:Date\s*:?\s*)?(\d{1,2})\s+([A-Za-z]{3})[a-z]*,?\s+(\d{2})\b', caseSensitive: false).firstMatch(text);
    if (dateMatch1 != null) {
      try {
        final day = int.parse(dateMatch1.group(1)!);
        final monthStr = dateMatch1.group(2)!.toLowerCase();
        final yearShort = int.parse(dateMatch1.group(3)!);
        
        // Convert 2-digit year: 00-49 = 2000-2049, 50-99 = 1950-1999
        final year = yearShort < 50 ? 2000 + yearShort : 1900 + yearShort;
        
        // Parse month name
        final monthNames = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
        final month = monthNames.indexOf(monthStr.substring(0, 3)) + 1;
        
        if (month > 0 && day >= 1 && day <= 31) {
          parsedDate = DateTime(year, month, day);
          print('✅ Date: $parsedDate from "${dateMatch1.group(0)}"');
        }
      } catch (e) {
        print('⚠️ Date parse failed (format 1): $e');
      }
    }
    
    // Try format: "02-Apr-25" (with dashes)
    if (parsedDate == null) {
      final dateMatch2 = RegExp(r'(\d{1,2})-([A-Za-z]{3})-(\d{2})\b', caseSensitive: false).firstMatch(text);
      if (dateMatch2 != null) {
        try {
          final day = int.parse(dateMatch2.group(1)!);
          final monthStr = dateMatch2.group(2)!.toLowerCase();
          final yearShort = int.parse(dateMatch2.group(3)!);
          
          // Convert 2-digit year: 00-49 = 2000-2049, 50-99 = 1950-1999
          final year = yearShort < 50 ? 2000 + yearShort : 1900 + yearShort;
          
          // Parse month name
          final monthNames = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
          final month = monthNames.indexOf(monthStr.substring(0, 3)) + 1;
          
          if (month > 0 && day >= 1 && day <= 31) {
            parsedDate = DateTime(year, month, day);
            print('✅ Date: $parsedDate from "${dateMatch2.group(0)}"');
          }
        } catch (e) {
          print('⚠️ Date parse failed (format 2): $e');
        }
      }
    }
    
    // Try format: "DD/MM/YYYY" or "DD-MM-YYYY"
    if (parsedDate == null) {
      final dateMatch3 = RegExp(r'(?:Date\s*:?\s*)?(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})\b').firstMatch(text);
      if (dateMatch3 != null) {
        try {
          final day = int.parse(dateMatch3.group(1)!);
          final month = int.parse(dateMatch3.group(2)!);
          final yearRaw = int.parse(dateMatch3.group(3)!);
          final year = yearRaw < 100 ? (yearRaw < 50 ? 2000 + yearRaw : 1900 + yearRaw) : yearRaw;
          
          if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
            parsedDate = DateTime(year, month, day);
            print('✅ Date: $parsedDate from "${dateMatch3.group(0)}"');
          }
        } catch (e) {
          print('⚠️ Date parse failed (format 3): $e');
        }
      }
    }
    
    // Only set date if successfully parsed
    if (parsedDate != null) {
      invoiceDate.value = parsedDate;
    } else {
      print('⚠️ Date not detected or format not supported');
    }
    
    // 4. Amount extraction: Find subtotal, calculate 5% VAT, then gross
    // Strategy: Find subtotal/net amount (before VAT), calculate VAT = subtotal * 0.05, gross = subtotal + VAT
    double? subtotal;
    
    // Look for subtotal labels in the text (case-insensitive)
    final subtotalLabels = [
      r'Sub\.?\s*Total\s*:?\s*(?:AED\s*)?([\d,]+\.?\d{2}?)',
      r'Subtotal\s*:?\s*(?:AED\s*)?([\d,]+\.?\d{2}?)',
      r'Total\s+before\s+VAT\s*:?\s*(?:AED\s*)?([\d,]+\.?\d{2}?)',
      r'Net\s+Amount\s*:?\s*(?:AED\s*)?([\d,]+\.?\d{2}?)',
      r'Amount\s+excl\.?\s*VAT\s*:?\s*(?:AED\s*)?([\d,]+\.?\d{2}?)',
      r'Amount\s+before\s+VAT\s*:?\s*(?:AED\s*)?([\d,]+\.?\d{2}?)',
    ];
    
    for (final pattern in subtotalLabels) {
      final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
      if (match != null) {
        try {
          final amountStr = match.group(1)!.replaceAll(',', '');
          subtotal = double.tryParse(amountStr);
          if (subtotal != null && subtotal > 0) {
            print('✅ Found Subtotal: $subtotal from pattern "${match.group(0)}"');
            break;
          }
        } catch (e) {
          print('⚠️ Failed to parse subtotal: $e');
        }
      }
    }
    
    // Fallback: Look for amounts in the totals section and find the one before "VAT" or "Total"
    if (subtotal == null) {
      final startIdx = (lines.length * 0.7).toInt();
      final amounts = <double>[];
      final amountLines = <String>[];
      
      for (int i = startIdx; i < lines.length; i++) {
        final line = lines[i].toLowerCase();
        final match = RegExp(r'([\d,]+\.\d{2})').firstMatch(lines[i]);
        if (match != null) {
          final amount = double.tryParse(match.group(1)!.replaceAll(',', ''));
          if (amount != null && amount > 1.0 && amount < 10000) {
            amounts.add(amount);
            amountLines.add(line);
            print('💰 Found amount: $amount at line $i: "${lines[i]}"');
          }
        }
      }
      
      // Look for the amount that appears before "VAT" or before the final "Total"
      if (amounts.isNotEmpty) {
        // Find the largest amount that's NOT the grand total
        // Usually subtotal is the second largest or appears before "VAT" label
        final sorted = List<double>.from(amounts)..sort((a, b) => b.compareTo(a));
        
        // Check if any line contains "vat" and get the amount before it
        for (int i = startIdx; i < lines.length; i++) {
          final line = lines[i].toLowerCase();
          if (line.contains('vat') && i > startIdx) {
            // Look for amount in previous line
            final prevMatch = RegExp(r'([\d,]+\.\d{2})').firstMatch(lines[i - 1]);
            if (prevMatch != null) {
              final prevAmount = double.tryParse(prevMatch.group(1)!.replaceAll(',', ''));
              if (prevAmount != null && prevAmount > 0) {
                subtotal = prevAmount;
                print('✅ Found Subtotal before VAT: $subtotal');
                break;
              }
            }
          }
        }
        
        // If still not found, use second largest amount (assuming largest is grand total)
        if (subtotal == null && sorted.length >= 2) {
          subtotal = sorted[1];  // Second largest is likely subtotal
          print('✅ Using second largest amount as Subtotal: $subtotal');
        } else if (subtotal == null && sorted.isNotEmpty) {
          // If only one amount, check if it could be subtotal (not grand total)
          // If it's reasonable size, use it
          subtotal = sorted[0];
          print('✅ Using largest amount as Subtotal: $subtotal');
        }
      }
    }
    
    // Calculate VAT and Gross from Subtotal
    if (subtotal != null && subtotal > 0) {
      netAmount.value = subtotal;
      netAmountController.text = subtotal.toStringAsFixed(2);
      
      // Calculate VAT as 5% of subtotal
      vatAmount.value = (subtotal * 0.05);
      
      // Calculate Gross = Subtotal + VAT
      grossAmount.value = subtotal + vatAmount.value;
      
      print('✅ CALCULATED: Subtotal=$subtotal, VAT (5%)=${vatAmount.value.toStringAsFixed(2)}, Gross=${grossAmount.value.toStringAsFixed(2)}');
    } else {
      print('⚠️ Could not find subtotal in invoice');
    }
    
    print('📊 FINAL: Net=${netAmount.value}, VAT=${vatAmount.value}, Gross=${grossAmount.value}, Additional=${additionalCharges.value}');
  }

  void _loadInvoiceData() {
    supplierController.text = invoice.supplierName;
    invoiceNumberController.text = invoice.id;
    notesController.text = invoice.notes;
    invoiceDate.value = invoice.date;
    selectedCategory.value = invoice.category;
    isCtDeductible.value = invoice.isCtDeductible;
    
    // Initialize payment status from invoice
    isPaid.value = invoice.status == 'Paid';
    dueDate.value = invoice.dueDate;

    grossAmount.value = invoice.grossAmount;
    vatAmount.value = invoice.vatAmount;
    additionalCharges.value = invoice.additionalCharges;

    // Calculate net from gross if needed
    if (grossAmount.value > 0 && netAmount.value == 0.0) {
      netAmount.value = grossAmount.value - vatAmount.value - additionalCharges.value;
    }

    // Initialize text controllers with current values
    if (netAmount.value > 0) {
      netAmountController.text = netAmount.value.toStringAsFixed(2);
    } else {
      netAmountController.clear();
    }
    
    if (additionalCharges.value > 0) {
      additionalChargesController.text = additionalCharges.value.toStringAsFixed(2);
    } else {
      additionalChargesController.clear();
    }
    
    debugPrint('✅ Initialized Net Amount controller: ${netAmountController.text}');
    debugPrint('✅ Initialized Additional Charges controller: ${additionalChargesController.text}');
    debugPrint('✅ Loaded from Firebase: Net=${netAmount.value}, VAT=${vatAmount.value}, Gross=${grossAmount.value}, Additional=${additionalCharges.value}');

    // Determine VAT inclusive state based on data (mock logic or default)
    // For this demo, let's assume default is inclusive
    isVatInclusive.value = true;

    // DON'T recalculate VAT for existing invoices - use the values from Firebase!
    // calculateVAT(fromGross: false); // REMOVED - this was overwriting Firebase values

    // Initial Assessment
    _runRiskAssessment();

    // ONLY show extraction animation for NEW invoices (from OCR)
    // Existing invoices should load instantly from Firebase
    if (isNewInvoice) {
      isExtracting.value = true;
      Future.delayed(const Duration(seconds: 2), () {
        isExtracting.value = false;
      });
    }
  }

  void calculateVAT({bool fromGross = true}) {
    // VAT is ALWAYS calculated from Net Amount only (5% of net)
    // Additional charges are NOT part of VAT calculation
    // Gross = Net + VAT (NOT including additional charges)
    
    // CRITICAL: NEVER update controller text here - only update reactive values
    if (netAmount.value > 0) {
      // Calculate VAT from net (5%)
      final calculatedVat = netAmount.value * 0.05;
      // Round to 2 decimals
      vatAmount.value = (calculatedVat * 100).roundToDouble() / 100;
      
      // Gross = Net + VAT ONLY (additional charges are separate!)
      grossAmount.value = netAmount.value + vatAmount.value;
      
      print('💰 VAT Calculation: Net=${netAmount.value}, VAT=${vatAmount.value}, Gross=${grossAmount.value}, Additional=${additionalCharges.value}');
    } else if (grossAmount.value > 0 && fromGross) {
      // Calculate from gross (reverse: gross = net + vat, so net = gross / 1.05)
      // BUT: Don't update netAmount.value if user is currently editing it!
      // Only update if netAmount is 0 (meaning user hasn't entered anything)
      if (netAmount.value == 0.0) {
        netAmount.value = grossAmount.value / 1.05;
        vatAmount.value = grossAmount.value - netAmount.value;
        // Update controller text ONLY if it's empty
        if (netAmountController.text.isEmpty || netAmountController.text == '0.00' || netAmountController.text == '0') {
          netAmountController.text = netAmount.value.toStringAsFixed(2);
        }
      }
      
      print('💰 VAT Calculation (from gross): Gross=${grossAmount.value}, Net=${netAmount.value}, VAT=${vatAmount.value}');
    } else {
      // If both net and gross are 0, reset VAT
      vatAmount.value = 0.0;
      grossAmount.value = 0.0;
    }
    _runRiskAssessment();
  }

  void _runRiskAssessment() {
    // 1. Create a temporary Invoice object from current form state
    final tempInvoice = Invoice(
      id: invoiceNumberController.text,
      supplierName: supplierController.text,
      category: selectedCategory.value,
      date: invoiceDate.value ?? DateTime.now(),
      grossAmount: grossAmount.value,
      vatAmount: vatAmount.value,
      status: invoice.status, // Preserve status
      taxBadge: invoice.taxBadge, // Preserve or calc
      notes: notesController.text,
      isCtDeductible: isCtDeductible.value,
      vatActivity: invoice.vatActivity,
    );

    // 2. Get InvoiceListController (source of truth for logic)
    if (Get.isRegistered<InvoiceListController>()) {
      final listController = Get.find<InvoiceListController>();
      
      // 3. Run assessment
      final detectedRisks = listController.assessInvoiceRisks(tempInvoice, listController.invoices);
      
      // 4. Update local state
      risks.assignAll(detectedRisks);
      
      // Update specific flags for UI helpers
      vatValid.value = !detectedRisks.any((r) => r.type == InvoiceRiskType.vatMismatch);
      isDuplicate.value = detectedRisks.any((r) => r.type == InvoiceRiskType.duplicateInvoice);
      
      missingFields.clear();
      if (detectedRisks.any((r) => r.type == InvoiceRiskType.missingSupplier)) missingFields.add('Supplier');
      if (detectedRisks.any((r) => r.type == InvoiceRiskType.missingAmount)) missingFields.add('Total Amount');
    }
  }

  // Update methods from UI
  void updateGrossAmount(String val) {
    double? d = double.tryParse(val.replaceAll(',', ''));
    if (d != null) {
      grossAmount.value = d;
    }
  }

  void updateNetAmount(String val) {
    // DO NOTHING - let the controller listener handle it
    // This prevents any interference with user typing
  }

  void updateAdditionalCharges(String val) {
    // DO NOTHING - let the controller listener handle it
    // This prevents any interference with user typing
  }

  Future<void> selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: invoiceDate.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      invoiceDate.value = picked;
    }
  }

  void discardChanges() {
    Get.back();
  }

  Future<void> confirmAndSave() async {
    if (isSaving.value) {
      print('⚠️ Already saving, ignoring duplicate call');
      return;
    }
    
    // Validate required fields BEFORE setting isSaving
    if (supplierController.text.isEmpty) {
      SnackbarService.to.showError(
        'Validation Error',
        'Supplier name is required',
      );
      return;
    }

    if (invoiceNumberController.text.isEmpty) {
      SnackbarService.to.showError(
        'Validation Error',
        'Invoice number is required',
      );
      return;
    }

    if (grossAmount.value <= 0) {
      SnackbarService.to.showError(
        'Validation Error',
        'Gross amount must be greater than 0',
      );
      return;
    }

    // Validate due date if unpaid
    if (!isPaid.value && dueDate.value == null) {
      SnackbarService.to.showError(
        'Validation Error',
        'Due date is required when invoice is not paid',
      );
      return;
    }

    // Set isSaving AFTER validation
    isSaving.value = true;
    
    try {
      print('💾 confirmAndSave: Starting save process');
      
      // Check if this is a new invoice (from OCR)
      if (isNewInvoice) {
        print('💾 confirmAndSave: Saving as NEW invoice');
        SnackbarService.to.showInfo(
          'Saving',
          'Saving invoice to database...',
        );
        // Save as NEW invoice
        await _saveNewInvoice();
        return;
      }
      
      print('💾 confirmAndSave: Updating EXISTING invoice');
      SnackbarService.to.showInfo(
        'Updating',
        'Updating invoice...',
      );

      // Otherwise, update existing invoice
      // Recalculate risks before saving
      final tempInvoice = Invoice(
        id: invoiceNumberController.text,
        supplierName: supplierController.text,
        category: selectedCategory.value.isNotEmpty ? selectedCategory.value : invoice.category,
        date: invoiceDate.value ?? DateTime.now(),
        grossAmount: grossAmount.value,
        vatAmount: vatAmount.value,
        additionalCharges: additionalCharges.value,
        status: _determineInvoiceStatus(),
        taxBadge: invoice.taxBadge,
        notes: notesController.text,
        isCtDeductible: isCtDeductible.value,
        vatActivity: invoice.vatActivity,
        dueDate: isPaid.value ? null : dueDate.value,
        risks: const [],
      );

      // Get all invoices for risk assessment
      List<Invoice> allInvoices = [];
      if (Get.isRegistered<InvoiceListController>()) {
        allInvoices = Get.find<InvoiceListController>().invoices.toList();
      }

      // Assess risks
      List<InvoiceRisk> updatedRisks = [];
      if (Get.isRegistered<InvoiceListController>()) {
        final listController = Get.find<InvoiceListController>();
        updatedRisks = listController.assessInvoiceRisks(tempInvoice, allInvoices);
      }

      // Ensure userId is set (required for security rules)
      String finalUserId = invoice.userId;
      if (finalUserId.isEmpty) {
        // Try to get current user from Firebase Auth directly
        final firebaseAuth = FirebaseAuth.instance;
        final currentUser = firebaseAuth.currentUser;
        if (currentUser != null) {
          finalUserId = currentUser.uid;
        } else {
          SnackbarService.to.showError(
            'Error',
            'You must be logged in to save invoices.',
          );
          return;
        }
      }

      // Read values from controllers (source of truth) to ensure we get latest user input
      final netText = netAmountController.text.replaceAll('AED', '').replaceAll(',', '').replaceAll(' ', '').trim();
      final netFromController = double.tryParse(netText) ?? netAmount.value;
      
      final additionalText = additionalChargesController.text.replaceAll('AED', '').replaceAll(',', '').replaceAll(' ', '').trim();
      final additionalFromController = double.tryParse(additionalText) ?? additionalCharges.value;
      
      // Calculate VAT from net amount
      final calculatedVat = netFromController * 0.05;
      final vatFromNet = (calculatedVat * 100).roundToDouble() / 100;
      final grossFromNet = netFromController + vatFromNet;
      
      // Create updated invoice from form data with recalculated risks.
      // Note: we preserve immutable metadata like userId and imageUrl from the
      // existing `invoice` instance so that edits only touch what the user sees.
      final updatedInvoice = Invoice(
        id: invoiceNumberController.text,
        supplierName: supplierController.text,
        category: selectedCategory.value.isNotEmpty ? selectedCategory.value : invoice.category,
        date: invoiceDate.value ?? DateTime.now(),
        grossAmount: grossFromNet,
        vatAmount: vatFromNet,
        additionalCharges: additionalFromController,
        status: _determineInvoiceStatus(),
        taxBadge: invoice.taxBadge,
        notes: notesController.text,
        isCtDeductible: isCtDeductible.value,
        vatActivity: invoice.vatActivity,
        dueDate: isPaid.value ? null : dueDate.value,
        userId: finalUserId,
        imageUrl: invoice.imageUrl,
        firestoreDocId: invoice.firestoreDocId,
        risks: updatedRisks,
        isFlagged: invoice.isFlagged.value,
      );

      // Update in Firestore `user_invoices` by the known document id.
      // Priority: use firestoreDocId from invoice object, then invoiceDocId from args, then fallback to invoice.id
      final docId = invoice.firestoreDocId ?? invoiceDocId ?? invoice.id;
      
      print('🔥 Invoice Details: About to update invoice in Firestore');
      print('🔥 Document ID: $docId');
      print('🔥 User ID: ${updatedInvoice.userId}');
      print('🔥 Invoice ID: ${updatedInvoice.id}');
      
      try {
        final success = await _invoiceRepository.updateInvoiceByDocId(
          docId,
          updatedInvoice,
        );
        
        if (success) {
          print('✅✅✅ Invoice Details: Update SUCCESSFUL ✅✅✅');
          SnackbarService.to.showSuccess(
            'title_updated'.tr,
            'msg_invoice_updated_success'.tr,
          );
          
          // Trigger refresh of invoice list and dashboard
          if (Get.isRegistered<InvoiceListController>()) {
            final invoiceController = Get.find<InvoiceListController>();
            await invoiceController.refreshInvoices();
          }
          
          if (Get.isRegistered<DashboardController>()) {
            final dashboardController = Get.find<DashboardController>();
            dashboardController.loadDashboardData();
          }
          
          // Reset hasChanges flag
          hasChanges.value = false;
          // Close the screen after a short delay to allow stream to update
          await Future.delayed(const Duration(milliseconds: 800));
          Get.back();
        } else {
          print('❌ Invoice Details: Update returned false');
          SnackbarService.to.showError(
            'Error',
            'Failed to save invoice. Please try again.',
          );
        }
      } catch (updateError, updateStack) {
        print('❌❌❌ Invoice Details: Update FAILED ❌❌❌');
        print('❌ Error: $updateError');
        print('❌ Stack: $updateStack');
        rethrow; // Let outer catch handle it
      }
    } catch (e, stackTrace) {
      print('❌❌❌ INVOICE DETAILS: ERROR SAVING INVOICE ❌❌❌');
      print('❌ Error Type: ${e.runtimeType}');
      print('❌ Error Message: $e');
      print('❌ Stack Trace:');
      print(stackTrace);
      print('❌ Invoice Doc ID: $invoiceDocId');
      print('❌ Invoice: ${invoice.id}');
      debugPrint('❌❌❌ INVOICE DETAILS: ERROR SAVING INVOICE ❌❌❌');
      debugPrint('❌ Error Type: ${e.runtimeType}');
      debugPrint('❌ Error Message: $e');
      debugPrint('❌ Stack Trace: $stackTrace');
      SnackbarService.to.showError(
        'Error',
        'Failed to save invoice: ${e.toString()}',
      );
    } finally {
      isSaving.value = false;
      print('💾 confirmAndSave: isSaving reset to false');
    }
  }
  
  /// Save a new invoice (from OCR) to Firebase
  Future<void> _saveNewInvoice() async {
    try {
      // Ensure user is authenticated
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        SnackbarService.to.showError(
          'Error',
          'You must be logged in to save invoices.',
        );
        return;
      }
      
      // 1) Prepare base invoice data from current form state
      final now = DateTime.now();
      final baseInvoice = Invoice(
        id: invoiceNumberController.text.isNotEmpty
            ? invoiceNumberController.text
            : 'INV-${now.millisecondsSinceEpoch}',
        supplierName: supplierController.text,
        category: selectedCategory.value.isNotEmpty ? selectedCategory.value : categories.first,
        date: invoiceDate.value ?? DateTime.now(),
        grossAmount: grossAmount.value,
        vatAmount: vatAmount.value,
        additionalCharges: additionalCharges.value,
        status: _determineInvoiceStatus(),
        taxBadge: 'VAT 5%',
        notes: notesController.text,
        isCtDeductible: isCtDeductible.value,
        vatActivity: 'Low',
        dueDate: isPaid.value ? null : dueDate.value,
        userId: currentUser.uid,
        imageUrl: null,
        risks: risks.toList(),
        isFlagged: false,
      );

      // 2) Generate Firestore document id
      final firestore = FirebaseFirestore.instance;
      final collectionRef = firestore.collection('user_invoices');
      final docRef = collectionRef.doc();
      final docId = docRef.id;

      String? imageUrl;

      // 3) Upload image to Firebase Storage if we have one
      if (kIsWeb && invoiceImageBytes != null) {
        try {
          final storage = FirebaseStorage.instance;
          final storageRef = storage.ref().child(
              'user_invoices/${currentUser.uid}/$docId.jpg');
          print('📤 Invoice Details: Uploading image bytes to Firebase Storage at ${storageRef.fullPath}');
          final uploadTask = await storageRef.putData(
            invoiceImageBytes!,
            SettableMetadata(contentType: 'image/jpeg'),
          );
          imageUrl = await uploadTask.ref.getDownloadURL();
          print('✅ Invoice Details: Image uploaded. URL: $imageUrl');
        } catch (e, stack) {
          print('❌ Invoice Details: Failed to upload image: $e');
          print('❌ Stack trace: $stack');
          // Continue without image; user still gets saved invoice
          imageUrl = null;
        }
      } else if (!kIsWeb && invoiceImageFile != null) {
        try {
          final storage = FirebaseStorage.instance;
          final storageRef = storage.ref().child(
              'user_invoices/${currentUser.uid}/$docId.jpg');
          print('📤 Invoice Details: Uploading image to Firebase Storage at ${storageRef.fullPath}');
          // On mobile, cast to dart:io File
          final ioFile = invoiceImageFile as dynamic;
          final uploadTask = await storageRef.putFile(ioFile);
          imageUrl = await uploadTask.ref.getDownloadURL();
          print('✅ Invoice Details: Image uploaded. URL: $imageUrl');
        } catch (e, stack) {
          print('❌ Invoice Details: Failed to upload image: $e');
          print('❌ Stack trace: $stack');
          // Continue without image; user still gets saved invoice
          imageUrl = null;
        }
      }

      // 4) Persist invoice to Firestore
      final invoiceToSave = baseInvoice.copyWith(
        imageUrl: imageUrl,
        firestoreDocId: docId,
      );

      print('🔥 Invoice Details: About to save NEW invoice to Firestore');
      print('🔥 Document ID: $docId');
      print('🔥 User ID: ${currentUser.uid}');
      print('🔥 Invoice ID: ${invoiceToSave.id}');
      
      await docRef.set(invoiceToSave.toMap());
      print('✅✅✅ Invoice Details: Firestore write SUCCESSFUL ✅✅✅');

      // Create notification for new invoice
      try {
        await NotificationHelper.createSystemNotification(
          titleKey: 'notif_invoice_created',
          titleParams: {},
          messageKey: 'notif_invoice_created_msg',
          messageParams: {
            'invoiceNumber': invoiceToSave.id,
            'supplierName': invoiceToSave.supplierName.isNotEmpty 
                ? invoiceToSave.supplierName 
                : 'Unknown Supplier',
          },
          isCritical: false,
        );
        print('✅ Invoice Details: Notification created for new invoice');
      } catch (notifError) {
        print('⚠️ Invoice Details: Failed to create notification: $notifError');
        // Don't fail the save if notification fails
      }

      SnackbarService.to.showSuccess(
        'invoice_saved'.tr,
        'msg_invoice_saved_success'.tr,
      );
      
      print('🎉 Invoice Details: Save complete');
      
      // Trigger refresh of invoice list and dashboard
      if (Get.isRegistered<InvoiceListController>()) {
        final invoiceController = Get.find<InvoiceListController>();
        await invoiceController.refreshInvoices();
      }
      
      if (Get.isRegistered<DashboardController>()) {
        final dashboardController = Get.find<DashboardController>();
        dashboardController.loadDashboardData();
      }
      
      // Navigate back to main screen after a short delay to allow stream to update
      await Future.delayed(const Duration(milliseconds: 800));
      Get.offAllNamed('/main');
    } catch (e, stackTrace) {
      print('❌❌❌ Invoice Details: ERROR SAVING NEW INVOICE ❌❌❌');
      print('❌ Error: $e');
      print('❌ Stack trace: $stackTrace');
      
      String errorMessage = 'Failed to save invoice';
      if (e.toString().contains('permission') || e.toString().contains('PERMISSION_DENIED')) {
        errorMessage = 'Firestore permission denied. Check security rules.';
      } else if (e.toString().contains('network') || e.toString().contains('UNAVAILABLE')) {
        errorMessage = 'Network error. Check your internet connection.';
      }
      
      SnackbarService.to.showError(
        'Error',
        errorMessage,
      );
    }
  }

  /// Determine invoice status based on payment status
  String _determineInvoiceStatus() {
    if (isPaid.value) {
      return 'Paid';
    } else {
      // If due date is set and hasn't passed, it's Pending
      if (dueDate.value != null && dueDate.value!.isAfter(DateTime.now())) {
        return 'Pending';
      }
      // If due date is set and has passed, it's Pending (overdue)
      if (dueDate.value != null && dueDate.value!.isBefore(DateTime.now())) {
        return 'Pending';
      }
      // If no due date but not paid, default to Pending
      return 'Pending';
    }
  }
  
  /// Select due date (called from UI)
  Future<void> selectDueDate() async {
    final picked = await showDatePicker(
      context: Get.context!,
      initialDate: dueDate.value ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      dueDate.value = picked;
      _checkForChanges();
    }
  }

  @override
  void onClose() {
    supplierController.dispose();
    invoiceNumberController.dispose();
    notesController.dispose();
    netAmountController.dispose();
    additionalChargesController.dispose();
    super.onClose();
  }
}
