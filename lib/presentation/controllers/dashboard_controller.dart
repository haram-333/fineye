import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/snackbar_service.dart';
import '../../domain/services/compliance_status_service.dart';
import '../../data/models/invoice_model.dart';
import '../views/dashboard/widgets/readiness_checklist_modal.dart';
import 'company_profile_controller.dart';
import 'invoice_list_controller.dart';
import 'status_bar_controller.dart';
import 'notifications_controller.dart';
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
  var vatTotalAmount = 'AED 0.00'.obs;
  var vatPendingCount = '0'.obs;
  var vatDeadlineDate = 'Due: '.obs;
  var vatDaysLeftCount = 0.obs;
  var vatMonthTitle = 'Total VAT for '.obs; // Dynamic month title

  // VAT Breakdown (for "Why this amount?")
  var vatOutputAmount = 'AED 0.00'.obs;
  var vatInputAmount = 'AED 0.00'.obs;
  var vatAdjustmentsAmount = 'AED 0.00'.obs;

  // Corporate Tax Data
  var ctTotalAmount = 'AED 0.00'.obs;
  var ctNextPaymentType = 'Advance'.obs;
  var ctDeadlineDate = 'Due: '.obs;
  var ctDaysLeftCount = 0.obs;

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
      print('📊 Dashboard: Invoices changed, recalculating totals...');
      _syncComplianceData();
      _calculateTotalsFromInvoices(invoiceController.invoices);
      _calculateDeadlinesFromInvoices(invoiceController.invoices); // Recalculate deadlines from invoices
      _updateDeadlineDates(); // Also update deadline display when invoices change
    });
    
    // Initial calculation (invoices might be empty at first, but will update when loaded)
    _syncComplianceData();
    _calculateTotalsFromInvoices(invoiceController.invoices);
    
    // Load dashboard data (deadlines, notifications, etc.)
    loadDashboardData();
    _checkCompanySetup();
  }

  void _syncComplianceData() {
    if (Get.isRegistered<InvoiceListController>()) {
      final invoiceController = Get.find<InvoiceListController>();
      
      final totalInvoices = invoiceController.invoices.length;
      // Check for UNPAID invoices (status != 'Paid') - this is what "Action needed" should check
      final unpaidInvoices = invoiceController.invoices.where((i) => i.status != 'Paid').length;
      
      // Update service with real data
      // If there are 0 unpaid invoices, hasUnreviewedInvoices will be false (passes the check)
      _complianceService.updateInvoiceStatus(
        totalInvoices: totalInvoices,
        reviewedInvoices: totalInvoices - unpaidInvoices, // Reviewed = Paid
      );
      
      // Count high-risk invoices based on risks property
      // If there are 0 invoices, all counts will be 0 (passes the checks)
      final highRisks = invoiceController.invoices.where((i) => i.risks.any((r) => r.severity.toString().contains('high'))).length;
      final totalRisks = invoiceController.invoices.where((i) => i.risks.isNotEmpty).length;
      
      _complianceService.updateRiskStatus(
        totalRisks: totalRisks,
        highRisks: highRisks,
      );
      
      // Set tax period as complete if there are invoices (assuming period is complete for now)
      // In a real app, this would check if the current tax period has ended
      _complianceService.updateTaxPeriodStatus(true);
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
      // If no invoices, tax period is considered complete (nothing to file)
      _complianceService.updateTaxPeriodStatus(true);
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
    
    // Ensure invoices are loaded (if not already loading)
    if (invoiceController.invoices.isEmpty && !invoiceController.isLoading.value) {
      print('📊 Dashboard: No invoices found, triggering load...');
      invoiceController.loadInvoices();
    }
    
    print('📊 Dashboard: Calculating totals from ${invoiceController.invoices.length} invoices');
    // Calculate real totals from invoices (will be recalculated when invoices load via ever() listener)
    _calculateTotalsFromInvoices(invoiceController.invoices);
    
    // Update compliance status from real invoice data
    updateComplianceFromInvoices();

    // Calculate deadlines from pending invoices
    _calculateDeadlinesFromInvoices(invoiceController.invoices);
    
    // Update deadline dates and days left
    _updateDeadlineDates();

    // Load real notifications from NotificationsController
    _loadRealNotifications();

    hasHighRiskInvoices.value = invoiceController.invoices.any(
      (i) => i.hasHighRisk,
    );
  }
  
  void _calculateDeadlinesFromInvoices(List<Invoice> invoices) {
    final now = DateTime.now();
    
    // Find all pending invoices (status != 'Paid')
    final pendingInvoices = invoices.where((inv) => inv.status != 'Paid').toList();
    
    if (pendingInvoices.isEmpty) {
      // No pending invoices - set deadlines to null/empty (will be hidden in UI)
      vatDeadline.value = DateTime(2100, 1, 1); // Far future date as placeholder
      vatDaysLeftCount.value = 0;
      vatDeadlineDate.value = '';
      print('📊 Dashboard: No pending invoices, hiding deadline');
      return;
    }
    
    // Find the latest due date from pending invoices
    DateTime? latestDueDate;
    for (final invoice in pendingInvoices) {
      if (invoice.dueDate != null) {
        if (latestDueDate == null || invoice.dueDate!.isAfter(latestDueDate)) {
          latestDueDate = invoice.dueDate;
        }
      }
    }
    
    // If we found a due date, use it; otherwise use invoice date as fallback
    if (latestDueDate != null) {
      vatDeadline.value = latestDueDate;
      print('📊 Dashboard: Latest due date from pending invoices: $latestDueDate');
    } else {
      // Fallback: use the latest invoice date from pending invoices
      final latestInvoiceDate = pendingInvoices.map((inv) => inv.date).reduce((a, b) => a.isAfter(b) ? a : b);
      vatDeadline.value = latestInvoiceDate;
      print('📊 Dashboard: No due dates found, using latest invoice date: $latestInvoiceDate');
    }
    
    // CT deadline: end of current quarter + 30 days (keep as is for now)
    final currentQuarter = ((now.month - 1) ~/ 3) + 1;
    final quarterEndMonth = currentQuarter * 3;
    final quarterEnd = DateTime(now.year, quarterEndMonth + 1, 0);
    ctDeadline.value = quarterEnd.add(const Duration(days: 30));
  }
  
  void _updateDeadlineDates() {
    final now = DateTime.now();
    
    // VAT deadline - only show if there are pending invoices
    final pendingInvoices = Get.isRegistered<InvoiceListController>() 
        ? Get.find<InvoiceListController>().invoices.where((inv) => inv.status != 'Paid').toList()
        : <Invoice>[];
    
    if (pendingInvoices.isEmpty) {
      // No pending invoices - hide deadline
      vatDaysLeftCount.value = 0;
      vatDeadlineDate.value = '';
    } else {
      final vatDaysLeft = vatDeadline.value.difference(now).inDays;
      vatDaysLeftCount.value = vatDaysLeft > 0 ? vatDaysLeft : 0;
      vatDeadlineDate.value = 'Due: ${DateFormat('dd MMM yyyy').format(vatDeadline.value)}';
    }
    
    // CT deadline
    final ctDaysLeft = ctDeadline.value.difference(now).inDays;
    ctDaysLeftCount.value = ctDaysLeft > 0 ? ctDaysLeft : 0;
    ctDeadlineDate.value = 'Due: ${DateFormat('dd MMM yyyy').format(ctDeadline.value)}';
  }
  
  void _loadRealNotifications() {
    // Try to get notifications from NotificationsController
    if (Get.isRegistered<NotificationsController>()) {
      final notificationsController = Get.find<NotificationsController>();
      // Get first 3 notifications
      final notifications = notificationsController.filteredNotifications.take(3).map((n) {
        return NotificationItem(
          message: n.message,
          time: n.time,
          category: _mapNotificationTypeToCategory(n.type),
        );
      }).toList();
      recentNotifications.assignAll(notifications);
    } else {
      // Fallback: use invoice-based notifications
      if (Get.isRegistered<InvoiceListController>()) {
        final invoiceController = Get.find<InvoiceListController>();
        final unpaidCount = invoiceController.invoices.where((i) => i.status != 'Paid').length;
        recentNotifications.assignAll([
          if (unpaidCount > 0)
            NotificationItem(
              message: '$unpaidCount invoices need review',
              time: 'Today',
              category: 'System',
            ),
        ]);
      }
    }
  }
  
  String _mapNotificationTypeToCategory(dynamic type) {
    if (type.toString().contains('vat')) return 'VAT';
    if (type.toString().contains('corporate') || type.toString().contains('ct')) return 'Corporate';
    return 'System';
  }

  void _calculateTotalsFromInvoices(List<Invoice> invoices) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    // Update month title dynamically (will be updated below if no current month invoices)
    final monthName = DateFormat('MMM').format(now);
    
    print('📊 Dashboard: Calculating from ${invoices.length} total invoices');
    print('📊 Dashboard: Current month/year: $currentMonth/$currentYear');
    
    if (invoices.isEmpty) {
      print('📊 Dashboard: No invoices, setting defaults');
      // Set default values if no invoices
      vatTotalAmount.value = 'AED 0.00';
      vatOutputAmount.value = 'AED 0.00';
      vatInputAmount.value = 'AED 0.00';
      vatAdjustmentsAmount.value = 'AED 0.00';
      vatPendingCount.value = '0';
      ctTotalAmount.value = 'AED 0.00';
      invoiceCount.value = 0;
      totalExpenses.value = 0.0;
      totalVAT.value = 0.0;
      return;
    }

    // Calculate totals
    invoiceCount.value = invoices.length;
    
    // Filter invoices for CURRENT MONTH only (for VAT filing period)
    // VAT is typically filed monthly, so show current month's VAT
    final currentMonthInvoices = invoices.where((inv) {
      final isCurrentMonth = inv.date.year == currentYear && inv.date.month == currentMonth;
      if (isCurrentMonth) {
        print('📊 Dashboard: Found current month invoice: ${inv.id}, VAT: ${inv.vatAmount}, Date: ${inv.date}');
      }
      return isCurrentMonth;
    }).toList();
    
    print('📊 Dashboard: Found ${currentMonthInvoices.length} invoices for current month out of ${invoices.length} total');
    
    // If no invoices in current month, show ALL invoices' VAT (for visibility)
    // This helps when user has invoices from previous months
    final invoicesToUse = currentMonthInvoices.isEmpty ? invoices : currentMonthInvoices;
    final periodLabel = currentMonthInvoices.isEmpty 
        ? 'All Time' 
        : monthName;
    
    // Update month title - show "All Time" if no current month invoices
    vatMonthTitle.value = 'Total VAT for $periodLabel';
    
    // Total expenses (gross amounts)
    totalExpenses.value = invoicesToUse.fold(0.0, (sum, inv) => sum + inv.grossAmount);
    
    // Total VAT
    totalVAT.value = invoicesToUse.fold(0.0, (sum, inv) => sum + inv.vatAmount);
    
    print('📊 Dashboard: Total VAT calculated: ${totalVAT.value} from ${invoicesToUse.length} invoices');
    
    // Pending invoices count (unpaid invoices) - ALL invoices, not just current month
    final unpaidCount = invoices.where((inv) => inv.status != 'Paid').length;
    vatPendingCount.value = unpaidCount.toString();
    unverifiedInvoiceCount.value = unpaidCount;
    
    print('📊 Dashboard: Unpaid invoices count: $unpaidCount');
    
    // VAT Input (from purchases/invoices) - assuming all invoices are purchases for now
    final inputVat = invoicesToUse.fold(0.0, (sum, inv) => sum + inv.vatAmount);
    
    // VAT Output - would need separate sales invoices, for now assume 0
    // In a real app, you'd filter invoices by type (purchase vs sales)
    final outputVat = 0.0;
    
    // VAT Total = Sum of all VAT amounts from invoices (what user sees as "Total VAT")
    final vatTotal = invoicesToUse.fold(0.0, (sum, inv) => sum + inv.vatAmount);
    
    print('📊 Dashboard: VAT Total: $vatTotal');
    
    // Format amounts
    vatTotalAmount.value = _formatAmount(vatTotal); // Show total VAT from invoices
    vatInputAmount.value = _formatAmount(-inputVat); // Negative for input
    vatOutputAmount.value = _formatAmount(outputVat);
    vatAdjustmentsAmount.value = 'AED 0.00';
    
    // Calculate Corporate Tax Total from CT deductible invoices (ALL invoices, not just current month)
    // CT deductible = invoices where isCtDeductible is true
    final ctDeductibleInvoices = invoices.where((inv) => inv.isCtDeductible).toList();
    final ctTotal = ctDeductibleInvoices.fold(0.0, (sum, inv) => sum + inv.grossAmount);
    ctTotalAmount.value = _formatAmount(ctTotal);
    
    print('📊 Dashboard: CT Total: $ctTotal from ${ctDeductibleInvoices.length} CT deductible invoices');
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
