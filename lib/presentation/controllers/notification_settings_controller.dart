import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/services/settings_storage_service.dart';
import '../../core/services/snackbar_service.dart';
import '../../core/services/notification_preferences_service.dart';
import '../views/notification_settings/widgets/custom_schedule_dialog.dart';

class NotificationSettingsController extends GetxController {
  final _storageService = SettingsStorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationPreferencesService _prefsService = NotificationPreferencesService();
  
  // Notification Preferences
  final RxBool vatReminders = true.obs;
  final RxBool ctReminders = true.obs;
  final RxBool ocrErrors = true.obs;
  final RxBool duplicateAlerts = true.obs;
  final RxBool monthlySummaries = false.obs;

  // Channels (exclusive: push OR in-app only)
  final RxBool pushNotifications = true.obs;
  final RxBool emailUpdates = true.obs;
  final RxBool inAppOnly = false.obs;

  // Quiet Hours (exclusive selection)
  final RxBool quietHoursEnabled = false.obs; // Master toggle for quiet hours
  final RxString quietHoursMode = 'night'.obs; // 'night', 'weekends', 'custom' (only used when enabled)
  
  // Custom Schedule
  final Rx<TimeOfDay> customStartTime = const TimeOfDay(hour: 22, minute: 0).obs;
  final Rx<TimeOfDay> customEndTime = const TimeOfDay(hour: 7, minute: 0).obs;
  final RxList<int> customSelectedDays = <int>[].obs; // 0 = Monday, 6 = Sunday

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
    _loadCustomSchedule();
  }

  Future<void> _loadSettings() async {
    final user = _auth.currentUser;
    
    // Try to load from Firestore first
    if (user != null) {
      try {
        final doc = await _firestore
            .collection('user_notification_settings')
            .doc(user.uid)
            .get();
        
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          vatReminders.value = data['vatReminders'] as bool? ?? true;
          ctReminders.value = data['ctReminders'] as bool? ?? true;
          ocrErrors.value = data['ocrErrors'] as bool? ?? true;
          duplicateAlerts.value = data['duplicateAlerts'] as bool? ?? true;
          monthlySummaries.value = data['monthlySummaries'] as bool? ?? false;
          pushNotifications.value = data['pushNotifications'] as bool? ?? true;
          emailUpdates.value = data['emailUpdates'] as bool? ?? true;
          inAppOnly.value = data['inAppOnly'] as bool? ?? false;
          quietHoursEnabled.value = data['quietHoursEnabled'] as bool? ?? false;
          quietHoursMode.value = data['quietHoursMode'] as String? ?? 'night';
          
          // Sync to local storage
          await _storageService.saveNotificationSettings(
            vatReminders: vatReminders.value,
            ctReminders: ctReminders.value,
            ocrErrors: ocrErrors.value,
            duplicateAlerts: duplicateAlerts.value,
            monthlySummaries: monthlySummaries.value,
            pushNotifications: pushNotifications.value,
            emailUpdates: emailUpdates.value,
            inAppOnly: inAppOnly.value,
            quietHoursMode: quietHoursMode.value,
          );
          return;
        }
      } catch (e) {
        // Fall back to local storage if Firestore fails
      }
    }
    
    // Fallback to local storage
    final settings = await _storageService.loadNotificationSettings();
    vatReminders.value = settings['vatReminders'] as bool;
    ctReminders.value = settings['ctReminders'] as bool;
    ocrErrors.value = settings['ocrErrors'] as bool;
    duplicateAlerts.value = settings['duplicateAlerts'] as bool;
    monthlySummaries.value = settings['monthlySummaries'] as bool;
    pushNotifications.value = settings['pushNotifications'] as bool;
    emailUpdates.value = settings['emailUpdates'] as bool;
    inAppOnly.value = settings['inAppOnly'] as bool;
    quietHoursEnabled.value = settings['quietHoursEnabled'] as bool? ?? false;
    quietHoursMode.value = settings['quietHoursMode'] as String? ?? 'night';
  }

  void toggleVatReminders(bool value) async {
    vatReminders.value = value;
    await _saveToggleToStorage('vatReminders', value);
    await _saveToggleToFirestore('vatReminders', value);
    _clearNotificationPreferencesCache();
  }

  void toggleCtReminders(bool value) async {
    ctReminders.value = value;
    await _saveToggleToStorage('ctReminders', value);
    await _saveToggleToFirestore('ctReminders', value);
    _clearNotificationPreferencesCache();
  }

  void toggleOcrErrors(bool value) async {
    ocrErrors.value = value;
    await _saveToggleToStorage('ocrErrors', value);
    await _saveToggleToFirestore('ocrErrors', value);
    _clearNotificationPreferencesCache();
  }

  void toggleDuplicateAlerts(bool value) async {
    duplicateAlerts.value = value;
    await _saveToggleToStorage('duplicateAlerts', value);
    await _saveToggleToFirestore('duplicateAlerts', value);
    _clearNotificationPreferencesCache();
  }

  void toggleMonthlySummaries(bool value) async {
    monthlySummaries.value = value;
    await _saveToggleToStorage('monthlySummaries', value);
    await _saveToggleToFirestore('monthlySummaries', value);
    _clearNotificationPreferencesCache();
  }

  void togglePushNotifications(bool value) async {
    pushNotifications.value = value;
    // Exclusive logic: if enabling push, disable in-app only
    if (value && inAppOnly.value) {
      inAppOnly.value = false;
      await _saveToggleToStorage('pushNotifications', value);
      await _saveToggleToStorage('inAppOnly', false);
      await _saveToggleToFirestore('pushNotifications', value);
      await _saveToggleToFirestore('inAppOnly', false);
    } else {
      await _saveToggleToStorage('pushNotifications', value);
      await _saveToggleToFirestore('pushNotifications', value);
    }
    
    // Clear notification preferences cache
    _clearNotificationPreferencesCache();
  }

  void toggleEmailUpdates(bool value) async {
    emailUpdates.value = value;
    await _saveToggleToStorage('emailUpdates', value);
    await _saveToggleToFirestore('emailUpdates', value);
    _clearNotificationPreferencesCache();
  }

  void toggleInAppOnly(bool value) async {
    inAppOnly.value = value;
    // Exclusive logic: if enabling in-app only, disable push
    if (value && pushNotifications.value) {
      pushNotifications.value = false;
      await _saveToggleToStorage('inAppOnly', value);
      await _saveToggleToStorage('pushNotifications', false);
      await _saveToggleToFirestore('inAppOnly', value);
      await _saveToggleToFirestore('pushNotifications', false);
    } else {
      await _saveToggleToStorage('inAppOnly', value);
      await _saveToggleToFirestore('inAppOnly', value);
    }
    
    // Clear notification preferences cache
    _clearNotificationPreferencesCache();
  }
  
  /// Helper to save toggle to local storage
  Future<void> _saveToggleToStorage(String key, bool value) async {
    switch (key) {
      case 'vatReminders':
        await _storageService.saveNotificationSettings(vatReminders: value);
        break;
      case 'ctReminders':
        await _storageService.saveNotificationSettings(ctReminders: value);
        break;
      case 'ocrErrors':
        await _storageService.saveNotificationSettings(ocrErrors: value);
        break;
      case 'duplicateAlerts':
        await _storageService.saveNotificationSettings(duplicateAlerts: value);
        break;
      case 'monthlySummaries':
        await _storageService.saveNotificationSettings(monthlySummaries: value);
        break;
      case 'pushNotifications':
        await _storageService.saveNotificationSettings(pushNotifications: value);
        break;
      case 'emailUpdates':
        await _storageService.saveNotificationSettings(emailUpdates: value);
        break;
      case 'inAppOnly':
        await _storageService.saveNotificationSettings(inAppOnly: value);
        break;
    }
  }
  
  /// Helper to save toggle to Firestore
  Future<void> _saveToggleToFirestore(String key, dynamic value) async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      await _firestore
          .collection('user_notification_settings')
          .doc(user.uid)
          .set({
        key: value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to save $key to Firestore: $e');
    }
  }
  
  /// Clear notification preferences cache
  void _clearNotificationPreferencesCache() {
    _prefsService.clearCache();
  }

  void toggleQuietHoursEnabled(bool value) async {
    quietHoursEnabled.value = value;
    await _storageService.saveNotificationSettings(quietHoursEnabled: value);
    await _saveToggleToFirestore('quietHoursEnabled', value);
    _clearNotificationPreferencesCache();
    
    // If disabling, set mode to 'off' for internal tracking
    if (!value) {
      await _saveToggleToFirestore('quietHoursMode', 'off');
    }
  }
  
  void setQuietHoursMode(String mode) async {
    if (!quietHoursEnabled.value) return; // Don't allow setting mode when disabled
    
    quietHoursMode.value = mode;
    await _storageService.saveNotificationSettings(quietHoursMode: mode);
    
    // If switching away from custom, clear custom schedule
    if (mode != 'custom') {
      customSelectedDays.clear();
    }
    
    // Save to Firestore
    await _saveToggleToFirestore('quietHoursMode', mode);
    _clearNotificationPreferencesCache();
  }

  Future<void> setCustomSchedule() async {
    final result = await Get.dialog<Map<String, dynamic>>(
      CustomScheduleDialog(
        initialStartTime: customStartTime.value,
        initialEndTime: customEndTime.value,
        initialSelectedDays: List.from(customSelectedDays),
      ),
    );

    if (result != null) {
      customStartTime.value = result['startTime'] as TimeOfDay;
      customEndTime.value = result['endTime'] as TimeOfDay;
      customSelectedDays.value = List<int>.from(result['selectedDays'] as List);
      
      // Set mode to custom
      quietHoursMode.value = 'custom';
      
      // Save to storage and Firestore
      await _saveCustomSchedule();
      _clearNotificationPreferencesCache();
      
      SnackbarService.to.showSuccess(
        'title_success'.tr,
        'msg_custom_schedule_saved'.tr,
      );
    }
  }
  
  Future<void> _saveCustomSchedule() async {
    // Save to local storage
    await _storageService.saveNotificationSettings(
      quietHoursMode: 'custom',
    );
    
    // Save custom schedule details to Firestore
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('user_notification_settings')
            .doc(user.uid)
            .set({
          'quietHoursMode': 'custom',
          'customStartHour': customStartTime.value.hour,
          'customStartMinute': customStartTime.value.minute,
          'customEndHour': customEndTime.value.hour,
          'customEndMinute': customEndTime.value.minute,
          'customSelectedDays': customSelectedDays.toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Failed to save custom schedule to Firestore: $e');
      }
    }
  }
  
  Future<void> _loadCustomSchedule() async {
    final user = _auth.currentUser;
    if (user == null) return;
    
    try {
      final doc = await _firestore
          .collection('user_notification_settings')
          .doc(user.uid)
          .get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['quietHoursMode'] == 'custom') {
          customStartTime.value = TimeOfDay(
            hour: data['customStartHour'] as int? ?? 22,
            minute: data['customStartMinute'] as int? ?? 0,
          );
          customEndTime.value = TimeOfDay(
            hour: data['customEndHour'] as int? ?? 7,
            minute: data['customEndMinute'] as int? ?? 0,
          );
          customSelectedDays.value = List<int>.from(
            data['customSelectedDays'] as List? ?? [],
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to load custom schedule: $e');
    }
  }

  Future<void> saveSettings() async {
    final user = _auth.currentUser;
    if (user == null) {
      SnackbarService.to.showError(
        'title_error'.tr,
        'You must be logged in to save settings.',
      );
      return;
    }
    
    try {
      // Save to local storage
      await _storageService.saveNotificationSettings(
        vatReminders: vatReminders.value,
        ctReminders: ctReminders.value,
        ocrErrors: ocrErrors.value,
        duplicateAlerts: duplicateAlerts.value,
        monthlySummaries: monthlySummaries.value,
        pushNotifications: pushNotifications.value,
        emailUpdates: emailUpdates.value,
        inAppOnly: inAppOnly.value,
        quietHoursEnabled: quietHoursEnabled.value,
        quietHoursMode: quietHoursMode.value,
      );
      
      // Save to Firestore
      final firestoreData = {
        'vatReminders': vatReminders.value,
        'ctReminders': ctReminders.value,
        'ocrErrors': ocrErrors.value,
        'duplicateAlerts': duplicateAlerts.value,
        'monthlySummaries': monthlySummaries.value,
        'pushNotifications': pushNotifications.value,
        'emailUpdates': emailUpdates.value,
        'inAppOnly': inAppOnly.value,
        'quietHoursEnabled': quietHoursEnabled.value,
        'quietHoursMode': quietHoursEnabled.value ? quietHoursMode.value : 'off',
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Add custom schedule if mode is custom
      if (quietHoursMode.value == 'custom') {
        firestoreData['customStartHour'] = customStartTime.value.hour;
        firestoreData['customStartMinute'] = customStartTime.value.minute;
        firestoreData['customEndHour'] = customEndTime.value.hour;
        firestoreData['customEndMinute'] = customEndTime.value.minute;
        firestoreData['customSelectedDays'] = customSelectedDays.toList();
      }
      
      await _firestore
          .collection('user_notification_settings')
          .doc(user.uid)
          .set(firestoreData, SetOptions(merge: true));
      
      // Clear cache to ensure fresh preferences are used
      _clearNotificationPreferencesCache();
      
      Get.back();
      SnackbarService.to.showSuccess(
        'title_success'.tr,
        'msg_notif_settings_saved'.tr,
      );
    } catch (e) {
      SnackbarService.to.showError(
        'title_error'.tr,
        'Failed to save settings: ${e.toString()}',
      );
    }
  }

  Future<void> resetToDefaults() async {
    final user = _auth.currentUser;
    if (user == null) {
      SnackbarService.to.showError(
        'title_error'.tr,
        'You must be logged in to reset settings.',
      );
      return;
    }
    
    // Reset reactive values
    vatReminders.value = true;
    ctReminders.value = true;
    ocrErrors.value = true;
    duplicateAlerts.value = true;
    monthlySummaries.value = false;
    pushNotifications.value = true;
    emailUpdates.value = true;
    inAppOnly.value = false;
    quietHoursEnabled.value = false;
    quietHoursMode.value = 'night';
    customSelectedDays.clear();
    customStartTime.value = const TimeOfDay(hour: 22, minute: 0);
    customEndTime.value = const TimeOfDay(hour: 7, minute: 0);
    
    // Save to local storage
    await _storageService.saveNotificationSettings(
      vatReminders: true,
      ctReminders: true,
      ocrErrors: true,
      duplicateAlerts: true,
      monthlySummaries: false,
      pushNotifications: true,
      emailUpdates: true,
      inAppOnly: false,
      quietHoursEnabled: false,
      quietHoursMode: 'night',
    );
    
    // Save to Firestore
    try {
      await _firestore
          .collection('user_notification_settings')
          .doc(user.uid)
          .set({
        'vatReminders': true,
        'ctReminders': true,
        'ocrErrors': true,
        'duplicateAlerts': true,
        'monthlySummaries': false,
        'pushNotifications': true,
        'emailUpdates': true,
        'inAppOnly': false,
        'quietHoursEnabled': false,
        'quietHoursMode': 'night',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      _clearNotificationPreferencesCache();
    } catch (e) {
      debugPrint('Failed to reset settings in Firestore: $e');
    }
    
    SnackbarService.to.showSuccess(
      'title_reset'.tr,
      'msg_notif_settings_reset'.tr,
    );
  }
}
