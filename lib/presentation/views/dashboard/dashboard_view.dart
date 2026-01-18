import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/compliance_colors.dart';
import '../../../domain/services/compliance_status_service.dart';
import '../../controllers/dashboard_controller.dart';
import '../../controllers/invoice_list_controller.dart';
import '../../controllers/main_controller.dart';

class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(DashboardController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: () async {
          controller.loadDashboardData();
          // Also refresh invoice list if available
          if (Get.isRegistered<InvoiceListController>()) {
            await Get.find<InvoiceListController>().refreshInvoices();
          }
        },
        color: AppColors.primaryBlue,
        child: CustomScrollView(
          slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            pinned: false,
            backgroundColor: Colors.white.withValues(alpha: 0.7),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            ),
            titleSpacing: 20,
            automaticallyImplyLeading: false,
            toolbarHeight: 90,
            title: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'greeting'.tr,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'company_name'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 20.0),
                child: IconButton(
                  onPressed: () {
                    if (Get.isRegistered<MainController>()) {
                      Get.find<MainController>().changeTabIndex(3);
                    }
                  },
                  icon: const Icon(Icons.notifications_outlined, color: AppColors.ink),
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Compliance Status Indicator
                  Obx(() => _buildTopComplianceIndicator(context)),
                  const SizedBox(height: 24),

                  // VAT Overview Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'vat_overview'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'vat_position'.tr,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Obx(
                    () {
                      final status = controller.complianceStatus.value;
                      final baseColor = ComplianceColors.getPanelColor(status, hasRisks: !controller.noHighRiskFlags.value);
                      final iconColor = ComplianceColors.getIconColor(status, hasRisks: !controller.noHighRiskFlags.value);
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildOverviewCard(
                            color: iconColor,
                            backgroundColor: baseColor,
                            title: controller.vatMonthTitle.value,
                            badgeText: 'VAT',
                            summaryLabel: 'label_summary'.tr,
                            firstDatumLabel: 'label_total_vat'.tr,
                            firstDatumValue: controller.vatTotalAmount.value,
                            secondDatumLabel: 'label_pending_review'.tr,
                            secondDatumValue: controller.vatPendingCount.value,
                            breakdownLabel: 'label_breakdown'.tr,
                            deadlineTitle: controller.vatDeadlineDate.value.isNotEmpty ? 'label_deadline_vat'.tr : '',
                            deadlineDate: controller.vatDeadlineDate.value,
                            daysLeft: controller.vatDaysLeftCount.value > 0 
                                ? 'label_due_in_days'.trParams({'days': controller.vatDaysLeftCount.value.toString()})
                                : '',
                            reminderText: controller.vatDeadlineDate.value.isNotEmpty ? 'label_reminder'.tr : null,
                          ),
                          const SizedBox(height: 8),

                          // Button moved up immediately after VAT panel
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: TextButton.icon(
                              onPressed: () => _showVatBreakdownSheet(context),
                              icon: const Icon(
                                Icons.info_outline,
                                size: 18,
                                color: AppColors.primaryBlue,
                              ),
                              label: Text(
                                'vat_why_amount_trigger'.tr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // Spacer between VAT section and Notification Box
                  const SizedBox(height: 24),

                  // Notification Box (CT Disclaimer) moved here
                  // Notification Box (CT Disclaimer) moved here
                  _buildCtDisclaimer(),

                  const SizedBox(height: 16),

                  // Corporate Tax Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ct_overview'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'ct_position'.tr,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Corporate Tax Card
_buildOverviewCard(
                  color: Colors.white,
                  backgroundColor: null,
                    title: 'total_ct_est'.tr,
                    badgeText: 'CT',
                    summaryLabel: 'label_summary'.tr,
                    firstDatumLabel: 'label_total_ct'.tr,
                    firstDatumValue: controller.ctTotalAmount.value,
                    secondDatumLabel: 'label_next_payment'.tr,
                    secondDatumValue: 'label_advance'.tr,
                    breakdownLabel: 'label_breakdown'.tr,
                    deadlineTitle: 'label_deadline_ct'.tr,
                    deadlineDate: controller.ctDeadlineDate.value,
                    daysLeft: 'label_due_in_days'.trParams({'days': controller.ctDaysLeftCount.value.toString()}),
                    reminderText: 'label_reminder'.tr,
                    isCtPanel: true,
                  ),  const SizedBox(height: 32),

                  // Upload Invoice Button
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        if (Get.isRegistered<MainController>()) {
                          Get.find<MainController>().changeTabIndex(2);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'upload_invoice_btn'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.crop_free, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Recent Notifications
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'recent_notifications'.tr,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => controller.showReadinessChecklist(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.download, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'quick_export'.tr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Notifications List
                  Obx(
                    () => ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: controller.recentNotifications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = controller.recentNotifications[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.1),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon container
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getIconForCategory(item.category),
                                  color: AppColors.primaryBlue,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.message,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ink,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item.time,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                        Text(
                                          item.category,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: _getColorForCategory(item.category),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Spacer to ensure content is not hidden behind the bottom nav
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'System':
        return Icons.article_outlined;
      case 'VAT':
        return Icons.percent;
      case 'Corporate':
        return Icons.business;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getColorForCategory(String category) {
    if (category == 'VAT' || category == 'Corporate') {
      return AppColors.successGreen; 
    }
    if (category == 'Alerts') return AppColors.dangerRed;
    if (category == 'System') return AppColors.primaryBlue;
    return AppColors.primaryBlue;
  }

  void _showVatBreakdownSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'vat_why_amount_title'.tr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'vat_why_amount_subtitle'.tr,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 20),

                // Breakdown rows
                _buildVatBreakdownRow(
                  label: 'vat_output_label'.tr,
                  value: controller.vatOutputAmount.value,
                ),
                const SizedBox(height: 12),
                _buildVatBreakdownRow(
                  label: 'vat_input_label'.tr,
                  value: controller.vatInputAmount.value,
                ),
                const SizedBox(height: 12),
                _buildVatBreakdownRow(
                  label: 'vat_adjustments_label'.tr,
                  value: controller.vatAdjustmentsAmount.value,
                ),
                const SizedBox(height: 12),
                Text(
                  'vat_zero_rated_label'.tr,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _buildVatBreakdownRow(
                  label: 'vat_total_label'.tr,
                  value: controller.vatTotalAmount.value,
                  isEmphasized: true,
                ),
                const SizedBox(height: 20),

                // View invoices button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      if (Get.isRegistered<MainController>()) {
                        Get.find<MainController>().changeTabIndex(1);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'vat_view_invoices_button'.tr,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVatBreakdownRow({
    required String label,
    required String value,
    bool isEmphasized = false,
  }) {
    final textStyle = TextStyle(
      fontSize: isEmphasized ? 15 : 14,
      fontWeight: isEmphasized ? FontWeight.w700 : FontWeight.w500,
      color: AppColors.ink,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: textStyle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: textStyle,
        ),
      ],
    );
  }

  // NEW: Top Compliance Status Indicator
  Widget _buildTopComplianceIndicator(BuildContext context) {
    final status = controller.complianceStatus.value;
    final hasHighRisk = !controller.noHighRiskFlags.value;
    final statusColor = ComplianceColors.getStatusColor(status, hasHighRisks: hasHighRisk);
    final backgroundColor = ComplianceColors.getPanelColor(status, hasHighRisks: hasHighRisk);
    
    
    String statusKey = 'compliance_status_ready';
    String headingKey = 'compliance_status_ready_heading';
    String subtextKey = 'compliance_status_ready_subtext';
    
    switch (status) {
      case ComplianceStatus.readyToFile:
        statusKey = 'compliance_status_ready';
        headingKey = 'compliance_status_ready_heading';
        subtextKey = 'compliance_status_ready_subtext';
        break;
      case ComplianceStatus.actionNeeded:
        statusKey = 'compliance_status_action';
        headingKey = 'compliance_status_action_heading';
        subtextKey = 'compliance_status_action_subtext';
        break;
      case ComplianceStatus.doNotFile:
        statusKey = 'compliance_status_do_not_file';
        headingKey = 'compliance_status_do_not_file_heading';
        subtextKey = 'compliance_status_do_not_file_subtext';
        break;
    }

    return GestureDetector(
      onTap: () {
          // Switch to invoices tab
          Get.find<MainController>().changeTabIndex(1);
          
          // Filter to show unpaid invoices (status != 'Paid')
          if (Get.isRegistered<InvoiceListController>()) {
            final invoiceController = Get.find<InvoiceListController>();
            // Clear any existing filters and show unpaid invoices
            invoiceController.searchController.clear();
            // The invoice list will show all invoices, but we can filter by status
            // For now, just navigate - the user can see all invoices including unpaid ones
          }

      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getStatusIcon(status),
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'compliance_status_title'.tr.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor.withValues(alpha: 0.8),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Status text (main)
                  Text(
                    statusKey.tr,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Heading (what's the issue)
                  Text(
                    headingKey.tr,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Subtext (how to fix)
                  Text(
                    subtextKey.tr,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            
            // Action Arrow
            Icon(
              Icons.chevron_right,
              color: statusColor.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Corporate Tax Disclaimer Widget
  Widget _buildCtDisclaimer() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'ct_disclaimer_message'.tr,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getStatusIcon(ComplianceStatus status) {
    switch (status) {
      case ComplianceStatus.readyToFile:
        return Icons.check_circle_outline;
      case ComplianceStatus.actionNeeded:
        return Icons.warning_amber_rounded;
      case ComplianceStatus.doNotFile:
        return Icons.error_outline_rounded;
    }

  }

  Widget _buildOverviewCard({
    required Color color,
    Color? backgroundColor,
    required String title,
    required String badgeText,
    required String summaryLabel,
    required String firstDatumLabel,
    required String firstDatumValue,
    required String secondDatumLabel,
    required String secondDatumValue,
    required String breakdownLabel,
    required String deadlineTitle,
    required String deadlineDate,
    required String daysLeft,
    String? reminderText,
    bool isCtPanel = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isCtPanel
            ? const LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isCtPanel ? null : backgroundColor ?? color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: isCtPanel ? null : Border.all(
          color: color.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: isCtPanel ? [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title + Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isCtPanel ? Colors.white : color,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isCtPanel 
                    ? Colors.white.withValues(alpha: 0.2)
                    : color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: isCtPanel ? Colors.white : color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // "Summary" Label
          Text(
            summaryLabel,
            style: TextStyle(
              color: isCtPanel 
                ? Colors.white.withValues(alpha: 0.6)
                : color.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 12),

          // Data Row (Two items)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item 1
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstDatumLabel,
                      style: TextStyle(
                        color: isCtPanel ? Colors.white : color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        firstDatumValue,
                        style: TextStyle(
                          color: isCtPanel ? Colors.white : color,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Item 2
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      secondDatumLabel,
                      style: TextStyle(
                        color: isCtPanel ? Colors.white : color,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        secondDatumValue,
                        style: TextStyle(
                          color: isCtPanel ? Colors.white : color,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // "Tax breakdown" Label
          Text(
            breakdownLabel,
            style: TextStyle(
              color: isCtPanel ? Colors.white.withValues(alpha: 0.6) : color.withValues(alpha: 0.7),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          // Only show deadline section if there's a deadline date
          if (deadlineDate.isNotEmpty && deadlineTitle.isNotEmpty) ...[
          const SizedBox(height: 20),

          // Next deadline section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  deadlineTitle,
                  style: TextStyle(
                    color: isCtPanel ? Colors.white : color,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
                if (daysLeft.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2), // Darker badge background
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  daysLeft,
                  style: TextStyle(
                    color: isCtPanel ? Colors.white : color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
                ],
            ],
          ),

          const SizedBox(height: 4),

          Text(
            deadlineDate,
            style: TextStyle(
              color: isCtPanel ? Colors.white.withValues(alpha: 0.8) : color.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),

          if (reminderText != null) ...[
            const SizedBox(height: 8),
            Text(
              reminderText,
              style: TextStyle(
                color: isCtPanel ? Colors.white.withValues(alpha: 0.7) : color.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            ],
          ],
        ],
      ),
    );
  }
}
