/// Section-based invoice extractor
/// Divides invoice into logical sections and extracts data from each
class SectionBasedInvoiceExtractor {
  /// Extract invoice data by dividing into sections
  static InvoiceExtractionResult extractFromSections(String fullText) {
    if (fullText.isEmpty) {
      return InvoiceExtractionResult.empty();
    }

    // Normalize text: remove extra spaces, handle common OCR errors
    final normalized = fullText.replaceAll(RegExp(r'\s+'), ' ');
    final lines =
        normalized
            .split('\n')
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();

    if (lines.isEmpty) {
      return InvoiceExtractionResult.empty();
    }

    // Divide invoice into sections
    final sections = _divideIntoSections(lines);

    // Extract data from each section
    final result = InvoiceExtractionResult();

    // Section 1: Header/Title (usually first 3-5 lines) - Supplier name
    if (sections.header.isNotEmpty) {
      print(
        '🔍 Extracting supplier from ${sections.header.length} header lines:',
      );
      for (int i = 0; i < sections.header.length; i++) {
        print('   Header[$i]: "${sections.header[i]}"');
      }
      result.supplierName = _extractSupplierName(sections.header);
      print('✅ Extracted supplier name: ${result.supplierName ?? "null"}');
    } else {
      print('⚠️ No header lines found for supplier extraction');
    }

    // Section 2: Metadata (date, invoice number) - Usually middle section
    if (sections.metadata.isNotEmpty) {
      result.invoiceDate = _extractDate(sections.metadata);
      result.invoiceNumber = _extractInvoiceNumber(sections.metadata);
    }

    // If date or invoice number not found in metadata, search entire document
    if (result.invoiceDate == null || result.invoiceNumber == null) {
      final monthAbbr = [
        'jan',
        'feb',
        'mar',
        'apr',
        'may',
        'jun',
        'jul',
        'aug',
        'sep',
        'oct',
        'nov',
        'dec',
      ];

      // Search entire document for date
      if (result.invoiceDate == null) {
        result.invoiceDate = _extractDateFromLines(lines, monthAbbr);
      }

      // Search entire document for invoice number
      if (result.invoiceNumber == null) {
        result.invoiceNumber = _extractInvoiceNumber(lines);
      }
    }

    // Section 3: Items list (usually largest section) - Skip for now
    // We don't need individual items, just totals

    // Section 4: Totals (usually last 5-10 lines) - Amounts
    if (sections.totals.isNotEmpty) {
      final amounts = _extractAmounts(sections.totals);
      result.subtotal = amounts.subtotal;
      result.vatAmount = amounts.vatAmount;
      result.totalAmount = amounts.totalAmount;
    }

    // If totals section didn't have enough info, search entire document
    if (result.subtotal == null && result.totalAmount == null) {
      final amounts = _extractAmounts(lines);
      result.subtotal ??= amounts.subtotal;
      result.vatAmount ??= amounts.vatAmount;
      result.totalAmount ??= amounts.totalAmount;
    }

    return result;
  }

