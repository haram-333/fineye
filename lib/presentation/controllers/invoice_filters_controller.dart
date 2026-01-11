
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fineye/presentation/controllers/invoice_list_controller.dart';

class InvoiceFiltersController extends GetxController {
  // Date Range
  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();
  final selectedPeriod = 'period_this_month'.obs;

  // Supplier & Category
  final selectedSupplier = Rxn<String>();
  final selectedCategory = Rxn<String>();
  
  // Dynamic Data for Dropdowns (populated from actual invoices)
  final RxList<String> suppliers = <String>['All suppliers'].obs;
  final RxList<String> categories = <String>['All categories'].obs;

  // Status
  final selectedStatuses = <String>[].obs;
  final allStatuses = ['Approved', 'Paid', 'Review', 'Flagged'];

  // Tax Type
  final selectedTaxType = 'All tax types'.obs;
  final allTaxTypes = ['All tax types', 'VAT 5%', 'Zero-rated', 'Exempt'];

  // Amount Range
  final minAmountController = TextEditingController();
  final maxAmountController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    // Initialize with default values
    setToThisMonth();
    // Load suppliers and categories from actual invoices
    _loadDynamicData();
  }
  
  void _loadDynamicData() {
    if (Get.isRegistered<InvoiceListController>()) {
      final invoiceController = Get.find<InvoiceListController>();
      
      // Extract unique suppliers
      final uniqueSuppliers = invoiceController.invoices
          .map((inv) => inv.supplierName)
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList();
      uniqueSuppliers.sort();
      suppliers.value = ['All suppliers', ...uniqueSuppliers];
      
      // Extract unique categories
      final uniqueCategories = invoiceController.invoices
          .map((inv) => inv.category)
          .where((cat) => cat.isNotEmpty)
          .toSet()
          .toList();
      uniqueCategories.sort();
      categories.value = ['All categories', ...uniqueCategories];
      
      print('✅ Loaded ${uniqueSuppliers.length} suppliers and ${uniqueCategories.length} categories');
    }
  }

  void onDateSelected(DateTime? start, DateTime? end) {
    startDate.value = start;
    endDate.value = end;
    selectedPeriod.value = ''; // Clear preset if custom range
  }

  void setToThisMonth() {
    final now = DateTime.now();
    startDate.value = DateTime(now.year, now.month, 1);
    endDate.value = DateTime(now.year, now.month + 1, 0);
    selectedPeriod.value = 'period_this_month';
  }

  void setToLastMonth() {
    final now = DateTime.now();
    startDate.value = DateTime(now.year, now.month - 1, 1);
    endDate.value = DateTime(now.year, now.month, 0);
    selectedPeriod.value = 'period_last_month';
  }

  void setToLast90Days() {
    final now = DateTime.now();
    endDate.value = now;
    startDate.value = now.subtract(const Duration(days: 90));
    selectedPeriod.value = 'period_last_90';
  }

  void setToThisYear() {
    final now = DateTime.now();
    startDate.value = DateTime(now.year, 1, 1);
    endDate.value = DateTime(now.year, 12, 31);
    selectedPeriod.value = 'period_this_year';
  }

  void toggleStatus(String status) {
    if (selectedStatuses.contains(status)) {
      selectedStatuses.remove(status);
    } else {
      selectedStatuses.add(status);
    }
  }

  void setTaxType(String type) {
    selectedTaxType.value = type;
  }

  void clearAll() {
    setToThisMonth();
    selectedSupplier.value = null;
    selectedCategory.value = null;
    selectedStatuses.clear();
    selectedTaxType.value = 'All tax types';
    minAmountController.clear();
    maxAmountController.clear();
  }

  void applyFilters() {
    // Implement apply logic and pass back to previous screen
    Get.back(result: {
      'startDate': startDate.value,
      'endDate': endDate.value,
      'supplier': selectedSupplier.value,
      'category': selectedCategory.value,
      'statuses': selectedStatuses,
      'taxType': selectedTaxType.value,
      'minAmount': minAmountController.text,
      'maxAmount': maxAmountController.text,
    });
  }

  @override
  void onClose() {
    minAmountController.dispose();
    maxAmountController.dispose();
    super.onClose();
  }
}
