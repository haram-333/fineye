import 'dart:convert';
import 'dart:io' if (dart.library.html) 'package:fineye/presentation/controllers/file_stub.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../data/models/invoice_model.dart';
import '../../../data/repositories/user_invoice_repository.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/snackbar_service.dart';
import '../../../core/services/notification_helper.dart';

class OCRPreviewController extends GetxController {
  final UserInvoiceRepository _userInvoiceRepository = UserInvoiceRepository();

  // Passed invoice from list (optional)
  Invoice? invoice;

  /// Optional Firestore document id when editing an existing user invoice.
  /// When creating a new invoice from OCR this will be generated at save time.
  String? invoiceDocId;

  /// Optional file of the original (or preprocessed) invoice image.
  /// Used to upload to Firebase Storage when saving a new invoice.
  File? invoiceImageFile;

  // Raw OCR text
  final RxString rawOcrText = ''.obs;

  // Text Controllers
  // Text Controllers
  final TextEditingController supplierController = TextEditingController();
  final TextEditingController invoiceNumberController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController rawJsonController = TextEditingController();
  
  // Dynamic Fields
  final RxMap<String, String> additionalFields = <String, String>{}.obs;
  // Map to hold controllers for dynamic fields so we can edit them
  final Map<String, TextEditingController> pAdditionalControllers = {};

  // Reactive Variables
  final Rx<DateTime> invoiceDate = DateTime.now().obs;
  final RxString selectedCategory = 'Office supplies'.obs;

  // VAT Calculation Variables
  final RxBool isVatInclusive = true.obs;
  final RxBool isPurchase = true.obs; // true = Purchase (Input VAT), false = Sales (Output VAT)
  final RxDouble netAmount = 0.0.obs;
  final RxDouble vatAmount = 0.0.obs;
  final RxDouble grossAmount = 0.0.obs;
  final RxDouble additionalCharges = 0.0.obs; // Delivery, service charges, etc.

  // Validation & Warnings
  final RxBool vatValid = true.obs;
  final RxBool isDuplicate = false.obs;
  final RxList<String> missingFields = <String>[].obs;
  final RxBool isCtDeductible = true.obs;
  
  // Saving state
  final RxBool isSaving = false.obs;

  // Risk flags
  final RxList<InvoiceRisk> risks = <InvoiceRisk>[].obs;
  
  // Flag to track if we trusted AI data
  bool isExtractedDataLoaded = false;

  // Store extracted data for passing to invoice details
  dynamic storedExtractedData;

  // Categories
  final List<String> categories = [
    'Office supplies',
    'Utilities',
    'Transport',
    'Subscriptions',
    'Marketing',
    'Professional fees',
    'Rent',
    'Other',
  ];

