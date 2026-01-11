import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';
import 'notification_preferences_service.dart';

/// Helper class to create notifications with automatic preference checking
class NotificationHelper {
  static final NotificationService _notificationService = NotificationService();
  static final NotificationPreferencesService _prefsService = NotificationPreferencesService();
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Create a VAT-related notification
  static Future<String?> createVatNotification({
    required String titleKey,
    Map<String, dynamic>? titleParams,
    required String messageKey,
    Map<String, dynamic>? messageParams,
    bool isCritical = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    // Check if VAT reminders are enabled
    final shouldSend = await _prefsService.shouldSendNotification(
      notificationType: 'vat',
      isCritical: isCritical,
    );
    
    return await _notificationService.createNotification(
      userId: user.uid,
      notificationData: {
        'type': 'vat',
        'titleKey': titleKey,
        'titleParams': titleParams ?? {},
        'messageKey': messageKey,
        'messageParams': messageParams ?? {},
        'isCritical': isCritical,
      },
      checkPreferences: false, // Already checked above
    );
  }
  
  /// Create a Corporate Tax-related notification
  static Future<String?> createCtNotification({
    required String titleKey,
    Map<String, dynamic>? titleParams,
    required String messageKey,
    Map<String, dynamic>? messageParams,
    bool isCritical = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    // Check if CT reminders are enabled
    final shouldSend = await _prefsService.shouldSendNotification(
      notificationType: 'corporate',
      isCritical: isCritical,
    );
    
    return await _notificationService.createNotification(
      userId: user.uid,
      notificationData: {
        'type': 'corporate',
        'titleKey': titleKey,
        'titleParams': titleParams ?? {},
        'messageKey': messageKey,
        'messageParams': messageParams ?? {},
        'isCritical': isCritical,
      },
      checkPreferences: false,
    );
  }
  
  /// Create an OCR error notification
  static Future<String?> createOcrErrorNotification({
    required String message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    // Check if OCR errors are enabled
    final shouldSend = await _prefsService.shouldSendNotification(
      notificationType: 'ocr_error',
      isCritical: false,
    );
    
    return await _notificationService.createNotification(
      userId: user.uid,
      notificationData: {
        'type': 'ocr',
        'titleKey': 'notif_invoice_error',
        'titleParams': {},
        'messageKey': message,
        'messageParams': {},
        'isCritical': false,
      },
      checkPreferences: false,
    );
  }
  
  /// Create a duplicate invoice alert
  static Future<String?> createDuplicateAlertNotification({
    required String invoiceId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    // Check if duplicate alerts are enabled
    final shouldSend = await _prefsService.shouldSendNotification(
      notificationType: 'duplicate',
      isCritical: false,
    );
    
    return await _notificationService.createNotification(
      userId: user.uid,
      notificationData: {
        'type': 'warning',
        'titleKey': 'notif_invoice_duplicate',
        'titleParams': {},
        'messageKey': 'notif_invoice_duplicate',
        'messageParams': {'invoiceId': invoiceId},
        'isCritical': false,
      },
      checkPreferences: false,
    );
  }
  
  /// Create a system notification
  static Future<String?> createSystemNotification({
    required String titleKey,
    Map<String, dynamic>? titleParams,
    required String messageKey,
    Map<String, dynamic>? messageParams,
    bool isCritical = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    // System notifications are always enabled, but still check quiet hours
    final shouldSend = await _prefsService.shouldSendNotification(
      notificationType: 'system',
      isCritical: isCritical,
    );
    
    return await _notificationService.createNotification(
      userId: user.uid,
      notificationData: {
        'type': 'system',
        'titleKey': titleKey,
        'titleParams': titleParams ?? {},
        'messageKey': messageKey,
        'messageParams': messageParams ?? {},
        'isCritical': isCritical,
      },
      checkPreferences: false,
    );
  }
  
  /// Create a security/warning notification (always sent)
  static Future<String?> createSecurityNotification({
    required String titleKey,
    Map<String, dynamic>? titleParams,
    required String messageKey,
    Map<String, dynamic>? messageParams,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    
    // Security notifications are always sent (critical)
    return await _notificationService.createNotification(
      userId: user.uid,
      notificationData: {
        'type': 'warning',
        'titleKey': titleKey,
        'titleParams': titleParams ?? {},
        'messageKey': messageKey,
        'messageParams': messageParams ?? {},
        'isCritical': true,
      },
      checkPreferences: false,
    );
  }
}

