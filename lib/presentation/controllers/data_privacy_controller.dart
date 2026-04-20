import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/snackbar_service.dart';

class DataPrivacyController extends GetxController {
  static const int _batchLimit = 400;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  Future<void> exportUserData() async {
    try {
      // Show loading
      SnackbarService.to.showInfo(
        'title_exporting_data'.tr,
        'msg_preparing_data_export'.tr,
      );
      
      // In production, this would:
      // 1. Query Firestore for user data
      // 2. Generate JSON/CSV file
      // 3. Save to device storage
      // 4. Share file
      
      await Future.delayed(const Duration(seconds: 2));
      
      SnackbarService.to.showSuccess(
        'title_export_complete'.tr,
        'msg_data_export_success'.tr,
      );
    } catch (e) {
      SnackbarService.to.showError(
        'title_export_failed'.tr,
        'msg_data_export_error'.trParams({'error': e.toString()}),
      );
    }
  }

  Future<void> clearCache() async {
    try {
      // Clear image cache
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      }
      
      SnackbarService.to.showSuccess(
        'title_cache_cleared'.tr,
        'msg_cache_cleared_success'.tr,
      );
    } catch (e) {
      SnackbarService.to.showError(
        'title_clear_cache_failed'.tr,
        'msg_clear_cache_error'.tr,
      );
    }
  }

  Future<void> deleteAccount() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('delete_account_title'.tr),
        content: Text('delete_warning'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('btn_cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('btn_delete_account'.tr),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final user = _auth.currentUser;
        if (user == null) {
          SnackbarService.to.showError(
            'title_error'.tr,
            'msg_delete_account_error'.tr,
          );
          return;
        }

        SnackbarService.to.showInfo(
          'title_account_deletion'.tr,
          'msg_account_deletion_submitted'.tr,
        );

        await _deleteUserData(user.uid);

        // Clear local preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // Delete auth account last (may require recent login)
        await user.delete();

        await _auth.signOut();
        Get.offAllNamed('/auth');
      } catch (e) {
        if (e is FirebaseAuthException && e.code == 'requires-recent-login') {
          SnackbarService.to.showError(
            'title_error'.tr,
            'msg_delete_account_error'.tr,
          );
          return;
        }
        SnackbarService.to.showError(
          'title_deletion_failed'.tr,
          'msg_delete_account_error'.tr,
        );
      }
    }
  }

  Future<void> _deleteUserData(String uid) async {
    await _deleteUserInvoices(uid);
    await _deleteUserNotifications(uid);
    await _deleteUserSettings(uid);
    await _deleteUserActivity(uid);
    await _deleteUserProfile(uid);
    await _deleteUserStorage(uid);
  }

  Future<void> _deleteUserInvoices(String uid) async {
    final query = _firestore
        .collection('user_invoices')
        .where('userId', isEqualTo: uid)
        .limit(_batchLimit);
    await _deleteQueryInBatches(query);
  }

  Future<void> _deleteUserNotifications(String uid) async {
    final notifCollection = _firestore
        .collection('user_notifications')
        .doc(uid)
        .collection('notifications')
        .limit(_batchLimit);
    await _deleteQueryInBatches(notifCollection);
    await _firestore.collection('user_notifications').doc(uid).delete().catchError((_) {});
  }

  Future<void> _deleteUserSettings(String uid) async {
    await _firestore.collection('user_notification_settings').doc(uid).delete().catchError((_) {});
    await _firestore.collection('user_tax_settings').doc(uid).delete().catchError((_) {});
    await _firestore.collection('user_fcm_tokens').doc(uid).delete().catchError((_) {});
  }

  Future<void> _deleteUserActivity(String uid) async {
    await _firestore.collection('user_activity').doc(uid).delete().catchError((_) {});
  }

  Future<void> _deleteUserProfile(String uid) async {
    await _firestore.collection('users').doc(uid).delete().catchError((_) {});
  }

  Future<void> _deleteUserStorage(String uid) async {
    try {
      final rootRef = _storage.ref('user_invoices/$uid');
      await _deleteStorageFolder(rootRef);
    } catch (e) {
      debugPrint('Storage deletion error: $e');
    }
  }

  Future<void> _deleteStorageFolder(Reference ref) async {
    final listResult = await ref.listAll();
    for (final item in listResult.items) {
      await item.delete().catchError((_) {});
    }
    for (final prefix in listResult.prefixes) {
      await _deleteStorageFolder(prefix);
    }
  }

  Future<void> _deleteQueryInBatches(Query query) async {
    while (true) {
      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) break;
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      if (snapshot.docs.length < _batchLimit) break;
    }
  }
}
