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
        'Biometric Unavailable',
        'Biometric authentication is not available on this device.',
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
            'Biometric Enabled',
            'Biometric authentication has been enabled successfully.',
          );
        }
      } on PlatformException catch (e) {
        SnackbarService.to.showError(
          'Authentication Failed',
          e.message ?? 'Failed to authenticate. Please try again.',
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
        'Screen Privacy Enabled',
        'App content will be hidden in the app switcher and screenshots are disabled.',
      );
    } else {
      await ScreenPrivacyService.disable();
      SnackbarService.to.showInfo(
        'Screen Privacy Disabled',
        'App content will be visible in the app switcher.',
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
        'Auto-lock Disabled',
        'App will no longer auto-lock automatically.',
      );
    } else {
      final effectiveTime = autoLockTime.value == 'off' ? '3m' : autoLockTime.value;
      autoLockTime.value = effectiveTime;
      await _storageService.saveSecuritySettings(
        autoLockEnabled: true,
        autoLockTime: effectiveTime,
      );
      final timeoutMinutes = int.tryParse(effectiveTime.replaceAll('m', '')) ?? 3;
      AutoLockService.instance.updateSettings(
        enabled: true,
        timeoutMinutes: timeoutMinutes,
      );
      SnackbarService.to.showInfo(
        'Auto-lock Enabled',
        'App will auto-lock after $effectiveTime of inactivity.',
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
    final timeoutMinutes = int.tryParse(time.replaceAll('m', '')) ?? 3;
    AutoLockService.instance.updateSettings(timeoutMinutes: timeoutMinutes);
    
    SnackbarService.to.showInfo(
      'Auto-lock Updated',
      'App will auto-lock after $time of inactivity.',
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
      title: 'Sign out from all devices?',
      middleText: 'This will sign you out from all logged-in devices except this one.',
      textConfirm: 'Sign out',
      textCancel: 'Cancel',
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
