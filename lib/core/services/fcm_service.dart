import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'notification_service.dart';
import 'quiet_hours_service.dart';
import 'notification_preferences_service.dart';

/// Top-level function for handling background messages
/// Must be a top-level function (not a class method)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('📬 Background message received: ${message.messageId}');
  debugPrint('📬 Title: ${message.notification?.title}');
  debugPrint('📬 Body: ${message.notification?.body}');
  debugPrint('📬 Data: ${message.data}');
  
  // Initialize Firebase if not already initialized
  // Note: This is needed because background handler runs in isolate
  // await Firebase.initializeApp();
  
  // Check if notification is critical
  final isCritical = message.data['isCritical'] == true || 
                     message.data['type'] == 'warning' ||
                     message.data['type'] == 'security';
  
  // For background messages, we still save to Firestore
  // The quiet hours check will be done when displaying the notification
  // This ensures users can see all notifications in the app later
  debugPrint('💾 Background notification will be saved to Firestore');
}

/// Firebase Cloud Messaging Service
/// Handles push notifications for the app
class FCMService {
  static FCMService? _instance;
  static FCMService get instance => _instance ??= FCMService._();
  
  FCMService._();
  
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();
  final QuietHoursService _quietHoursService = QuietHoursService();
  final NotificationPreferencesService _prefsService = NotificationPreferencesService();
  
  String? _fcmToken;
  StreamSubscription<User?>? _authStateSubscription;
  
  /// Initialize FCM service
  Future<void> initialize() async {
    try {
      // Request permission for notifications
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      debugPrint('📱 FCM Permission status: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('⚠️ User granted provisional notification permission');
      } else {
        debugPrint('❌ User denied notification permission');
        return;
      }
      
      // Get FCM token
      _fcmToken = await _messaging.getToken();
      debugPrint('📱 FCM Token: $_fcmToken');
      
      // Save token to Firestore for current user
      await _saveTokenToFirestore(_fcmToken);
      
      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        debugPrint('🔄 FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        _saveTokenToFirestore(newToken);
      });
      
      // Set up foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      
      // Handle notification taps (when app is opened from notification)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
      // Check if app was opened from a notification
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }
      
      // Listen to auth state changes to update token
      _authStateSubscription = _auth.authStateChanges().listen((user) {
        if (user != null) {
          // User logged in, save token
          _saveTokenToFirestore(_fcmToken);
        } else {
          // User logged out, remove token (optional)
          debugPrint('👤 User logged out, FCM token remains for next login');
        }
      });
      
    } catch (e, stackTrace) {
      debugPrint('❌ FCM initialization error: $e');
      debugPrint('❌ Stack trace: $stackTrace');
    }
  }
  
  /// Save FCM token to Firestore for the current user
  Future<void> _saveTokenToFirestore(String? token) async {
    final user = _auth.currentUser;
    if (user == null || token == null) return;
    
    try {
      await _firestore
          .collection('user_fcm_tokens')
          .doc(user.uid)
          .set({
        'token': token,
        'userId': user.uid,
        'updatedAt': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.toString(),
      }, SetOptions(merge: true));
      
      debugPrint('✅ FCM token saved to Firestore for user: ${user.uid}');
    } catch (e) {
      debugPrint('❌ Failed to save FCM token: $e');
    }
  }
  
  /// Handle foreground messages (when app is open)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('📬 Foreground message received: ${message.messageId}');
    debugPrint('📬 Title: ${message.notification?.title}');
    debugPrint('📬 Body: ${message.notification?.body}');
    debugPrint('📬 Data: ${message.data}');
    
    // Check if notification is critical (security alerts should always be shown)
    final isCritical = message.data['isCritical'] == true || 
                       message.data['type'] == 'warning' ||
                       message.data['type'] == 'security';
    
    final notificationType = message.data['type'] as String? ?? 'system';
    
    // Check if notification should be sent (respects all user preferences)
    final shouldSend = await _prefsService.shouldSendPush(
      notificationType: notificationType,
      isCritical: isCritical,
    );
    
    if (!shouldSend) {
      debugPrint('🔇 Notification suppressed due to user preferences');
      // Still save to Firestore so user can see it later in the app
      await _saveNotificationFromMessage(message);
      return;
    }
    
    // Save notification to Firestore
    await _saveNotificationFromMessage(message);
    
    // Show local notification (optional - you can use flutter_local_notifications)
    // For now, we'll just show a snackbar
    if (Get.isRegistered<GetxController>()) {
      // You can show a snackbar or in-app notification here
      debugPrint('💬 Showing in-app notification');
    }
  }
  
  /// Handle notification taps (when user taps on notification)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 Notification tapped: ${message.messageId}');
    debugPrint('👆 Data: ${message.data}');
    
    // Navigate to relevant screen based on notification data
    final data = message.data;
    final type = data['type'] as String?;
    
    // You can add navigation logic here based on notification type
    // For example:
    // if (type == 'invoice') {
    //   Get.toNamed(AppRoutes.invoiceDetails, arguments: data);
    // } else if (type == 'vat') {
    //   Get.toNamed(AppRoutes.dashboard);
    // }
  }
  
  /// Save notification from FCM message to Firestore
  Future<void> _saveNotificationFromMessage(RemoteMessage message) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      final notificationData = {
        'type': message.data['type'] ?? 'system',
        'titleKey': message.data['titleKey'] ?? 'notifications_title',
        'titleParams': message.data['titleParams'] ?? {},
        'messageKey': message.data['messageKey'] ?? message.notification?.body ?? '',
        'messageParams': message.data['messageParams'] ?? {},
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        'userId': user.uid,
        'fcmMessageId': message.messageId,
      };
      
      await _notificationService.createNotification(
        userId: user.uid,
        notificationData: notificationData,
      );
      
      debugPrint('✅ Notification saved to Firestore');
    } catch (e) {
      debugPrint('❌ Failed to save notification: $e');
    }
  }
  
  /// Get current FCM token
  String? get token => _fcmToken;
  
  /// Dispose resources
  void dispose() {
    _authStateSubscription?.cancel();
  }
}

