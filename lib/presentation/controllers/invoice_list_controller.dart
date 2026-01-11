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

  // Data
  final RxList<Invoice> invoices = <Invoice>[].obs;
  final RxList<Invoice> filteredInvoices = <Invoice>[].obs;
  final RxBool isLoading = false.obs;

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

    // Listen to search & filters
    searchController.addListener(() {
      searchQuery.value = searchController.text;
      _applyFilters();
    });
    ever(riskFilter, (_) => _applyFilters());
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

    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      result = result
          .where((inv) =>
              inv.supplierName.toLowerCase().contains(query) ||
              inv.id.toLowerCase().contains(query) ||
              inv.grossAmount.toString().contains(query))
          .toList();
    }

    if (riskFilter.value == 'with_risk') {
      result = result.where((inv) => inv.hasRisk).toList();
    } else if (riskFilter.value == 'no_risk') {
      result = result.where((inv) => !inv.hasRisk).toList();
    }

    filteredInvoices.assignAll(result);
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
    if (result != null) {
      // Logic to apply filters would go here
      // For now, we just acknowledge the return
      if (result is Map) {
        // Example: supplier = result['supplier']
      }
      SnackbarService.to.showInfo(
        'title_filters_applied'.tr, 
        'msg_filters_received'.tr,
      );
    }
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
