import 'ocr_service.dart';
import 'dart:math' as math;

/// Service for extracting structured invoice data from OCR text
/// Handles Arabic and English text, multiple invoice formats
class InvoiceDataExtractor {
  /// Extract invoice data from OCR result
  Future<ExtractedInvoiceData> extractInvoiceData(OCRResult ocrResult) async {
    if (!ocrResult.hasText) {
      return ExtractedInvoiceData.empty();
    }

    final fullText = ocrResult.fullText;
    final lines = ocrResult.lines.map((l) => l.text).toList();

    // Extract each field using multiple strategies
    final supplierName = _extractSupplierName(fullText, lines);
    final invoiceNumber = _extractInvoiceNumber(fullText, lines);
    final invoiceDate = _extractInvoiceDate(fullText, lines);
    final amounts = _extractAmounts(fullText, lines);
    final vatAmount = _extractVATAmount(fullText, lines, amounts.netAmount);

    // Calculate confidence for each field
    final supplierConfidence = supplierName.value != null ? 0.8 : 0.0;
    final invoiceNumberConfidence = invoiceNumber.value != null ? 0.8 : 0.0;
    final dateConfidence = invoiceDate.value != null ? 0.8 : 0.0;

    return ExtractedInvoiceData(
      supplierName: ExtractedField<String>(
        value: supplierName.value,
        confidence: supplierConfidence,
        rawText: supplierName.rawText,
      ),
      invoiceNumber: ExtractedField<String>(
        value: invoiceNumber.value,
        confidence: invoiceNumberConfidence,
        rawText: invoiceNumber.rawText,
      ),
      invoiceDate: ExtractedField<DateTime>(
        value: invoiceDate.value,
        confidence: dateConfidence,
        rawText: invoiceDate.rawText,
      ),
      netAmount: amounts.netAmount,
      vatAmount: vatAmount,
      grossAmount: amounts.grossAmount,
      overallConfidence: ocrResult.confidence,
    );
  }

  /// Extract supplier name using multiple patterns
  ExtractedField<String> _extractSupplierName(String fullText, List<String> lines) {
    // Pattern 1: Look for "Supplier:" or "المورد" label
    final supplierPatterns = [
      RegExp(r'(?:Supplier|Vendor|From|From:)\s*:?\s*(.+?)(?:\n|$)', caseSensitive: false),
      RegExp(r'المورد\s*:?\s*(.+?)(?:\n|$)'),
      RegExp(r'اسم\s*المورد\s*:?\s*(.+?)(?:\n|$)'),
    ];

    for (final pattern in supplierPatterns) {
      final match = pattern.firstMatch(fullText);
      if (match != null && match.group(1) != null) {
        final value = match.group(1)!.trim();
        if (value.isNotEmpty && value.length > 2) {
          return ExtractedField(value: value, rawText: value);
        }
      }
    }

    // Pattern 2: Look for company indicators in first few lines
    final companyIndicators = ['LLC', 'Ltd', 'Inc', 'شركة', 'مؤسسة', 'L.L.C'];
    for (int i = 0; i < math.min(5, lines.length); i++) {
      final line = lines[i].trim();
      if (line.length > 5 && line.length < 100) {
        final lineLower = line.toLowerCase();
        for (final indicator in companyIndicators) {
          if (lineLower.contains(indicator.toLowerCase())) {
            return ExtractedField(value: line, rawText: line);
          }
        }
      }
    }

    // Pattern 3: First substantial line (usually company name)
    for (int i = 0; i < math.min(3, lines.length); i++) {
      final line = lines[i].trim();
      if (line.length > 5 && line.length < 100 && !_isNumeric(line)) {
        return ExtractedField(value: line, rawText: line);
      }
    }

    return ExtractedField.empty();
  }

  /// Extract invoice number using multiple patterns
  ExtractedField<String> _extractInvoiceNumber(String fullText, List<String> lines) {
    // Pattern 1: Common invoice number formats
    final invoicePatterns = [
      RegExp(r'(?:Invoice\s*#?|INV|Invoice\s*Number|رقم\s*الفاتورة)\s*:?\s*([A-Z0-9\-]+)', caseSensitive: false),
      RegExp(r'INV-?(\d+)', caseSensitive: false),
      RegExp(r'#\s*(\d+)'),
      RegExp(r'Invoice\s*:?\s*(\d+)', caseSensitive: false),
    ];

    for (final pattern in invoicePatterns) {
      final match = pattern.firstMatch(fullText);
      if (match != null && match.group(1) != null) {
        final value = match.group(1)!.trim();
        if (value.isNotEmpty) {
          return ExtractedField(value: value, rawText: value);
        }
      }
    }

    // Pattern 2: Look for standalone numbers that could be invoice numbers
    for (final line in lines) {
      final numberMatch = RegExp(r'\b([A-Z]{2,4}-?\d{4,})\b').firstMatch(line);
      if (numberMatch != null) {
        return ExtractedField(value: numberMatch.group(1)!, rawText: line);
      }
    }

    return ExtractedField.empty();
  }

