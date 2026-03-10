import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/invoice_model.dart';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/format_helper.dart';
import 'package:get/get.dart';

/// Service to export invoices to professional formats (Excel)
class InvoiceExportService {
  /// Helper to get category translation key (duplicate from Controller to avoid circular imports)
  static String _getCategoryTranslationKey(String category) {
    final Map<String, String> categoryKeys = {
      'Office supplies': 'cat_office_supplies',
      'Utilities': 'cat_utilities',
      'Transport': 'cat_transport',
      'Subscriptions': 'cat_subscriptions',
      'Marketing': 'cat_marketing',
      'Professional fees': 'cat_professional_fees',
      'Rent': 'cat_rent',
      'Maintenance': 'cat_maintenance',
      'Other': 'cat_other',
    };
    return categoryKeys[category] ?? 'cat_other';
  }

  /// Helper to get status translation
  static String _getStatusTranslation(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'lbl_paid'.tr;
      case 'not paid':
      case 'unpaid':
        return 'lbl_not_paid'.tr;
      case 'pending':
        return 'status_pending'.tr;
      case 'review':
        return 'lbl_review'.tr; // Assuming this key exists or falls back
      default:
        // Try to translate if key exists, otherwise return formatted
        return status;
    }
  }

  /// Export invoices to professional Excel (.xlsx) file
  static Future<String?> exportToExcel(List<Invoice> invoices) async {
    try {
      if (invoices.isEmpty) {
        debugPrint('⚠️ No invoices to export');
        return null;
      }

      final excel = Excel.createExcel();
      final sheet = excel['Invoices'];
      excel.delete('Sheet1'); // Remove default sheet

      // In Arabic mode, we align right but keep columns LTR order for "inside content"
      // as per user request. We will shift title/labels manually if needed.
      final isArabic = Get.locale?.languageCode == 'ar';

      // Add Headers
      sheet.appendRow([
        TextCellValue('col_invoice_no'.tr),
        TextCellValue('col_supplier'.tr),
        TextCellValue('col_category'.tr),
        TextCellValue('col_date'.tr),
        TextCellValue('col_gross_amount'.tr),
        TextCellValue('col_vat_amount'.tr),
        TextCellValue('col_additional_charges'.tr),
        TextCellValue('col_status'.tr),
        TextCellValue('col_tax_badge'.tr),
        TextCellValue('col_ct_deductible'.tr),
        TextCellValue('col_vat_activity'.tr),
        TextCellValue('col_notes'.tr),
      ]);

      // Style headers
      for (var i = 0; i < 12; i++) {
        var cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#002060'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
          horizontalAlign:
              isArabic ? HorizontalAlign.Right : HorizontalAlign.Left,
        );
      }

      // Add Rows
      for (final invoice in invoices) {
        sheet.appendRow([
          TextCellValue(invoice.id),
          TextCellValue(invoice.supplierName),
          TextCellValue(
            _getCategoryTranslationKey(invoice.category).tr,
          ), // Translated Category
          TextCellValue(FormatHelper.date(invoice.date)),
          DoubleCellValue(invoice.grossAmount),
          DoubleCellValue(invoice.vatAmount),
          DoubleCellValue(invoice.additionalCharges),
          TextCellValue(
            _getStatusTranslation(invoice.status),
          ), // Translated Status
          TextCellValue(invoice.taxBadge),
          TextCellValue(
            invoice.isCtDeductible ? 'lbl_yes'.tr : 'lbl_no'.tr,
          ), // Translated Boolean
          TextCellValue(invoice.vatActivity),
          TextCellValue(invoice.notes),
        ]);
      }

      // Save file
      final directory = await getTemporaryDirectory(); // Use temp for sharing
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'fineye_invoices_$timestamp.xlsx';
      final filePath = '${directory.path}/$fileName';

      final fileBytes = excel.save();
      if (fileBytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);

        debugPrint('✅ Excel exported to: $filePath');

        // Share the file so the user can "download" or save it anywhere
        await Share.shareXFiles([
          XFile(filePath),
        ], subject: 'FinEye Invoices Export');

        return filePath;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error exporting Excel: $e');
      return null;
    }
  }

  /// Export VAT summary to professional Excel
  static Future<String?> exportVATSummary({
    required String companyName,
    required String trn,
    required String vatPeriod,
    required String businessType,
    required double totalVAT,
    required double outputVAT,
    required double inputVAT,
    required int pendingCount,
    required int invoicesCount, // Added explicit count
    required List<Invoice> invoices,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['VAT Summary'];
      excel.delete('Sheet1');

      final isArabic = Get.locale?.languageCode == 'ar';
      const int rightSideColumn = 8;

      int currentRow = 0;

      // Helper to add a row and increment counter
      void appendRow(List<CellValue> row, {CellStyle? style}) {
        List<CellValue> finalRow = row;

        // If Arabic and it's a single-label row, move it to a dedicated side column.
        if (isArabic && row.length == 1) {
          finalRow = [
            TextCellValue(''),
            TextCellValue(''),
            TextCellValue(''),
            TextCellValue(''),
            TextCellValue(''),
            TextCellValue(''),
            TextCellValue(''),
            TextCellValue(''),
            row[0],
          ];
        }

        sheet.appendRow(finalRow);

        // Default style with alignment if none provided
        final effectiveStyle =
            style ??
            CellStyle(
              horizontalAlign:
                  isArabic ? HorizontalAlign.Right : HorizontalAlign.Left,
            );

        // Apply style to the cells that were actually provided (or shifted)
        if (isArabic && row.length == 1) {
          sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: rightSideColumn,
                  rowIndex: currentRow,
                ),
              )
              .cellStyle = effectiveStyle;
        } else {
          for (var i = 0; i < finalRow.length; i++) {
            var cell = sheet.cell(
              CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow),
            );
            cell.cellStyle = effectiveStyle;
          }
        }
        currentRow++;
      }

      // 1. Header Section
      final headerTitleStyle = CellStyle(
        bold: true,
        fontSize: 16,
        horizontalAlign:
            isArabic ? HorizontalAlign.Right : HorizontalAlign.Left,
      );
      final headerLabelStyle = CellStyle(
        bold: true,
        fontSize: 11,
        horizontalAlign:
            isArabic ? HorizontalAlign.Right : HorizontalAlign.Left,
      );
      final separatorStyle = CellStyle(
        fontColorHex: ExcelColor.fromHexString('#808080'),
        horizontalAlign:
            isArabic ? HorizontalAlign.Right : HorizontalAlign.Left,
      );
      final String separator =
          '------------------------------------------------------------';

      appendRow([TextCellValue(separator)], style: separatorStyle);
      appendRow([
        TextCellValue('report_vat_summary_title'.tr),
      ], style: headerTitleStyle);
      appendRow([TextCellValue(separator)], style: separatorStyle);
      appendRow([]); // Spacing

      appendRow([
        TextCellValue('${'report_company'.tr.padRight(20)} : $companyName'),
      ], style: headerLabelStyle);
      appendRow([
        TextCellValue('${'report_trn'.tr.padRight(20)} : $trn'),
      ], style: headerLabelStyle);
      appendRow([
        TextCellValue(
          '${'report_business_type'.tr.padRight(20)} : $businessType',
        ),
      ], style: headerLabelStyle);
      appendRow([
        TextCellValue('${'report_currency'.tr.padRight(20)} : AED'),
      ], style: headerLabelStyle);
      appendRow([]); // Spacing

      // Custom date format: 15/01/2026 – 10:45 AM/PM
      final now = DateTime.now();
      final amPm =
          isArabic
              ? (now.hour < 12 ? 'صباحًا' : 'مساءً')
              : (now.hour < 12 ? 'AM' : 'PM');
      final timeFormatted =
          DateFormat('dd/MM/yyyy – hh:mm').format(now) + ' $amPm';

      appendRow([
        TextCellValue('${'report_vat_period'.tr.padRight(20)} : $vatPeriod'),
      ], style: headerLabelStyle);
      appendRow([
        TextCellValue(
          '${'report_generated_on'.tr.padRight(20)} : $timeFormatted',
        ),
      ], style: headerLabelStyle);
      appendRow([]); // Spacing

      // 2. VAT Summary Section
      final sectionTitleStyle = CellStyle(bold: true, fontSize: 12);

      appendRow([TextCellValue(separator)], style: separatorStyle);
      appendRow([
        TextCellValue('report_section_summary'.tr),
      ], style: sectionTitleStyle);
      appendRow([TextCellValue(separator)], style: separatorStyle);

      appendRow([
        TextCellValue(
          '${'report_output_vat'.tr.padRight(35)} : ${outputVAT.toStringAsFixed(2)}',
        ),
      ]);
      appendRow([
        TextCellValue(
          '${'report_input_vat'.tr.padRight(35)} : ${inputVAT.toStringAsFixed(2)}',
        ),
      ]);

      appendRow([TextCellValue(separator)], style: separatorStyle);

      // Formatting negative VAT with parentheses
      final totalVatStr =
          totalVAT < 0
              ? '(${totalVAT.abs().toStringAsFixed(2)})'
              : totalVAT.toStringAsFixed(2);

      final netVatStyle = CellStyle(
        bold: true,
        fontColorHex: ExcelColor.fromHexString(
          totalVAT >= 0 ? '#000000' : '#FF0000',
        ),
        horizontalAlign:
            isArabic ? HorizontalAlign.Right : HorizontalAlign.Left,
      );
      appendRow([
        TextCellValue('${'report_net_vat'.tr.padRight(35)} : $totalVatStr'),
      ], style: netVatStyle);
      appendRow([]);

      appendRow([
        TextCellValue(
          '${'report_total_invoices'.tr.padRight(35)} : $invoicesCount',
        ),
      ]);
      appendRow([
        TextCellValue(
          '${'report_pending_invoices'.tr.padRight(35)} : $pendingCount',
        ),
      ]);
      appendRow([]);

      // 3. VAT by Category
      appendRow([TextCellValue(separator)], style: separatorStyle);
      appendRow([
        TextCellValue('report_section_input_category'.tr),
      ], style: sectionTitleStyle);
      appendRow([TextCellValue(separator)], style: separatorStyle);

      final categoryMap = <String, double>{};
      for (final invoice in invoices.where(
        (inv) => inv.invoiceType != 'sale',
      )) {
        categoryMap[invoice.category] =
            (categoryMap[invoice.category] ?? 0.0) + invoice.vatAmount;
      }

      double totalInputVatFromCategories = 0;
      for (final entry in categoryMap.entries) {
        final translatedCategory = _getCategoryTranslationKey(entry.key).tr;
        appendRow([
          TextCellValue(
            '${translatedCategory.padRight(35)} : ${entry.value.toStringAsFixed(2)}',
          ),
        ]);
        totalInputVatFromCategories += entry.value;
      }

      appendRow([TextCellValue(separator)], style: separatorStyle);
      appendRow([
        TextCellValue(
          '${'report_total_input'.tr.padRight(35)} : ${totalInputVatFromCategories.toStringAsFixed(2)}',
        ),
      ], style: CellStyle(bold: true));
      appendRow([]);

      // 4. Detailed Invoice List
      appendRow([TextCellValue(separator)], style: separatorStyle);
      appendRow([
        TextCellValue('report_section_details'.tr),
      ], style: sectionTitleStyle);
      appendRow([TextCellValue(separator)], style: separatorStyle);

      final tableHeaders = [
        TextCellValue('col_invoice_no'.tr),
        TextCellValue('col_supplier'.tr),
        TextCellValue('col_date'.tr),
        TextCellValue('col_net_amount'.tr),
        TextCellValue('col_vat_amount'.tr),
        TextCellValue('col_gross_amount'.tr),
        TextCellValue('col_status'.tr),
        TextCellValue('col_vat_percentage'.tr),
      ];

      final tableHeaderStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#002060'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );

      appendRow(tableHeaders, style: tableHeaderStyle);

      double totalNet = 0;
      double totalVATSum = 0;
      double totalGross = 0;

      for (final invoice in invoices) {
        final netAmount =
            invoice.netAmount > 0
                ? invoice.netAmount
                : (invoice.grossAmount - invoice.vatAmount);
        totalNet += netAmount;
        totalVATSum += invoice.vatAmount;
        totalGross += invoice.grossAmount;

        appendRow([
          TextCellValue(invoice.id),
          TextCellValue(invoice.supplierName),
          TextCellValue(FormatHelper.date(invoice.date)),
          DoubleCellValue(netAmount),
          DoubleCellValue(invoice.vatAmount),
          DoubleCellValue(invoice.grossAmount),
          TextCellValue(
            _getStatusTranslation(invoice.status),
          ), // Translated status
          TextCellValue('5%'), // Standard rate
        ]);
      }

      // Add TOTALS Row
      final totalsStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#E6E6E6'),
      );
      appendRow([
        TextCellValue('report_totals'.tr),
        TextCellValue(''),
        TextCellValue(''),
        DoubleCellValue(totalNet),
        DoubleCellValue(totalVATSum),
        DoubleCellValue(totalGross),
        TextCellValue(''),
        TextCellValue(''),
      ], style: totalsStyle);
      appendRow([]);

      // 5. Compliance Notes
      appendRow([
        TextCellValue('report_section_notes'.tr),
      ], style: sectionTitleStyle);
      appendRow([TextCellValue('report_note_1'.tr)]);
      appendRow([TextCellValue('report_note_2'.tr)]);
      appendRow([TextCellValue('report_note_3'.tr)]);
      appendRow([TextCellValue('report_note_4'.tr)]);
      appendRow([TextCellValue('report_note_5'.tr)]);
      appendRow([]);

      // 6. Footer
      final footerStyle = CellStyle(
        italic: true,
        fontColorHex: ExcelColor.fromHexString('#808080'),
      );
      appendRow([TextCellValue('report_footer_system'.tr)], style: footerStyle);
      appendRow([TextCellValue('report_footer_type'.tr)], style: footerStyle);
      appendRow([TextCellValue('report_footer_format'.tr)], style: footerStyle);

      // Set Column Widths (Simple auto-fit approximation)
      sheet.setColumnWidth(0, 25);
      sheet.setColumnWidth(1, 30);
      sheet.setColumnWidth(2, 15);
      sheet.setColumnWidth(3, 15);
      sheet.setColumnWidth(4, 15);
      sheet.setColumnWidth(5, 15);
      sheet.setColumnWidth(6, 15);
      sheet.setColumnWidth(7, 10);
      sheet.setColumnWidth(8, 55);

      // Save and Share
      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'VAT_Summary_Report_$timestamp.xlsx';
      final filePath = '${directory.path}/$fileName';

      final fileBytes = excel.save();
      if (fileBytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);

        await Share.shareXFiles([
          XFile(filePath),
        ], subject: 'FinEye VAT Summary Report');

        return filePath;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error exporting VAT Summary: $e');
      return null;
    }
  }
}
