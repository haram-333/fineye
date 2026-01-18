import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/invoice_edit_controller.dart';
import '../../../core/constants/app_colors.dart';

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
        title: const Text(
          'Edit Invoice',
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
              // Invoice Number & Date
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Invoice Number',
                      controller: controller.invoiceNumberController,
                      required: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateField(
                      label: 'Invoice Date',
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
                label: 'Supplier Name',
                controller: controller.supplierController,
                required: true,
              ),
              const SizedBox(height: 16),
              
              // Category
              _buildCategoryField(controller),
              const SizedBox(height: 16),
              
              // Net Amount
              _buildAmountField(
                label: 'Net Amount',
                controller: controller.netAmountController,
                required: true,
                onChanged: () => controller.update(),
              ),
              const SizedBox(height: 16),
              
              // VAT Amount (calculated, read-only)
              _buildReadOnlyAmountField(
                label: 'VAT Amount (5%)',
                value: controller.vatAmount,
              ),
              const SizedBox(height: 16),
              
              // Additional Charges
              _buildAmountField(
                label: 'Additional Charges',
                controller: controller.additionalChargesController,
                onChanged: () => controller.update(),
              ),
              const SizedBox(height: 16),
              
              // Gross Amount (calculated, read-only)
              _buildReadOnlyAmountField(
                label: 'Gross Amount',
                value: controller.grossAmount,
              ),
              const SizedBox(height: 16),
              
              // Final Total (calculated, read-only)
              _buildReadOnlyAmountField(
                label: 'Final Total',
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
                label: 'Notes',
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
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
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
                Text(
                  date != null ? DateFormat('dd MMM yyyy').format(date) : 'Select date',
                  style: TextStyle(
                    fontSize: 14,
                    color: date != null ? AppColors.ink : Colors.grey,
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
        const Text(
          'Category',
          style: TextStyle(
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
            hint: const Text('Select category', style: TextStyle(color: Colors.grey)),
            items: controller.categories.map((cat) {
              return DropdownMenuItem(
                value: cat,
                child: Text(cat),
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
            text: NumberFormat("#,##0.00").format(value),
          ),
          readOnly: true,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: AppColors.ink,
          ),
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
          const Text(
            'Payment Status',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildPaymentRadio(
                label: 'Paid',
                value: true,
                selected: controller.isPaid,
                onTap: () => controller.setPaymentStatus(true),
              ),
              const SizedBox(width: 24),
              _buildPaymentRadio(
                label: 'Not Paid',
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
                const Text(
                  'Due Date',
                  style: TextStyle(
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
                    Text(
                      controller.dueDate != null
                          ? DateFormat('dd MMM yyyy').format(controller.dueDate!)
                          : 'Select due date',
                      style: TextStyle(
                        fontSize: 14,
                        color: controller.dueDate != null 
                            ? AppColors.ink 
                            : Colors.grey,
                      ),
                    ),
                    const Icon(Icons.calendar_today, size: 18, color: Color(0xFF9CA3AF)),
                  ],
                ),
              ),
            ),
            if (controller.dueDate == null) ...[
              const SizedBox(height: 4),
              const Text(
                'Due date is required for unpaid invoices',
                style: TextStyle(
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
          const Text(
            'CT Deductible',
            style: TextStyle(
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