  @override
  void onInit() {
    super.onInit();

    // Get invoice or raw OCR text from arguments
    print('📥 OCR Preview: Received arguments: ${Get.arguments != null}');
    if (Get.arguments != null) {
      print('📥 OCR Preview: Arguments type: ${Get.arguments.runtimeType}');
      
      if (Get.arguments is Invoice) {
        print('📥 OCR Preview: Arguments is Invoice');
        invoice = Get.arguments as Invoice;
        _loadInvoiceData();
      } else if (Get.arguments is Map) {
        final args = Get.arguments as Map;
        print('📥 OCR Preview: Arguments is Map with keys: ${args.keys}');

        // Capture image file when provided (mobile only).
        if (args['file'] != null && args['file'] is File) {
          invoiceImageFile = args['file'] as File;
          print('📸 OCR Preview: Received image file: ${invoiceImageFile!.path}');
        }

        // Capture existing invoice doc id when editing an existing user invoice.
        if (args['invoiceDocId'] != null && args['invoiceDocId'] is String) {
          invoiceDocId = args['invoiceDocId'] as String;
          print('🆔 OCR Preview: Received existing invoiceDocId: $invoiceDocId');
        }
        
        // Check if raw OCR text is provided
        if (args['rawOcrText'] != null) {
          final text = args['rawOcrText'] as String? ?? '';
          print('✅ OCR Preview: Loading raw OCR text (${text.length} characters)');
          rawOcrText.value = text;
        } else {
          print('⚠️ OCR Preview: No rawOcrText in arguments');
        }
        
        // Check if structured extracted data is provided
        if (args['extractedData'] != null) {
          print('✅ OCR Preview: Loading structured extracted data');
          storedExtractedData = args['extractedData'];
          _loadExtractedData(args['extractedData']);
          isExtractedDataLoaded = true;
        }
        
        // Check if invoice is provided (for editing existing invoice)
        if (args['invoice'] != null && args['invoice'] is Invoice) {
          print('📥 OCR Preview: Found invoice in arguments');
          invoice = args['invoice'] as Invoice;
          _loadInvoiceData();
        }
      } else {
        print('⚠️ OCR Preview: Arguments is neither Invoice nor Map');
      }
    } else {
      print('⚠️ OCR Preview: No arguments provided - manual entry mode');
    }

    // Only parse raw text if we DID NOT load structured data
    // This prevents "rule-based shit" from overwriting valid AI data
    if (rawOcrText.value.isNotEmpty && !isExtractedDataLoaded) {
      print('🔍 OCR Preview: Parsing amounts from raw OCR text (Rule-based fallback)...');
      _parseRawTextToFields(rawOcrText.value);
      print('🔍 OCR Preview: After parsing - Net: ${netAmount.value}, VAT: ${vatAmount.value}, Gross: ${grossAmount.value}');
    }

    // Watchers for auto-calculation
    ever(isVatInclusive, (_) => calculateVAT());
    ever(netAmount, (_) => calculateVAT());
    ever(additionalCharges, (_) => calculateVAT());
  }

  void _loadInvoiceData() {
    if (invoice == null) return;
    
    supplierController.text = invoice!.supplierName;
    invoiceNumberController.text = invoice!.id;
    notesController.text = invoice?.notes ?? '';
    invoiceDate.value = invoice!.date;
    selectedCategory.value = invoice!.category;
    grossAmount.value = invoice!.grossAmount;
    vatAmount.value = invoice!.vatAmount;
    isCtDeductible.value = invoice!.isCtDeductible;

    // Calculate net from existing data
    netAmount.value = grossAmount.value - vatAmount.value;

    // Seed existing risks from invoice, then run local checks
    risks.assignAll(invoice!.risks);
    _checkDuplicate();
    _validateFields();
    _validateVAT();
  }
  
