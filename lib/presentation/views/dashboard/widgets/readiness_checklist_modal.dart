import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/compliance_colors.dart';
import '../../../../core/utils/format_helper.dart';
import '../../../../domain/services/compliance_status_service.dart';
import '../../../controllers/dashboard_controller.dart';
import '../../../controllers/main_controller.dart';

class ReadinessChecklistModal extends StatelessWidget {
  const ReadinessChecklistModal({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<DashboardController>();

    return Container(
      margin: const EdgeInsets.only(top: 100),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Obx(() {
              final status = controller.complianceStatus.value; // Use ComplianceStatus directly
              
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Title
                  Text(
                    'readiness_checklist_title'.tr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'readiness_checklist_subtitle'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Check 1: All invoices reviewed
                  _buildCheckItem(
                    isPassed: controller.allInvoicesReviewed.value,
                    title: controller.allInvoicesReviewed.value 
                        ? 'check_all_invoices_reviewed'.tr
                        : 'Invoices pending review',
                    description: controller.allInvoicesReviewed.value
                        ? 'all_invoices_pass'.tr
                        : 'invoices_pending'.tr.replaceAll('@count', controller.pendingInvoicesCount.value.toString()),
                  ),
                  const SizedBox(height: 16),

                  // Check 2: No high-risk flags
                  _buildCheckItem(
                    isPassed: controller.noHighRiskFlags.value,
                    isCritical: !controller.noHighRiskFlags.value,
                    title: controller.noHighRiskFlags.value
                        ? 'check_no_high_risk'.tr
                        : 'High-risk flags detected',
                    description: controller.noHighRiskFlags.value
                        ? 'no_high_risk_pass'.tr
                        : 'high_risk_detected'.tr.replaceAll('@count', controller.highRiskInvoicesCount.value.toString()),
                  ),
                  const SizedBox(height: 16),

                  // Check 3: Tax period complete
                  _buildCheckItem(
                    isPassed: controller.taxPeriodComplete.value,
                    title: controller.taxPeriodComplete.value
                        ? 'check_tax_period_complete'.tr
                        : 'Tax period incomplete',
                    description: controller.taxPeriodComplete.value
                        ? 'tax_period_pass'.tr
                        : 'tax_period_incomplete'.tr,
                  ),
                  const SizedBox(height: 24),

                  // Status Summary Card
                  _buildStatusSummaryCard(status),
                  const SizedBox(height: 24),

                  // Action Buttons
                  if (status == ComplianceStatus.readyToFile) // Changed from ReadinessStatus.ready
                    _buildExportButton(controller)
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Get.back(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              'cancel'.tr,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              Get.back();
                              // Navigate to invoices to fix issues
                              if (Get.isRegistered<MainController>()) {
                                Get.find<MainController>().changeTabIndex(1);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: AppColors.primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'fix_issues_first'.tr,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItem({
    required bool isPassed,
    required String title,
    required String description,
    bool isCritical = false,
  }) {
    final Color iconColor;
    final IconData icon;
    final Color iconBgColor;

    if (isPassed) {
      iconColor = AppColors.successGreen;
      icon = Icons.check_circle;
      iconBgColor = const Color(0xFFE8F7F0);
    } else if (isCritical) {
      iconColor = AppColors.dangerRed;
      icon = Icons.cancel;
      iconBgColor = const Color(0xFFFEE2E2);
    } else {
      iconColor = AppColors.warningAmber;
      icon = Icons.warning_amber_rounded;
      iconBgColor = const Color(0xFFFEF6E7);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isPassed ? Colors.grey.shade50 : iconBgColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPassed ? Colors.grey.shade200 : iconColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSummaryCard(ComplianceStatus status) {
    final Color bgColor = ComplianceColors.getPanelColor(status);
    final Color textColor = ComplianceColors.getTextColor(status);
    
    final IconData icon;
    final String statusText;
    final String summaryText;

    switch (status) {
      case ComplianceStatus.readyToFile:
        icon = Icons.check_circle;
        statusText = 'ready_to_file'.tr;
        summaryText = 'readiness_summary_green'.tr;
        break;
      case ComplianceStatus.actionNeeded:
        icon = Icons.warning_amber_rounded;
        statusText = 'review_needed'.tr;
        summaryText = 'readiness_summary_yellow'.tr;
        break;
      case ComplianceStatus.doNotFile:
        icon = Icons.error_rounded;
        statusText = 'do_not_file'.tr;
        summaryText = 'readiness_summary_red'.tr;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summaryText,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(DashboardController controller) {
    return ElevatedButton(
      onPressed: () => _showExportSelectionDialog(Get.context!, controller),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: AppColors.successGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.download, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            'proceed_to_export'.tr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showExportSelectionDialog(BuildContext context, DashboardController controller) {
    // Current period formatted string
    final range = controller.selectedVatPeriod.value;
    String currentPeriodStr;
    if (range.start.year == range.end.year && range.start.month == range.end.month) {
      currentPeriodStr = FormatHelper.monthYear(range.start);
    } else {
      currentPeriodStr = '${FormatHelper.date(range.start)} - ${FormatHelper.date(range.end)}';
    }
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'dialog_export_period_title'.tr,
                style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Option 1: Current Month
               _buildExportOption(
                icon: Icons.calendar_today,
                label: 'btn_export_current'.trParams({'month': currentPeriodStr}),
                onTap: () {
                  Navigator.pop(ctx);
                  // Show format selection dialog
                  _showFormatSelectionDialog(context, controller, customRange: null);
                },
                isPrimary: true,
              ),
              const SizedBox(height: 12),
              
              // Option 2: Select Date Range
              _buildExportOption(
                icon: Icons.date_range,
                label: 'btn_select_month'.tr,
                onTap: () async {
                  Navigator.pop(ctx);
                  // Use date range picker for flexible range selection
                   final DateTimeRange? pickedRange = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2101),
                    initialDateRange: controller.selectedVatPeriod.value,
                  );
                  
                  if (pickedRange != null) {
                    // Show format selection dialog
                    _showFormatSelectionDialog(context, controller, customRange: pickedRange);
                  }
                },
              ),
              const SizedBox(height: 12),
              
              // Option 3: Custom Range
              _buildExportOption(
                icon: Icons.linear_scale,
                label: 'btn_select_range'.tr,
                onTap: () async {
                  Navigator.pop(ctx);
                  final DateTimeRange? pickedRange = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2101),
                    initialDateRange: controller.selectedVatPeriod.value,
                  );
                  
                  if (pickedRange != null) {
                    controller.performActualExport(customRange: pickedRange);
                  }
                },
              ),
              
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('cancel'.tr, style: const TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildExportOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primaryBlue.withOpacity(0.05) : Colors.white,
          border: Border.all(
            color: isPrimary ? AppColors.primaryBlue : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon, 
              color: isPrimary ? AppColors.primaryBlue : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
                  color: isPrimary ? AppColors.primaryBlue : AppColors.ink,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isPrimary ? AppColors.primaryBlue : Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showFormatSelectionDialog(BuildContext context, DashboardController controller, {DateTimeRange? customRange}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'dialog_export_format_title'.tr,
                style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Option 1: PDF Only
              _buildExportOption(
                icon: Icons.picture_as_pdf,
                label: 'btn_export_pdf'.tr,
                onTap: () {
                  Navigator.pop(ctx);
                  controller.performActualExport(customRange: customRange, exportFormat: 'pdf');
                },
                isPrimary: true,
              ),
              const SizedBox(height: 12),
              
              // Option 2: Excel Only
              _buildExportOption(
                icon: Icons.table_chart,
                label: 'btn_export_excel'.tr,
                onTap: () {
                  Navigator.pop(ctx);
                  controller.performActualExport(customRange: customRange, exportFormat: 'excel');
                },
              ),
              const SizedBox(height: 12),
              
              // Option 3: Both
              _buildExportOption(
                icon: Icons.file_download,
                label: 'btn_export_both'.tr,
                onTap: () {
                  Navigator.pop(ctx);
                  controller.performActualExport(customRange: customRange, exportFormat: 'both');
                },
              ),
              
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('cancel'.tr, style: const TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
