import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fineye/core/constants/app_routes.dart';
import 'package:fineye/core/services/snackbar_service.dart';
import 'package:fineye/domain/services/compliance_status_service.dart';
import 'package:fineye/data/repositories/user_invoice_repository.dart';
import 'package:fineye/data/services/auth_service.dart';
import 'package:fineye/data/models/invoice_model.dart';
import 'dashboard_controller.dart';

const double vatTolerance = 0.05;

class InvoiceListController extends GetxController {
  final UserInvoiceRepository _invoiceRepository = UserInvoiceRepository();
  final AuthService _authService = AuthService();
  
  // Search & Filter
  final TextEditingController searchController = TextEditingController();
  final RxString searchQuery = ''.obs;

  // Risk Filter: all / with risk / no risk
  final RxString riskFilter = 'all'.obs;

  // Advanced Filters (from InvoiceFiltersController)
  final Rx<DateTime?> filterStartDate = Rx<DateTime?>(null);
  final Rx<DateTime?> filterEndDate = Rx<DateTime?>(null);
  final RxString filterSupplier = ''.obs;
  final RxString filterCategory = ''.obs;
  final RxList<String> filterStatuses = <String>[].obs;
  final RxString filterTaxType = 'All tax types'.obs;
  final RxDouble filterMinAmount = RxDouble(0.0);
  final RxDouble filterMaxAmount = RxDouble(0.0);

  // Saved Filters
  final RxList<Map<String, dynamic>> savedFilters = <Map<String, dynamic>>[].obs;
  final RxString defaultFilterName = 'VAT review'.obs;

  // Data
  final RxList<Invoice> invoices = <Invoice>[].obs;
  final RxList<Invoice> filteredInvoices = <Invoice>[].obs;
  final RxBool isLoading = false.obs;
  
  // Get saved filters count
  int get savedFiltersCount => savedFilters.length;
  
  // Get default filter name
  String get defaultFilterDisplayName => defaultFilterName.value;

  int get totalFlaggedInvoices =>
      invoices.where((inv) => inv.hasRisk).length;

  int get missingTrnCount =>
      invoices.expand((inv) => inv.risks).where((r) => r.type == InvoiceRiskType.missingTrn).length;

  int get vatMismatchCount =>
      invoices.expand((inv) => inv.risks).where((r) => r.type == InvoiceRiskType.vatMismatch).length;

  int get duplicateCount =>
      invoices.expand((inv) => inv.risks).where((r) => r.type == InvoiceRiskType.duplicateInvoice).length;

  // Helper function to get translation key for category
  static String getCategoryTranslationKey(String category) {
    final Map<String, String> categoryKeys = {
      'Office supplies': 'cat_office_supplies',
      'Utilities': 'cat_utilities',
      'Transport': 'cat_transport',
      'Subscriptions': 'cat_subscriptions',
      'Marketing': 'cat_marketing',
      'Professional fees': 'cat_professional_fees',
      'Rent': 'cat_rent',
      'Maintenance': 'cat_maintenance',
      'Other': 'cat_other',
    };
    return categoryKeys[category] ?? 'cat_other';
  }

