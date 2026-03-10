import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../controllers/invoice_edit_controller.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/format_helper.dart';

class InvoiceEditView extends GetView<InvoiceEditController> {
  const InvoiceEditView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<InvoiceEditController>()) {
      Get.put(InvoiceEditController());
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: AppColors.ink),
        title: Text(
          'edit_invoice'.tr,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        // Removed top save button - only bottom one
      ),
      body: GetBuilder<InvoiceEditController>(
        builder: (controller) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImagePreview(controller),
              const SizedBox(height: 20),
              // Invoice Number & Date
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'invoice_number'.tr,
                      controller: controller.invoiceNumberController,
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateField(
                      label: 'invoice_date'.tr,
                      date: controller.invoiceDate,
                      onTap: controller.selectDate,
                      required: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Supplier
              _buildTextField(
                label: 'supplier_name'.tr,
                controller: controller.supplierController,
                required: true,
              ),
              const SizedBox(height: 16),
              
              // Category
              _buildCategoryField(controller),
              const SizedBox(height: 16),
              
              // Net Amount
              _buildAmountField(
                label: 'net_amount'.tr,
                controller: controller.netAmountController,
                required: true,
                onChanged: () => controller.update(),
              ),
              const SizedBox(height: 16),
              
              // VAT Amount (calculated, read-only)
              _buildReadOnlyAmountField(
                label: '${"vat_amount".tr} (5%)',
                value: controller.vatAmount,
              ),
              const SizedBox(height: 16),
              
              // Additional Charges
              _buildAmountField(
                label: 'additional_charges'.tr,
                controller: controller.additionalChargesController,
                onChanged: () => controller.update(),
              ),
              const SizedBox(height: 16),
              
              // Gross Amount (calculated, read-only)
              _buildReadOnlyAmountField(
                label: 'gross_amount'.tr,
                value: controller.grossAmount,
              ),
              const SizedBox(height: 16),
              
              // Final Total (calculated, read-only)
              _buildReadOnlyAmountField(
                label: 'final_total'.tr,
                value: controller.finalTotal,
                isTotal: true,
              ),
              const SizedBox(height: 24),
              
              // Payment Status
              _buildPaymentStatusSection(controller),
              const SizedBox(height: 24),
              
              // CT Deductible
              _buildCtDeductibleSection(controller),
              const SizedBox(height: 24),
              
              // Notes
              _buildTextField(
                label: 'notes_section'.tr,
                controller: controller.notesController,
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: controller.saveInvoice,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'save_changes'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(InvoiceEditController controller) {
    final imageUrl = controller.invoice.imageUrl;
    // For demo/debugging if imageUrl is null but it's a known invoice
    if (imageUrl == null || imageUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'invoice_preview'.tr, // Correctly localized
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showFullScreenImage(imageUrl),
              icon: const Icon(Icons.fullscreen, size: 20, color: AppColors.primaryBlue),
              label: Text(
                'full_details'.tr,
                style: const TextStyle(color: AppColors.primaryBlue),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showFullScreenImage(imageUrl),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              color: Colors.white,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40),
                            const SizedBox(height: 8),
                            Text('error_loading_image'.tr, style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'tap_to_enlarge'.tr,
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              child: Container(
                color: Colors.black.withValues(alpha: 0.9),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            InteractiveViewer(
              maxScale: 5.0,
              child: Image.network(
                imageUrl,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                },
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Get.back(),
                ),
              ),
            ),
          ],
        ),
      ),
      useSafeArea: false,
    );
  }
  
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: AppColors.ink),
          decoration: InputDecoration(
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
  
  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    bool required = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFD1D5DB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: Text(
                    date != null ? FormatHelper.date(date) : 'select_date'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      color: date != null ? AppColors.ink : Colors.grey,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today, size: 18, color: Color(0xFF9CA3AF)),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCategoryField(InvoiceEditController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'category'.tr,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFD1D5DB)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<String>(
            value: controller.selectedCategory.isEmpty ? null : controller.selectedCategory,
            isExpanded: true,
            underline: const SizedBox(),
            hint: Text('select_category'.tr, style: const TextStyle(color: Colors.grey)),
            items: controller.categories.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Text(controller.getLocalizedCategory(cat)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.setCategory(value);
              }
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildAmountField({
    required String label,
    required TextEditingController controller,
    bool required = false,
    VoidCallback? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            if (required) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontSize: 14, color: AppColors.ink),
          onChanged: (_) => onChanged?.call(),
          decoration: InputDecoration(
            prefixText: 'AED ',
            prefixStyle: const TextStyle(fontSize: 14, color: AppColors.ink),
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
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
  
  Widget _buildReadOnlyAmountField({
    required String label,
    required double value,
    bool isTotal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: TextEditingController(
            text: FormatHelper.amount(value),
          ),
          readOnly: true,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: AppColors.ink,
          ),
          textAlign: TextAlign.start,
          textDirection: ui.TextDirection.ltr,
          decoration: InputDecoration(
            prefixText: 'AED ',
            prefixStyle: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: AppColors.ink,
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPaymentStatusSection(InvoiceEditController controller) {
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
            'payment_status'.tr,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildPaymentRadio(
                label: 'paid'.tr,
                value: true,
                selected: controller.isPaid,
                onTap: () => controller.setPaymentStatus(true),
              ),
              const SizedBox(width: 24),
              _buildPaymentRadio(
                label: 'not_paid'.tr,
                value: false,
                selected: !controller.isPaid,
                onTap: () => controller.setPaymentStatus(false),
              ),
            ],
          ),
          if (!controller.isPaid) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'due_date'.tr,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: controller.selectDueDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: controller.dueDate == null 
                        ? Colors.red.withValues(alpha: 0.5)
                        : const Color(0xFFD1D5DB),
                    width: controller.dueDate == null ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Directionality(
                      textDirection: ui.TextDirection.ltr,
                      child: Text(
                        controller.dueDate != null
                            ? FormatHelper.date(controller.dueDate!)
                            : 'select_due_date'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          color: controller.dueDate != null 
                              ? AppColors.ink 
                              : Colors.grey,
                        ),
                      ),
                    ),
                    const Icon(Icons.calendar_today, size: 18, color: Color(0xFF9CA3AF)),
                  ],
                ),
              ),
            ),
            if (controller.dueDate == null) ...[
              const SizedBox(height: 4),
              Text(
                'due_date_required'.tr,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
  
  Widget _buildPaymentRadio({
    required String label,
    required bool value,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? AppColors.primaryBlue : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCtDeductibleSection(InvoiceEditController controller) {
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
          Text(
            'ct_deductible_section'.tr,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColors.ink,
            ),
          ),
          Switch(
            value: controller.isCtDeductible,
            onChanged: (_) => controller.toggleCtDeductible(),
            activeColor: AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }
}
