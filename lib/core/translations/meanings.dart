/// meanings.dart
///
/// This file provides human‑readable English meanings for all keys that can
/// appear in alerts / notifications. It is intended to support external
/// notification systems (e.g. push, email) that need stable keys plus
/// a canonical English description.
///
/// IMPORTANT:
/// - Keep keys in sync with `messages.dart` but do NOT rename existing keys.
/// - When adding new notification‑related keys, append them here as well.

// Map of notification/alert keys → default English meaning/label.
// Existing keys from `messages.dart` are mirrored here; do not modify them,
// only append new keys as needed.
const Map<String, String> notificationMeanings = {
  // General notifications
  'notifications_title': 'Notifications',
  'notifications_subtitle': 'Stay updated on your tax compliance',
  'no_notifications': 'No notifications yet',
  'no_notifications_desc': 'You\'re all caught up! We\'ll notify you of important updates.',
  'mark_all_read': 'Mark all as read',
  'mark_as_read': 'Mark as read',
  'mark_as_unread': 'Mark as unread',
  'delete_notification': 'Delete notification',
  'filter_all': 'All notifications',
  'filter_unread': 'Unread notifications',
  'filter_system': 'System notifications only',
  'notification_deleted': 'Notification deleted',

  // Notification time labels
  'notif_time_now': 'Now',
  'notif_time_just_now': 'Just now',
  'notif_time_minutes_ago': '{count} minutes ago',
  'notif_time_hour_ago': '1 hour ago',
  'notif_time_hours_ago': '{count} hours ago',
  'notif_time_today': 'Today',
  'notif_time_yesterday': 'Yesterday',
  'notif_time_days_ago': '{count} days ago',
  'notif_time_week_ago': '1 week ago',
  'notif_time_weeks_ago': '{count} weeks ago',
  'notif_time_due_in': 'Due in {count} days',
  'notif_time_due_today': 'Due today',
  'notif_time_due_tomorrow': 'Due tomorrow',
  'notif_time_overdue': 'Overdue',

  // VAT notifications
  'notif_vat_return_due': 'VAT return due in {days} days',
  'notif_vat_return_due_today': 'VAT return due today',
  'notif_vat_return_overdue': 'VAT return overdue',
  'notif_vat_reminder': 'Reminder before VAT deadline',
  'notif_vat_filed_success': 'VAT return filed successfully',
  'notif_vat_ready_to_file': 'VAT return ready to file',
  'notif_vat_review_needed': 'VAT return needs review',
  'notif_vat_period_ending': 'VAT period ending soon',
  'notif_vat_calculation_ready': 'VAT calculation completed',
  'notif_vat_refund_due': 'VAT refund expected',
  'notif_vat_payment_due': 'VAT payment due',

  // Corporate tax notifications
  'notif_ct_estimate_ready': 'Corporate tax estimate ready',
  'notif_ct_review_estimate': 'Review quarterly corporate tax estimate',
  'notif_ct_return_due': 'Corporate tax return due in {days} days',
  'notif_ct_return_due_today': 'Corporate tax return due today',
  'notif_ct_filed_success': 'Corporate tax return filed successfully',
  'notif_ct_payment_due': 'Corporate tax payment due',
  'notif_ct_period_ending': 'Corporate tax period ending soon',
  'notif_ct_registration_reminder': 'Corporate tax registration deadline approaching',

  // Invoice notifications
  'notif_invoice_uploaded': 'Invoice uploaded successfully',
  'notif_invoice_processed': 'Invoice processed',
  'notif_invoice_created': 'New invoice created',
  'notif_invoice_created_msg': 'Invoice @invoiceNumber from @supplierName has been created successfully',
  'notif_invoice_error': 'Invoice processing error',
  'notif_invoice_missing_data': 'Invoice has missing data',
  'notif_invoice_high_risk': 'High‑risk invoice detected',
  'notif_invoice_needs_review': 'Invoice needs your review',
  'notif_invoice_approved': 'Invoice approved',
  'notif_invoice_rejected': 'Invoice rejected',
  'notif_invoices_pending': '{count} invoices pending review',
  'notif_invoice_duplicate': 'Duplicate invoice detected',

  // Compliance & alert notifications
  'notif_compliance_status_changed': 'Compliance status changed',
  'notif_compliance_ready': 'Ready to file – all checks passed',
  'notif_compliance_action_needed': 'Action needed – review alerts',
  'notif_compliance_high_risk': 'High‑risk situation – do not file yet',
  'notif_missing_invoices': 'Missing invoices for this period',
  'notif_data_incomplete': 'Company data incomplete',
  'notif_setup_required': 'Company setup required',
  'notif_deadline_approaching': 'Tax deadline approaching',
  'notif_deadline_missed': 'Tax deadline missed',

  // System notifications
  'notif_backup_completed': 'FinEye backup completed',
  'notif_backup_success': 'Data backup to the cloud completed successfully',
  'notif_backup_failed': 'Backup failed',
  'notif_sync_completed': 'Data sync completed',
  'notif_sync_failed': 'Data sync failed',
  'notif_update_available': 'App update available',
  'notif_update_required': 'Update required to continue',
  'notif_maintenance': 'Scheduled maintenance',
  'notif_service_restored': 'Service restored',
  'notif_new_feature': 'New feature available',

  // Warning / severity notifications
  'notif_warning_title': 'Warning',
  'notif_error_title': 'Error',
  'notif_critical_title': 'Critical alert',
  'notif_data_loss_warning': 'Risk of data loss',
  'notif_security_alert': 'Security alert',
  'notif_unusual_activity': 'Unusual activity detected',
  'notif_verification_required': 'Verification required',
  'notif_action_required': 'Action required',

  // Notification actions
  'notif_action_view': 'View notification detail',
  'notif_action_review': 'Review related data',
  'notif_action_file': 'File now',
  'notif_action_dismiss': 'Dismiss notification',
  'notif_action_update': 'Update application or data',
  'notif_action_fix': 'Fix now',
  'notif_action_learn_more': 'Learn more',
  'notif_action_contact_support': 'Contact support',

  // Notification categories
  'notif_category_vat': 'VAT‑related notification',
  'notif_category_corporate_tax': 'Corporate tax notification',
  'notif_category_invoices': 'Invoice‑related notification',
  'notif_category_compliance': 'Compliance alert',
  'notif_category_system': 'System status notification',
  'notif_category_alerts': 'General alert',
  'notif_category_reminders': 'Reminder notification',

  // Generic alert titles/messages that often appear in snackbars/dialogs
  'title_success': 'Success',
  'title_error': 'Error',
  'title_warning': 'Warning',
  'title_saved': 'Saved',
  'title_upload': 'Upload',
  'title_filters_applied': 'Filters applied',
  'title_coming_soon': 'Coming soon',
  'title_signed_out': 'Signed out',
  'msg_notif_settings_reset': 'Notification settings reset to defaults',
  'msg_notif_settings_saved': 'Notification settings saved',

  // Invoice status labels
  'status_approved': 'Invoice status: Approved',
};