  @override
  void onInit() {
    super.onInit();
    loadInvoices();
    loadSavedFilters();

    // Listen to search & filters
    searchController.addListener(() {
      searchQuery.value = searchController.text;
      _applyFilters();
    });
    ever(riskFilter, (_) => _applyFilters());
    ever(filterStartDate, (_) => _applyFilters());
    ever(filterEndDate, (_) => _applyFilters());
    ever(filterSupplier, (_) => _applyFilters());
    ever(filterCategory, (_) => _applyFilters());
    ever(filterStatuses, (_) => _applyFilters());
    ever(filterTaxType, (_) => _applyFilters());
    ever(filterMinAmount, (_) => _applyFilters());
    ever(filterMaxAmount, (_) => _applyFilters());
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
  
  List<InvoiceRisk> assessInvoiceRisks(Invoice invoice, List<Invoice> allInvoices) {
    List<InvoiceRisk> identifiedRisks = [];
    
    // 1. Missing TRN Check (High Risk)
    if (invoice.isVatRegistered && invoice.supplierName.toLowerCase().contains('unknown')) {
       identifiedRisks.add(const InvoiceRisk(
        type: InvoiceRiskType.missingTrn,
        severity: InvoiceRiskSeverity.high,
      ));
    }
    
    // 2. VAT Mismatch Check (High Risk)
    // Check if VAT is approx 5% of Net Amount
    // Net = Gross - VAT
    // Expected VAT = Net * 0.05
    if (invoice.vatAmount > 0) {
      final double netAmount = invoice.grossAmount - invoice.vatAmount;
      final double expectedVat = netAmount * 0.05;
      final double difference = (invoice.vatAmount - expectedVat).abs();
      
      if (difference > vatTolerance) {
        identifiedRisks.add(const InvoiceRisk(
          type: InvoiceRiskType.vatMismatch,
          severity: InvoiceRiskSeverity.high,
        ));
      }
    }
    
    // 3. Duplicate Invoice (Medium Risk)
    // Same Supplier + Same Date + Same Amount
    final bool isDuplicate = allInvoices.any((other) => 
      other.id != invoice.id &&
      other.supplierName == invoice.supplierName &&
      other.date.isAtSameMomentAs(invoice.date) &&
      (other.grossAmount - invoice.grossAmount).abs() < 0.01
    );
    
    if (isDuplicate) {
      identifiedRisks.add(const InvoiceRisk(
        type: InvoiceRiskType.duplicateInvoice,
        severity: InvoiceRiskSeverity.warning, // Medium
      ));
    }
    
    // 4. Missing Critical Fields (Medium Risk)
    if (invoice.supplierName.isEmpty) {
      identifiedRisks.add(const InvoiceRisk(
        type: InvoiceRiskType.missingSupplier,
        severity: InvoiceRiskSeverity.warning,
      ));
    }
    
    if (invoice.grossAmount <= 0) {
      identifiedRisks.add(const InvoiceRisk(
        type: InvoiceRiskType.missingAmount,
        severity: InvoiceRiskSeverity.warning,
      ));
    }
    
    // 5. VAT Charged but Supplier Not Registered (High Risk)
    if (invoice.vatAmount > 0 && invoice.taxBadge == 'Exempt') {
       identifiedRisks.add(const InvoiceRisk(
        type: InvoiceRiskType.supplierNotRegistered,
        severity: InvoiceRiskSeverity.high,
      ));
    }
    
    return identifiedRisks;
  }

  void loadInvoices() {
    final user = _authService.currentUser;
    if (user == null) {
      // No authenticated user; clear list and stop.
      invoices.clear();
      filteredInvoices.clear();
      isLoading.value = false;
      SnackbarService.to.showError(
        'Error',
        'You must be logged in to view invoices.',
      );
      return;
    }

    isLoading.value = true;

    // Try to load with index first, fallback to without index if needed
    Stream<List<Invoice>> invoiceStream;
    try {
      invoiceStream = _invoiceRepository.getInvoicesForUser(user.uid);
    } catch (e) {
      // If initial setup fails, use fallback
      debugPrint('Using fallback query (no index): $e');
      invoiceStream = _invoiceRepository.getInvoicesForUserWithoutIndex(user.uid);
    }

    // Listen to Firestore stream for this user's invoices in `user_invoices`.
    invoiceStream.listen((firestoreInvoices) {
      // Assess risks for all invoices
      final updatedInvoices = firestoreInvoices.map((invoice) {
        final risks = assessInvoiceRisks(invoice, firestoreInvoices);
        return invoice.copyWith(risks: risks);
      }).toList();

      invoices.assignAll(updatedInvoices);
      _applyFilters();
      isLoading.value = false;
    }, onError: (error) {
      print('Error loading invoices: $error');
      
      // Check if it's an index error - try fallback
      final errorStr = error.toString();
      if (errorStr.contains('index') || errorStr.contains('failed-precondition')) {
        // Extract the index creation URL if present
        final urlMatch = RegExp(r'https://[^\s]+').firstMatch(errorStr);
        final indexUrl = urlMatch?.group(0);
        
        print('⚠️ Index error detected. Trying fallback query...');
        if (indexUrl != null) {
          print('🔗 Create index at: $indexUrl');
        }
        
        // Try fallback query without index
        try {
          _invoiceRepository.getInvoicesForUserWithoutIndex(user.uid).listen((firestoreInvoices) {
            final updatedInvoices = firestoreInvoices.map((invoice) {
              final risks = assessInvoiceRisks(invoice, firestoreInvoices);
              return invoice.copyWith(risks: risks);
            }).toList();
            invoices.assignAll(updatedInvoices);
            _applyFilters();
            isLoading.value = false;
            
            // Log that we're using fallback (don't show annoying banner)
            print('⚠️ Using fallback query (no index). Create index for better performance.');
          }, onError: (fallbackError) {
            print('Fallback query also failed: $fallbackError');
            SnackbarService.to.showError(
              'Error',
              'Failed to load invoices. Please check your connection.',
            );
            invoices.clear();
            filteredInvoices.clear();
            isLoading.value = false;
          });
        } catch (e) {
          SnackbarService.to.showError(
            'Error',
            'Failed to load invoices: ${error.toString()}',
          );
          invoices.clear();
          filteredInvoices.clear();
          isLoading.value = false;
        }
      } else {
        SnackbarService.to.showError(
          'Error',
          'Failed to load invoices: ${error.toString()}',
        );
        invoices.clear();
        filteredInvoices.clear();
        isLoading.value = false;
      }
    });
  }

  void _applyFilters() {
    var result = invoices.toList();

    // Apply search query
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      result = result
          .where((inv) =>
              inv.supplierName.toLowerCase().contains(query) ||
              inv.id.toLowerCase().contains(query) ||
              inv.grossAmount.toString().contains(query))
          .toList();
    }

    // Apply risk filter
    if (riskFilter.value == 'with_risk') {
      result = result.where((inv) => inv.hasRisk).toList();
    } else if (riskFilter.value == 'no_risk') {
      result = result.where((inv) => !inv.hasRisk).toList();
    }

    // Apply advanced filters from InvoiceFiltersController
    if (filterStartDate.value != null) {
      result = result.where((inv) => inv.date.isAfter(filterStartDate.value!.subtract(const Duration(days: 1)))).toList();
    }
    if (filterEndDate.value != null) {
      result = result.where((inv) => inv.date.isBefore(filterEndDate.value!.add(const Duration(days: 1)))).toList();
    }
    if (filterSupplier.value.isNotEmpty && filterSupplier.value != 'All suppliers') {
      result = result.where((inv) => inv.supplierName == filterSupplier.value).toList();
    }
    if (filterCategory.value.isNotEmpty && filterCategory.value != 'All categories') {
      result = result.where((inv) => inv.category == filterCategory.value).toList();
    }
    if (filterStatuses.isNotEmpty) {
      result = result.where((inv) => filterStatuses.contains(inv.status)).toList();
    }
    if (filterTaxType.value != 'All tax types') {
      result = result.where((inv) => inv.taxBadge == filterTaxType.value).toList();
    }
    if (filterMinAmount.value > 0) {
      result = result.where((inv) => inv.grossAmount >= filterMinAmount.value).toList();
    }
    if (filterMaxAmount.value > 0) {
      result = result.where((inv) => inv.grossAmount <= filterMaxAmount.value).toList();
    }

    filteredInvoices.assignAll(result);
    print('🔍 Applied filters: ${result.length} invoices shown out of ${invoices.length} total');
  }