  /// Extract invoice date using multiple date formats
  ExtractedField<DateTime> _extractInvoiceDate(String fullText, List<String> lines) {
    // Date patterns (English and Arabic formats)
    final datePatterns = [
      // DD/MM/YYYY or DD-MM-YYYY
      RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})\b'),
      // YYYY/MM/DD
      RegExp(r'\b(\d{4})[/-](\d{1,2})[/-](\d{1,2})\b'),
      // DD MMM YYYY
      RegExp(r'\b(\d{1,2})\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*\s+(\d{4})\b', caseSensitive: false),
      // DD-MMM-YY or DD-MMM-YYYY (e.g. 13-Dec-25)
      RegExp(
        r'\b(\d{1,2})[-](Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\w*[-](\d{2,4})\b',
        caseSensitive: false,
      ),
      // Date label patterns
      RegExp(r'(?:Date|Invoice\s*Date|تاريخ)\s*:?\s*(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})', caseSensitive: false),
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(fullText);
      if (match != null) {
        try {
          DateTime? date;
          if (match.groupCount == 3) {
            final day = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final year = int.parse(match.group(3)!);
            final fullYear = year < 100 ? (year < 50 ? 2000 + year : 1900 + year) : year;
            
            // Validate date
            if (month >= 1 && month <= 12 && day >= 1 && day <= 31) {
              date = DateTime(fullYear, month, day);
              // Check if date is reasonable (not too far in past/future)
              final now = DateTime.now();
              if (date.isAfter(DateTime(2000)) && date.isBefore(DateTime(now.year + 1))) {
                return ExtractedField(value: date, rawText: match.group(0)!);
              }
            }
          }
        } catch (e) {
          // Continue to next pattern
        }
      }
    }

    return ExtractedField.empty();
  }

  /// Extract amounts (net, gross, VAT) from text
  ExtractedAmounts _extractAmounts(String fullText, List<String> lines) {
    double? netAmount;
    double? grossAmount;

    // 1) UAE-style labels: "Total before VAT", "VAT incl.", "Grand Total"
    final totalBeforeVatMatch = RegExp(
      r'(?:Total\s+before\s+VAT)\s*:?\s*(?:AED\s*)?([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(fullText);
    if (totalBeforeVatMatch != null) {
      netAmount = double.tryParse(
        totalBeforeVatMatch.group(1)!.replaceAll(',', ''),
      );
    }

    final grandTotalMatch = RegExp(
      r'(?:Grand\s+Total)\s*:?\s*(?:AED\s*)?([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(fullText);
    if (grandTotalMatch != null) {
      grossAmount = double.tryParse(
        grandTotalMatch.group(1)!.replaceAll(',', ''),
      );
    }

    // 2) Fallback: generic amount extraction if still missing
    if (grossAmount == null || netAmount == null) {
      final amountPatterns = [
        RegExp(r'(?:Total|Gross|Amount|المجموع|الإجمالي)\s*:?\s*(?:AED\s*)?([\d,]+\.?\d*)', caseSensitive: false),
        RegExp(r'AED\s*([\d,]+\.?\d*)', caseSensitive: false),
        RegExp(r'([\d,]+\.?\d*)\s*AED', caseSensitive: false),
        RegExp(r'([\d,]+\.?\d*)\s*درهم'),
      ];

      // Look for "Total" or "Gross" amount (usually largest)
      for (final pattern in amountPatterns) {
        final matches = pattern.allMatches(fullText);
        for (final match in matches) {
          if (match.group(1) != null) {
            final value = double.tryParse(match.group(1)!.replaceAll(',', ''));
            if (value != null && value > 0 && (grossAmount == null || value > grossAmount)) {
              grossAmount = value;
            }
          }
        }
      }

      // Look for "Subtotal" or "Net" amount
      final netPatterns = [
        RegExp(r'(?:Subtotal|Net|Sub-total|المجموع\s*الفرعي)\s*:?\s*(?:AED\s*)?([\d,]+\.?\d*)', caseSensitive: false),
      ];

      for (final pattern in netPatterns) {
        final match = pattern.firstMatch(fullText);
        if (match != null && match.group(1) != null) {
          final value = double.tryParse(match.group(1)!.replaceAll(',', ''));
          if (value != null && value > 0) {
            netAmount = value;
            break;
          }
        }
      }
    }

    // 3) If we still don't have explicit amounts, try a UAE-style fallback:
    //    take the last three monetary numbers in the text as:
    //    [net, vat, gross] in that order. This matches many small POS receipts.
    if (grossAmount == null || netAmount == null) {
      final allNumberMatches = RegExp(r'([\d]{1,3}(?:[\d,]*)(?:\.\d{1,2})?)')
          .allMatches(fullText)
          .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '')))
          .whereType<double>()
          .toList();

      if (allNumberMatches.length >= 3) {
        final last = allNumberMatches[allNumberMatches.length - 1];
        final thirdLast = allNumberMatches[allNumberMatches.length - 3];

        netAmount ??= thirdLast;
        grossAmount ??= last;
      }
    }

    // 4) Last resort: derive net from gross (assuming 5% VAT inclusive)
    if (netAmount == null && grossAmount != null) {
      netAmount = grossAmount / 1.05;
    }

    return ExtractedAmounts(
      netAmount: netAmount,
      grossAmount: grossAmount,
    );
  }

  /// Extract VAT amount
  double? _extractVATAmount(String fullText, List<String> lines, double? netAmount) {
    // 1) Prefer explicit VAT labels such as "VAT incl."
    final labeledVatMatch = RegExp(
      r'(?:VAT\s*incl\.?|VAT\s*amount|ضريبة\s*القيمة\s*المضافة)\s*:?\s*(?:AED\s*)?([\d,]+\.?\d*)',
      caseSensitive: false,
    ).firstMatch(fullText);
    if (labeledVatMatch != null && labeledVatMatch.group(1) != null) {
      final value = double.tryParse(labeledVatMatch.group(1)!.replaceAll(',', ''));
      if (value != null && value > 0) {
        return value;
      }
    }

    // 2) Generic VAT patterns
    final vatPatterns = [
      RegExp(r'(?:VAT|Tax|ضريبة)\s*(?:5%|5\s*%)?\s*:?\s*(?:AED\s*)?([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'5%\s*(?:VAT|Tax|ضريبة)\s*:?\s*(?:AED\s*)?([\d,]+\.?\d*)', caseSensitive: false),
    ];

    for (final pattern in vatPatterns) {
      final match = pattern.firstMatch(fullText);
      if (match != null && match.group(1) != null) {
        final value = double.tryParse(match.group(1)!.replaceAll(',', ''));
        if (value != null && value > 0) {
          return value;
        }
      }
    }

    // 3) Fallback: calculate VAT from net amount (5% of net)
    if (netAmount != null && netAmount > 0) {
      return netAmount * 0.05;
    }

    return null;
  }

  /// Check if string is primarily numeric
  bool _isNumeric(String text) {
    final numericCount = text.split('').where((c) => RegExp(r'\d').hasMatch(c)).length;
    return numericCount > text.length * 0.5;
  }
}

