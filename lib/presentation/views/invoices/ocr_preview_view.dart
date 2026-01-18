import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/ocr_preview_controller.dart';
import '../../../data/models/invoice_model.dart';
import '../../../core/constants/app_colors.dart';

class OCRPreviewView extends GetView<OCRPreviewController> {
  const OCRPreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<OCRPreviewController>()) {
      Get.put(OCRPreviewController());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        top: false,
        bottom: false,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRiskSummary(),
                    const SizedBox(height: 16),
                    _buildWarnings(),
                    const SizedBox(height: 16),
                    _buildStructuredFieldsSection(),
                    const SizedBox(height: 24),
                    _buildAdditionalFieldsSection(),
                    const SizedBox(height: 24),
                    _buildRawOcrTextSection(),
                    const SizedBox(height: 24),
                    _buildAmountsSection(),
                    const SizedBox(height: 24),
                    _buildVatSettingsSection(),
                    const SizedBox(height: 24),
                    _buildCtDeductibleSection(),
                    const SizedBox(height: 24),
                    _buildNotesSection(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: false,
      backgroundColor: const Color(0xFFF5F7FA).withValues(alpha: 0.9),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: BackButton(color: AppColors.ink),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'invoice_details'.tr,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          Text(
            'review_screen_subtitle'.tr,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      centerTitle: false,
      actions: const [],
    );
  }

  Widget _buildRiskSummary() {
    return Obx(() {
      final risks = controller.risks;
      if (risks.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_outlined, color: Color(0xFF10B981)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'invoice_risk_none'.tr,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
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
                    color: AppColors.ink,
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
                                color: AppColors.ink,
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
        return 'risk_vat_calculation_error_title';
    }
  }

  Widget _buildWarnings() {
    return Column(
      children: [
        Obx(() {
          if (controller.missingFields.isEmpty) return const SizedBox.shrink();
          return _buildWarningBox(
            'missing_fields_warning'.tr,
            'missing_fields_desc'.tr,
            Icons.warning_amber_rounded,
            AppColors.warningYellow,
          );
        }),
        Obx(() {
          if (!controller.isDuplicate.value) return const SizedBox.shrink();
          return Column(
            children: [
              const SizedBox(height: 12),
              _buildWarningBox(
                'duplicate_warning'.tr,
                'duplicate_desc'.tr,
                Icons.content_copy,
                Colors.orange,
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildWarningBox(String title, String desc, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12, color: AppColors.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStructuredFieldsSection() {
    return _buildSection(
      'invoice_information'.tr,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Supplier Name
          _buildTextField(
            label: 'supplier_name'.tr,
            controller: controller.supplierController,
            icon: Icons.business,
            hint: 'enter_supplier_name'.tr,
          ),
          const SizedBox(height: 16),
          
          // Invoice Number
          _buildTextField(
            label: 'invoice_number'.tr,
            controller: controller.invoiceNumberController,
            icon: Icons.receipt_long,
            hint: 'enter_invoice_number'.tr,
          ),
          const SizedBox(height: 16),
          
          // Invoice Date
          Builder(
            builder: (context) => Obx(() => _buildDateField(
              label: 'invoice_date'.tr,
              date: controller.invoiceDate.value,
              onTap: () => _selectDate(context),
              icon: Icons.calendar_today,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalFieldsSection() {
    return Obx(() {
      if (controller.additionalFields.isEmpty) return const SizedBox.shrink();

      return _buildSection(
        'additional_details'.tr, 
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: controller.additionalFields.entries.map((entry) {
            final key = entry.key;
            // Prettify key
            final label = key.replaceAll('_', ' ').capitalizeFirst ?? key;

            // Get controller if exists
            final textController = controller.pAdditionalControllers[key] ??
                TextEditingController(text: entry.value);

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildTextField(
                label: label,
                controller: textController,
                icon: Icons.info_outline,
                hint: '',
              ),
            );
          }).toList(),
        ),
      );
    });
  }
  
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.ink),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.ink, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.ink),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                const Icon(Icons.calendar_today, size: 20, color: AppColors.ink),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: controller.invoiceDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      controller.invoiceDate.value = picked;
    }
  }

  Widget _buildRawOcrTextSection() {
    return _buildSection(
      'extracted_text'.tr,
      Obx(() {
        final text = controller.rawOcrText.value;
        if (text.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'no_text_extracted'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          );
        }

        // Detect if text contains Arabic characters for proper RTL handling
        // Expanded range includes Arabic, Persian, Urdu, and related scripts
        final arabicPattern = RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]');
        final containsArabic = arabicPattern.hasMatch(text);
        
        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 500),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: SelectableText(
              text,
              textDirection: containsArabic ? TextDirection.rtl : TextDirection.ltr,
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.ink,
                height: 1.8,
                letterSpacing: 0.3,
                fontFamily: containsArabic ? 'Noto Sans Arabic' : 'Roboto', // Better Arabic font support
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAmountsSection() {
    return _buildSection(
      'amounts'.tr,
      Column(
        children: [
          // Net Amount
          Obx(() => _buildAmountRow(
            'net_amount'.tr,
            controller.netAmount,
            onChanged: controller.updateNetAmount,
            formulaText: controller.isVatInclusive.value
                ? 'formula_net_inclusive'.tr
                : null,
          )),
          const Divider(height: 24),
          
          // VAT Amount
          _buildAmountRow(
            '${"vat_amount".tr} (5%)',
            controller.vatAmount,
            readOnly: true,
            formulaText: 'formula_vat'.tr,
          ),
          const Divider(height: 24),
          
          // Gross Amount (Prominent)
          Obx(() => _buildAmountRow(
            'gross_amount'.tr,
            controller.grossAmount,
            onChanged: controller.updateGrossAmount,
            isGross: true,
            formulaText: !controller.isVatInclusive.value
                ? 'formula_gross_exclusive'.tr
                : null,
          )),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    RxDouble amount, {
    Function(String)? onChanged,
    bool readOnly = false,
    bool isGross = false,
    String? formulaText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isGross ? FontWeight.bold : FontWeight.w600,
            fontSize: isGross ? 16 : 14,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => TextField(
          controller: TextEditingController(text: amount.value.toStringAsFixed(2))
            ..selection = TextSelection.collapsed(offset: amount.value.toStringAsFixed(2).length),
          readOnly: readOnly,
          keyboardType: TextInputType.number,
          textDirection: TextDirection.ltr,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: isGross ? 18 : 15,
            fontWeight: isGross ? FontWeight.bold : FontWeight.normal,
            color: AppColors.ink,
          ),
          decoration: InputDecoration(
            prefixText: 'AED ',
            prefixStyle: TextStyle(
              fontSize: isGross ? 18 : 15,
              fontWeight: isGross ? FontWeight.bold : FontWeight.normal,
              color: AppColors.ink,
            ),
            filled: true,
            fillColor: readOnly ? const Color(0xFFF5F5F5) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
            ),
          ),
        )),
        if (formulaText != null) ...[
          const SizedBox(height: 6),
          Text(
            formulaText,
            style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ],
      ],
    );
  }

  Widget _buildVatSettingsSection() {
    return _buildSection(
      'vat_settings'.tr,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('vat_type'.tr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Obx(() => Row(
            children: [
              Expanded(
                child: _buildRadioOption(
                  'vat_inclusive_option'.tr,
                  controller.isVatInclusive.value,
                  () => controller.isVatInclusive.value = true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRadioOption(
                  'vat_exclusive_option'.tr,
                  !controller.isVatInclusive.value,
                  () => controller.isVatInclusive.value = false,
                ),
              ),
            ],
          )),
          const SizedBox(height: 20),
          
          Text('invoice_type'.tr, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          Obx(() => Row(
            children: [
              Expanded(
                child: _buildRadioOption(
                  'purchase_input_vat'.tr,
                  controller.isPurchase.value,
                  () => controller.isPurchase.value = true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRadioOption(
                  'sales_output_vat'.tr,
                  !controller.isPurchase.value,
                  () => controller.isPurchase.value = false,
                ),
              ),
            ],
          )),
          const SizedBox(height: 20),
          
          // VAT Validation Indicator
          Obx(() => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: controller.vatValid.value
                  ? AppColors.successGreen.withValues(alpha: 0.1)
                  : AppColors.warningYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: controller.vatValid.value
                    ? AppColors.successGreen
                    : AppColors.warningYellow,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  controller.vatValid.value ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: controller.vatValid.value
                      ? AppColors.successGreen
                      : AppColors.warningYellow,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.vatValid.value ? 'vat_correct'.tr : 'vat_incorrect'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: controller.vatValid.value
                          ? AppColors.successGreen
                          : AppColors.warningYellow,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryBlue.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : AppColors.borderGrey,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? AppColors.primaryBlue : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? AppColors.primaryBlue : AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCtDeductibleSection() {
    return _buildSection(
      'ct_deductible_section'.tr,
      Obx(() => SwitchListTile(
        value: controller.isCtDeductible.value,
        onChanged: (value) => controller.isCtDeductible.value = value,
        title: Text('ct_deductible_toggle'.tr),
        contentPadding: EdgeInsets.zero,
        activeColor: AppColors.primaryBlue,
      )),
    );
  }

  Widget _buildNotesSection() {
    return _buildSection(
      'notes_section'.tr,
      TextField(
        controller: controller.notesController,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: 'notes_placeholder'.tr,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: controller.showReviewSummary,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryBlue),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'review_before_saving'.tr,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: controller.isSaving.value ? null : controller.saveInvoice,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              disabledBackgroundColor: Colors.grey.shade400,
            ),
            child: controller.isSaving.value
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'saving_invoice'.tr,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                : Text(
                    'save_invoice'.tr,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        )),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Get.back(),
          child: Text('cancel'.tr, style: const TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

}