  /// Load structured data from ExtractedInvoiceData
  void _loadExtractedData(dynamic extractedData) {
    if (extractedData == null) return;
    
    try {
      // Extract supplier name
      if (extractedData.supplierName?.value != null) {
        supplierController.text = extractedData.supplierName.value;
        print('✅ Loaded supplier: ${extractedData.supplierName.value}');
      }
      
      // Extract invoice number
      if (extractedData.invoiceNumber?.value != null) {
        invoiceNumberController.text = extractedData.invoiceNumber.value;
        print('✅ Loaded invoice number: ${extractedData.invoiceNumber.value}');
      }
      
      // Extract invoice date
      if (extractedData.invoiceDate?.value != null) {
        invoiceDate.value = extractedData.invoiceDate.value;
        print('✅ Loaded invoice date: ${extractedData.invoiceDate.value}');
      }
      
      // Extract amounts
      if (extractedData.grossAmount != null) {
        grossAmount.value = extractedData.grossAmount;
        print('✅ Loaded gross amount: ${extractedData.grossAmount}');
      }
      
      if (extractedData.netAmount != null) {
        netAmount.value = extractedData.netAmount;
        print('✅ Loaded net amount: ${extractedData.netAmount}');
      }
      
      if (extractedData.vatAmount != null) {
        vatAmount.value = extractedData.vatAmount;
        print('✅ Loaded VAT amount: ${extractedData.vatAmount}');
      }
      
      // Load additional dynamic fields
      additionalFields.clear();
      pAdditionalControllers.clear();
      
      final handledTypes = [
        'supplier_name', 'supplier',
        'invoice_id', 'invoice_number',
        'invoice_date', 'date',
        'total_amount', 'total', 'gross_amount',
        'net_amount', 'net',
        'tax_amount', 'vat_amount', 'vat'
      ];

      if (extractedData.rawEntities.isNotEmpty) {
        // 1. Populate Dynamic Fields
        extractedData.rawEntities.forEach((key, value) {
          // Normalize key to check against handled types
          if (!handledTypes.contains(key) && value != null) {
            final valStr = value.toString();
            additionalFields[key] = valStr;
            pAdditionalControllers[key] = TextEditingController(text: valStr);
            print('✅ Loaded additional field: $key = $valStr');
          }
        });

        // 2. Populate Raw JSON View for debugging/verification
        // Using 2 spaces indentation for readability
        const JsonEncoder encoder = JsonEncoder.withIndent('  ');
        rawJsonController.text = encoder.convert(extractedData.rawEntities);
      }
      
      // Auto-calculate if needed
      calculateVAT();
    } catch (e, stackTrace) {
      print('❌❌❌ OCR PREVIEW: ERROR LOADING EXTRACTED DATA ❌❌❌');
      print('❌ Error Type: ${e.runtimeType}');
      print('❌ Error Message: $e');
      print('❌ Stack Trace:');
      print(stackTrace);
      debugPrint('❌❌❌ OCR PREVIEW: ERROR LOADING EXTRACTED DATA ❌❌❌');
      debugPrint('❌ Error Type: ${e.runtimeType}');
      debugPrint('❌ Error Message: $e');
      debugPrint('❌ Stack Trace: $stackTrace');
    }
  }
  
