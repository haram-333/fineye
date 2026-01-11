import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/snackbar_service.dart';
import '../../domain/services/compliance_status_service.dart';
import '../../data/models/invoice_model.dart';
import '../views/dashboard/widgets/readiness_checklist_modal.dart';
import 'company_profile_controller.dart';
import 'invoice_list_controller.dart';
import 'status_bar_controller.dart';
import '../../core/services/invoice_export_service.dart';



class NotificationItem {
  final String message;
  final String time;
  final String category; // 'VAT', 'Corporate', 'System'

  NotificationItem({
    required this.message,
    required this.time,
    required this.category,
  });
}

class DashboardController extends GetxController {
  // Services
  final _complianceService = Get.find<ComplianceStatusService>();

  // Reactive variables
  final totalExpenses = 0.0.obs;
  final totalVAT = 0.0.obs;
  final invoiceCount = 0.obs;


  final totalVat = 'AED 24,500.00'.obs;
  final pendingInvoices = 12.obs;
  
  // Company setup completion flag
  final isCompanySetupComplete = true.obs;
  final showSetupBanner = false.obs;

  // VAT Data
  var vatTotalAmount = 'AED 2,890.00'.obs;
  var vatPendingCount = '8'.obs;
  var vatDeadlineDate = 'Due: 28 Jul 2025'.obs;
  var vatDaysLeftCount = 10.obs;

  // VAT Breakdown (for "Why this amount?")
  var vatOutputAmount = 'AED 4,500.00'.obs;
  var vatInputAmount = 'AED -1,610.00'.obs;
  var vatAdjustmentsAmount = 'AED 0.00'.obs;

  // Corporate Tax Data
  var ctTotalAmount = 'AED 18,400.00'.obs;
  var ctNextPaymentType = 'Advance'.obs;
  var ctDeadlineDate = 'Due: 15 Sep 2025'.obs;
  var ctDaysLeftCount = 59.obs;

  // Deadlines
  final vatDeadline = DateTime.now().obs;
  final ctDeadline = DateTime.now().obs;

  // CT specific
  final ctEstimate = 0.0.obs;

  // Notifications
  final recentNotifications = <NotificationItem>[].obs;
  
  // Compliance internal tracking
  final unverifiedInvoiceCount = 0.obs;
  final hasHighRiskInvoices = false.obs;
  final highRiskInvoicesCount = 0.obs;


  Rx<ComplianceStatus> get complianceStatus => _complianceService.currentStatus;
  
  // Readiness check results mirrored from service
  RxBool get allInvoicesReviewed => RxBool(!_complianceService.hasUnreviewedInvoices.value);
  RxInt get pendingInvoicesCount => _complianceService.unreviewedCount;
  RxBool get noHighRiskFlags => RxBool(!_complianceService.hasHighRiskFlags.value);
  RxBool get taxPeriodComplete => _complianceService.isTaxPeriodComplete;




  @override
  void onInit() {
    super.onInit();
    Get.find<StatusBarController>().setTransparent();
    
    // Ensure InvoiceListController is initialized first
    if (!Get.isRegistered<InvoiceListController>()) {
      Get.put(InvoiceListController());
    }
    
    // Initial data sync (handles empty state)
    _syncComplianceData();
    
    // Listen for changes to invoices and update dashboard data
    final invoiceController = Get.find<InvoiceListController>();
    ever(invoiceController.invoices, (_) {
      _syncComplianceData();
      _calculateTotalsFromInvoices(invoiceController.invoices);
    });
    
    // Load dashboard data
    loadDashboardData();
    _checkCompanySetup();
  }