  Future<void> toggleFlag(Invoice invoice) async {
    invoice.isFlagged.value = !invoice.isFlagged.value;
    
    // Update in Firestore
    final updatedInvoice = invoice.copyWith(isFlagged: invoice.isFlagged.value);
    final success = await _invoiceRepository.updateInvoice(updatedInvoice);
    
    if (!success) {
      // Revert if update failed
      invoice.isFlagged.value = !invoice.isFlagged.value;
      SnackbarService.to.showError('Error', 'Failed to update invoice flag');
    }
  }

  void setRiskFilter(String value) {
    riskFilter.value = value;
  }

  void showFilterOptions() async {
    final result = await Get.toNamed(AppRoutes.invoiceFilters);
    if (result != null && result is Map) {
      // Apply filters from result
      filterStartDate.value = result['startDate'] as DateTime?;
      filterEndDate.value = result['endDate'] as DateTime?;
      filterSupplier.value = result['supplier'] as String? ?? '';
      filterCategory.value = result['category'] as String? ?? '';
      filterStatuses.assignAll((result['statuses'] as List<dynamic>?)?.cast<String>() ?? []);
      filterTaxType.value = result['taxType'] as String? ?? 'All tax types';
      
      // Parse amount filters
      final minAmountStr = result['minAmount'] as String? ?? '';
      final maxAmountStr = result['maxAmount'] as String? ?? '';
      filterMinAmount.value = minAmountStr.isNotEmpty ? double.tryParse(minAmountStr) ?? 0.0 : 0.0;
      filterMaxAmount.value = maxAmountStr.isNotEmpty ? double.tryParse(maxAmountStr) ?? 0.0 : 0.0;
      
      // Reapply filters
      _applyFilters();
      
      SnackbarService.to.showInfo(
        'title_filters_applied'.tr, 
        'Filters applied successfully',
      );
    }
  }
  
