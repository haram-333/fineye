import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service to check if notifications should be suppressed during quiet hours
class QuietHoursService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  /// Check if current time is within quiet hours for the user
  Future<bool> isQuietHoursActive() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    try {
      final doc = await _firestore
          .collection('user_notification_settings')
          .doc(user.uid)
          .get();
      
      if (!doc.exists || doc.data() == null) return false;
      
      final data = doc.data()!;
      final enabled = data['quietHoursEnabled'] as bool? ?? false;
      
      if (!enabled) return false; // Quiet hours disabled
      
      final mode = data['quietHoursMode'] as String? ?? 'night';
      
      final now = DateTime.now();
      final currentDay = now.weekday - 1; // 0 = Monday, 6 = Sunday
      final currentHour = now.hour;
      final currentMinute = now.minute;
      final currentTimeMinutes = currentHour * 60 + currentMinute;
      
      // Handle predefined modes
      if (mode == 'night') {
        // 22:00 to 07:00
        if (currentTimeMinutes >= 22 * 60 || currentTimeMinutes < 7 * 60) {
          return true;
        }
      } else if (mode == 'weekends') {
        // Saturday (5) or Sunday (6)
        if (currentDay == 5 || currentDay == 6) {
          return true;
        }
      } else if (mode == 'custom') {
        // Check custom schedule
        final selectedDays = List<int>.from(data['customSelectedDays'] as List? ?? []);
        if (!selectedDays.contains(currentDay)) {
          return false; // Not a selected day
        }
        
        final startHour = data['customStartHour'] as int? ?? 22;
        final startMinute = data['customStartMinute'] as int? ?? 0;
        final endHour = data['customEndHour'] as int? ?? 7;
        final endMinute = data['customEndMinute'] as int? ?? 0;
        
        final startTimeMinutes = startHour * 60 + startMinute;
        final endTimeMinutes = endHour * 60 + endMinute;
        
        // Handle time range that spans midnight
        if (startTimeMinutes > endTimeMinutes) {
          // Range spans midnight (e.g., 22:00 to 07:00)
          if (currentTimeMinutes >= startTimeMinutes || currentTimeMinutes < endTimeMinutes) {
            return true;
          }
        } else {
          // Normal range (e.g., 09:00 to 17:00)
          if (currentTimeMinutes >= startTimeMinutes && currentTimeMinutes < endTimeMinutes) {
            return true;
          }
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking quiet hours: $e');
      return false; // Default to allowing notifications on error
    }
  }
  
  /// Check if notification should be suppressed (quiet hours + non-critical)
  /// Critical notifications (security alerts) should always be delivered
  Future<bool> shouldSuppressNotification({required bool isCritical}) async {
    if (isCritical) return false; // Never suppress critical notifications
    
    return await isQuietHoursActive();
  }
}

