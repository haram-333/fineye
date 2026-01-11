import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../controllers/notification_settings_controller.dart';
import 'widgets/notification_widgets.dart';

class NotificationSettingsView extends GetView<NotificationSettingsController> {
  const NotificationSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<NotificationSettingsController>()) {
      Get.put(NotificationSettingsController());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Get.back(),
        ),
        toolbarHeight: 90,
        title: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'notification_settings_title'.tr,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'notification_settings_subtitle'.tr,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationPreferences(),
            _buildChannels(),
            _buildQuietHours(),
            _buildSampleNotification(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(context),
    );
  }

  Widget _buildNotificationPreferences() {
    return NotificationSectionCard(
      title: 'notif_prefs'.tr,
      subtitle: 'notif_prefs_subtitle'.tr,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.notifications_outlined,
          color: AppColors.primaryBlue,
          size: 20,
        ),
      ),
      children: [
        Obx(() => NotificationToggleTile(
              title: 'vat_reminders_toggle'.tr,
              description: 'vat_reminders_desc'.tr,
              value: controller.vatReminders.value,
              onChanged: controller.toggleVatReminders,
            )),
        Obx(() => NotificationToggleTile(
              title: 'ct_reminders_toggle'.tr,
              description: 'ct_reminders_desc'.tr,
              value: controller.ctReminders.value,
              onChanged: controller.toggleCtReminders,
            )),
        Obx(() => NotificationToggleTile(
              title: 'ocr_errors_toggle'.tr,
              description: 'ocr_errors_desc'.tr,
              value: controller.ocrErrors.value,
              onChanged: controller.toggleOcrErrors,
            )),
        Obx(() => NotificationToggleTile(
              title: 'duplicate_alerts_toggle'.tr,
              description: 'duplicate_alerts_desc'.tr,
              value: controller.duplicateAlerts.value,
              onChanged: controller.toggleDuplicateAlerts,
            )),
        Obx(() => NotificationToggleTile(
              title: 'monthly_summary_toggle'.tr,
              description: 'monthly_summary_desc'.tr,
              value: controller.monthlySummaries.value,
              onChanged: controller.toggleMonthlySummaries,
            )),
      ],
    );
  }

  Widget _buildChannels() {
    return NotificationSectionCard(
      title: 'channels_section'.tr,
      subtitle: 'channels_subtitle'.tr,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.send_outlined,
          color: AppColors.primaryBlue,
          size: 20,
        ),
      ),
      children: [
        Obx(() => NotificationToggleTile(
              title: 'push_notifications'.tr,
              description: 'push_notifications_desc'.tr,
              value: controller.pushNotifications.value,
              onChanged: controller.togglePushNotifications,
            )),
        Obx(() => NotificationToggleTile(
              title: 'email_updates'.tr,
              description: 'email_updates_desc'.tr,
              value: controller.emailUpdates.value,
              onChanged: controller.toggleEmailUpdates,
            )),
        Obx(() => NotificationToggleTile(
              title: 'in_app_only'.tr,
              description: 'in_app_only_desc'.tr,
              value: controller.inAppOnly.value,
              onChanged: controller.toggleInAppOnly,
            )),
      ],
    );
  }

  Widget _buildQuietHours() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'quiet_hours_section'.tr,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'quiet_hours_subtitle'.tr,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Obx(() => Switch.adaptive(
                      value: controller.quietHoursEnabled.value,
                      onChanged: controller.toggleQuietHoursEnabled,
                      activeColor: AppColors.primaryBlue,
                    )),
              ],
            ),
            const SizedBox(height: 16),
            // Quiet hours options (only shown when enabled)
            Obx(() => controller.quietHoursEnabled.value
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          QuietHourChip(
                            label: 'quiet_hours_night'.tr,
                            isSelected: controller.quietHoursMode.value == 'night',
                            onTap: () => controller.setQuietHoursMode('night'),
                          ),
                          QuietHourChip(
                            label: 'quiet_hours_weekends'.tr,
                            isSelected: controller.quietHoursMode.value == 'weekends',
                            onTap: () => controller.setQuietHoursMode('weekends'),
                          ),
                          if (controller.quietHoursMode.value == 'custom')
                            QuietHourChip(
                              label: _formatCustomSchedule(controller),
                              isSelected: true,
                              onTap: () => controller.setCustomSchedule(),
                            ),
                        ],
                      ),
                    ],
                  )
                : const SizedBox.shrink()),
            Obx(() => controller.quietHoursEnabled.value
                ? Column(
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: controller.setCustomSchedule,
                            child: Text(
                              controller.quietHoursMode.value == 'custom'
                                  ? 'edit_custom_schedule'.tr
                                  : 'set_custom_schedule'.tr,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                          if (controller.quietHoursMode.value == 'custom')
                            IconButton(
                              icon: const Icon(Icons.edit, size: 18, color: AppColors.primaryBlue),
                              onPressed: controller.setCustomSchedule,
                              tooltip: 'edit_custom_schedule'.tr,
                            ),
                        ],
                      ),
                    ],
                  )
                : const SizedBox.shrink()),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFFF59E0B),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'quiet_hours_note'.tr,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92400E),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCustomSchedule(NotificationSettingsController controller) {
    if (controller.customSelectedDays.isEmpty) {
      return 'Custom';
    }
    
    final startTime = controller.customStartTime.value;
    final endTime = controller.customEndTime.value;
    final startStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final endStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final selectedDayNames = controller.customSelectedDays
        .map((day) => dayNames[day])
        .join(', ');
    
    return '$startStr–$endStr • $selectedDayNames';
  }

  Widget _buildSampleNotification() {
    return NotificationSectionCard(
      title: 'sample_notification_section'.tr,
      subtitle: 'sample_notification_subtitle'.tr,
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.notifications_active_outlined,
          color: AppColors.primaryBlue,
          size: 20,
        ),
      ),
      children: [
        SampleNotificationCard(
          message: 'sample_notif_message'.tr,
          meta: 'sample_notif_meta'.tr,
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
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
                  'save_notification_settings'.tr,
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
}
