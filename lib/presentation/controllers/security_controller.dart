import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/services/settings_storage_service.dart';
import '../../core/services/snackbar_service.dart';
import '../../core/services/screen_privacy_service.dart';
import '../../core/services/auto_lock_service.dart';

class SecurityController extends GetxController {
  final _storageService = SettingsStorageService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  
  // Login & Authentication
  final RxBool isTwoFactorEnabled = true.obs;
  final RxBool isBiometricEnabled = false.obs;
  final RxBool isBiometricAvailable = false.obs;

  // Data Protection
  final RxBool isScreenPrivacyEnabled = true.obs;
  final RxBool isAutoLockEnabled = true.obs;
  final RxString autoLockTime = '3m'.obs; // 3m, 5m, 15m

  // Devices (Mock Data)
  final RxList<Map<String, dynamic>> activeSessions = <Map<String, dynamic>>[
    {
      'device': 'iPhone 13 Pro',
      'location': 'Dubai, UAE',
      'isActive': true,
      'isCurrent': true,
    },
    {
      'device': 'MacBook Pro',
      'location': 'Abu Dhabi, UAE',
      'isActive': true,
      'isCurrent': false,
      'lastActive': '2 hours ago',
    }
  ].obs;

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    _checkBiometricAvailability();
  }

  Future<void> _loadSettings() async {
    final settings = await _storageService.loadSecuritySettings();
    isTwoFactorEnabled.value = settings['twoFactorEnabled'] as bool;
    isBiometricEnabled.value = settings['biometricEnabled'] as bool;
    isScreenPrivacyEnabled.value = settings['screenPrivacy'] as bool;
    autoLockTime.value = settings['autoLockTime'] as String;
    isAutoLockEnabled.value = settings['autoLockEnabled'] as bool;
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final isAvailable = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      isBiometricAvailable.value = isAvailable && isDeviceSupported;
    } catch (e) {
      isBiometricAvailable.value = false;
    }
  }

  Future<void> toggleTwoFactor(bool value) async {
    isTwoFactorEnabled.value = value;
    await _storageService.saveSecuritySettings(twoFactorEnabled: value);
  }

  Future<void> toggleBiometric(bool value) async {
    if (value && !isBiometricAvailable.value) {
      SnackbarService.to.showError(
        'title_biometric_unavailable'.tr,
        'msg_biometric_not_available'.tr,
      );
      return;
    }

    if (value) {
      // Authenticate before enabling
      try {
        final didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Enable biometric authentication for FinEye',
          options: const AuthenticationOptions(
            biometricOnly: true,
            stickyAuth: true,
          ),
        );

        if (didAuthenticate) {
          isBiometricEnabled.value = true;
          await _storageService.saveSecuritySettings(biometricEnabled: true);
          SnackbarService.to.showSuccess(
            'title_biometric_enabled'.tr,
            'msg_biometric_enabled_success'.tr,
          );
        }
      } on PlatformException catch (e) {
        SnackbarService.to.showError(
          'title_auth_failed'.tr,
          e.message ?? 'msg_auth_failed_retry'.tr,
        );
      }
    } else {
      isBiometricEnabled.value = false;
      await _storageService.saveSecuritySettings(biometricEnabled: false);
    }
  }

  Future<void> toggleScreenPrivacy(bool value) async {
    isScreenPrivacyEnabled.value = value;
    await _storageService.saveSecuritySettings(screenPrivacy: value);
    
    // Apply screen privacy setting using native implementation
    if (value) {
      await ScreenPrivacyService.enable();
      SnackbarService.to.showSuccess(
        'title_screen_privacy_enabled'.tr,
        'msg_screen_privacy_enabled'.tr,
      );
    } else {
      await ScreenPrivacyService.disable();
      SnackbarService.to.showInfo(
        'title_screen_privacy_disabled'.tr,
        'msg_screen_privacy_disabled'.tr,
      );
    }
  }

  Future<void> toggleAutoLockEnabled(bool value) async {
    isAutoLockEnabled.value = value;
    // When disabling, store a sentinel "off" value; when enabling, default to 3 minutes if unset.
    if (!value) {
      await _storageService.saveSecuritySettings(
        autoLockEnabled: false,
        autoLockTime: 'off',
      );
      AutoLockService.instance.updateSettings(enabled: false);
      SnackbarService.to.showInfo(
        'title_auto_lock_disabled'.tr,
        'msg_auto_lock_disabled'.tr,
      );
    } else {
      final effectiveTime = autoLockTime.value == 'off' ? '3m' : autoLockTime.value;
      autoLockTime.value = effectiveTime;
      await _storageService.saveSecuritySettings(
        autoLockEnabled: true,
        autoLockTime: effectiveTime,
      );
      final timeoutSeconds = (int.tryParse(effectiveTime.replaceAll('m', '')) ?? 3) * 60;
      AutoLockService.instance.updateSettings(
        enabled: true,
        timeoutSeconds: timeoutSeconds,
      );
      SnackbarService.to.showInfo(
        'title_auto_lock_enabled'.tr,
        'msg_auto_lock_enabled'.trParams({'time': effectiveTime}),
      );
    }
  }

  Future<void> setAutoLockTime(String time) async {
    if (!isAutoLockEnabled.value) {
      // Ignore taps when auto-lock is disabled
      return;
    }
    autoLockTime.value = time;
    await _storageService.saveSecuritySettings(
      autoLockTime: time,
      autoLockEnabled: true,
    );
    
    // Apply auto-lock setting
    final timeoutSeconds = (int.tryParse(time.replaceAll('m', '')) ?? 3) * 60;
    AutoLockService.instance.updateSettings(timeoutSeconds: timeoutSeconds);
    
    SnackbarService.to.showInfo(
      'title_auto_lock_updated'.tr,
      'msg_auto_lock_updated'.trParams({'time': time}),
    );
  }

  Future<void> resetSettings() async {
    isTwoFactorEnabled.value = true; // Default
    isBiometricEnabled.value = false; // Default
    isScreenPrivacyEnabled.value = true; // Default
  isAutoLockEnabled.value = true; // Default
  autoLockTime.value = '3m'; // Default
    
    await _storageService.saveSecuritySettings(
      twoFactorEnabled: true,
      biometricEnabled: false,
      screenPrivacy: true,
      autoLockTime: '3m',
      autoLockEnabled: true,
    );
    
    SnackbarService.to.showSuccess(
      'title_success'.tr, 
      'msg_security_reset'.tr,
    );
  }

  void signOutAllDevices() {
    Get.defaultDialog(
      title: 'dialog_sign_out_all_title'.tr,
      middleText: 'dialog_sign_out_all_message'.tr,
      textConfirm: 'btn_sign_out'.tr,
      textCancel: 'btn_cancel'.tr,
      confirmTextColor: Get.theme.colorScheme.onError,
      buttonColor: Get.theme.colorScheme.error,
      onConfirm: () {
        // Mock sign out logic - in production, this would call an API
        activeSessions.removeWhere((session) => !session['isCurrent']);
        Get.back();
        SnackbarService.to.showSuccess(
          'title_signed_out'.tr, 
          'msg_signed_out_all'.tr,
        );
      }
    );
  }

  Future<void> saveSecuritySettings() async {
    // Save all current security settings
    await _storageService.saveSecuritySettings(
      twoFactorEnabled: isTwoFactorEnabled.value,
      biometricEnabled: isBiometricEnabled.value,
      screenPrivacy: isScreenPrivacyEnabled.value,
      autoLockTime: isAutoLockEnabled.value ? autoLockTime.value : 'off',
      autoLockEnabled: isAutoLockEnabled.value,
    );
  }
}
