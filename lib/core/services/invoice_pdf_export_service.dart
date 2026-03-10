import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:get/get.dart';
import '../../data/models/invoice_model.dart';
import '../utils/format_helper.dart';

/// Service to export invoices to PDF format
class InvoicePdfExportService {
  /// Sanitizes strings for PDF (removes Unicode marks like \u200E)
  static String _sanitize(String text) {
    // Remove LTR and RTL marks that can crash PDF rendering with default fonts
    return text.replaceAll('\u200E', '').replaceAll('\u200F', '');
  }

  /// Detects if a string contains Arabic characters
  static bool _hasArabic(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  /// Export invoices to PDF file
  static Future<String?> exportToPdf(
    List<Invoice> invoices, {
    required String companyName,
    required String companyTrn,
    required String periodLabel,
    required int totalInvoices,
    required double totalVat,
    required double outputVat,
    required double inputVat,
    required double totalGross,
  }) async {
    try {
      if (invoices.isEmpty) {
        debugPrint('⚠️ No invoices to export');
        return null;
      }

      // Load Arabic font for PDF rendering
      final fontData = await rootBundle.load("assets/fonts/Amiri-Regular.ttf");
      final amiriFont = pw.Font.ttf(fontData);

      final pdf = pw.Document();
      final isRtl = Get.locale?.languageCode == 'ar';

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          textDirection: isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          margin: const pw.EdgeInsets.all(32),
          header:
              (context) => pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(bottom: 20),
                child: pw.Text(
                  'FinEye Tax Management',
                  style: pw.TextStyle(
                    font: amiriFont,
                    color: PdfColors.grey400,
                    fontSize: 10,
                  ),
                ),
              ),
          footer:
              (context) => pw.Container(
                alignment: pw.Alignment.centerRight,
                margin: const pw.EdgeInsets.only(top: 20),
                child: pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(
                    font: amiriFont,
                    color: PdfColors.grey400,
                    fontSize: 10,
                  ),
                ),
              ),
          build: (context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          _sanitize('report_vat_summary_title'.tr),
                          style: pw.TextStyle(
                            font: amiriFont,
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          _sanitize(periodLabel),
                          style: pw.TextStyle(
                            font: amiriFont,
                            fontSize: 14,
                            color: PdfColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Information Grid
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          'report_company_name'.tr,
                          companyName,
                          amiriFont,
                        ),
                        _buildInfoRow('report_trn'.tr, companyTrn, amiriFont),
                        _buildInfoRow(
                          'report_export_date'.tr,
                          FormatHelper.dateTime(DateTime.now()),
                          amiriFont,
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 40),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        children: [
                          _buildSummaryRow(
                            'report_total_invoices'.tr,
                            totalInvoices.toString(),
                            amiriFont,
                          ),
                          _buildSummaryRow(
                            'report_total_gross'.tr,
                            FormatHelper.currency(totalGross),
                            amiriFont,
                          ),
                          _buildSummaryRow(
                            'report_output_vat'.tr,
                            FormatHelper.currency(outputVat),
                            amiriFont,
                          ),
                          _buildSummaryRow(
                            'report_input_vat'.tr,
                            FormatHelper.currency(inputVat),
                            amiriFont,
                          ),
                          _buildSummaryRow(
                            'report_net_vat'.tr,
                            FormatHelper.currency(totalVat),
                            amiriFont,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // Invoice Table
              pw.Table(
                border: pw.TableBorder(
                  horizontalInside: const pw.BorderSide(
                    color: PdfColors.grey200,
                    width: 0.5,
                  ),
                  bottom: const pw.BorderSide(
                    color: PdfColors.grey300,
                    width: 1,
                  ),
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.5),
                  1: const pw.FlexColumnWidth(2.5),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1.5),
                  4: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Header Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue900,
                    ),
                    children: [
                      _buildTableCell(
                        'col_invoice_no'.tr,
                        amiriFont,
                        isHeader: true,
                      ),
                      _buildTableCell(
                        'col_supplier'.tr,
                        amiriFont,
                        isHeader: true,
                      ),
                      _buildTableCell('col_date'.tr, amiriFont, isHeader: true),
                      _buildTableCell(
                        'col_gross_amount'.tr,
                        amiriFont,
                        isHeader: true,
                      ),
                      _buildTableCell(
                        'col_vat_amount'.tr,
                        amiriFont,
                        isHeader: true,
                      ),
                    ],
                  ),
                  // Data Rows
                  ...invoices.map((invoice) {
                    return pw.TableRow(
                      children: [
                        _buildTableCell(invoice.id, amiriFont),
                        _buildTableCell(invoice.supplierName, amiriFont),
                        _buildTableCell(
                          FormatHelper.date(invoice.date),
                          amiriFont,
                        ),
                        _buildTableCell(
                          FormatHelper.currency(invoice.grossAmount),
                          amiriFont,
                        ),
                        _buildTableCell(
                          FormatHelper.currency(invoice.vatAmount),
                          amiriFont,
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ];
          },
        ),
      );

      // Save PDF
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'VAT_Report_$timestamp.pdf';
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(await pdf.save());

      debugPrint('✅ PDF exported successfully: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('❌ Error exporting PDF: $e');
      return null;
    }
  }

  static pw.Widget _buildInfoRow(String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Text(
            _sanitize(label),
            textDirection: _hasArabic(label) ? pw.TextDirection.rtl : null,
            style: pw.TextStyle(
              font: font,
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            _sanitize(value),
            textDirection: _hasArabic(value) ? pw.TextDirection.rtl : null,
            style: pw.TextStyle(font: font, fontSize: 10),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryRow(String label, String value, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            _sanitize(label),
            textDirection: _hasArabic(label) ? pw.TextDirection.rtl : null,
            style: pw.TextStyle(
              font: font,
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
          ),
          pw.Text(
            _sanitize(value),
            textDirection: _hasArabic(value) ? pw.TextDirection.rtl : null,
            style: pw.TextStyle(
              font: font,
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              color: PdfColors.blue900,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        _sanitize(text),
        textDirection: _hasArabic(text) ? pw.TextDirection.rtl : null,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
        textAlign: pw.TextAlign.left,
      ),
    );
  }
}