  void loadSavedFilters() {
    // Load saved filters from SharedPreferences or Firestore
    // For now, initialize with default filter
    if (savedFilters.isEmpty) {
      savedFilters.add({
        'name': 'VAT review',
        'isDefault': true,
        'filters': {
          'statuses': ['Pending', 'Review'],
          'taxType': 'VAT 5%',
        },
      });
      defaultFilterName.value = 'VAT review';
    }
  }
  
  void saveCurrentFilter(String name) {
    final filter = {
      'name': name,
      'isDefault': savedFilters.isEmpty,
      'filters': {
        'startDate': filterStartDate.value?.millisecondsSinceEpoch,
        'endDate': filterEndDate.value?.millisecondsSinceEpoch,
        'supplier': filterSupplier.value,
        'category': filterCategory.value,
        'statuses': filterStatuses.toList(),
        'taxType': filterTaxType.value,
        'minAmount': filterMinAmount.value,
        'maxAmount': filterMaxAmount.value,
      },
    };
    savedFilters.add(filter);
    if (filter['isDefault'] == true) {
      defaultFilterName.value = name;
    }
    // TODO: Persist to SharedPreferences or Firestore
  }

  Future<void> exportInvoices() async {
    // Show readiness checklist before allowing export
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().showReadinessChecklist();
    } else {
      // Fallback: Check compliance directly if dashboard not available
      final complianceService = Get.find<ComplianceStatusService>();
      if (!complianceService.canProceedToFile()) {
         SnackbarService.to.showError(
          'Action Blocked',
          'Cannot proceed with export. Please resolve all compliance issues first.',
        );
        return;
      }
      
      SnackbarService.to.showInfo(
        'Export',
        'Exporting invoices...',
      );
    }
  }

  // Refresh invoices manually
  Future<void> refreshInvoices() async {
    loadInvoices();
  }

  // Delete an invoice
  Future<void> deleteInvoice(Invoice invoice) async {
    try {
      // Use firestoreDocId if available, otherwise fallback to invoice.id
      final docId = invoice.firestoreDocId ?? invoice.id;
      debugPrint('🗑️ Deleting invoice with docId: $docId');
      
      final success = await _invoiceRepository.deleteInvoice(docId);
      if (success) {
        SnackbarService.to.showSuccess(
          'Success',
          'Invoice deleted successfully',
        );
        // The invoice list will automatically update via the Firestore stream
      } else {
        SnackbarService.to.showError(
          'Error',
          'Failed to delete invoice',
        );
      }
    } catch (e) {
      debugPrint('❌ Error deleting invoice: $e');
      SnackbarService.to.showError(
        'Error',
        'Failed to delete invoice: ${e.toString()}',
      );
    }
  }
}
