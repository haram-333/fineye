import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'notification_preferences_service.dart';

/// Service for managing notifications in Firestore
class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationPreferencesService _prefsService = NotificationPreferencesService();
  
  /// Create a notification for a user (checks preferences first)
  Future<String?> createNotification({
    required String userId,
    required Map<String, dynamic> notificationData,
    bool checkPreferences = true,
  }) async {
    // Check preferences if enabled
    if (checkPreferences) {
      final notificationType = notificationData['type'] as String? ?? 'system';
      final isCritical = notificationData['isCritical'] == true ||
                         notificationType == 'warning' ||
                         notificationType == 'security';
      
      final shouldSend = await _prefsService.shouldSendNotification(
        notificationType: notificationType,
        isCritical: isCritical,
      );
      
      if (!shouldSend) {
        debugPrint('🔇 Notification creation suppressed: User preferences');
        // Still create in Firestore but mark as suppressed
        notificationData['suppressed'] = true;
        notificationData['suppressionReason'] = 'user_preferences';
      }
    }
    
    try {
      final docRef = _firestore
          .collection('user_notifications')
          .doc(userId)
          .collection('notifications')
          .doc();
      
      await docRef.set({
        ...notificationData,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Notification created: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Failed to create notification: $e');
      return null;
    }
  }
  
  /// Mark notification as read
  Future<bool> markAsRead(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('user_notifications')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      debugPrint('❌ Failed to mark notification as read: $e');
      return false;
    }
  }
  
  /// Mark all notifications as read for a user
  Future<bool> markAllAsRead(String userId) async {
    try {
      final notificationsRef = _firestore
          .collection('user_notifications')
          .doc(userId)
          .collection('notifications');
      
      // Get all notifications (not just unread ones) to ensure consistency
      final snapshot = await notificationsRef.get();
      
      // If no notifications, return early
      if (snapshot.docs.isEmpty) {
        return true;
      }
      
      // Filter documents that need to be updated
      final docsToUpdate = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['isRead'] != true;
      }).toList();
      
      if (docsToUpdate.isEmpty) {
        debugPrint('✅ All notifications already marked as read');
        return true;
      }
      
      // Use batch write for efficiency (max 500 operations per batch)
      const int batchLimit = 500;
      int processed = 0;
      
      while (processed < docsToUpdate.length) {
        final batch = _firestore.batch();
        final endIndex = (processed + batchLimit < docsToUpdate.length)
            ? processed + batchLimit
            : docsToUpdate.length;
        
        for (int i = processed; i < endIndex; i++) {
          batch.update(docsToUpdate[i].reference, {
            'isRead': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        
        await batch.commit();
        processed = endIndex;
      }
      
      debugPrint('✅ Marked ${docsToUpdate.length} notifications as read for user: $userId');
      return true;
    } catch (e) {
      debugPrint('❌ Failed to mark all notifications as read: $e');
      return false;
    }
  }
  
  /// Delete a notification
  Future<bool> deleteNotification(String userId, String notificationId) async {
    try {
      await _firestore
          .collection('user_notifications')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
      
      return true;
    } catch (e) {
      debugPrint('❌ Failed to delete notification: $e');
      return false;
    }
  }
  
  /// Get notification count for a user
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('user_notifications')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ Failed to get unread count: $e');
      return 0;
    }
  }
}