  /// Try to parse raw text and extract fields using regex
  void _parseRawTextToFields(String text) {
    // Simple regex-based extraction as fallback
    // Supplier name - first substantial line
    final supplierMatch = RegExp(r'(?:Supplier|Vendor|From|المورد)\s*:?\s*(.+?)(?:\n|$)', caseSensitive: false).firstMatch(text);
    if (supplierMatch != null && supplierController.text.isEmpty) {
      supplierController.text = supplierMatch.group(1)?.trim() ?? '';
    }
    
    // Invoice number
    final invoiceMatch = RegExp(r'(?:Invoice\s*#?|INV|رقم\s*الفاتورة)\s*:?\s*([A-Z0-9\-]+)', caseSensitive: false).firstMatch(text);
    if (invoiceMatch != null && invoiceNumberController.text.isEmpty) {
      invoiceNumberController.text = invoiceMatch.group(1)?.trim() ?? '';
    }
    
    // Amounts: work line-by-line so we can handle labels on one line
    // and the number on the next line, as in many POS receipts.
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    double? findAmountAfterLabel(List<String> labels, {bool fromEnd = false}) {
      final numberRegex = RegExp(r'(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?|\d+\.\d{1,2})');
      final indices = List<int>.generate(lines.length, (i) => i);
      final it = fromEnd ? indices.reversed : indices;

      for (final i in it) {
        final lower = lines[i].toLowerCase();
        if (labels.any((label) => lower.contains(label.toLowerCase()))) {
          // Try same line first - look for decimal numbers (amounts, not quantities)
          final sameLineMatches = numberRegex.allMatches(lines[i]);
          // Prefer decimal numbers (likely amounts) over integers (likely quantities)
          for (final match in sameLineMatches) {
            final value = double.tryParse(match.group(1)!.replaceAll(',', ''));
            if (value != null && value > 0) {
              // If it's a decimal or > 1, it's likely an amount
              if (value.toString().contains('.') || value > 1) {
                return value;
              }
            }
          }
          
          // Then look ahead for the first substantial number (decimal or > 1)
          // Skip small integers (likely quantities like "1", "2")
          for (var j = i + 1; j < lines.length && j <= i + 5; j++) {
            final matches = numberRegex.allMatches(lines[j]);
            for (final m in matches) {
              final value = double.tryParse(m.group(1)!.replaceAll(',', ''));
              if (value != null && value > 0) {
                // Prefer decimal numbers or numbers > 1 (amounts, not quantities)
                if (value.toString().contains('.') || value > 1) {
                  return value;
                }
              }
            }
          }
        }
      }
      return null;
    }

    // 1) Net amount from "Total before VAT", "Net Amount", etc.
    // Always try to extract from invoice text, even if value is already set
    final net = findAmountAfterLabel([
      'total before vat',
      'net amount',
      'amount excl',
      'الصافي',
    ]);
    if (net != null && net > 0) {
      print('✅ Parsed Net Amount from invoice: $net');
      netAmount.value = net;
    } else {
      print('⚠️ Could not find Net Amount in invoice text');
    }

    // 2) VAT amount from "VAT incl." / "VAT amount" etc.
    // Always try to extract from invoice text, even if value is already set
    final vat = findAmountAfterLabel([
      'vat incl',
      'vat amount',
      'value added tax',
      'ضريبة القيمة المضافة',
      'ضريبة',
    ]);
    if (vat != null && vat > 0) {
      print('✅ Parsed VAT Amount from invoice: $vat');
      vatAmount.value = vat;
    } else {
      print('⚠️ Could not find VAT Amount in invoice text');
    }

    // 3) Gross amount from "Grand Total" / "Total" labels
    // Always try to extract from invoice text, even if value is already set
    final gross = findAmountAfterLabel(
      [
        'grand total',
        'total amount',
        'total',
        'gross',
        'المجموع',
      ],
      fromEnd: true,
    );
    if (gross != null && gross > 0) {
      print('✅ Parsed Gross Amount from invoice: $gross');
      grossAmount.value = gross;
    } else {
      print('⚠️ Could not find Gross Amount in invoice text');
    }

    // 4) POS-style fallback for receipts like Sweet Burger:
    // Find the three totals that appear after "Total before VAT", "VAT incl.", "Grand Total"
    // The key is to find numbers that appear right after these labels, not item prices
    final lowerText = text.toLowerCase();
    if (lowerText.contains('total before vat') &&
        lowerText.contains('grand total')) {
      // Find the section starting from "Total before VAT"
      final totalsStartIndex = lowerText.indexOf('total before vat');
      final totalsSection = text.substring(totalsStartIndex);
      final totalsLines = totalsSection
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      
      final numberRegex = RegExp(r'(\d{1,3}(?:,\d{3})*(?:\.\d{1,2})?|\d+\.\d{1,2})');
      
      // Find the three totals by looking for numbers that appear after each label
      double? foundNet, foundVat, foundGross;
      
      for (int i = 0; i < totalsLines.length; i++) {
        final line = totalsLines[i].toLowerCase();
        
        // Find Net (Total before VAT)
        if (line.contains('total before vat') && foundNet == null) {
          // Look on same line or next 2 lines for a substantial number
          for (int j = i; j < totalsLines.length && j <= i + 2; j++) {
            final matches = numberRegex.allMatches(totalsLines[j]);
            for (final m in matches) {
              final value = double.tryParse(m.group(1)!.replaceAll(',', ''));
              // Net should be a substantial amount (typically > 10 for invoices)
              if (value != null && value >= 10) {
                foundNet = value;
                print('🔍 POS: Found Net = $value after "Total before VAT"');
                break;
              }
            }
            if (foundNet != null) break;
          }
        }
        
        // Find VAT (VAT incl.)
        if ((line.contains('vat incl') || line.contains('vat amount')) && foundVat == null) {
          for (int j = i; j < totalsLines.length && j <= i + 2; j++) {
            final matches = numberRegex.allMatches(totalsLines[j]);
            for (final m in matches) {
              final value = double.tryParse(m.group(1)!.replaceAll(',', ''));
              // VAT should be > 0 but typically < gross
              if (value != null && value > 0 && value < (foundGross ?? 1000)) {
                foundVat = value;
                print('🔍 POS: Found VAT = $value after "VAT incl"');
                break;
              }
            }
            if (foundVat != null) break;
          }
        }
        
        // Find Gross (Grand Total)
        if (line.contains('grand total') && foundGross == null) {
          for (int j = i; j < totalsLines.length && j <= i + 2; j++) {
            final matches = numberRegex.allMatches(totalsLines[j]);
            for (final m in matches) {
              final value = double.tryParse(m.group(1)!.replaceAll(',', ''));
              // Gross should be the largest, typically > net
              if (value != null && value > 0 && value >= (foundNet ?? 0)) {
                foundGross = value;
                print('🔍 POS: Found Gross = $value after "Grand Total"');
                break;
              }
            }
            if (foundGross != null) break;
          }
        }
      }
      
      // Apply the found values
      if (foundNet != null || foundVat != null || foundGross != null) {
        print('🔄 POS fallback results: net=$foundNet, vat=$foundVat, gross=$foundGross');
        print('🔄 Current values: net=${netAmount.value}, vat=${vatAmount.value}, gross=${grossAmount.value}');
        
        if (foundNet != null && (netAmount.value == 0.0 || netAmount.value < 1.0 || (netAmount.value != foundNet && foundNet > 10))) {
          print('✅ Using POS fallback for Net: $foundNet');
          netAmount.value = foundNet;
        }
        if (foundVat != null && (vatAmount.value == 0.0 || vatAmount.value < 0.1 || (vatAmount.value != foundVat && foundVat > 0))) {
          print('✅ Using POS fallback for VAT: $foundVat');
          vatAmount.value = foundVat;
        }
        if (foundGross != null && (grossAmount.value == 0.0 || grossAmount.value < 1.0 || (grossAmount.value != foundGross && foundGross > 10))) {
          print('✅ Using POS fallback for Gross: $foundGross');
          grossAmount.value = foundGross;
        }
      } else {
        print('⚠️ POS fallback: Could not find all three totals');
      }
    }

    // Invoice date: always prefer a date parsed from the invoice text itself.
    final datePatterns = <RegExp>[
      // 13-Dec-25 or 13-Dec-2025
      RegExp(
        r'\b(\d{1,2})[-](Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*[-](\d{2,4})\b',
        caseSensitive: false,
      ),
      // 13/12/2025 or 13-12-25
      RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})\b'),
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          DateTime parsed;
          if (pattern.pattern.contains('Jan|Feb|Mar')) {
            final day = int.parse(match.group(1)!);
            final monthStr = match.group(2)!;
            final yearRaw = int.parse(match.group(3)!);
            final month = const {
              'jan': 1,
              'feb': 2,
              'mar': 3,
              'apr': 4,
              'may': 5,
              'jun': 6,
              'jul': 7,
              'aug': 8,
              'sep': 9,
              'oct': 10,
              'nov': 11,
              'dec': 12,
            }[monthStr.toLowerCase()]!;
            final year = yearRaw < 100 ? (yearRaw < 50 ? 2000 + yearRaw : 1900 + yearRaw) : yearRaw;
            parsed = DateTime(year, month, day);
          } else {
            final part1 = int.parse(match.group(1)!);
            final part2 = int.parse(match.group(2)!);
            final part3 = int.parse(match.group(3)!);
            // Assume DD/MM/YYYY
            final year = part3 < 100 ? (part3 < 50 ? 2000 + part3 : 1900 + part3) : part3;
            parsed = DateTime(year, part2, part1);
          }
          invoiceDate.value = parsed;
          break;
        } catch (_) {
          // Ignore and try next pattern
        }
      }
    }
    
    calculateVAT();
  }

  @override
  void onClose() {
    supplierController.dispose();
    invoiceNumberController.dispose();
    notesController.dispose();
    super.onClose();
  }

  void calculateVAT() {
    // Always calculate VAT from Net Amount (5% of net)
    // Round VAT to 2 decimal places (e.g., 4.095 → 4.10)
    if (netAmount.value > 0) {
      final calculatedVat = netAmount.value * 0.05;
      // Round to 2 decimals: multiply by 100, round, divide by 100
      vatAmount.value = (calculatedVat * 100).roundToDouble() / 100;
      
      // Gross = Net + VAT + Additional Charges
      grossAmount.value = netAmount.value + vatAmount.value + additionalCharges.value;
    } else {
      // If net is 0, reset VAT and Gross
      vatAmount.value = 0.0;
      grossAmount.value = additionalCharges.value;
    }

    _validateVAT();
  }

  void _validateVAT() {
    // Check if VAT is approximately 5% of net amount (allowing small rounding errors)
    if (netAmount.value > 0) {
      double expectedVat = netAmount.value * 0.05;
      double difference = (vatAmount.value - expectedVat).abs();
      vatValid.value = difference < 0.01; // Allow 1 cent tolerance

      // Maintain VAT mismatch risk
      _setRisk(
        InvoiceRiskType.vatMismatch,
        !vatValid.value,
        severity: InvoiceRiskSeverity.warning,
      );
    } else {
      vatValid.value = true;
      _setRisk(InvoiceRiskType.vatMismatch, false);
    }
  }

  void _checkDuplicate() {
    // Reuse incoming duplicate risk if present; otherwise simple heuristic
    final hasIncomingDuplicate =
        invoice?.risks.any((r) => r.type == InvoiceRiskType.duplicateInvoice) ?? false;

    final bool detectedDuplicate =
        hasIncomingDuplicate || grossAmount.value > 10000;

    isDuplicate.value = detectedDuplicate;
    _setRisk(
      InvoiceRiskType.duplicateInvoice,
      detectedDuplicate,
      severity: InvoiceRiskSeverity.high,
    );
  }

  void _validateFields() {
    missingFields.clear();

    if (supplierController.text.isEmpty) {
      missingFields.add('Supplier');
    }
    if (invoiceNumberController.text.isEmpty) {
      missingFields.add('Invoice Number');
    }
    if (grossAmount.value <= 0) {
      missingFields.add('Amount');
    }

    // Example: mark missing TRN as a risk if supplier name contains "LLC" but we have no TRN stored
    final bool missingTrn = supplierController.text.contains('LLC') &&
        !(invoice?.notes.toLowerCase().contains('trn') ?? false);
    _setRisk(
      InvoiceRiskType.missingTrn,
      missingTrn,
      severity: InvoiceRiskSeverity.warning,
    );
  }

  void _setRisk(InvoiceRiskType type, bool active,
      {InvoiceRiskSeverity severity = InvoiceRiskSeverity.warning}) {
    final existingIndex =
        risks.indexWhere((r) => r.type == type);

    if (active) {
      final risk = InvoiceRisk(type: type, severity: severity);
      if (existingIndex == -1) {
        risks.add(risk);
      } else {
        risks[existingIndex] = risk;
      }
    } else if (existingIndex != -1) {
      risks.removeAt(existingIndex);
    }
  }

  Future<void> selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: invoiceDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      invoiceDate.value = picked;
    }
  }

  void showReviewSummary() {
    Get.dialog(
      AlertDialog(
        title: Text('review_invoice_title'.tr),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _summaryRow('supplier'.tr, supplierController.text),
              _summaryRow('invoice_number_short'.tr, invoiceNumberController.text),
              _summaryRow('invoice_date'.tr, invoiceDate.value.toString().split(' ')[0]),
              _summaryRow('category'.tr, selectedCategory.value),
              const Divider(),
              _summaryRow('net_amount'.tr, 'AED ${netAmount.value.toStringAsFixed(2)}'),
              _summaryRow('vat_amount'.tr, 'AED ${vatAmount.value.toStringAsFixed(2)}'),
              _summaryRow('gross_amount'.tr, 'AED ${grossAmount.value.toStringAsFixed(2)}'),
              const Divider(),
              _summaryRow('vat_type_label'.tr, isVatInclusive.value ? 'vat_inclusive_option'.tr : 'vat_exclusive_option'.tr),
              _summaryRow('invoice_type_label'.tr, isPurchase.value ? 'purchase_input_vat'.tr : 'sales_output_vat'.tr),
              _summaryRow('ct_deductible_label'.tr, isCtDeductible.value ? 'lbl_yes'.tr : 'lbl_no'.tr),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('btn_back'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              saveInvoice();
            },
            child: Text('btn_confirm_save'.tr),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }

  Future<void> saveInvoice() async {
    // This method is no longer used - InvoiceDetailsController handles saving
    SnackbarService.to.showInfo(
      'title_info'.tr,
      'msg_use_save_button'.tr,
    );
    return;
  }
  
  // OLD SAVE CODE - NO LONGER USED
  /*
  Future<void> _saveInvoiceOld() async {
    // Prevent multiple simultaneous saves
    if (isSaving.value) {
      return;
    }
    
    _validateFields();

    if (missingFields.isNotEmpty) {
      SnackbarService.to.showError(
        'validation_failed'.tr,
        missingFields.join(', '),
      );
      return;
    }

    // Ensure user is authenticated
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      SnackbarService.to.showError(
        'auth_required'.tr,
        'please_login_to_save_invoice'.tr,
      );
      return;
    }

    isSaving.value = true;
    
    try {
      SnackbarService.to.showInfo(
        'saving_invoice'.tr,
        'saving_invoice_to_database'.tr,
        duration: const Duration(seconds: 2),
      );

      // 1) Prepare base invoice data from current form state
      final now = DateTime.now();
      final baseInvoice = Invoice(
        id: invoiceNumberController.text.isNotEmpty
            ? invoiceNumberController.text
            : 'INV-${now.millisecondsSinceEpoch}',
        supplierName: supplierController.text,
        category: selectedCategory.value,
        date: invoiceDate.value,
        grossAmount: grossAmount.value,
        vatAmount: vatAmount.value,
        additionalCharges: additionalCharges.value,
        status: invoice?.status ?? 'Pending',
        taxBadge: invoice?.taxBadge ?? 'VAT 5%',
        notes: notesController.text,
        isCtDeductible: isCtDeductible.value,
        vatActivity: invoice?.vatActivity ?? 'Low',
        userId: currentUser.uid,
        imageUrl: null,
        risks: risks.toList(),
        isFlagged: invoice?.isFlagged.value ?? false,
      );

      // 2) Generate/resolve Firestore document id.
      // If we're editing an existing user invoice and already know its docId, reuse it.
      // Otherwise, pre-create a doc ref so we can align storage path with doc id.
      final firestore = FirebaseFirestore.instance;
      final collectionRef = firestore.collection('user_invoices');
      final docRef = invoiceDocId != null
          ? collectionRef.doc(invoiceDocId)
          : collectionRef.doc();
      final docId = docRef.id;

      String? imageUrl;

      // 3) Upload image to Firebase Storage if we have one and we're not on web.
      if (invoiceImageFile != null && !kIsWeb) {
        try {
          final storage = FirebaseStorage.instance;
          final storageRef = storage.ref().child(
              'user_invoices/${currentUser.uid}/$docId.jpg');
          print(
              '📤 OCR Preview: Uploading image to Firebase Storage at ${storageRef.fullPath}');
          // On mobile, cast to dart:io File
          final ioFile = invoiceImageFile as dynamic;
          final uploadTask = await storageRef.putFile(ioFile);
          imageUrl = await uploadTask.ref.getDownloadURL();
          print('✅ OCR Preview: Image uploaded. URL: $imageUrl');
        } catch (e, stack) {
          print('❌ OCR Preview: Failed to upload image: $e');
          print('❌ Stack trace: $stack');
          // Continue without image; user still gets saved invoice.
          imageUrl = null;
        }
      } else if (invoiceImageFile != null && kIsWeb) {
        // On web, we can't use putFile, skip image upload for now
        // TODO: Implement web image upload using bytes if needed
        print('⚠️ OCR Preview: Image upload skipped on web platform');
        imageUrl = null;
      }

      // 4) Persist invoice to Firestore in `user_invoices` with aligned docId.
      // Set firestoreDocId so the invoice object knows its Firestore document ID
      final invoiceToSave = baseInvoice.copyWith(
        imageUrl: imageUrl,
        firestoreDocId: docId,
      );

      // Log the data we're about to save
      print('🔥 OCR Preview: About to save invoice to Firestore');
      print('🔥 Collection: user_invoices');
      print('🔥 Document ID: $docId');
      print('🔥 User ID: ${currentUser.uid}');
      print('🔥 Invoice ID: ${invoiceToSave.id}');
      print('🔥 Supplier: ${invoiceToSave.supplierName}');
      
      // Convert to map and log it
      final invoiceMap = invoiceToSave.toMap();
      print('🔥 Invoice map keys: ${invoiceMap.keys.toList()}');
      print('🔥 Invoice map size: ${invoiceMap.length} fields');
      
      try {
        print('🔥 Attempting Firestore write to ${docRef.path}...');
        await docRef.set(invoiceMap);
        print('✅✅✅ OCR Preview: Firestore write SUCCESSFUL ✅✅✅');
        print('✅ Document path: ${docRef.path}');
      } catch (firestoreError, firestoreStack) {
        print('❌❌❌ FIRESTORE WRITE FAILED ❌❌❌');
        print('❌ Error Type: ${firestoreError.runtimeType}');
        print('❌ Error: $firestoreError');
        print('❌ Stack: $firestoreStack');
        rethrow; // Re-throw so outer catch can handle it
      }

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
        print('✅ OCR Preview: Notification created for new invoice');
      } catch (notifError) {
        print('⚠️ OCR Preview: Failed to create notification: $notifError');
        // Don't fail the save if notification fails
      }

      // Show success
      SnackbarService.to.showSuccess(
        'ocr_success_title'.tr,
        'ocr_success_message'.trParams({'count': extractedCount.toString()}),
      );

      // 5) Navigate directly to full Invoice Details screen for this invoice.
      // We pass both the Invoice object, Firestore docId, AND the extracted data
      // so InvoiceDetailsController can auto-populate form fields
      Get.offNamed(
        AppRoutes.invoiceDetails,
        arguments: {
          'invoice': invoiceToSave,
          'invoiceDocId': docId,
          // Pass extracted data for auto-population
          'extractedData': storedExtractedData,
          'rawOcrText': rawOcrText.value, // Pass raw text for fallback parsing
          // Also pass file info for image upload
          'file': invoiceImageFile,
          'imageBytes': null, // Web support
        },
      );
    } catch (e, stackTrace) {
      print('❌❌❌ OCR PREVIEW: ERROR SAVING INVOICE ❌❌❌');
      print('❌ Error Type: ${e.runtimeType}');
      print('❌ Error Message: $e');
      print('❌ Stack Trace:');
      print(stackTrace);
      print('❌ Invoice Doc ID: $invoiceDocId');
      print('❌ Invoice: ${invoice?.id ?? "null"}');
      debugPrint('❌❌❌ OCR PREVIEW: ERROR SAVING INVOICE ❌❌❌');
      debugPrint('❌ Error Type: ${e.runtimeType}');
      debugPrint('❌ Error Message: $e');
      debugPrint('❌ Stack Trace: $stackTrace');
      
      // Show more detailed error to user
      String errorMessage = 'failed_to_save_invoice'.tr;
      if (e.toString().contains('permission') || e.toString().contains('PERMISSION_DENIED')) {
        errorMessage = 'Firestore permission denied. Check security rules.';
      } else if (e.toString().contains('network') || e.toString().contains('UNAVAILABLE')) {
        errorMessage = 'Network error. Check your internet connection.';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }
      
      SnackbarService.to.showError(
        'error'.tr,
        errorMessage,
      );
    } finally {
      isSaving.value = false;
    }
  }
  */

  void updateGrossAmount(String value) {
    grossAmount.value = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
  }

  void updateNetAmount(String value) {
    netAmount.value = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
  }

  void updateAdditionalCharges(String value) {
    additionalCharges.value = double.tryParse(value.replaceAll(',', '')) ?? 0.0;
  }
}
