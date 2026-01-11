import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'quiet_hours_service.dart';

/// Service to check user notification preferences before sending notifications
class NotificationPreferencesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final QuietHoursService _quietHoursService = QuietHoursService();
  
  /// Cache for user preferences (refreshed periodically)
  Map<String, dynamic>? _cachedPreferences;
  DateTime? _cacheTimestamp;
  static const Duration _cacheValidity = Duration(minutes: 5);
  
  /// Get user notification preferences (with caching)
  Future<Map<String, dynamic>> _getPreferences() async {
    final user = _auth.currentUser;
    if (user == null) {
      return _getDefaultPreferences();
    }
    
    // Return cached preferences if still valid
    if (_cachedPreferences != null && 
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheValidity) {
      return _cachedPreferences!;
    }
    
    try {
      final doc = await _firestore
          .collection('user_notification_settings')
          .doc(user.uid)
          .get();
      
      if (doc.exists && doc.data() != null) {
        _cachedPreferences = doc.data()!;
        _cacheTimestamp = DateTime.now();
        return _cachedPreferences!;
      }
    } catch (e) {
      debugPrint('⚠️ Failed to load notification preferences: $e');
    }
    
    return _getDefaultPreferences();
  }
  
  Map<String, dynamic> _getDefaultPreferences() {
    return {
      'vatReminders': true,
      'ctReminders': true,
      'ocrErrors': true,
      'duplicateAlerts': true,
      'monthlySummaries': false,
      'pushNotifications': true,
      'emailUpdates': true,
      'inAppOnly': false,
      'quietHoursEnabled': false,
      'quietHoursMode': 'night',
    };
  }
  
  /// Clear cache (call when preferences are updated)
  void clearCache() {
    _cachedPreferences = null;
    _cacheTimestamp = null;
  }
  
  /// Check if a notification type is enabled
  Future<bool> isNotificationTypeEnabled(String notificationType) async {
    final prefs = await _getPreferences();
    
    switch (notificationType.toLowerCase()) {
      case 'vat':
      case 'vat_reminder':
      case 'vat_return':
      case 'vat_payment':
        return prefs['vatReminders'] as bool? ?? true;
      
      case 'corporate':
      case 'ct':
      case 'corporate_tax':
      case 'ct_reminder':
      case 'ct_return':
      case 'ct_payment':
        return prefs['ctReminders'] as bool? ?? true;
      
      case 'ocr':
      case 'ocr_error':
      case 'invoice_error':
        return prefs['ocrErrors'] as bool? ?? true;
      
      case 'duplicate':
      case 'duplicate_invoice':
      case 'duplicate_alert':
        return prefs['duplicateAlerts'] as bool? ?? true;
      
      case 'monthly':
      case 'monthly_summary':
        return prefs['monthlySummaries'] as bool? ?? false;
      
      case 'system':
      case 'security':
      case 'warning':
      case 'critical':
        // System/security notifications are always enabled
        return true;
      
      default:
        // Default to enabled for unknown types
        return true;
    }
  }
  
  /// Check if push notifications are enabled
  Future<bool> isPushEnabled() async {
    final prefs = await _getPreferences();
    return prefs['pushNotifications'] as bool? ?? true;
  }
  
  /// Check if in-app only mode is enabled
  Future<bool> isInAppOnly() async {
    final prefs = await _getPreferences();
    return prefs['inAppOnly'] as bool? ?? false;
  }
  
  /// Check if email updates are enabled
  Future<bool> isEmailEnabled() async {
    final prefs = await _getPreferences();
    return prefs['emailUpdates'] as bool? ?? true;
  }
  
  /// Check if notification should be sent (considers all preferences)
  Future<bool> shouldSendNotification({
    required String notificationType,
    required bool isCritical,
    bool checkQuietHours = true,
  }) async {
    // Critical notifications (security alerts) are always sent
    if (isCritical) {
      return true;
    }
    
    // Check if notification type is enabled
    final typeEnabled = await isNotificationTypeEnabled(notificationType);
    if (!typeEnabled) {
      debugPrint('🔇 Notification suppressed: Type "$notificationType" is disabled');
      return false;
    }
    
    // Check quiet hours (if enabled)
    if (checkQuietHours) {
      final shouldSuppress = await _quietHoursService.shouldSuppressNotification(
        isCritical: isCritical,
      );
      if (shouldSuppress) {
        debugPrint('🔇 Notification suppressed: Quiet hours active');
        return false;
      }
    }
    
    return true;
  }
  
  /// Check if notification should be sent via push (FCM)
  Future<bool> shouldSendPush({
    required String notificationType,
    required bool isCritical,
  }) async {
    // Critical notifications always sent via push
    if (isCritical) {
      return true;
    }
    
    // Check if push is enabled
    final pushEnabled = await isPushEnabled();
    if (!pushEnabled) {
      debugPrint('🔇 Push notification suppressed: Push notifications disabled');
      return false;
    }
    
    // Check if in-app only mode is enabled
    final inAppOnly = await isInAppOnly();
    if (inAppOnly) {
      debugPrint('🔇 Push notification suppressed: In-app only mode enabled');
      return false;
    }
    
    // Check other preferences
    return await shouldSendNotification(
      notificationType: notificationType,
      isCritical: isCritical,
    );
  }
  
  /// Check if notification should be sent via email
  Future<bool> shouldSendEmail({
    required String notificationType,
    required bool isCritical,
  }) async {
    // Critical notifications always sent via email
    if (isCritical) {
      return true;
    }
    
    // Check if email is enabled
    final emailEnabled = await isEmailEnabled();
    if (!emailEnabled) {
      debugPrint('🔇 Email notification suppressed: Email updates disabled');
      return false;
    }
    
    // Check other preferences
    return await shouldSendNotification(
      notificationType: notificationType,
      isCritical: isCritical,
    );
  }
  
  /// Get all preferences (for debugging/admin)
  Future<Map<String, dynamic>> getAllPreferences() async {
    return await _getPreferences();
  }
}

