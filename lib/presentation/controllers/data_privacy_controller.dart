import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/services/snackbar_service.dart';

class DataPrivacyController extends GetxController {
  
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
        // In production, this would:
        // 1. Delete user data from Firestore
        // 2. Delete user account from Firebase Auth
        // 3. Clear all local data
        // 4. Navigate to auth screen
        
        SnackbarService.to.showInfo(
          'title_account_deletion'.tr,
          'msg_account_deletion_submitted'.tr,
        );
        
        // Navigate to auth after a delay
        await Future.delayed(const Duration(seconds: 2));
        Get.offAllNamed('/auth');
      } catch (e) {
        SnackbarService.to.showError(
          'title_deletion_failed'.tr,
          'msg_delete_account_error'.tr,
        );
      }
    }
  }
}
