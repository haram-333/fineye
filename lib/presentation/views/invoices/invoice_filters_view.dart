
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:fineye/presentation/controllers/invoice_filters_controller.dart';
import 'package:fineye/core/constants/app_colors.dart';
import 'package:fineye/core/services/snackbar_service.dart';

class InvoiceFiltersView extends GetView<InvoiceFiltersController> {
  const InvoiceFiltersView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is registered
    if (!Get.isRegistered<InvoiceFiltersController>()) {
      Get.put(InvoiceFiltersController());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildDateRangeSection(context),
            const SizedBox(height: 16),
            _buildSupplierCategorySection(),
            const SizedBox(height: 16),
            _buildStatusSection(),
            const SizedBox(height: 16),
            _buildTaxTypeSection(),
            const SizedBox(height: 16),
            _buildAmountRangeSection(),
            const SizedBox(height: 20), // Reduced spacing
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(context),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: const BackButton(color: Colors.black),
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'filters_title'.tr,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          Text(
            'filters_subtitle'.tr,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: controller.clearAll,
          child: Text(
            'clear_all'.tr,
            style: const TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildDateRangeSection(BuildContext context) {
    return _buildSectionCard(
      title: 'date_range_title'.tr,
      subtitle: 'date_range_subtitle'.tr,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('label_from'.tr, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 6),
                    _buildDatePicker(context, isStartDate: true),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('label_to'.tr, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    const SizedBox(height: 6),
                    _buildDatePicker(context, isStartDate: false),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickDateBtn('period_this_month', controller.setToThisMonth),
                const SizedBox(width: 8),
                _buildQuickDateBtn('period_last_month', controller.setToLastMonth),
                const SizedBox(width: 8),
                _buildQuickDateBtn('period_last_90', controller.setToLast90Days),
                const SizedBox(width: 8),
                _buildQuickDateBtn('period_this_year', controller.setToThisYear),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, {required bool isStartDate}) {
    return Obx(() {
      final date = isStartDate ? controller.startDate.value : controller.endDate.value;
      final text = date != null ? DateFormat('dd MMM yyyy').format(date) : 'select_date'.tr;
      
      return InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
          );
          if (picked != null) {
            if (isStartDate) {
              controller.onDateSelected(picked, controller.endDate.value);
            } else {
              controller.onDateSelected(controller.startDate.value, picked);
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: date != null ? Colors.black : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey.shade600),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildQuickDateBtn(String key, VoidCallback onTap) {
    return Obx(() {
      final isSelected = controller.selectedPeriod.value == key;
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.grey.shade50,
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            key.tr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSelected ? AppColors.primaryBlue : Colors.grey.shade600,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSupplierCategorySection() {
    return _buildSectionCard(
      title: 'supplier_category_title'.tr,
      subtitle: '', // Hiding subtitle as per image implies structure
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('label_supplier'.tr, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 6),
          Obx(() => DropdownButtonFormField<String>(
            value: controller.selectedSupplier.value,
            hint: Text('all_suppliers'.tr, style: const TextStyle(color: Colors.grey)),
            items: controller.suppliers.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (val) => controller.selectedSupplier.value = val,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          )),
          const SizedBox(height: 16),
          Text('label_category'.tr, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 6),
          Obx(() => DropdownButtonFormField<String>(
            value: controller.selectedCategory.value,
            hint: Text('all_categories'.tr, style: const TextStyle(color: Colors.grey)),
            items: controller.categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (val) => controller.selectedCategory.value = val,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    return _buildSectionCard(
      title: 'status_title'.tr,
      subtitle: 'status_subtitle'.tr,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: controller.allStatuses.map((status) => _buildStatusChip(status)).toList(),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;

    // Matching colors from visual design
    switch (status) {
      case 'Paid':
        color = const Color(0xFF10B981);
        break;
      case 'Pending':
        color = const Color(0xFFF59E0B);
        break;
      case 'Review':
        color = const Color(0xFF3B82F6);
        break;
      case 'Flagged':
        color = const Color(0xFFEF4444);
        break;
      default:
        color = Colors.grey;
    }

    return Obx(() {
      final isSelected = controller.selectedStatuses.contains(status);
      return GestureDetector(
        onTap: () => controller.toggleStatus(status),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.transparent,
            border: Border.all(color: isSelected ? color : Colors.grey.shade200),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status.tr, // Assuming simple translation keys for now
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : color,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTaxTypeSection() {
    return _buildSectionCard(
      title: 'tax_type_title'.tr,
      subtitle: 'tax_type_subtitle'.tr,
      child: Obx(() => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: controller.allTaxTypes.map((type) {
          final isSelected = controller.selectedTaxType.value == type;
          return GestureDetector(
            onTap: () => controller.setTaxType(type),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.white,
                border: Border.all(
                  color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
                  width: isSelected ? 1.5 : 1,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                // Localization key mapping needs to be handled if strict, using raw for now or defined keys
                _getTaxTypeTr(type),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.primaryBlue : Colors.black87,
                ),
              ),
            ),
          );
        }).toList(),
      )),
    );
  }

  String _getTaxTypeTr(String type) {
    switch (type) {
      case 'All tax types': return 'all_tax_types'.tr;
      case 'VAT 5%': return 'vat_5_percent'.tr;
      case 'Zero-rated': return 'zero_rated'.tr;
      case 'Exempt': return 'exempt'.tr;
      default: return type;
    }
  }

  Widget _buildAmountRangeSection() {
    return _buildSectionCard(
      title: 'amount_range_title'.tr,
      subtitle: 'amount_range_subtitle'.tr,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('min_amount'.tr, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: controller.minAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'AED 0.00',
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('max_amount'.tr, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: controller.maxAmountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'no_limit'.tr,
                    hintStyle: TextStyle(color: Colors.grey.shade400),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: controller.applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'apply_filters'.tr,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () {
                  // Save logic placeholder
                  SnackbarService.to.showSuccess(
                    'title_saved'.tr, 
                    'msg_view_saved_default'.tr,
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'save_as_default'.tr,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

