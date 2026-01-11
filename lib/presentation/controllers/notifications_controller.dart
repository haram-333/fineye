import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../core/services/notification_service.dart';

/// High‑level category for notifications. Used to style the Alerts UI.
enum NotificationType { vat, corporate, system, warning }

/// Single notification shown in the Alerts screen.
///
/// The text itself comes from translation keys in `messages.dart`.
class AppNotification {
  final String id;
  final String title;
  final String message;
  final String time;
  final NotificationType type;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
  });
}

/// Controller that wires the Alerts screen to Firebase (Firestore + Auth).
///
/// Firestore data model (per‑user notifications):
///   Collection: user_notifications
///     Document: <uid>
///       Collection: notifications
///         Document: <notificationId> with fields:
///           - type: 'vat' | 'corporate' | 'system' | 'warning'
///           - titleKey: translation key for the title (e.g. 'notif_vat_return_due')
///           - titleParams: optional map of params for the title (e.g. { 'days': 5 })
///           - messageKey: translation key for the body message
///           - messageParams: optional map of params for the message
///           - createdAt: Firestore Timestamp
///           - isRead: bool
class NotificationsController extends GetxController {
  /// All notifications currently loaded in memory.
  final notifications = <AppNotification>[].obs;

  /// Current filter applied on the Alerts screen.
  /// Possible values: 'All', 'Unread', 'System'.
  final filterType = 'All'.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;

  // Computed property for filtered list
  List<AppNotification> get filteredNotifications {
    if (filterType.value == 'Unread') {
      return notifications.where((n) => !n.isRead).toList();
    } else if (filterType.value == 'System') {
      return notifications.where((n) => n.type == NotificationType.system).toList();
    }
    return notifications;
  }

  // Computed property for counts
  int get unreadCount => notifications.where((n) => !n.isRead).length;
  int get allCount => notifications.length;

  @override
  void onInit() {
    super.onInit();
    _subscribeToUserNotifications();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  /// Subscribe to the current user's notification documents in Firestore.
  void _subscribeToUserNotifications() {
    final user = _auth.currentUser;
    if (user == null) {
      notifications.clear();
      return;
    }

    _subscription?.cancel();

    _subscription = _firestore
        .collection('user_notifications')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        final mapped = snapshot.docs.map(_mapDocToNotification).toList();
        notifications.assignAll(mapped);
      },
      onError: (error) {
        // If there is any error, keep existing notifications but log it.
        debugPrint('⚠️ Notifications stream error: $error');
      },
    );
  }

  /// Reload notifications (for pull-to-refresh).
  /// This re-subscribes to the Firestore stream.
  Future<void> loadNotifications() async {
    _subscribeToUserNotifications();
    // Small delay for visual feedback
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Map a Firestore document into an in‑memory [AppNotification].
  AppNotification _mapDocToNotification(
      QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    // Type mapping (default to system).
    final typeStr = (data['type'] as String?)?.toLowerCase() ?? 'system';
    final type = _mapType(typeStr);

    // Translation keys & params.
    final String titleKey =
        (data['titleKey'] as String?) ?? 'notifications_title';
    final Map<String, dynamic> rawTitleParams =
        (data['titleParams'] as Map?)?.cast<String, dynamic>() ?? {};

    final String? messageKey = data['messageKey'] as String?;
    final Map<String, dynamic> rawMessageParams =
        (data['messageParams'] as Map?)?.cast<String, dynamic>() ?? {};

    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final bool isRead = data['isRead'] == true;

    // Localized strings using the same keys as messages.dart / meanings.dart.
    final title = rawTitleParams.isEmpty
        ? titleKey.tr
        : titleKey.trParams(
            rawTitleParams.map((k, v) => MapEntry(k, v.toString())),
          );

    String message = '';
    if (messageKey != null && messageKey.isNotEmpty) {
      message = rawMessageParams.isEmpty
          ? messageKey.tr
          : messageKey.trParams(
              rawMessageParams.map((k, v) => MapEntry(k, v.toString())),
            );
    }

    final timeLabel = _formatTime(createdAt, typeStr: typeStr);

    return AppNotification(
      id: doc.id,
      title: title,
      message: message,
      time: timeLabel,
      type: type,
      isRead: isRead,
    );
  }

  NotificationType _mapType(String type) {
    switch (type) {
      case 'vat':
        return NotificationType.vat;
      case 'corporate':
      case 'ct':
        return NotificationType.corporate;
      case 'warning':
        return NotificationType.warning;
      case 'system':
      default:
        return NotificationType.system;
    }
  }

  /// Format a human‑friendly time label using notification time translations.
  String _formatTime(DateTime? dateTime, {required String typeStr}) {
    if (dateTime == null) return 'notif_time_now'.tr;

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'notif_time_just_now'.tr;
    } else if (diff.inMinutes < 60) {
      return 'notif_time_minutes_ago'
          .trParams({'count': diff.inMinutes.toString()});
    } else if (diff.inHours == 1) {
      return 'notif_time_hour_ago'.tr;
    } else if (diff.inHours < 24) {
      return 'notif_time_hours_ago'
          .trParams({'count': diff.inHours.toString()});
    } else if (diff.inDays == 1) {
      return 'notif_time_yesterday'.tr;
    } else if (diff.inDays < 7) {
      return 'notif_time_days_ago'
          .trParams({'count': diff.inDays.toString()});
    } else if (diff.inDays < 14) {
      return 'notif_time_week_ago'.tr;
    } else if (diff.inDays < 60) {
      final weeks = (diff.inDays / 7).floor();
      return 'notif_time_weeks_ago'.trParams({'count': weeks.toString()});
    }

    // Fallback to a simple date string (so very old notifications remain readable).
    return '${dateTime.day.toString().padLeft(2, '0')} '
        '${_monthShort(dateTime.month)} '
        '${dateTime.year}';
  }

  String _monthShort(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    if (month < 1 || month > 12) return '';
    return months[month - 1];
  }

  Future<void> markAllAsRead() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      final notificationService = NotificationService();
      await notificationService.markAllAsRead(user.uid);
      
      // Update local state
      for (var notification in notifications) {
        notification.isRead = true;
      }
      notifications.refresh();
    } catch (e) {
      debugPrint('⚠️ Failed to mark all as read: $e');
    }
  }

  void toggleRead(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      notifications[index].isRead = !notifications[index].isRead;
      notifications.refresh();
      _updateReadState(id, notifications[index].isRead);
    }
  }

  void deleteNotification(String id) {
    notifications.removeWhere((n) => n.id == id);
    _deleteFromBackend(id);
  }

  void setFilter(String filter) {
    filterType.value = filter;
  }

  Future<void> _updateReadState(String id, bool isRead) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      if (isRead) {
        // Use notification service for consistency
        final notificationService = NotificationService();
        await notificationService.markAsRead(user.uid, id);
      } else {
        // Mark as unread
        await _firestore
            .collection('user_notifications')
            .doc(user.uid)
            .collection('notifications')
            .doc(id)
            .update({'isRead': false});
      }
    } catch (e) {
      debugPrint('⚠️ Failed to update notification read state: $e');
    }
  }

  Future<void> _deleteFromBackend(String id) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final notificationService = NotificationService();
      await notificationService.deleteNotification(user.uid, id);
    } catch (e) {
      debugPrint('⚠️ Failed to delete notification from backend: $e');
    }
  }
}