  void _syncComplianceData() {
    if (Get.isRegistered<InvoiceListController>()) {
      final invoiceController = Get.find<InvoiceListController>();
      
      final totalInvoices = invoiceController.invoices.length;
      final reviewedInvoices = invoiceController.invoices.where((i) => i.status == 'Reviewed').length;
      
      // Update service with real data
      // If there are 0 invoices, hasUnreviewedInvoices will be false (passes the check)
      _complianceService.updateInvoiceStatus(
        totalInvoices: totalInvoices,
        reviewedInvoices: reviewedInvoices,
      );
      
      // Count high-risk invoices based on risks property
      // If there are 0 invoices, all counts will be 0 (passes the checks)
      final highRisks = invoiceController.invoices.where((i) => i.risks.any((r) => r.severity.toString().contains('high'))).length;
      final totalRisks = invoiceController.invoices.where((i) => i.risks.isNotEmpty).length;
      
      _complianceService.updateRiskStatus(
        totalRisks: totalRisks,
        highRisks: highRisks,
      );
    } else {
      // If InvoiceListController is not registered, set safe defaults for empty state
      _complianceService.updateInvoiceStatus(
        totalInvoices: 0,
        reviewedInvoices: 0,
      );
      _complianceService.updateRiskStatus(
        totalRisks: 0,
        highRisks: 0,
      );
    }
  }
  
  void _checkCompanySetup() {
    // Check if CompanyProfileController is registered
    if (Get.isRegistered<CompanyProfileController>()) {
      final companyController = Get.find<CompanyProfileController>();
      isCompanySetupComplete.value = companyController.isCompanySetupComplete();
      showSetupBanner.value = !isCompanySetupComplete.value;
    } else {
      // If controller not registered, assume incomplete setup
      isCompanySetupComplete.value = false;
      showSetupBanner.value = true;
    }
  }
  
  void goToCompanyProfile() {
    Get.toNamed(AppRoutes.companyProfile);
  }
  
  void dismissSetupBanner() {
    showSetupBanner.value = false;
  }

  void loadDashboardData() {
    // Ensure InvoiceListController is initialized for real compliance data
    if (!Get.isRegistered<InvoiceListController>()) {
      Get.put(InvoiceListController());
    }
    
    final invoiceController = Get.find<InvoiceListController>();
    
    // Calculate real totals from invoices
    _calculateTotalsFromInvoices(invoiceController.invoices);
    
    // Update compliance status from real invoice data
    updateComplianceFromInvoices();

    vatDeadline.value = DateTime.now().add(const Duration(days: 10));
    ctDeadline.value = DateTime.now().add(const Duration(days: 59));

    // Set up notifications (can be enhanced to use real invoice data)
    final pendingCount = invoiceController.invoices.where((i) => i.status == 'Pending').length;
    recentNotifications.assignAll([
      NotificationItem(
        message: '$pendingCount invoices need review',
        time: 'Today • 11:20',
        category: 'System',
      ),
      NotificationItem(
        message: 'VAT return draft is ready for review',
        time: 'Yesterday • 18:05',
        category: 'VAT',
      ),
      NotificationItem(
        message: 'Corporate Tax reminder: confirm FY dates',
        time: 'Mon • 09:30',
        category: 'Corporate',
      ),
    ]);

    hasHighRiskInvoices.value = invoiceController.invoices.any(
      (i) => i.hasHighRisk,
    );
  }

