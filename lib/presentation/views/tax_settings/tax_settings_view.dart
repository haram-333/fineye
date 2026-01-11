import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../controllers/tax_settings_controller.dart';

class TaxSettingsView extends GetView<TaxSettingsController> {
  const TaxSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        top: false,
        bottom: false,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(controller),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('${'vat_reminder_title'.tr} / ${'vat_reminder_desc'.tr}'),
                    _buildVatReminderCard(controller),
                    
                    const SizedBox(height: 32),
                     _buildSectionHeader('${'ct_reminder_title'.tr} / ${'ct_reminder_desc'.tr}'),
                    _buildCtReminderCard(controller),
                    
                    const SizedBox(height: 32),
                    _buildSectionHeader('ct_settings_section'.tr),
                    _buildCtSettingsCard(controller),

                    const SizedBox(height: 32),
                    _buildSectionHeader('notif_prefs'.tr),
                    _buildNotificationPreferencesCard(controller),
                    const SizedBox(height: 120), // Bottom padding for bottom action buttons
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(context, controller),
    );
  }

  Widget _buildBottomActions(BuildContext context, TaxSettingsController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: controller.saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'save_settings'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: controller.resetToDefaults,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'reset_security_default'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(TaxSettingsController controller) {
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
      leading: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: BackButton(color: AppColors.ink),
        ),
      ),
      toolbarHeight: 90,
      title: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'tax_settings_title'.tr,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'tax_settings_subtitle'.tr,
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
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: () {
              // Navigate to notification settings or show bottom sheet
            },
            icon: const Icon(Icons.edit_notifications_outlined, color: AppColors.ink),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              padding: const EdgeInsets.all(8),
            ),
          ),
        )
      ],
    );
  }
  
  Widget _buildSectionHeader(String title) {
     return Padding(
       padding: const EdgeInsets.only(bottom: 12),
       child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
     );
  }

  Widget _buildVatReminderCard(TaxSettingsController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF5FF), // Light Blue
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4169E1).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.percent, color: Color(0xFF4169E1)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                            'vat_reminder_title'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            'next_vat_filing'.tr,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                 decoration: BoxDecoration(
                   color: controller.vatStatus['bg'],
                   borderRadius: BorderRadius.circular(20),
                 ),
                 child: Text(
                   controller.vatStatus['text'],
                   style: TextStyle(
                     fontSize: 12,
                     fontWeight: FontWeight.bold,
                     color: controller.vatStatus['color'],
                   ),
                 ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMM yyyy').format(controller.nextVatFilingDate),
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
              Text(
                'est_vat'.tr,
                 style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${DateFormat('dd MMM yyyy').format(controller.nextVatFilingDate)} • ${controller.vatDueText}',
            style: const TextStyle(fontSize: 13, color: AppColors.ink),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('60 days', 60, controller.selectedVatReminder, controller.setVatReminder),
              _buildFilterChip('30 days', 30, controller.selectedVatReminder, controller.setVatReminder),
              _buildFilterChip('15 days', 15, controller.selectedVatReminder, controller.setVatReminder),
              _buildFilterChip('7 days', 7, controller.selectedVatReminder, controller.setVatReminder),
              _buildFilterChip('3 days', 3, controller.selectedVatReminder, controller.setVatReminder),
              _buildFilterChip('1 day', 1, controller.selectedVatReminder, controller.setVatReminder),
              _buildFilterChip('On due date', 0, controller.selectedVatReminder, controller.setVatReminder),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCtReminderCard(TaxSettingsController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9), // Light Green
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2ECC71).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.location_city, color: Color(0xFF2ECC71)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text(
                            'ct_reminder_title'.tr,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                          Text(
                            'ct_reminder_desc'.tr,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                 decoration: BoxDecoration(
                   color: controller.ctStatus['bg'],
                   borderRadius: BorderRadius.circular(20),
                 ),
                 child: Text(
                   controller.ctStatus['text'],
                   style: TextStyle(
                     fontSize: 12,
                     fontWeight: FontWeight.bold,
                     color: controller.ctStatus['color'],
                   ),
                 ),
              ),
            ],
          ),
          const SizedBox(height: 16),
           Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd MMM yyyy').format(controller.nextCtPaymentDate),
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
              ),
              Text(
                'status_planned'.tr,
                 style: TextStyle(fontWeight: FontWeight.normal, color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${DateFormat('dd MMM yyyy').format(controller.nextCtPaymentDate)} • ${controller.ctDueText}',
            style: const TextStyle(fontSize: 13, color: AppColors.ink),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCtFilterChip('90 days', 90, controller.selectedCtReminder, controller.setCtReminder),
              _buildCtFilterChip('30 days', 30, controller.selectedCtReminder, controller.setCtReminder),
              _buildCtFilterChip('10 days', 10, controller.selectedCtReminder, controller.setCtReminder),
              _buildCtFilterChip('3 days', 3, controller.selectedCtReminder, controller.setCtReminder),
              _buildCtFilterChip('1 day', 1, controller.selectedCtReminder, controller.setCtReminder),
              _buildCtFilterChip('On due date', 0, controller.selectedCtReminder, controller.setCtReminder),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCtSettingsCard(TaxSettingsController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
             color: Colors.black.withValues(alpha: 0.05),
             blurRadius: 10,
             offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ct_registered'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      'ct_registered_desc'.tr, 
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              Obx(() => Switch(
                value: controller.isCtRegistered.value,
                onChanged: (val) => controller.isCtRegistered.value = val,
                activeColor: AppColors.primaryBlue,
              )),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildDatePicker(
                  'financial_year_start'.tr,
                  controller.financialYearStart,
                  controller,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDatePicker(
                  'financial_year_end'.tr,
                  controller.financialYearEnd,
                  controller,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildDatePicker(
            'ct_registration_date'.tr,
            controller.ctRegistrationDate,
            controller,
            subtitle: 'as_per_certificate'.tr,
          ),
           const SizedBox(height: 20),
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('next_ct_deadline'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('static_deadline_desc'.tr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(controller.nextCtPaymentDate),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
             ],
           )
        ],
      ),
    );
  }

  Widget _buildNotificationPreferencesCard(TaxSettingsController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(16),
         boxShadow: [
           BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
           )
         ],
      ),
      child: Column(
        children: [
          // VAT Reminders Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('vat_reminders_toggle'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('vat_reminders_desc'.tr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Obx(() => Switch.adaptive(
                value: controller.vatRemindersEnabled.value,
                onChanged: (val) => controller.vatRemindersEnabled.value = val,
                activeColor: AppColors.primaryBlue,
              )),
            ],
          ),
          const Divider(height: 24),
          // CT Reminders Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ct_reminders_toggle'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('ct_reminders_desc'.tr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Obx(() => Switch.adaptive(
                value: controller.ctRemindersEnabled.value,
                onChanged: (val) => controller.ctRemindersEnabled.value = val,
                activeColor: AppColors.primaryBlue,
              )),
            ],
          ),
          const Divider(height: 24),
          // OCR Errors Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ocr_errors_toggle'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('ocr_errors_desc'.tr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Obx(() => Switch.adaptive(
                value: controller.ocrErrorsEnabled.value,
                onChanged: (val) => controller.ocrErrorsEnabled.value = val,
                activeColor: AppColors.primaryBlue,
              )),
            ],
          ),
          const Divider(height: 24),
          // Duplicate Invoice Alerts Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('duplicate_alerts_toggle'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('duplicate_alerts_desc'.tr, style: const TextStyle(fontSize: 12, color:Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Obx(() => Switch.adaptive(
                value: controller.duplicateInvoiceAlertsEnabled.value,
                onChanged: (val) => controller.duplicateInvoiceAlertsEnabled.value = val,
                activeColor: AppColors.primaryBlue,
              )),
            ],
          ),
          const Divider(height: 24),
          // Monthly Summaries Toggle
          Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
         Flexible(
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
                    Text('monthly_summary_toggle'.tr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
               const SizedBox(height: 4),
                    Text('monthly_summary_desc'.tr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
             ],
           ),
         ),
         const SizedBox(width: 12),
         Obx(() => Switch.adaptive(
                value: controller.monthlySummariesEnabled.value,
                onChanged: (val) => controller.monthlySummariesEnabled.value = val,
           activeColor: AppColors.primaryBlue,
         )),
      ],
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(String label, Rx<DateTime> date, TaxSettingsController controller, {String? subtitle}) {
    return GestureDetector(
      onTap: () => controller.selectDate(date),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                   if(subtitle != null) ...[
                     Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
                   ],
                   const SizedBox(height: 4),
                   Obx(() => Text(
                     DateFormat('dd MMM yyyy').format(date.value),
                     style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                   )),
                ],
              ),
            ),
            const Icon(Icons.calendar_today_outlined, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int value, RxInt selectedVal, Function(int) onToggle) {
    return Obx(() {
      final isSelected = selectedVal.value == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) onToggle(value);
      },
      selectedColor: const Color(0xFF1565C0), // Darker Blue
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF1565C0),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF1565C0)),
      ),
      checkmarkColor: Colors.white,
    );
    });
  }

    Widget _buildCtFilterChip(String label, int value, RxInt selectedVal, Function(int) onToggle) {
    return Obx(() {
      final isSelected = selectedVal.value == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) onToggle(value);
      },
      selectedColor: const Color(0xFF2ECC71), // Green
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF2ECC71),
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFF2ECC71)),
      ),
      checkmarkColor: Colors.white,
    );
    });
  }
}
