import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/invoice_model.dart';
import 'package:gal/gal.dart';

/// Service to export invoices to CSV format
class InvoiceExportService {
  
  /// Export invoices to CSV file
  static Future<String?> exportToCSV(List<Invoice> invoices) async {
    try {
      if (invoices.isEmpty) {
        debugPrint('⚠️ No invoices to export');
        return null;
      }

      // Create CSV content
      final csvContent = _generateCSVContent(invoices);
      
      // Get the downloads directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'fineye_invoices_$timestamp.csv';
      final filePath = '${directory.path}/$fileName';
      
      // Write to file
      final file = File(filePath);
      await file.writeAsString(csvContent);
      
      debugPrint('✅ CSV exported to: $filePath');
      
      // Try to save to gallery/downloads for user access
      try {
        await Gal.putImage(filePath);
        debugPrint('✅ CSV saved to gallery/downloads');
      } catch (e) {
        debugPrint('⚠️ Could not save to gallery: $e');
      }
      
      return filePath;
    } catch (e) {
      debugPrint('❌ Error exporting CSV: $e');
      return null;
    }
  }
  
  /// Export VAT summary to CSV
  static Future<String?> exportVATSummary({
    required double totalVAT,
    required double outputVAT,
    required double inputVAT,
    required int pendingCount,
    required List<Invoice> invoices,
  }) async {
    try {
      // Create VAT summary CSV content
      final csvContent = _generateVATSummaryCSV(
        totalVAT: totalVAT,
        outputVAT: outputVAT,
        inputVAT: inputVAT,
        pendingCount: pendingCount,
        invoices: invoices,
      );
      
      // Get the downloads directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'fineye_vat_summary_$timestamp.csv';
      final filePath = '${directory.path}/$fileName';
      
      // Write to file
      final file = File(filePath);
      await file.writeAsString(csvContent);
      
      debugPrint('✅ VAT Summary CSV exported to: $filePath');
      
      // Try to save to gallery/downloads for user access
      try {
        await Gal.putImage(filePath);
        debugPrint('✅ VAT Summary saved to gallery/downloads');
      } catch (e) {
        debugPrint('⚠️ Could not save to gallery: $e');
      }
      
      return filePath;
    } catch (e) {
      debugPrint('❌ Error exporting VAT Summary: $e');
      return null;
    }
  }
  
  /// Generate CSV content from invoices
  static String _generateCSVContent(List<Invoice> invoices) {
    final buffer = StringBuffer();
    
    // CSV Header
    buffer.writeln('Invoice Number,Supplier Name,Category,Date,Gross Amount (AED),VAT Amount (AED),Additional Charges (AED),Status,Tax Badge,CT Deductible,VAT Activity,Notes');
    
    // CSV Rows
    for (final invoice in invoices) {
      buffer.writeln([
        _escapeCSV(invoice.id),
        _escapeCSV(invoice.supplierName),
        _escapeCSV(invoice.category),
        DateFormat('yyyy-MM-dd').format(invoice.date),
        invoice.grossAmount.toStringAsFixed(2),
        invoice.vatAmount.toStringAsFixed(2),
        invoice.additionalCharges.toStringAsFixed(2),
        _escapeCSV(invoice.status),
        _escapeCSV(invoice.taxBadge),
        invoice.isCtDeductible ? 'Yes' : 'No',
        _escapeCSV(invoice.vatActivity),
        _escapeCSV(invoice.notes),
      ].join(','));
    }
    
    return buffer.toString();
  }
  
  /// Generate VAT Summary CSV
  static String _generateVATSummaryCSV({
    required double totalVAT,
    required double outputVAT,
    required double inputVAT,
    required int pendingCount,
    required List<Invoice> invoices,
  }) {
    final buffer = StringBuffer();
    final dateStr = DateFormat('MMMM yyyy').format(DateTime.now());
    
    // Summary Section
    buffer.writeln('FinEye - VAT Summary Report');
    buffer.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    buffer.writeln('Period: $dateStr');
    buffer.writeln('');
    buffer.writeln('VAT Summary');
    buffer.writeln('Output VAT (Sales),${outputVAT.toStringAsFixed(2)}');
    buffer.writeln('Input VAT (Purchases),${inputVAT.toStringAsFixed(2)}');
    buffer.writeln('Net VAT Due,${totalVAT.toStringAsFixed(2)}');
    buffer.writeln('Pending Review,$pendingCount');
    buffer.writeln('Total Invoices,${invoices.length}');
    buffer.writeln('');
    
    // Invoices by Category
    buffer.writeln('VAT by Category');
    final categoryMap = <String, double>{};
    for (final invoice in invoices) {
      categoryMap[invoice.category] = (categoryMap[invoice.category] ?? 0.0) + invoice.vatAmount;
    }
    buffer.writeln('Category,VAT Amount (AED)');
    for (final entry in categoryMap.entries) {
      buffer.writeln('${_escapeCSV(entry.key)},${entry.value.toStringAsFixed(2)}');
    }
    buffer.writeln('');
    
    // Detailed Invoice List
    buffer.writeln('Detailed Invoice List');
    buffer.writeln('Invoice Number,Supplier Name,Category,Date,Gross Amount (AED),VAT Amount (AED),Status,Tax Badge');
    
    for (final invoice in invoices) {
      buffer.writeln([
        _escapeCSV(invoice.id),
        _escapeCSV(invoice.supplierName),
        _escapeCSV(invoice.category),
        DateFormat('yyyy-MM-dd').format(invoice.date),
        invoice.grossAmount.toStringAsFixed(2),
        invoice.vatAmount.toStringAsFixed(2),
        _escapeCSV(invoice.status),
        _escapeCSV(invoice.taxBadge),
      ].join(','));
    }
    
    return buffer.toString();
  }
  
  /// Escape CSV values (handle commas, quotes, newlines)
  static String _escapeCSV(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