  /// Divide invoice lines into logical sections
  static InvoiceSections _divideIntoSections(List<String> lines) {
    final sections = InvoiceSections();

    if (lines.isEmpty) return sections;

    // Section 1: Header (first 3-5 lines) - Supplier name usually here
    final headerEnd = lines.length > 5 ? 5 : lines.length;
    sections.header = lines.sublist(0, headerEnd);

    // Section 2: Metadata (look for date/invoice number keywords)
    // Usually appears in first 10-15 lines, but after header
    final metadataStart = headerEnd;
    final metadataEnd = lines.length > 15 ? 15 : lines.length;

    // Find metadata section by looking for keywords
    int? metadataStartIndex;
    int? metadataEndIndex;

    for (int i = metadataStart; i < metadataEnd && i < lines.length; i++) {
      final line = lines[i].toLowerCase();
      // Look for date/invoice number indicators
      if (line.contains('date') ||
          line.contains('chk') ||
          line.contains('check') ||
          line.contains('invoice') ||
          line.contains('bill') ||
          _hasDatePattern(line) ||
          _hasInvoiceNumberPattern(line)) {
        metadataStartIndex ??= i;
        metadataEndIndex = i + 3; // Include 2-3 lines after keyword
      }
    }

    if (metadataStartIndex != null && metadataEndIndex != null) {
      sections.metadata = lines.sublist(
        metadataStartIndex,
        metadataEndIndex > lines.length ? lines.length : metadataEndIndex,
      );
    } else {
      // Fallback: use lines 5-15 as metadata section
      sections.metadata = lines.sublist(
        metadataStart,
        metadataEnd > lines.length ? lines.length : metadataEnd,
      );
    }

    // Section 3: Items list (middle section) - Skip for now
    // We'll identify this as lines between metadata and totals

    // Section 4: Totals (last 5-10 lines) - Amounts usually here
    final totalsStart = lines.length > 10 ? lines.length - 10 : 0;
    sections.totals = lines.sublist(totalsStart);

    return sections;
  }

  /// Extract supplier name from header section
  /// ONLY extracts the top/first line of the invoice, nothing else
  static String? _extractSupplierName(List<String> headerLines) {
    if (headerLines.isEmpty) return null;

    // Get the first line (top line of invoice)
    final firstLine = headerLines[0].trim();
    if (firstLine.isEmpty) return null;

    // Skip only if it's clearly just numbers, dates, or amounts
    if (_isNumericOnly(firstLine) ||
        _isDatePattern(firstLine) ||
        _isAmountPattern(firstLine)) {
      return null;
    }

    // Keywords that indicate the end of company name
    final stopKeywords = [
      'tax invoice',
      'invoice',
      'tel:',
      'tel ',
      'phone:',
      'phone ',
      'whtsp',
      'whatsapp',
      'address',
      'near',
      'p.o. box',
      'p.0. box',
      'trn#',
      'trn #',
      'vat reg',
      'vat no',
      'bill',
      'receipt',
      'registration',
      'road',
      'street',
      'uae',
      'u.a.e',
      'date',
      'رقم',
      'فاتورة',
    ];

    // Clean the first line: remove everything after stop keywords
    String cleanedLine = firstLine;
    final lowerLine = cleanedLine.toLowerCase();

    print('🔍 Supplier extraction: Processing first line: "$firstLine"');

    // Find the earliest stop keyword and cut everything after it
    int? earliestStopIndex;
    for (final keyword in stopKeywords) {
      final index = lowerLine.indexOf(keyword.toLowerCase());
      if (index >= 0 &&
          (earliestStopIndex == null || index < earliestStopIndex)) {
        earliestStopIndex = index;
        print(
          '🔍 Supplier extraction: Found stop keyword "$keyword" at index $index',
        );
      }
    }

    // Only cut if stop keyword is found AND we have content before it
    if (earliestStopIndex != null) {
      if (earliestStopIndex > 0) {
        // Cut everything after the stop keyword
        cleanedLine = cleanedLine.substring(0, earliestStopIndex).trim();
        print('🔍 Supplier extraction: Cut line to: "$cleanedLine"');
      } else {
        // Stop keyword at position 0 - try next line or first word
        print('⚠️ Supplier extraction: Stop keyword at position 0');
        if (headerLines.length > 1) {
          final secondLine = headerLines[1].trim();
          if (secondLine.isNotEmpty &&
              !_isNumericOnly(secondLine) &&
              !_isDatePattern(secondLine) &&
              !_isAmountPattern(secondLine)) {
            cleanedLine = secondLine;
            final secondLower = cleanedLine.toLowerCase();
            int? secondStopIndex;
            for (final keyword in stopKeywords) {
              final idx = secondLower.indexOf(keyword.toLowerCase());
              if (idx >= 0 &&
                  idx > 0 &&
                  (secondStopIndex == null || idx < secondStopIndex)) {
                secondStopIndex = idx;
              }
            }
            if (secondStopIndex != null && secondStopIndex > 0) {
              cleanedLine = cleanedLine.substring(0, secondStopIndex).trim();
            }
            print('🔍 Supplier extraction: Using second line: "$cleanedLine"');
          }
        }
        // If still empty, try first word from first line
        if (cleanedLine.isEmpty || cleanedLine == firstLine) {
          final words = firstLine.split(RegExp(r'\s+'));
          for (final word in words) {
            if (word.length >= 2 &&
                !_isNumericOnly(word) &&
                !_isDatePattern(word)) {
              cleanedLine = word;
              print(
                '🔍 Supplier extraction: Using first valid word: "$cleanedLine"',
              );
              break;
            }
          }
        }
      }
    }

    // Remove trailing punctuation and clean up
    cleanedLine = cleanedLine.replaceAll(RegExp(r'[,\-\.]+$'), '').trim();

    // If cleaned line is too long, truncate it
    if (cleanedLine.length > 100) {
      cleanedLine = cleanedLine.substring(0, 100).trim();
    }

    // Return the cleaned first line (as long as it's not empty and has at least 2 chars)
    if (cleanedLine.isNotEmpty && cleanedLine.length >= 2) {
      print('✅ Supplier extraction: Returning "$cleanedLine"');
      return cleanedLine;
    } else {
      print(
        '⚠️ Supplier extraction: Cleaned line invalid, trying first line as-is',
      );
      // Last resort: return first line as-is if it's reasonable
      if (firstLine.length >= 2 && firstLine.length <= 100) {
        print(
          '✅ Supplier extraction: Returning first line as-is: "$firstLine"',
        );
        return firstLine;
      }
      return null;
    }
  }

