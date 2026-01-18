
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../controllers/invoice_details_controller.dart';
import '../../controllers/invoice_list_controller.dart';
import '../../../data/models/invoice_model.dart';
import '../../../core/constants/app_colors.dart';

class InvoiceDetailsView extends GetView<InvoiceDetailsController> {
  final Invoice? invoice;
  const InvoiceDetailsView({super.key, this.invoice});

  @override
  Widget build(BuildContext context) {
    // ALWAYS delete and recreate the controller for each new invoice
    // This ensures fresh state and prevents data from previous invoices
    if (Get.isRegistered<InvoiceDetailsController>()) {
      print('🗑️ Deleting existing InvoiceDetailsController');
      Get.delete<InvoiceDetailsController>();
    }
    
    print('✨ Creating new InvoiceDetailsController');
    Get.put(InvoiceDetailsController(initialInvoice: invoice));
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC), // Consistent Light Background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: BackButton(color: AppColors.ink),
        title: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'invoice_details'.tr, // Title
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827), // Primary Text
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'review_screen_subtitle'.tr, // Subtitle
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280), // Secondary Text
                ),
              ),
            ],
          ),
        ),
        toolbarHeight: 90,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1.5 Original invoice image (if available)
              _buildInvoiceImage(),
              const SizedBox(height: 20),

              // 2. Invoice Summary Card
              _buildSummaryCard(),
              
              // 2.1 Invoice Risk Summary
              _buildRiskSummary(),
              const SizedBox(height: 20),
              
              // 3. Extraction Status
              _buildExtractionStatus(),
              const SizedBox(height: 20),
              
              // 4. Invoice Information Header
              _buildSectionHeader('invoice_info'.tr, badgeText: 'auto_detected'.tr),
              const SizedBox(height: 16),
              
              // 5. Alerts
              _buildAlerts(),
              
              // 6. Invoice Fields
              _buildInvoiceFields(),
              const SizedBox(height: 20),
              
              // 7. Category Section
              _buildCategorySection(),
              const SizedBox(height: 20),
              
              // 8. VAT Calculation Engine
              _buildVatEngine(),
              const SizedBox(height: 20),
              
              // 9. Summary / Tax Breakdown
              _buildTaxBreakdown(),
              const SizedBox(height: 20),
              
              // 10. CT Deductible
              _buildCtDeductible(),
              const SizedBox(height: 20),
              
              // 10.5. Payment Status
              _buildPaymentStatusSection(),
              const SizedBox(height: 20),
              
              // 11. Notes
              _buildNotesSection(),
              const SizedBox(height: 20),
              
              // 12. Review Before Saving
              _buildReviewSection(),
              const SizedBox(height: 20),
              
              // 13. Show Original Invoice
              _buildOriginalInvoiceToggle(),
              const SizedBox(height: 32),
              
              // 14. Bottom Action Bar
              _buildBottomActions(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Show the stored invoice image (from Firebase Storage URL) when available.
  Widget _buildInvoiceImage() {
    // Check if we have a local file/bytes (new invoice) or URL (existing invoice)
    final hasLocalFile = kIsWeb ? controller.invoiceImageBytes != null : controller.invoiceImageFile != null;
    final hasUrl = invoice?.imageUrl != null && invoice!.imageUrl!.isNotEmpty;
    
    if (!hasLocalFile && !hasUrl) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Warning Banner (different text for new vs existing invoices)
        if (controller.isNewInvoice)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7), // Light amber
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFBBF24), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'OCR may not capture all details accurately. Please review the invoice image below and verify all extracted information.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE), // Light blue
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF0EA5E9), width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Color(0xFF0284C7), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Review invoice details and make any necessary updates. Tap the image to view full size.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        
        // Invoice Image Preview with Tap to Zoom
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              // Show fullscreen zoomable image
              _showFullscreenImage(context, hasLocalFile, hasUrl);
            },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 3 / 4,
                  child: hasLocalFile
                      ? (kIsWeb
                          ? Image.memory(
                              controller.invoiceImageBytes!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildImageError();
                              },
                            )
                          : Image.file(
                              controller.invoiceImageFile! as dynamic,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildImageError();
                              },
                            ))
                      : Image.network(
                          invoice!.imageUrl!,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return _buildImageError();
                          },
                        ),
                ),
                // Tap to Zoom Overlay
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_in, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Tap to enlarge',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image_outlined, size: 32, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              'Failed to load invoice image',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullscreenImage(BuildContext context, bool hasLocalFile, bool hasUrl) {
    final transformationController = TransformationController();
    
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Zoomable Image with Double Tap
            GestureDetector(
              onDoubleTapDown: (details) {
                // Store tap position for zoom centering
                final position = details.localPosition;
                
                // Toggle between zoomed in (2.5x) and reset
                if (transformationController.value != Matrix4.identity()) {
                  // Reset zoom
                  transformationController.value = Matrix4.identity();
                } else {
                  // Zoom in at tap position
                  final double scale = 2.5;
                  final double x = -position.dx * (scale - 1);
                  final double y = -position.dy * (scale - 1);
                  transformationController.value = Matrix4.identity()
                    ..translate(x, y)
                    ..scale(scale);
                }
              },
              child: InteractiveViewer(
                transformationController: transformationController,
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: hasLocalFile
                      ? (kIsWeb
                          ? Image.memory(
                              controller.invoiceImageBytes!,
                              fit: BoxFit.contain,
                            )
                          : Image.file(
                              controller.invoiceImageFile! as dynamic,
                              fit: BoxFit.contain,
                            ))
                      : Image.network(
                          invoice!.imageUrl!,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
            ),
            // Close Button
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 24),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            // Hint Text
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Double tap to zoom • Pinch to zoom in/out',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. Invoice Summary Card
  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Icon Container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.picture_as_pdf, color: Color(0xFF6B7280)),
          ),
          const SizedBox(width: 16),
          // Right: Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'label_summary'.tr, 
                      style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                    ),
                    Flexible(
                      child: Obx(() => Text(
                        'AED ${NumberFormat('#,##0.00').format(controller.grossAmount.value + controller.additionalCharges.value)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                        overflow: TextOverflow.ellipsis,
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      flex: 4,
                      child: Obx(() => Text(
                        '${'vat_amount'.tr} (5%): AED ${NumberFormat('#,##0.00').format(controller.vatAmount.value)}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        overflow: TextOverflow.ellipsis,
                      )),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 5,
                      child: Obx(() => Text(
                        '${controller.invoice.supplierName} • ${controller.invoiceDate.value != null ? DateFormat('dd MMM yyyy').format(controller.invoiceDate.value!) : ''}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. Invoice Extraction Status Card
  Widget _buildExtractionStatus() {
    return Obx(() {
      // Only show if extracting or recently finished, leveraging controller state
      // For demo purposes, we might show it if status is 'In progress'
      if (!controller.isExtracting.value) return const SizedBox.shrink();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryBlue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'extracting_details'.tr, // "Extracting invoice details..."
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF111827)),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'status_in_progress'.tr, // "In progress"
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'extracting_desc'.tr, // Description text
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRiskSummary() {
    return Obx(() {
      final risks = controller.risks;
      if (risks.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCD34D)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'invoice_risk_title'.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'risk_badge_label'.tr,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'invoice_risk_subtitle_with_count'
                  .trParams({'count': risks.length.toString()}),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: risks
                  .map(
                    (risk) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 18,
                            color: risk.severity == InvoiceRiskSeverity.high
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _mapRiskTypeToTitle(risk.type).tr,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );
    });
  }

  String _mapRiskTypeToTitle(InvoiceRiskType type) {
    switch (type) {
      case InvoiceRiskType.missingTrn:
        return 'risk_missing_trn_title';
      case InvoiceRiskType.supplierNotRegistered:
        return 'risk_supplier_not_registered_title';
      case InvoiceRiskType.duplicateInvoice:
        return 'risk_duplicate_invoice_title';
      case InvoiceRiskType.vatMismatch:
        return 'risk_vat_mismatch_title';
      case InvoiceRiskType.missingSupplier:
        return 'risk_missing_supplier_title';
      case InvoiceRiskType.missingDate:
        return 'risk_missing_date_title';
      case InvoiceRiskType.missingAmount:
        return 'risk_missing_amount_title';
      case InvoiceRiskType.vatCalculationError:
    }
    return 'risk_badge_label';
  }

  // 4. Invoice Information Header
  Widget _buildSectionHeader(String title, {String? badgeText}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        if (badgeText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF16A34A),
              ),
            ),
          ),
      ],
    );
  }

  // 5. Alerts
  Widget _buildAlerts() {
    return Column(
      children: [
        // Warning Alert: Missing Fields
        Obx(() {
          if (controller.missingFields.isEmpty) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB), // Warning Yellow Light
              border: Border.all(color: const Color(0xFFFCD34D)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'missing_fields_title'.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'missing_fields_msg'.tr,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF92400E)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),

        // Error Alert: Duplicate
        Obx(() {
          if (!controller.isDuplicate.value) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2), // Error Red Light
              border: Border.all(color: const Color(0xFFFECACA)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'duplicate_title'.tr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFFB91C1C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'duplicate_msg'.tr,
                        style: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // 6. Invoice Fields
  Widget _buildInvoiceFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Obx(() => _buildTextField(
                label: 'invoice_date'.tr,
                value: controller.invoiceDate.value != null 
                    ? DateFormat('dd MMM yyyy').format(controller.invoiceDate.value!)
                    : '',
                icon: Icons.calendar_today,
                onTap: controller.selectDate,
                helperText: controller.invoiceDate.value == null 
                    ? 'Date missing or format not supported' 
                    : null,
              )),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                label: 'invoice_number'.tr,
                controller: controller.invoiceNumberController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'supplier'.tr,
          controller: controller.supplierController,
        ),
        const SizedBox(height: 16),
        // Net Amount (editable)
        _buildMoneyField(
          label: 'Net Amount',
          value: controller.netAmount,
          onChanged: controller.updateNetAmount,
          textController: controller.netAmountController,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMoneyField(
                label: 'vat_amount'.tr,
                value: controller.vatAmount,
                readOnly: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMoneyField(
                label: 'Additional Charges',
                value: controller.additionalCharges,
                onChanged: controller.updateAdditionalCharges,
                textController: controller.additionalChargesController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Final Total (Gross + Additional, calculated, read-only)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Final Total',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 6),
            Obx(() {
              final total = controller.grossAmount.value + controller.additionalCharges.value;
              final displayText = total > 0 
                  ? NumberFormat("#,##0.00").format(total) 
                  : '0.00';
              return TextField(
                controller: TextEditingController(text: displayText),
                readOnly: true,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                decoration: InputDecoration(
                  prefixText: 'AED ',
                  prefixStyle: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }

  // 7. Category Section
  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'category'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 12),
        Obx(() => DropdownButtonFormField<String>(
          value: controller.selectedCategory.value.isEmpty ? null : controller.selectedCategory.value,
          hint: Text('select_category_hint'.tr),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            fillColor: Colors.white,
            filled: true,
          ),
          items: controller.categories.map((String c) {
            return DropdownMenuItem<String>(
              value: c,
              child: Text(InvoiceListController.getCategoryTranslationKey(c).tr),
            );
          }).toList(),
          onChanged: (val) => controller.selectedCategory.value = val ?? '',
        )),
        const SizedBox(height: 8),
        Text('helper_category'.tr, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            _buildChip('cat_utilities'.tr),
            _buildChip('cat_rent'.tr),
            _buildChip('cat_office_supplies'.tr),
            _buildChip('cat_marketing'.tr),
            _buildChip('cat_maintenance'.tr), // Added maintenance
          ],
        ),
      ],
    );
  }

  Widget _buildChip(String translationKey) {
    // Map translation keys back to English category values (same as stored in Firestore)
    final Map<String, String> translationKeyToCategory = {
      'cat_utilities': 'Utilities',
      'cat_rent': 'Rent',
      'cat_office_supplies': 'Office supplies',
      'cat_marketing': 'Marketing',
      'cat_maintenance': 'Maintenance',
      'cat_transport': 'Transport',
      'cat_subscriptions': 'Subscriptions',
      'cat_professional_fees': 'Professional fees',
      'cat_other': 'Other',
    };
    
    // Get the English category value (what's stored in Firestore)
    final categoryValue = translationKeyToCategory[translationKey] ?? 'Other';
    
    return ActionChip(
      label: Text(translationKey.tr), // Display translated label
      backgroundColor: const Color(0xFFF3F4F6),
      labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF374151), fontWeight: FontWeight.w500),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onPressed: () {
        // Save the English category value (not the translated label)
        controller.selectedCategory.value = categoryValue;
      },
    );
  }

  // 8. VAT Calculation Engine
  Widget _buildVatEngine() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6), // Muted Background
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'vat_calc_engine_title'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 16),
          // Radio Buttons
          Obx(() => Row(
            children: [
              _buildRadioOption('vat_inclusive_option'.tr, true),
              const SizedBox(width: 24),
              _buildRadioOption('vat_exclusive_option'.tr, false),
            ],
          )),
          const SizedBox(height: 8),
          Text(
            'vat_calc_helper'.tr,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          
          // Cards (Net, VAT, Gross)
          Obx(() => Column(
            children: [
              _buildEngineCard(
                title: 'vat_net_card_title'.tr,
                amount: controller.netAmount.value,
                descInclusive: 'vat_inclusive_net_desc'.tr,
                descExclusive: 'vat_exclusive_net_desc'.tr,
                shortLabel: 'short_net'.tr,
              ),
              const SizedBox(height: 12),
              _buildEngineCard(
                title: 'vat_vat_card_title'.tr,
                amount: controller.vatAmount.value,
                descInclusive: 'vat_inclusive_vat_desc'.tr,
                descExclusive: 'vat_exclusive_vat_desc'.tr,
                shortLabel: 'short_vat'.tr,
              ),
              const SizedBox(height: 12),
              _buildEngineCard(
                title: 'vat_gross_card_title'.tr,
                amount: controller.grossAmount.value,
                descInclusive: 'vat_inclusive_gross_desc'.tr,
                descExclusive: 'vat_exclusive_gross_desc'.tr,
                shortLabel: 'short_gross'.tr,
              ),
            ],
          )),
          
          const SizedBox(height: 16),
          // VAT Validation Message
          Obx(() => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: controller.vatValid.value ? const Color(0xFFDCFCE7) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: controller.vatValid.value ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      controller.vatValid.value ? Icons.check_circle : Icons.error,
                      color: controller.vatValid.value ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      controller.vatValid.value ? 'vat_calc_correct_msg'.tr : 'vat_incorrect'.tr,
                      style: TextStyle(
                        color: controller.vatValid.value ? const Color(0xFF166534) : const Color(0xFFB91C1C),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                // Could add specific formula text here if needed as per prompt "Formula: Net amount x 5%..."
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String label, bool value) {
    return GestureDetector(
      onTap: () => controller.isVatInclusive.value = value,
      child: Row(
        children: [
          Icon(
            controller.isVatInclusive.value == value ? Icons.radio_button_checked : Icons.radio_button_off,
            color: controller.isVatInclusive.value == value ? const Color(0xFF1E6FFF) : const Color(0xFF9CA3AF),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
        ],
      ),
    );
  }

  Widget _buildEngineCard({
    required String title,
    required double amount,
    required String descInclusive,
    required String descExclusive,
    required String shortLabel,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$shortLabel: ',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                ),
                TextSpan(
                  text: 'AED ${NumberFormat('#,##0.00').format(amount)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            controller.isVatInclusive.value ? descInclusive : descExclusive,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.4),
          ),
        ],
      ),
    );
  }

  // 9. Summary / Tax Breakdown
  Widget _buildTaxBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'summary_tax_breakdown'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 16),
          _buildBreakdownRow('vat_net_card_title'.tr, controller.netAmount),
          const SizedBox(height: 12),
          _buildBreakdownRow('label_vat_5_percent'.tr, controller.vatAmount),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFE5E7EB)),
          ),
          _buildBreakdownRow('vat_gross_card_title'.tr, controller.grossAmount, isBold: true),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, RxDouble value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF374151)))),
        Obx(() => Text(
          'AED ${NumberFormat('#,##0.00').format(value.value)}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: const Color(0xFF111827),
          ),
        )),
      ],
    );
  }

  // 10. CT Deductible
  Widget _buildCtDeductible() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ct_deductible_toggle'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 4),
                Text(
                  'ct_deductible_desc'.tr, // Description
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Obx(() => Switch(
            value: controller.isCtDeductible.value,
            onChanged: (val) => controller.isCtDeductible.value = val,
            activeColor: const Color(0xFF1E6FFF),
          )),
        ],
      ),
    );
  }

  // 10.5. Payment Status
  Widget _buildPaymentStatusSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Status',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 16),
          // Radio buttons for Paid/Not Paid
          Obx(() => Row(
            children: [
              _buildPaymentRadioOption('Paid', true),
              const SizedBox(width: 24),
              _buildPaymentRadioOption('Not Paid', false),
            ],
          )),
          const SizedBox(height: 16),
          // Due date picker (only show when Not Paid is selected)
          Obx(() {
            if (controller.isPaid.value) {
              return const SizedBox.shrink();
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Due Date',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '*',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: controller.selectDueDate,
                  child: Obx(() => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: controller.dueDate.value == null 
                            ? Colors.red.withValues(alpha: 0.5)
                            : const Color(0xFFD1D5DB),
                        width: controller.dueDate.value == null ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          controller.dueDate.value != null
                              ? DateFormat('dd MMM yyyy').format(controller.dueDate.value!)
                              : 'Select due date',
                          style: TextStyle(
                            fontSize: 14,
                            color: controller.dueDate.value != null 
                                ? const Color(0xFF111827) 
                                : const Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(Icons.calendar_today, size: 18, color: Color(0xFF9CA3AF)),
                      ],
                    ),
                  )),
                ),
                if (controller.dueDate.value == null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Due date is required for unpaid invoices',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red.shade600,
                    ),
                  ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentRadioOption(String label, bool value) {
    return GestureDetector(
      onTap: () => controller.isPaid.value = value,
      child: Row(
        children: [
          Icon(
            controller.isPaid.value == value ? Icons.radio_button_checked : Icons.radio_button_off,
            color: controller.isPaid.value == value ? const Color(0xFF1E6FFF) : const Color(0xFF9CA3AF),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
        ],
      ),
    );
  }

  // 11. Notes
  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'notes_section'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF111827)),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller.notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'notes_placeholder'.tr,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
          ),
        ),
      ],
    );
  }

  // 12. Review Before Saving
  Widget _buildReviewSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'review_before_saving'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 16),
          _buildReviewRow('supplier'.tr, controller.supplierController.text),
          Obx(() => _buildReviewRow('invoice_type'.tr, controller.isPurchase.value ? 'purchase_input_vat'.tr : 'sales_output_vat'.tr)),
          Obx(() => _buildReviewRow('short_net'.tr, 'AED ${NumberFormat('#,##0.00').format(controller.netAmount.value)}')),
          Obx(() => _buildReviewRow('short_vat'.tr, 'AED ${NumberFormat('#,##0.00').format(controller.vatAmount.value)}')),
          Obx(() => _buildReviewRow('Additional Charges', 'AED ${NumberFormat('#,##0.00').format(controller.additionalCharges.value)}')),
          Obx(() => _buildReviewRow('Final Total', 'AED ${NumberFormat('#,##0.00').format(controller.grossAmount.value + controller.additionalCharges.value)}', isBold: true)),
          const Divider(height: 24, color: Color(0xFFE5E7EB)),
          Obx(() => _buildReviewRow(
            'ct_deductible_toggle'.tr, 
            controller.isCtDeductible.value ? 'ct_deductible'.tr : 'ct_non_deductible'.tr,
            isBold: true
          )),
          const SizedBox(height: 12),
          Text(
            'review_footer_text'.tr, // "Make sure line items..."
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 13. Show Original Invoice Toggle
  Widget _buildOriginalInvoiceToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'show_original_invoice'.tr,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF111827)),
                ),
                Text(
                  'show_original_subtitle'.tr, // "Tap to open full-screen preview"
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          Obx(() => Switch(
            value: controller.showOriginalInvoice.value,
            onChanged: (val) => controller.showOriginalInvoice.value = val,
            activeColor: const Color(0xFF1E6FFF),
          )),
        ],
      ),
    );
  }

  // 14. Bottom Action Bar
  Widget _buildBottomActions() {
    // Check if this is a NEW invoice (from OCR) or EXISTING invoice (viewing saved)
    final isNewInvoice = controller.isNewInvoice;
    
    if (isNewInvoice) {
      // NEW invoice: Show "Discard" and "Confirm & Save"
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: controller.discardChanges,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'btn_discard'.tr, // Discard
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Obx(() => ElevatedButton(
              onPressed: controller.isSaving.value ? null : controller.confirmAndSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E6FFF), // Primary Blue
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: controller.isSaving.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'btn_confirm_save'.tr, // Confirm & Save
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            )),
          ),
        ],
      );
    } else {
      // EXISTING invoice: Show "Close" and "Update"
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Get.back(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Close',
                style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151)),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Obx(() => ElevatedButton(
              onPressed: (controller.isSaving.value || !controller.hasChanges.value) 
                  ? null 
                  : controller.confirmAndSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E6FFF), // Primary Blue
                disabledBackgroundColor: Colors.grey.shade300,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: controller.isSaving.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Update',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: controller.hasChanges.value ? Colors.white : Colors.grey.shade500,
                      ),
                    ),
            )),
          ),
        ],
      );
    }
  }

  // Helpers
  Widget _buildTextField({
    required String label,
    String? value,
    TextEditingController? controller,
    String? helperText,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: AbsorbPointer(
            absorbing: onTap != null,
            child: TextField(
              controller: controller ?? TextEditingController(text: value),
              maxLines: null,
              minLines: 1,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              decoration: InputDecoration(
                suffixIcon: icon != null ? Icon(icon, size: 18, color: const Color(0xFF9CA3AF)) : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(helperText, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ]
      ],
    );
  }

  Widget _buildMoneyField({
    required String label,
    required RxDouble value,
    Function(String)? onChanged,
    bool readOnly = false,
    TextEditingController? textController,
  }) {
    // For editable fields, MUST use the provided controller (from controller class)
    // For read-only, we can create a new one each time since user can't edit
    if (readOnly) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 6),
          Obx(() {
            final displayText = value.value > 0 
                ? NumberFormat("#,##0.00").format(value.value) 
                : '0.00';
            return TextField(
              controller: TextEditingController(text: displayText),
              readOnly: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              decoration: InputDecoration(
                prefixText: 'AED ',
                prefixStyle: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
              ),
            );
          }),
        ],
      );
    }
    
    // For editable fields - MUST use the provided controller, don't recreate it
    if (textController == null) {
      throw Exception('TextEditingController must be provided for editable money fields');
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 6),
        TextField(
          key: ValueKey('money_$label'), // Unique key to prevent rebuild issues
          controller: textController,
          readOnly: false,
          // REMOVED onChanged - let the controller listener handle updates
          // This prevents any interference with user typing
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827)),
          decoration: InputDecoration(
            prefixText: 'AED ',
            prefixStyle: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF111827)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
            filled: true,
            fillColor: Colors.white,
            hintText: '0.00',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
          ),
        ),
      ],
    );
  }
}