  void _calculateTotalsFromInvoices(List<Invoice> invoices) {
    if (invoices.isEmpty) {
      // Set default values if no invoices
      vatTotalAmount.value = 'AED 0.00';
      vatOutputAmount.value = 'AED 0.00';
      vatInputAmount.value = 'AED 0.00';
      vatAdjustmentsAmount.value = 'AED 0.00';
      vatPendingCount.value = '0';
      invoiceCount.value = 0;
      totalExpenses.value = 0.0;
      totalVAT.value = 0.0;
      return;
    }

    // Calculate totals
    invoiceCount.value = invoices.length;
    
    // Total expenses (gross amounts)
    totalExpenses.value = invoices.fold(0.0, (sum, inv) => sum + inv.grossAmount);
    
    // Total VAT
    totalVAT.value = invoices.fold(0.0, (sum, inv) => sum + inv.vatAmount);
    
    // Pending invoices count
    final pendingCount = invoices.where((inv) => inv.status == 'Pending').length;
    vatPendingCount.value = pendingCount.toString();
    unverifiedInvoiceCount.value = pendingCount;
    
    // VAT Input (from purchases/invoices) - assuming all invoices are purchases for now
    final inputVat = invoices.fold(0.0, (sum, inv) => sum + inv.vatAmount);
    
    // VAT Output - would need separate sales invoices, for now assume 0
    // In a real app, you'd filter invoices by type (purchase vs sales)
    final outputVat = 0.0;
    
    // VAT Total (Output - Input)
    final vatTotal = outputVat - inputVat;
    
    // Format amounts
    vatTotalAmount.value = _formatAmount(vatTotal.abs());
    vatInputAmount.value = _formatAmount(-inputVat); // Negative for input
    vatOutputAmount.value = _formatAmount(outputVat);
    vatAdjustmentsAmount.value = 'AED 0.00';
  }

  String _formatAmount(double amount) {
    final formatted = amount.toStringAsFixed(2);
    final parts = formatted.split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];
    
    // Add comma separators
    String formattedInteger = '';
    for (int i = integerPart.length - 1; i >= 0; i--) {
      formattedInteger = integerPart[i] + formattedInteger;
      if ((integerPart.length - i) % 3 == 0 && i > 0) {
        formattedInteger = ',' + formattedInteger;
      }
    }
    
    return 'AED $formattedInteger.$decimalPart';
  }
  
  void updateComplianceFromInvoices() {
    // Trigger reactive update by accessing complianceStatus getter
    // This will fetch fresh data from InvoiceListController
    final _ = complianceStatus;
  }

  void exportInvoices() {
    SnackbarService.to.showSuccess(
      'title_success'.tr, 
      'msg_invoices_exported'.tr,
    );
  }
  
  Future<void> performActualExport() async {
    // Final safety check using service
    if (!_complianceService.canProceedToFile()) {
      SnackbarService.to.showError(
        'Action Blocked',
        'Cannot proceed with export. Please resolve all compliance issues first.',
      );
      return;
    }

    // This is called after readiness check passes
    Get.back(); // Close modal
    
    // Show loading
    SnackbarService.to.showInfo(
      'Exporting',
      'Preparing VAT summary export...',
    );
    
    try {
      // Get invoice data
      final invoiceController = Get.find<InvoiceListController>();
      final invoices = invoiceController.invoices;
      
      // Calculate VAT amounts
      final inputVat = invoices.fold(0.0, (sum, inv) => sum + inv.vatAmount);
      final outputVat = 0.0; // Would need separate sales invoices
      final totalVat = outputVat - inputVat;
      final pendingCount = invoices.where((inv) => inv.status == 'Pending').length;
      
      // Export VAT summary
      final filePath = await InvoiceExportService.exportVATSummary(
        totalVAT: totalVat.abs(),
        outputVAT: outputVat,
        inputVAT: inputVat,
        pendingCount: pendingCount,
        invoices: invoices,
      );
      
      if (filePath != null) {
        SnackbarService.to.showSuccess(
          'Export Complete',
          'VAT summary exported successfully to Documents folder',
          duration: const Duration(seconds: 3),
    );
      } else {
        SnackbarService.to.showError(
          'Export Failed',
          'Failed to export VAT summary. Please try again.',
        );
      }
    } catch (e) {
      debugPrint('❌ Error exporting: $e');
      SnackbarService.to.showError(
        'Export Failed',
        'An error occurred: ${e.toString()}',
      );
    }
  }
  
  
  void checkReadiness() {
    _syncComplianceData();
  }
  
  void showReadinessChecklist() {
    checkReadiness();
    Get.bottomSheet(
      const ReadinessChecklistModal(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
    );
  }
}
