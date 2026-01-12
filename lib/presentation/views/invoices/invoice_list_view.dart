import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'invoice_details_view.dart';
import 'package:fineye/presentation/controllers/invoice_list_controller.dart';
import 'package:fineye/presentation/controllers/main_controller.dart';
import 'package:fineye/data/models/invoice_model.dart';
import 'package:fineye/core/constants/app_colors.dart';
import 'package:fineye/core/services/snackbar_service.dart';

class InvoiceListView extends GetView<InvoiceListController> {
  const InvoiceListView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<InvoiceListController>()) {
      Get.put(InvoiceListController());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            print('🔄 Pull to refresh triggered');
            controller.loadInvoices();
            // Wait a bit for the stream to update
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: AppColors.primaryBlue,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSearchBar(),
                      const SizedBox(height: 16),
                      _buildFilterChips(),
                      const SizedBox(height: 16),
                      _buildVatReferenceCard(),
                      const SizedBox(height: 20),
                      _buildSectionHeader(),
                    ],
                  ),
                ),
              ),
              _buildInvoiceList(context),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: false,
      backgroundColor: const Color(0xFFF5F7FA).withValues(alpha: 0.9),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
      automaticallyImplyLeading: false,
      toolbarHeight: 90,
      title: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'invoices_title'.tr,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'invoices_subtitle'.tr,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      centerTitle: false,
      actions: const [],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller.searchController,
            style: const TextStyle(fontSize: 15, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: 'search_invoices'.tr,
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: controller.showFilterOptions,
          icon: const Icon(Icons.tune, color: AppColors.primaryBlue),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: controller.exportInvoices,
          icon: const Icon(Icons.file_download_outlined, color: AppColors.primaryBlue),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            padding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.bookmark_outline, size: 16, color: AppColors.primaryBlue),
              const SizedBox(width: 6),
              Text(
                'filter_saved'.tr,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Obx(() {
            final count = controller.savedFiltersCount;
            final defaultName = controller.defaultFilterDisplayName;
            return Text(
              count > 0 
                  ? '$count ${'presets'.tr} • ${'default'.tr}: $defaultName'
                  : 'no_saved_filters'.tr,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildVatReferenceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.calculate_outlined, color: AppColors.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Text(
                'vat_calculation_ref'.tr,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // VAT Inclusive Section
          _buildVatSection(
            title: 'vat_inc_title'.tr,
            subtitle: 'vat_inc_desc'.tr,
            calculations: [
              _VatCalculation(
                label: 'lbl_net_amount'.tr,
                value: 'AED 1,000.00',
                formula: 'fmt_net_formula'.tr,
                example: 'ex_net_amount'.tr,
              ),
              _VatCalculation(
                label: 'lbl_vat_amount'.tr,
                value: 'AED 50.00',
                formula: 'fmt_vat_formula'.tr,
                example: 'ex_vat_amount'.tr,
              ),
              _VatCalculation(
                label: 'lbl_gross_amount'.tr,
                value: 'AED 1,050.00',
                formula: 'fmt_gross_user'.tr,
                example: null,
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 24),
          
          // VAT Exclusive Section
          _buildVatSection(
            title: 'vat_exc_title'.tr,
            subtitle: 'vat_exc_desc'.tr,
            calculations: [
              _VatCalculation(
                label: 'lbl_net_amount'.tr,
                value: 'AED 1,000.00',
                formula: null,
                example: 'ex_gross_input'.tr,
              ),
              _VatCalculation(
                label: 'lbl_vat_amount'.tr,
                value: 'AED 50.00',
                formula: 'fmt_vat_formula'.tr,
                example: 'ex_vat_amount'.tr,
              ),
              _VatCalculation(
                label: 'lbl_gross_amount'.tr,
                value: 'AED 1,050.00',
                formula: 'fmt_gross_formula'.tr,
                example: 'ex_gross_amount'.tr,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVatSection({
    required String title,
    required String subtitle,
    required List<_VatCalculation> calculations,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        // Section Subtitle
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        
        // Calculations
        ...calculations.map((calc) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label and Value
              Text(
                '${calc.label}: ${calc.value}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              if (calc.formula != null) ...[
                const SizedBox(height: 3),
                Text(
                  '${'label_formula'.tr} ${calc.formula}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
              if (calc.example != null) ...[
                const SizedBox(height: 3),
                Text(
                  calc.example!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ],
          ),
        )),
      ],
    );
  }


  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'recent_invoices'.tr,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        Text(
          'swipe_actions'.tr,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildInvoiceList(BuildContext context) {
    return Obx(() {
      // Show empty state if no invoices
      if (controller.filteredInvoices.isEmpty && !controller.isLoading.value) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 40, 40, 140),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 24),
                const Text(
                  'No Invoices Yet',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Start by uploading your first invoice to get started with VAT tracking and compliance.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Switch to upload tab (index 2 in MainController)
                    if (Get.isRegistered<MainController>()) {
                      final mainController = Get.find<MainController>();
                      mainController.changeTabIndex(2); // Upload tab
                    }
                  },
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text(
                    'Upload Invoice',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      
      // Show loading state
      if (controller.isLoading.value) {
        return SliverFillRemaining(
          hasScrollBody: false,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryBlue,
            ),
          ),
        );
      }
      
      // Show invoice list
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final invoice = controller.filteredInvoices[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildSwipableInvoiceCard(context, invoice),
              );
            },
            childCount: controller.filteredInvoices.length,
          ),
        ),
      );
    });
  }

  Widget _buildSwipableInvoiceCard(BuildContext context, Invoice invoice) {
    return Dismissible(
      key: Key(invoice.id),
      direction: DismissDirection.horizontal,
      // Background shows when swiping right (startToEnd) - we want this for Delete
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Row(
          children: [
            Icon(Icons.open_in_new, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Text(
              'Open',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      // SecondaryBackground shows when swiping left (endToStart) - we want this for Delete
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 12),
            Icon(Icons.delete, color: Colors.white, size: 28),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right to open - don't dismiss, just open
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => InvoiceDetailsView(invoice: invoice),
            ),
          );
          return false; // Don't dismiss the item
        } else {
          // Swipe left to delete - show confirmation
          return await _showDeleteConfirmation(context, invoice);
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          // Delete confirmed (swipe left)
          controller.deleteInvoice(invoice);
        }
      },
      child: _buildInvoiceCard(context, invoice),
    );
  }

  Future<bool> _showDeleteConfirmation(BuildContext context, Invoice invoice) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Invoice'),
          content: Text('Are you sure you want to delete invoice ${invoice.id}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Widget _buildInvoiceCard(BuildContext context, Invoice invoice) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          MaterialPageRoute(
            builder: (context) => InvoiceDetailsView(invoice: invoice),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Company Name + Gross Amount
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company Name (Left, Flexible)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (invoice.supplierName.isEmpty || 
 invoice.supplierName.trim().toLowerCase() == 'unknown' || 
 invoice.supplierName.trim().toLowerCase() == 'unknown supplier')
 ? 'label_unknown_supplier'.tr
 : invoice.supplierName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Gross Amount (Right, Fixed)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${'label_gross_amount'.tr} AED ${NumberFormat('#,##0.00').format(invoice.grossAmount)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${'label_vat_5_percent'.tr} AED ${NumberFormat('#,##0.00').format(invoice.vatAmount)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Secondary Row: Category + Status Badge
            Row(
              children: [
                // Category Badge (Left)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _translateCategory(invoice.category),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                if (invoice.hasRisk) ...[
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: invoice.hasHighRisk 
                          ? const Color(0xFFFEE2E2) // Red bg
                          : const Color(0xFFFEF3C7), // Amber bg
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          invoice.hasHighRisk ? Icons.error_outline : Icons.warning_amber_rounded,
                          size: 14,
                          color: invoice.hasHighRisk 
                              ? AppColors.dangerRed // Red text
                              : AppColors.warningAmber, // Amber text
                        ),
                        const SizedBox(width: 4),
                        Text(
                          invoice.hasHighRisk 
                              ? 'risk_badge_high'.tr 
                              : 'risk_badge_medium'.tr,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: invoice.hasHighRisk 
                                ? AppColors.dangerRed 
                                : AppColors.warningAmber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Status Badge (Right)
                _buildStatusBadge(invoice.status),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Metadata Row: Date + Invoice Number
            Row(
              children: [
                Text(
                  DateFormat('dd MMM yyyy').format(invoice.date),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  ' • ',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                  ),
                ),
                Flexible(
                  child: Text(
                    invoice.id,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Bottom Section: Action Chips (Wrapping Layout)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // VAT Badge
                _buildActionChip(
                  icon: null,
                  label: _translateTaxBadge(invoice.taxBadge),
                  color: AppColors.primaryBlue,
                  isBold: true,
                ),
                // View Notes
                _buildActionChip(
                  icon: Icons.description_outlined,
                  label: 'view_notes'.tr,
                  color: const Color(0xFF10B981),
                ),
                // CT Deductible
                if (invoice.isCtDeductible)
                  _buildActionChip(
                    icon: Icons.check_circle_outline,
                    label: 'ct_deductible'.tr,
                    color: const Color(0xFF10B981),
                  ),
                // Time Indicator
                _buildActionChip(
                  icon: Icons.access_time,
                  label: 'label_days_ago'.trParams({'days': DateTime.now().difference(invoice.date).inDays.toString()}),
                  color: Colors.grey.shade600,
                ),
                // VAT Activity
                _buildVatActivityChip(invoice.vatActivity),

                if (invoice.hasRisk)
                  GestureDetector(
                    onTap: () => _showRiskDetails(invoice),
                    child: _buildActionChip(
                      icon: invoice.hasHighRisk ? Icons.error_outline : Icons.warning_amber_rounded,
                      label: invoice.hasHighRisk ? 'risk_badge_high'.tr : 'risk_badge_medium'.tr,
                      color: invoice.hasHighRisk ? const Color(0xFFDC2626) : const Color(0xFFD97706),
                      isBold: true,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Flag Invoice (Bottom Right)
            Align(
              alignment: Alignment.centerRight,
              child: Obx(() => TextButton.icon(
                onPressed: () => controller.toggleFlag(invoice),
                icon: Icon(
                  invoice.isFlagged.value ? Icons.flag : Icons.flag_outlined,
                  size: 16,
                  color: invoice.isFlagged.value ? Colors.red : Colors.grey.shade500,
                ),
                label: Text(
                  'flag_invoice'.tr,
                  style: TextStyle(
                    fontSize: 13,
                    color: invoice.isFlagged.value ? Colors.red : Colors.grey.shade600,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }

  void _showRiskDetails(Invoice invoice) {
    if (invoice.risks.isEmpty) return;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
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
                'risk_overview_title'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'risk_overview_flagged_count'
                    .trParams({'count': invoice.risks.length.toString()}),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 16),
              ...invoice.risks.map(
                (risk) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 20,
                        color: risk.severity == InvoiceRiskSeverity.high
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _mapRiskTypeToTitle(risk.type).tr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _mapRiskTypeToDescription(risk.type).tr,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _mapRiskTypeToTitle(InvoiceRiskType type) {
    switch (type) {
      case InvoiceRiskType.missingTrn:
        return 'risk_missing_trn_title';
      case InvoiceRiskType.supplierNotRegistered:
        return 'risk_supplier_not_registered_title';
      case InvoiceRiskType.duplicateInvoice:
        return 'risk_duplicate_invoice_title';
      case InvoiceRiskType.vatMismatch:
        return 'risk_vat_mismatch_title';
      case InvoiceRiskType.missingSupplier:
        return 'risk_missing_supplier_title';
      case InvoiceRiskType.missingDate:
        return 'risk_missing_date_title';
      case InvoiceRiskType.missingAmount:
        return 'risk_missing_amount_title';
      case InvoiceRiskType.vatCalculationError:
        return 'risk_vat_calculation_error_title';
      default:
        throw UnimplementedError('Unknown risk type: $type');
    }
  }

  String _mapRiskTypeToDescription(InvoiceRiskType type) {
    switch (type) {
      case InvoiceRiskType.missingTrn:
        return 'risk_missing_trn_desc';
      case InvoiceRiskType.supplierNotRegistered:
        return 'risk_supplier_not_registered_desc';
      case InvoiceRiskType.duplicateInvoice:
        return 'risk_duplicate_invoice_desc';
      case InvoiceRiskType.vatMismatch:
        return 'risk_vat_mismatch_desc';
      case InvoiceRiskType.missingSupplier:
        return 'risk_missing_supplier_desc';
      case InvoiceRiskType.missingDate:
        return 'risk_missing_date_desc';
      case InvoiceRiskType.missingAmount:
        return 'risk_missing_amount_desc';
      case InvoiceRiskType.vatCalculationError:
        return 'risk_vat_calculation_error_desc';
      default:
        throw UnimplementedError('Unknown risk type: $type');
    }
  }

  String _translateCategory(String category) {
    return InvoiceListController.getCategoryTranslationKey(category).tr;
  }

  String _translateTaxBadge(String taxBadge) {
    final taxBadgeMap = {
      'VAT 5%': 'vat_5_percent',
      'Zero-rated': 'zero_rated',
      'Exempt': 'exempt',
    };
    
    // If taxBadge is already a key, use it directly
    if (taxBadge.startsWith('vat_') || taxBadge.startsWith('zero_') || taxBadge == 'exempt') {
      return taxBadge.tr;
    }
    
    // Otherwise, try to map to a translation key
    final translationKey = taxBadgeMap[taxBadge];
    if (translationKey != null) {
      return translationKey.tr;
    }
    
    // If no mapping found, return as-is
    return taxBadge;
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    switch (status) {
      case 'Paid':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF065F46);
        break;
      case 'Pending':
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        break;
      case 'Review':
        bgColor = const Color(0xFFDEEBFF);
        textColor = const Color(0xFF1E40AF);
        break;
      default:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'status_${status.toLowerCase()}'.tr,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildActionChip({
    IconData? icon,
    required String label,
    required Color color,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVatActivityChip(String activity) {
    Color color;
    IconData icon;
    switch (activity) {
      case 'High':
        color = const Color(0xFFEF4444);
        icon = Icons.trending_up;
        break;
      case 'Medium':
        color = const Color(0xFFF59E0B);
        icon = Icons.trending_flat;
        break;
      case 'Low':
        color = const Color(0xFF10B981);
        icon = Icons.trending_down;
        break;
      default:
        color = Colors.grey;
        icon = Icons.trending_flat;
    }
    return _buildActionChip(
      icon: icon,
      label: 'vat_${activity.toLowerCase()}'.tr,
      color: color,
    );
  }


  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        // Navigate to Upload
        SnackbarService.to.showInfo(
          'title_upload'.tr, 
          'msg_upload_opening'.tr,
        );
      },
      backgroundColor: AppColors.primaryBlue,
      icon: const Icon(Icons.upload_file, color: Colors.white),
      label: Text(
        'upload_invoice_fab'.tr,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _VatCalculation {
  final String label;
  final String value;
  final String? formula;
  final String? example;

  _VatCalculation({
    required this.label,
    required this.value,
    this.formula,
    this.example,
  });
}
