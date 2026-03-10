import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Lightweight activity tracking for MVP admin analytics.
/// Writes per-user activity snapshots into `user_activity/{uid}`.
class ActivityTrackingService {
  ActivityTrackingService._();
  static final ActivityTrackingService instance = ActivityTrackingService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime? _lastRouteTrackedAt;
  String? _lastRouteName;

  Future<void> trackAppOpen() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('user_activity').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? '',
        'lastActiveAt': FieldValue.serverTimestamp(),
        'lastAppOpenAt': FieldValue.serverTimestamp(),
        'appOpenCount': FieldValue.increment(1),
        'platform': _platformLabel(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('ActivityTrackingService.trackAppOpen error: $e');
    }
  }

  Future<void> trackRouteView(String routeName) async {
    final user = _auth.currentUser;
    if (user == null || routeName.isEmpty) return;

    final now = DateTime.now();
    if (_lastRouteName == routeName &&
        _lastRouteTrackedAt != null &&
        now.difference(_lastRouteTrackedAt!).inSeconds < 8) {
      return;
    }
    _lastRouteTrackedAt = now;
    _lastRouteName = routeName;

    try {
      await _firestore.collection('user_activity').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email ?? '',
        'lastActiveAt': FieldValue.serverTimestamp(),
        'lastRoute': routeName,
        'lastRouteAt': FieldValue.serverTimestamp(),
        'screenViewCount': FieldValue.increment(1),
        'platform': _platformLabel(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('ActivityTrackingService.trackRouteView error: $e');
    }
  }

  String _platformLabel() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'unknown';
    }
  }
}
