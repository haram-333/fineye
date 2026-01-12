import 'package:get/get.dart';

/// Compliance status levels for dashboard and filing readiness
enum ComplianceStatus {
  readyToFile,    // 🟢 Green - All checks passed, safe to file
  actionNeeded,   // 🟡 Amber - Some issues need attention
  doNotFile,      // 🔴 Red - Critical issues, do not proceed
}

/// Centralized service for calculating and managing compliance status
/// Single source of truth for compliance state across the app
class ComplianceStatusService extends GetxService {
  final Rx<ComplianceStatus> currentStatus = ComplianceStatus.doNotFile.obs;
  
  // Default to false - if there are no invoices, there's nothing to review (passes check)
  final RxBool hasUnreviewedInvoices = false.obs;
  final RxBool hasActiveRisks = false.obs;
  final RxBool isTaxPeriodComplete = false.obs;
  final RxBool hasHighRiskFlags = false.obs;
  final RxBool hasMissingData = false.obs;
  
  final RxInt unreviewedCount = 0.obs;
  final RxInt riskCount = 0.obs;
  final RxInt highRiskCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    
    super.onInit();
    
    ever(hasUnreviewedInvoices, (_) => _recalculateStatus());
    ever(hasActiveRisks, (_) => _recalculateStatus());
    ever(isTaxPeriodComplete, (_) => _recalculateStatus());
    ever(hasHighRiskFlags, (_) => _recalculateStatus());
    ever(hasMissingData, (_) => _recalculateStatus());
    
    
    _recalculateStatus();
  }

  /// Calculate compliance status based on current state
  void _recalculateStatus() {
    // 🔴 RED: Critical issues - do not file
    if (hasHighRiskFlags.value || hasMissingData.value) {
      currentStatus.value = ComplianceStatus.doNotFile;
      return;
    }
    
    // 🟡 AMBER: Action needed - ONLY if there are unpaid invoices
    // Removed isTaxPeriodComplete check - it was causing false positives
    // Action needed should only show when there are actual unpaid invoices to review
    if (hasUnreviewedInvoices.value) {
      currentStatus.value = ComplianceStatus.actionNeeded;
      return;
    }
    
    // 🟢 GREEN: Ready to file - all invoices are paid/reviewed
    currentStatus.value = ComplianceStatus.readyToFile;
  }

  /// Update invoice review status
  void updateInvoiceStatus({
    required int totalInvoices,
    required int reviewedInvoices,
  }) {
    unreviewedCount.value = totalInvoices - reviewedInvoices;
    hasUnreviewedInvoices.value = unreviewedCount.value > 0;
  }

  /// Update risk flags status
  void updateRiskStatus({
    required int totalRisks,
    required int highRisks,
  }) {
    riskCount.value = totalRisks;
    highRiskCount.value = highRisks;
    hasActiveRisks.value = totalRisks > 0;
    hasHighRiskFlags.value = highRisks > 0;
  }

  /// Update tax period completion status
  void updateTaxPeriodStatus(bool isComplete) {
    isTaxPeriodComplete.value = isComplete;
  }

  /// Update missing data status
  void updateMissingDataStatus(bool hasMissing) {
    hasMissingData.value = hasMissing;
  }

  /// Get status color for UI
  String getStatusColor() {
    switch (currentStatus.value) {
      case ComplianceStatus.readyToFile:
        return 'green';
      case ComplianceStatus.actionNeeded:
        return 'amber';
      case ComplianceStatus.doNotFile:
        return 'red';
    }
  }

  /// Get status text key for localization
  String getStatusTextKey() {
    switch (currentStatus.value) {
      case ComplianceStatus.readyToFile:
        return 'compliance_status_ready';
      case ComplianceStatus.actionNeeded:
        return 'compliance_status_action';
      case ComplianceStatus.doNotFile:
        return 'compliance_status_do_not_file';
    }
  }

  /// Get status icon
  String getStatusIcon() {
    switch (currentStatus.value) {
      case ComplianceStatus.readyToFile:
        return '✓';
      case ComplianceStatus.actionNeeded:
        return '⚠';
      case ComplianceStatus.doNotFile:
        return '✕';
    }
  }

  /// Check if filing actions should be allowed
  bool canProceedToFile() {
    return currentStatus.value == ComplianceStatus.readyToFile;
  }

  /// Get detailed status message for user
  String getDetailedStatusMessage() {
    if (hasHighRiskFlags.value) {
      return 'compliance_critical_issues';
    }
    if (hasMissingData.value) {
      return 'gate_requirements_not_met';
    }
    if (hasUnreviewedInvoices.value || hasActiveRisks.value) {
      return 'compliance_issues_found';
    }
    return 'compliance_all_clear';
  }
}
