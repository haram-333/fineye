
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
  final allStatuses = ['Paid', 'Pending', 'Review'];

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
    
    // Reload dynamic data when invoices change
    if (Get.isRegistered<InvoiceListController>()) {
      final invoiceController = Get.find<InvoiceListController>();
      ever(invoiceController.invoices, (_) {
        _loadDynamicData();
      });
    }
  }
  
  void _loadDynamicData() {
    if (Get.isRegistered<InvoiceListController>()) {
      final invoiceController = Get.find<InvoiceListController>();
      
      // Extract unique suppliers (trim and filter out empty/unknown)
      final uniqueSuppliers = invoiceController.invoices
          .map((inv) => inv.supplierName.trim())
          .where((name) => name.isNotEmpty && 
                          name.toLowerCase() != 'unknown' && 
                          name.toLowerCase() != 'unknown supplier')
          .toSet()
          .toList();
      uniqueSuppliers.sort();
      suppliers.value = ['All suppliers', ...uniqueSuppliers];
      
      // Extract unique categories (trim and filter out empty)
      final uniqueCategories = invoiceController.invoices
          .map((inv) => inv.category.trim())
          .where((cat) => cat.isNotEmpty)
          .toSet()
          .toList();
      uniqueCategories.sort();
      categories.value = ['All categories', ...uniqueCategories];
      
      print('✅ Loaded ${uniqueSuppliers.length} suppliers and ${uniqueCategories.length} categories');
      print('  Suppliers: ${uniqueSuppliers.take(5).toList()}');
      print('  Categories: ${uniqueCategories.take(5).toList()}');
    }
  }
  
  /// Reload dynamic data (call this when invoices are updated)
  void reloadDynamicData() {
    _loadDynamicData();
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
    // Clear date range completely (don't set to this month)
    startDate.value = null;
    endDate.value = null;
    selectedPeriod.value = ''; // Clear period selection
    selectedSupplier.value = null;
    selectedCategory.value = null;
    selectedStatuses.clear();
    selectedTaxType.value = 'All tax types';
    minAmountController.clear();
    maxAmountController.clear();
  }

  void applyFilters() {
    // Normalize filter values before passing back
    // Convert "All suppliers" / "All categories" to null/empty
    final supplierValue = (selectedSupplier.value == null || 
                           selectedSupplier.value == 'All suppliers') 
        ? null 
        : selectedSupplier.value;
    
    final categoryValue = (selectedCategory.value == null || 
                          selectedCategory.value == 'All categories') 
        ? null 
        : selectedCategory.value;
    
    // Implement apply logic and pass back to previous screen
    Get.back(result: {
      'startDate': startDate.value,
      'endDate': endDate.value,
      'supplier': supplierValue,
      'category': categoryValue,
      'statuses': selectedStatuses.toList(), // Convert to regular list
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