/// Extracted invoice data with confidence scores
class ExtractedInvoiceData {
  final ExtractedField<String> supplierName;
  final ExtractedField<String> invoiceNumber;
  final ExtractedField<DateTime> invoiceDate;
  final double? netAmount;
  final double? vatAmount;
  final double? grossAmount;
  final double overallConfidence;
  final Map<String, dynamic> rawEntities;

  ExtractedInvoiceData({
    required this.supplierName,
    required this.invoiceNumber,
    required this.invoiceDate,
    this.netAmount,
    this.vatAmount,
    this.grossAmount,
    required this.overallConfidence,
    this.rawEntities = const {},
  });

  factory ExtractedInvoiceData.empty() {
    return ExtractedInvoiceData(
      supplierName: ExtractedField.empty(),
      invoiceNumber: ExtractedField.empty(),
      invoiceDate: ExtractedField.empty(),
      overallConfidence: 0.0,
      rawEntities: const {},
    );
  }

  /// Get count of successfully extracted fields
  int get extractedFieldCount {
    int count = 0;
    if (supplierName.value != null) count++;
    if (invoiceNumber.value != null) count++;
    if (invoiceDate.value != null) count++;
    if (grossAmount != null) count++;
    if (vatAmount != null) count++;
    return count;
  }

  /// Check if extraction was successful
  bool get hasExtractedData => extractedFieldCount > 0;
}

/// Extracted field with confidence and raw text
class ExtractedField<T> {
  final T? value;
  final double confidence;
  final String? rawText;

  ExtractedField({
    this.value,
    this.confidence = 0.0,
    this.rawText,
  });

  factory ExtractedField.empty() {
    return ExtractedField<T>(confidence: 0.0);
  }

  bool get hasValue => value != null;
  bool get isHighConfidence => confidence >= 0.7;
  bool get isMediumConfidence => confidence >= 0.5 && confidence < 0.7;
  bool get isLowConfidence => confidence < 0.5;
}

/// Extracted amounts
class ExtractedAmounts {
  final double? netAmount;
  final double? grossAmount;

  ExtractedAmounts({
    this.netAmount,
    this.grossAmount,
  });
}