  /// Extract date from metadata section
  /// Logic: Look for month names followed by numbers < 32, year is 4 digits
  /// Also searches entire document if metadata section doesn't yield results
  static DateTime? _extractDate(List<String> metadataLines) {
    // Month name mapping for English month abbreviations
    final monthAbbr = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
    ];

    // First try metadata section
    DateTime? date = _extractDateFromLines(metadataLines, monthAbbr);
    if (date != null) return date;

    // If not found, search entire document (fallback)
    return null;
  }

  /// Extract date from a list of lines
  static DateTime? _extractDateFromLines(
    List<String> lines,
    List<String> monthAbbr,
  ) {
    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      final originalLine =
          line; // Keep original for case-sensitive month matching

      // Pattern 1: "May04'17" or "May 04'17" (month name directly followed by day, then year)
      final pattern1a = RegExp(
        r"([A-Za-z]{3,})[a-z]*\s*(\d{1,2})\s*[,']?\s*(\d{2,4})\b",
        caseSensitive: false,
      );
      final match1a = pattern1a.firstMatch(originalLine);
      if (match1a != null) {
        try {
          final monthStr = match1a.group(1)!.toLowerCase();
          final day = int.parse(match1a.group(2)!);
          final yearRaw = int.parse(match1a.group(3)!);

          if (day >= 1 && day <= 31) {
            final monthIndex = monthAbbr.indexWhere(
              (m) => monthStr.startsWith(m),
            );
            if (monthIndex >= 0) {
              final year =
                  yearRaw < 100
                      ? (yearRaw < 50 ? 2000 + yearRaw : 1900 + yearRaw)
                      : yearRaw;
              if (year >= 2000 && year <= 2100) {
                final month = monthIndex + 1;
                return DateTime(year, month, day);
              }
            }
          }
        } catch (_) {
          // Continue to next pattern
        }
      }

      // Pattern 1b: "15 Apr, 18" or "15 Apr 18" (day, then month, then year)
      final pattern1b = RegExp(
        r"(\d{1,2})\s+([A-Za-z]{3,})[a-z]*\s*[,']?\s*(\d{2,4})\b",
        caseSensitive: false,
      );
      final match1b = pattern1b.firstMatch(lowerLine);
      if (match1b != null) {
        try {
          final day = int.parse(match1b.group(1)!);
          final monthStr = match1b.group(2)!.toLowerCase();
          final yearRaw = int.parse(match1b.group(3)!);

          if (day >= 1 && day <= 31) {
            final monthIndex = monthAbbr.indexWhere(
              (m) => monthStr.startsWith(m),
            );
            if (monthIndex >= 0) {
              final year =
                  yearRaw < 100
                      ? (yearRaw < 50 ? 2000 + yearRaw : 1900 + yearRaw)
                      : yearRaw;
              if (year >= 2000 && year <= 2100) {
                final month = monthIndex + 1;
                return DateTime(year, month, day);
              }
            }
          }
        } catch (_) {
          // Continue to next pattern
        }
      }

      // Pattern 2: "15-Apr-18" or "15 Apr 18" (without comma/apostrophe)
      final pattern2 = RegExp(
        r'(\d{1,2})[- ]([A-Za-z]{3})-?(\d{2,4})\b',
        caseSensitive: false,
      );
      final match2 = pattern2.firstMatch(lowerLine);
      if (match2 != null) {
        try {
          final day = int.parse(match2.group(1)!);
          final monthStr = match2.group(2)!.toLowerCase();
          final yearRaw = int.parse(match2.group(3)!);

          if (day >= 1 && day <= 31) {
            final monthIndex = monthAbbr.indexWhere(
              (m) => monthStr.startsWith(m),
            );
            if (monthIndex >= 0) {
              final year =
                  yearRaw < 100
                      ? (yearRaw < 50 ? 2000 + yearRaw : 1900 + yearRaw)
                      : yearRaw;
              if (year >= 2000 && year <= 2100) {
                final month = monthIndex + 1;
                return DateTime(year, month, day);
              }
            }
          }
        } catch (_) {
          // Continue
        }
      }

      // Pattern 3: "DD/MM/YYYY" or "DD-MM-YYYY"
      final pattern3 = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})\b');
      final match3 = pattern3.firstMatch(lowerLine);
      if (match3 != null) {
        try {
          final day = int.parse(match3.group(1)!);
          final month = int.parse(match3.group(2)!);
          final yearRaw = int.parse(match3.group(3)!);
          final year =
              yearRaw < 100
                  ? (yearRaw < 50 ? 2000 + yearRaw : 1900 + yearRaw)
                  : yearRaw;

          if (day >= 1 &&
              day <= 31 &&
              month >= 1 &&
              month <= 12 &&
              year >= 2000 &&
              year <= 2100) {
            return DateTime(year, month, day);
          }
        } catch (_) {
          // Continue
        }
      }
    }

    return null;
  }

  /// Extract invoice number from metadata section
  /// Logic: Look for keywords like CHK, Check, No., Invoice No, etc. and find numbers next to them
  static String? _extractInvoiceNumber(List<String> metadataLines) {
    // Common keywords for invoice number (prioritize CHK/Check)
    // IMPORTANT: Only extract if one of these keywords is found
    final keywords = [
      'chk',
      'check',
      'tax invoice #',
      'tax invoice#',
      'TAX INVOICE #',
      'invoice no',
      'invoice number',
      'invoice #',
      'bill no',
      'bill number',
      'bill #',
      'no.',
      'number',
      'رقم الفاتورة',
      'inv',
      'ref',
      'reference',
    ];

    for (final line in metadataLines) {
      final lowerLine = line.toLowerCase();
      final originalLine = line; // Keep original for case-sensitive matching

      // Check each keyword
      for (final keyword in keywords) {
        if (lowerLine.contains(keyword)) {
          // Pattern 1: "CHK: 406587" or "Check : 406587" or "CHK 406587"
          final pattern1 = RegExp(
            '$keyword\\s*:?\\s*#?\\s*(\\d{3,})',
            caseSensitive: false,
          );
          final match1 = pattern1.firstMatch(lowerLine);
          if (match1 != null) {
            final number = match1.group(1)!;
            // Validate it's not part of a date or amount
            if (!_isDatePattern(number) &&
                !_isAmountPattern(number) &&
                number.length >= 3) {
              return number;
            }
          }

          // Pattern 2: Find number immediately after keyword (more flexible)
          final keywordIndex = lowerLine.indexOf(keyword);
          if (keywordIndex >= 0) {
            final afterKeyword =
                originalLine.substring(keywordIndex + keyword.length).trim();
            // Look for number that appears right after keyword (within 20 chars)
            final numberMatch = RegExp(r'(\d{3,})').firstMatch(afterKeyword);
            if (numberMatch != null) {
              final number = numberMatch.group(1)!;
              final numberStart = afterKeyword.indexOf(number);
              // Number should be within first 20 characters after keyword
              if (numberStart >= 0 && numberStart < 20) {
                // Validate it's not part of a date or amount
                if (!_isDatePattern(number) && !_isAmountPattern(number)) {
                  return number;
                }
              }
            }
          }

          // Pattern 3: Find number on next line (if keyword is at end of line)
          final lineIndex = metadataLines.indexOf(line);
          if (lineIndex >= 0 && lineIndex + 1 < metadataLines.length) {
            final nextLine = metadataLines[lineIndex + 1].trim();
            // Only check if current line ends with keyword or keyword is near end
            if (lowerLine.length - lowerLine.indexOf(keyword) - keyword.length <
                10) {
              final numberMatch = RegExp(r'(\d{3,})').firstMatch(nextLine);
              if (numberMatch != null) {
                final number = numberMatch.group(1)!;
                // Validate it's not part of a date or amount
                if (!_isDatePattern(number) && !_isAmountPattern(number)) {
                  return number;
                }
              }
            }
          }
        }
      }
    }

    return null;
  }

  /// Extract amounts from totals section
  /// Logic: Process line-by-line (rows), only extract from lines containing keywords
  /// Priority: Sub total > Net amount > Total
  /// Extract the number that appears in the same row as the keyword
  static AmountExtractionResult _extractAmounts(List<String> totalsLines) {
    final result = AmountExtractionResult();

    // Keywords for each amount type (priority order)
    final subtotalKeywords = [
      'sub total',
      'subtotal',
      'sub. total',
      'sub-total',
      'total before vat',
      'total before VAT',
      'Total before VAT',
      'amount excl. vat',
      'amount excluding vat',
    ];

    final netAmountKeywords = ['net amount', 'net', 'net total'];

    final totalKeywords = ['total due', 'grand total', 'final total', 'total'];

    // Process each line (row) individually
    for (final line in totalsLines) {
      final lowerLine = line.toLowerCase().trim();
      if (lowerLine.isEmpty) continue;

      // Priority 1: Check for Sub total keywords (HIGHEST PRIORITY)
      // Check longer/more specific keywords first to avoid partial matches
      if (result.subtotal == null) {
        // Sort keywords by length (longest first) to match more specific ones first
        final sortedSubtotalKeywords = List<String>.from(subtotalKeywords)
          ..sort((a, b) => b.length.compareTo(a.length));

        for (final keyword in sortedSubtotalKeywords) {
          // Make keyword comparison case-insensitive
          final keywordLower = keyword.toLowerCase();
          if (lowerLine.contains(keywordLower)) {
            // Extract amount from this row - look for number after the keyword
            final amount = _extractAmountFromRow(line, keywordLower);
            if (amount != null && amount > 0) {
              result.subtotal = amount;
              print('✅ Found Subtotal ($keyword): $amount from row: "$line"');
              break; // Stop after first match
            }
          }
        }
      }

      // Priority 2: Check for Net amount keywords (if subtotal not found)
      if (result.subtotal == null) {
        for (final keyword in netAmountKeywords) {
          // Make keyword comparison case-insensitive
          final keywordLower = keyword.toLowerCase();
          if (lowerLine.contains(keywordLower)) {
            // Extract amount from this row
            final amount = _extractAmountFromRow(line, keywordLower);
            if (amount != null && amount > 0) {
              result.subtotal = amount; // Net amount = Subtotal
              print('✅ Found Net Amount: $amount from row: "$line"');
              break;
            }
          }
        }
      }

      // Priority 3: Check for Total keywords (only if subtotal/net not found)
      if (result.subtotal == null && result.totalAmount == null) {
        for (final keyword in totalKeywords) {
          // Make keyword comparison case-insensitive
          final keywordLower = keyword.toLowerCase();
          if (lowerLine.contains(keywordLower)) {
            // Extract amount from this row
            final amount = _extractAmountFromRow(line, keywordLower);
            if (amount != null && amount > 0) {
              result.totalAmount = amount;
              print('✅ Found Total: $amount from row: "$line"');
              break;
            }
          }
        }
      }

      // Extract VAT amount if line contains VAT keyword
      if (result.vatAmount == null) {
        if (lowerLine.contains('vat') ||
            lowerLine.contains('tax') ||
            lowerLine.contains('v.a.t')) {
          final amount = _extractAmountFromRow(line, 'vat');
          if (amount != null && amount > 0) {
            result.vatAmount = amount;
            print('✅ Found VAT Amount: $amount from row: "$line"');
          }
        }
      }
    }

    // Calculate missing values if we have partial data
    if (result.subtotal != null &&
        result.vatAmount == null &&
        result.totalAmount == null) {
      // Calculate VAT as 5% of subtotal (UAE standard)
      result.vatAmount = result.subtotal! * 0.05;
      // Total = Subtotal + VAT
      result.totalAmount = result.subtotal! * 1.05;
      print(
        '✅ Calculated VAT (5%): ${result.vatAmount}, Total: ${result.totalAmount}',
      );
    } else if (result.subtotal != null &&
        result.totalAmount != null &&
        result.vatAmount == null) {
      // Calculate VAT from subtotal and total
      result.vatAmount = result.totalAmount! - result.subtotal!;
      print('✅ Calculated VAT from Subtotal and Total: ${result.vatAmount}');
    } else if (result.totalAmount != null &&
        result.subtotal == null &&
        result.vatAmount == null) {
      // Assume 5% VAT: subtotal = total / 1.05
      result.subtotal = result.totalAmount! / 1.05;
      result.vatAmount = result.totalAmount! - result.subtotal!;
      print(
        '✅ Calculated Subtotal and VAT from Total: Subtotal=${result.subtotal}, VAT=${result.vatAmount}',
      );
    }

    return result;
  }

  /// Extract amount from a row that contains a keyword
  /// Looks for numbers in the same row, prioritizing numbers immediately after the keyword
  static double? _extractAmountFromRow(String line, String keyword) {
    final lowerLine = line.toLowerCase();
    final keywordLower = keyword.toLowerCase();
    final keywordIndex = lowerLine.indexOf(keywordLower);

    if (keywordIndex < 0) {
      print(
        '⚠️ Amount extraction: Keyword "$keyword" not found in line: "$line"',
      );
      return null;
    }

    print(
      '🔍 Amount extraction: Looking for amount after keyword "$keyword" in line: "$line"',
    );

    // Strategy 1: Look for amount IMMEDIATELY after the keyword (highest priority)
    // Extract text after keyword
    final afterKeyword = line.substring(keywordIndex + keyword.length);

    // Remove common separators that might appear after keyword (colon, dash, spaces)
    final cleanedAfterKeyword =
        afterKeyword.replaceAll(RegExp(r'^[:-\s]+'), '').trim();

    print('🔍 Amount extraction: Text after keyword: "$cleanedAfterKeyword"');

    // Find the FIRST amount that appears after the keyword
    // Use a comprehensive pattern that matches amounts with decimals
    // Pattern matches: 45.24, 1,234.56, 45.2, 45, etc.
    final amountPattern = RegExp(r'([\d,]+\.\d{1,2})|([\d,]+)');
    final firstMatch = amountPattern.firstMatch(cleanedAfterKeyword);

    if (firstMatch != null) {
      // Get the matched amount string
      final amountStr =
          (firstMatch.group(1) ?? firstMatch.group(2))!
              .replaceAll(',', '')
              .trim();
      final amount = double.tryParse(amountStr);

      if (amount != null && amount > 0) {
        // Verify this is the first amount after keyword (within first 50 chars)
        final matchPosition = cleanedAfterKeyword.indexOf(firstMatch.group(0)!);
        if (matchPosition >= 0 && matchPosition < 50) {
          print(
            '✅ Amount extraction: Found amount $amount immediately after keyword "$keyword" at position $matchPosition',
          );
          return amount;
        }
      }
    }

    // Strategy 2: If no amount found immediately after, try to find amount on the same line
    // but ensure it's after the keyword position (not before it)
    print(
      '⚠️ Amount extraction: No amount found immediately after keyword, searching entire line...',
    );
    final allAmountMatches = RegExp(
      r'([\d,]+\.\d{1,2})|([\d,]+)',
    ).allMatches(line);

    double? bestAmount;
    int bestPosition = -1;

    for (final match in allAmountMatches) {
      final amountStr =
          (match.group(1) ?? match.group(2))!.replaceAll(',', '').trim();
      final amount = double.tryParse(amountStr);

      if (amount != null && amount > 0) {
        final matchIndex = line.indexOf(match.group(0)!);
        // Only consider amounts that appear AFTER the keyword
        if (matchIndex > keywordIndex + keyword.length) {
          // Prefer amounts closer to the keyword
          if (bestAmount == null || matchIndex < bestPosition) {
            bestAmount = amount;
            bestPosition = matchIndex;
          }
        }
      }
    }

    if (bestAmount != null) {
      print(
        '✅ Amount extraction: Using amount $bestAmount found after keyword position (fallback)',
      );
      return bestAmount;
    }

    print('⚠️ Amount extraction: No valid amount found in line: "$line"');
    return null;
  }

  // Helper methods

  static bool _hasDatePattern(String text) {
    return RegExp(
          r'\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*\s+\d{1,2}',
          caseSensitive: false,
        ).hasMatch(text) ||
        RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(text);
  }

  static bool _hasInvoiceNumberPattern(String text) {
    return RegExp(
      r'(chk|check|invoice|bill)\s*(no|number|#)?',
      caseSensitive: false,
    ).hasMatch(text);
  }

  static bool _isNumericOnly(String text) {
    return RegExp(
      r'^\d+$',
    ).hasMatch(text.replaceAll(',', '').replaceAll('.', ''));
  }

  static bool _isDatePattern(String text) {
    return RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(text) ||
        RegExp(
          r'\b(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\w*\s+\d{1,2}',
          caseSensitive: false,
        ).hasMatch(text);
  }

  static bool _isAmountPattern(String text) {
    return RegExp(r'[\d,]+\.\d{2}').hasMatch(text) ||
        RegExp(r'aed\s*[\d,]+', caseSensitive: false).hasMatch(text);
  }
}

/// Invoice sections
class InvoiceSections {
  List<String> header = []; // Supplier name (top)
  List<String> metadata = []; // Date, invoice number (middle-top)
  List<String> items = []; // Items list (middle, optional)
  List<String> totals = []; // Amounts (bottom)
}

/// Extraction result
class InvoiceExtractionResult {
  String? supplierName;
  DateTime? invoiceDate;
  String? invoiceNumber;
  double? subtotal;
  double? vatAmount;
  double? totalAmount;

  InvoiceExtractionResult({
    this.supplierName,
    this.invoiceDate,
    this.invoiceNumber,
    this.subtotal,
    this.vatAmount,
    this.totalAmount,
  });

  factory InvoiceExtractionResult.empty() {
    return InvoiceExtractionResult();
  }

  bool get isEmpty =>
      supplierName == null &&
      invoiceDate == null &&
      invoiceNumber == null &&
      subtotal == null &&
      vatAmount == null &&
      totalAmount == null;
}

/// Amount extraction result
class AmountExtractionResult {
  double? subtotal;
  double? vatAmount;
  double? totalAmount;
}
