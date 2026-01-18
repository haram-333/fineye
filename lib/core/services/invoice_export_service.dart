import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/invoice_model.dart';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';

/// Service to export invoices to professional formats (Excel)
class InvoiceExportService {
  
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

      // Add Headers
      sheet.appendRow([
        TextCellValue('Invoice Number'),
        TextCellValue('Supplier Name'),
        TextCellValue('Category'),
        TextCellValue('Date'),
        TextCellValue('Gross Amount (AED)'),
        TextCellValue('VAT Amount (AED)'),
        TextCellValue('Additional Charges (AED)'),
        TextCellValue('Status'),
        TextCellValue('Tax Badge'),
        TextCellValue('CT Deductible'),
        TextCellValue('VAT Activity'),
        TextCellValue('Notes'),
      ]);

      // Style headers
      for (var i = 0; i < 12; i++) {
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#002060'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
      }

      // Add Rows
      for (final invoice in invoices) {
        sheet.appendRow([
          TextCellValue(invoice.id),
          TextCellValue(invoice.supplierName),
          TextCellValue(invoice.category),
          TextCellValue(DateFormat('yyyy-MM-dd').format(invoice.date)),
          DoubleCellValue(invoice.grossAmount),
          DoubleCellValue(invoice.vatAmount),
          DoubleCellValue(invoice.additionalCharges),
          TextCellValue(invoice.status),
          TextCellValue(invoice.taxBadge),
          TextCellValue(invoice.isCtDeductible ? 'Yes' : 'No'),
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
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'FinEye Invoices Export',
        );
        
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
    required double totalVAT,
    required double outputVAT,
    required double inputVAT,
    required int pendingCount,
    required List<Invoice> invoices,
  }) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['VAT Summary'];
      excel.delete('Sheet1');

      // 1. Summary Section
      sheet.appendRow([TextCellValue('FinEye - VAT Summary Report')]);
      sheet.appendRow([TextCellValue('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}')]);
      sheet.appendRow([TextCellValue('Period: ${DateFormat('MMMM yyyy').format(DateTime.now())}')]);
      sheet.appendRow([]); // Empty row

      sheet.appendRow([TextCellValue('VAT Summary'), TextCellValue('Amount (AED)')]);
      sheet.appendRow([TextCellValue('Output VAT (Sales)'), DoubleCellValue(outputVAT)]);
      sheet.appendRow([TextCellValue('Input VAT (Purchases)'), DoubleCellValue(inputVAT)]);
      sheet.appendRow([TextCellValue('Net VAT Due'), DoubleCellValue(totalVAT)]);
      sheet.appendRow([TextCellValue('Pending Review'), IntCellValue(pendingCount)]);
      sheet.appendRow([TextCellValue('Total Invoices'), IntCellValue(invoices.length)]);
      sheet.appendRow([]); // Empty row

      // Style Summary Headers
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).cellStyle = CellStyle(bold: true, fontSize: 16);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4)).cellStyle = CellStyle(bold: true);

      // 2. Invoices by Category
      sheet.appendRow([TextCellValue('VAT by Category'), TextCellValue('VAT Amount (AED)')]);
      final categoryMap = <String, double>{};
      for (final invoice in invoices) {
        categoryMap[invoice.category] = (categoryMap[invoice.category] ?? 0.0) + invoice.vatAmount;
      }
      for (final entry in categoryMap.entries) {
        sheet.appendRow([TextCellValue(entry.key), DoubleCellValue(entry.value)]);
      }
      sheet.appendRow([]); // Empty row

      // 3. Detailed Invoice List
      sheet.appendRow([
        TextCellValue('Invoice Number'),
        TextCellValue('Supplier Name'),
        TextCellValue('Category'),
        TextCellValue('Date'),
        TextCellValue('Gross Amount (AED)'),
        TextCellValue('VAT Amount (AED)'),
        TextCellValue('Status'),
        TextCellValue('Tax Badge')
      ]);

      // Style Detailed Header
      final startRowDetail = sheet.maxRows - 1;
      for (var i = 0; i < 8; i++) {
        var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: startRowDetail));
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#002060'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
      }

      for (final invoice in invoices) {
        sheet.appendRow([
          TextCellValue(invoice.id),
          TextCellValue(invoice.supplierName),
          TextCellValue(invoice.category),
          TextCellValue(DateFormat('yyyy-MM-dd').format(invoice.date)),
          DoubleCellValue(invoice.grossAmount),
          DoubleCellValue(invoice.vatAmount),
          TextCellValue(invoice.status),
          TextCellValue(invoice.taxBadge),
        ]);
      }

      // Save and Share
      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'fineye_vat_summary_$timestamp.xlsx';
      final filePath = '${directory.path}/$fileName';
      
      final fileBytes = excel.save();
      if (fileBytes != null) {
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);
        
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'FinEye VAT Summary Export',
        );
        
        return filePath;
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error exporting VAT Summary: $e');
      return null;
    }
  }
}

