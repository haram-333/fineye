import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../domain/services/compliance_status_service.dart';

class ComplianceColors {
  static Color getStatusColor(
    ComplianceStatus status, {
    bool hasRisks = false,
    bool hasHighRisks = false,
  }) {
    if (status == ComplianceStatus.doNotFile) {
      return AppColors.dangerRed;
    }
    if (status == ComplianceStatus.actionNeeded) {
      return AppColors.warningAmber;
    }
    return AppColors.successGreen;
  }

  static Color getPanelColor(
    ComplianceStatus status, {
    bool hasRisks = false,
    bool hasHighRisks = false,
  }) {
    final baseColor = getStatusColor(
      status,
      hasRisks: hasRisks,
      hasHighRisks: hasHighRisks,
    );
    
    return baseColor.withValues(alpha: 0.1);
  }

  static Color getBorderColor(
    ComplianceStatus status, {
    bool hasRisks = false,
    bool hasHighRisks = false,
  }) {
    final baseColor = getStatusColor(
      status,
      hasRisks: hasRisks,
      hasHighRisks: hasHighRisks,
    );
    
    return baseColor.withValues(alpha: 0.3);
  }

  static Color getTextColor(
    ComplianceStatus status, {
    bool hasRisks = false,
    bool hasHighRisks = false,
  }) {
    return getStatusColor(
      status,
      hasRisks: hasRisks,
      hasHighRisks: hasHighRisks,
    );
  }

  /// Get icon color
  static Color getIconColor(
    ComplianceStatus status, {
    bool hasRisks = false,
    bool hasHighRisks = false,
  }) {
    return getStatusColor(
      status,
      hasRisks: hasRisks,
      hasHighRisks: hasHighRisks,
    );
  }

  static bool validateGreenUsage(
    ComplianceStatus status,
    bool hasAnyIssues,
  ) {
    if (status == ComplianceStatus.readyToFile && hasAnyIssues) {
      return false;
    }
    return true;
  }
}
