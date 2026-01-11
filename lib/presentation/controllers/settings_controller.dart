import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_routes.dart';
import '../../core/services/snackbar_service.dart';
import '../../core/services/settings_storage_service.dart';
import '../../data/services/auth_service.dart';

class SettingsController extends GetxController {
  final _authService = AuthService();
  final isArabic = false.obs;
  final notificationsEnabled = true.obs;

  @override
  void onInit() {
    super.onInit();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final storageService = SettingsStorageService();
    final savedLanguage = await storageService.getLanguage();
    
    if (savedLanguage != null) {
      isArabic.value = savedLanguage == 'ar';
      var locale = isArabic.value ? const Locale('ar', 'AE') : const Locale('en', 'US');
      Get.updateLocale(locale);
    } else {
      // Sync toggle with current locale if no saved preference
    if (Get.locale?.languageCode == 'ar') {
      isArabic.value = true;
      }
    }
  }

  void toggleLanguage(bool value) async {
    isArabic.value = value;
    var locale = value ? const Locale('ar', 'AE') : const Locale('en', 'US');
    Get.updateLocale(locale);
    
    // Save to storage using SettingsStorageService
    final storageService = SettingsStorageService();
    await storageService.saveLanguage(locale.languageCode);
  }

  void toggleNotifications(bool value) {
    notificationsEnabled.value = value;
  }

  Future<void> logout() async {
    // Show confirmation dialog
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: Text('logout_confirmation_title'.tr),
        content: Text('logout_confirmation_message'.tr),
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
            child: Text('btn_logout'.tr),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Sign out from Firebase Auth
        await _authService.signOut();
        debugPrint('✅ User signed out from Firebase');
        
        // Clear local settings
      final storageService = SettingsStorageService();
      await storageService.clearAllSettings();
        debugPrint('✅ Local settings cleared');
      
      // Show success message
      SnackbarService.to.showSuccess(
        'title_signed_out'.tr,
        'msg_logout_success'.tr,
      );

      // Navigate to auth screen and clear navigation stack
      Get.offAllNamed(AppRoutes.auth);
      } catch (e) {
        debugPrint('❌ Logout error: $e');
        SnackbarService.to.showError(
          'title_error'.tr,
          'Failed to logout. Please try again.',
        );
      }
    }
  }
}
