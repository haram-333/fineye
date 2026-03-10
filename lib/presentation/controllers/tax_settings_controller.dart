import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/settings_storage_service.dart';
import '../../core/services/snackbar_service.dart';
import '../../core/services/notification_preferences_service.dart';

class TaxSettingsController extends GetxController {
  final _storageService = SettingsStorageService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationPreferencesService _prefsService = NotificationPreferencesService();
  
  // Reactive variables for VAT settings
  final RxBool vatRemindersEnabled = true.obs;
  // Changed to single integer for single selection
  final RxInt selectedVatReminder = 7.obs; 
  
  // Reactive variables for CT settings
  final RxBool ctRemindersEnabled = true.obs;
  // Changed to single integer for single selection
  final RxInt selectedCtReminder = 30.obs;
  final RxBool isCtRegistered = true.obs;
  
  // Reactive variables for Notification preferences
  final RxBool ocrErrorsEnabled = true.obs;
  final RxBool duplicateInvoiceAlertsEnabled = true.obs;
  final RxBool monthlySummariesEnabled = true.obs;

  // Date variables (default to current year for initial setup)
  final Rx<DateTime> financialYearStart =
      DateTime(DateTime.now().year, 1, 1).obs;
  final Rx<DateTime> financialYearEnd =
      DateTime(DateTime.now().year, 12, 31).obs;
  final Rx<DateTime> ctRegistrationDate =
      DateTime(DateTime.now().year, 1, 1).obs;
  
  // Mock Next Dates (In a real app, these would be calculated)
  final DateTime nextVatFilingDate = DateTime(2025, 2, 15);
  final DateTime nextCtPaymentDate = DateTime(2025, 6, 30);

  @override
  void onInit() {
    super.onInit();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = _auth.currentUser;
    if (user == null) {
      // Load from local storage only if not logged in
      await _loadFromLocalStorage();
      return;
    }
    
    try {
      // Try to load from Firestore first
      final notifDoc = await _firestore
          .collection('user_notification_settings')
          .doc(user.uid)
          .get();
      
      if (notifDoc.exists && notifDoc.data() != null) {
        final data = notifDoc.data()!;
        vatRemindersEnabled.value = data['vatReminders'] as bool? ?? true;
        ctRemindersEnabled.value = data['ctReminders'] as bool? ?? true;
        ocrErrorsEnabled.value = data['ocrErrors'] as bool? ?? true;
        duplicateInvoiceAlertsEnabled.value = data['duplicateAlerts'] as bool? ?? true;
        monthlySummariesEnabled.value = data['monthlySummaries'] as bool? ?? false;
      }
      
      // Load tax reminder preferences (stored separately or in same doc)
      final taxRemindersDoc = await _firestore
          .collection('user_tax_settings')
          .doc(user.uid)
          .get();
      
      if (taxRemindersDoc.exists && taxRemindersDoc.data() != null) {
        final data = taxRemindersDoc.data()!;
        selectedVatReminder.value = data['vatReminderDays'] as int? ?? 7;
        selectedCtReminder.value = data['ctReminderDays'] as int? ?? 30;
        isCtRegistered.value = data['isCtRegistered'] as bool? ?? true;
        
        final startMs = data['financialYearStart'] as Timestamp?;
        final endMs = data['financialYearEnd'] as Timestamp?;
        final ctRegMs = data['ctRegistrationDate'] as Timestamp?;
        
        if (startMs != null) financialYearStart.value = startMs.toDate();
        if (endMs != null) financialYearEnd.value = endMs.toDate();
        if (ctRegMs != null) ctRegistrationDate.value = ctRegMs.toDate();
      } else {
        // Fallback: Try loading from company profile
        final profileDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (profileDoc.exists && profileDoc.data() != null) {
          final data = profileDoc.data()!;
          isCtRegistered.value = data['isCtRegistered'] as bool? ?? true;
          
          final startMs = data['financialYearStart'] as Timestamp?;
          final endMs = data['financialYearEnd'] as Timestamp?;
          
          if (startMs != null) financialYearStart.value = startMs.toDate();
          if (endMs != null) financialYearEnd.value = endMs.toDate();
        }
      }
      
      // Sync to local storage
      await _saveToLocalStorage();
    } catch (e) {
      debugPrint('⚠️ Failed to load tax settings from Firestore: $e');
      // Fallback to local storage
      await _loadFromLocalStorage();
    }
  }
  
  Future<void> _loadFromLocalStorage() async {
    final settings = await _storageService.loadTaxSettings();
    final notifSettings = await _storageService.loadNotificationSettings();
    
    vatRemindersEnabled.value = notifSettings['vatReminders'] as bool? ?? true;
    ctRemindersEnabled.value = notifSettings['ctReminders'] as bool? ?? true;
    ocrErrorsEnabled.value = notifSettings['ocrErrors'] as bool? ?? true;
    duplicateInvoiceAlertsEnabled.value = notifSettings['duplicateAlerts'] as bool? ?? true;
    monthlySummariesEnabled.value = notifSettings['monthlySummaries'] as bool? ?? false;
    
    final profile = await _storageService.loadCompanyProfile();
    isCtRegistered.value = profile['isVatRegistered'] as bool? ?? true;
    financialYearStart.value = profile['financialYearStart'] as DateTime? ?? DateTime(DateTime.now().year, 1, 1);
    financialYearEnd.value = profile['financialYearEnd'] as DateTime? ?? DateTime(DateTime.now().year, 12, 31);
  }
  
  Future<void> _saveToLocalStorage() async {
    await _storageService.saveNotificationSettings(
      vatReminders: vatRemindersEnabled.value,
      ctReminders: ctRemindersEnabled.value,
      ocrErrors: ocrErrorsEnabled.value,
      duplicateAlerts: duplicateInvoiceAlertsEnabled.value,
      monthlySummaries: monthlySummariesEnabled.value,
    );
    
    await _storageService.saveCompanyProfile(
      isVatRegistered: isCtRegistered.value,
      financialYearStart: financialYearStart.value,
      financialYearEnd: financialYearEnd.value,
    );
  }

  void setVatReminder(int days) async {
    selectedVatReminder.value = days;
    // Auto-save to local storage
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('user_tax_settings')
            .doc(user.uid)
            .set({
          'vatReminderDays': days,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('⚠️ Failed to save VAT reminder: $e');
      }
    }
  }

  void setCtReminder(int days) async {
    selectedCtReminder.value = days;
    // Auto-save to local storage
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('user_tax_settings')
            .doc(user.uid)
            .set({
          'ctReminderDays': days,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('⚠️ Failed to save CT reminder: $e');
      }
    }
  }

  // Helper to get VAT status
  Map<String, dynamic> get vatStatus {
    final days = nextVatFilingDate.difference(DateTime.now()).inDays;
    if (days < 0) {
      return {'text': 'status_overdue'.tr, 'color': const Color(0xFFE74C3C), 'bg': const Color(0xFFFADBD8)};
    } else if (days <= 14) {
      return {'text': 'status_due_soon'.tr, 'color': const Color(0xFFfbc02d), 'bg': const Color(0xFFffecb3)};
    } else {
      return {'text': 'status_active'.tr, 'color': const Color(0xFF2e7d32), 'bg': const Color(0xFFc8e6c9)};
    }
  }
  
  // Helper to get CT status
  Map<String, dynamic> get ctStatus {
    final days = nextCtPaymentDate.difference(DateTime.now()).inDays;
    if (days < 0) {
      return {'text': 'status_overdue'.tr, 'color': const Color(0xFFE74C3C), 'bg': const Color(0xFFFADBD8)};
    } else if (days <= 30) {
       return {'text': 'status_due_soon'.tr, 'color': const Color(0xFFfbc02d), 'bg': const Color(0xFFffecb3)};
    } else {
      return {'text': 'status_active'.tr, 'color': const Color(0xFF2e7d32), 'bg': const Color(0xFFc8e6c9)};
    }
  }

  String get vatDueText {
     final days = nextVatFilingDate.difference(DateTime.now()).inDays;
     if (days < 0) return 'status_overdue_by_days'.trParams({'days': days.abs().toString()});
     if (days == 0) return 'status_due_today'.tr;
     return 'status_due_in_days'.trParams({'days': days.toString()});
  }

  String get ctDueText {
     // CT might be "Planned" if far away
      final days = nextCtPaymentDate.difference(DateTime.now()).inDays;
      if (days > 60) return 'status_planned'.tr;
      return vatDueText.replaceFirst('Due', 'Due'); // Just reusing logic, essentially "Due in X days"
  }

  Future<void> saveSettings() async {
    final user = _auth.currentUser;
    if (user == null) {
      SnackbarService.to.showError(
        'title_error'.tr,
        'msg_must_login_save'.tr,
      );
      return;
    }
    
    try {
      // Save notification preferences to Firestore
      await _firestore
          .collection('user_notification_settings')
          .doc(user.uid)
          .set({
        'vatReminders': vatRemindersEnabled.value,
        'ctReminders': ctRemindersEnabled.value,
        'ocrErrors': ocrErrorsEnabled.value,
        'duplicateAlerts': duplicateInvoiceAlertsEnabled.value,
        'monthlySummaries': monthlySummariesEnabled.value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Save tax reminder settings to Firestore
      await _firestore
          .collection('user_tax_settings')
          .doc(user.uid)
          .set({
        'vatReminderDays': selectedVatReminder.value,
        'ctReminderDays': selectedCtReminder.value,
        'isCtRegistered': isCtRegistered.value,
        'financialYearStart': Timestamp.fromDate(financialYearStart.value),
        'financialYearEnd': Timestamp.fromDate(financialYearEnd.value),
        'ctRegistrationDate': Timestamp.fromDate(ctRegistrationDate.value),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Also update company profile with CT registration and financial year
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set({
        'isCtRegistered': isCtRegistered.value,
        'financialYearStart': Timestamp.fromDate(financialYearStart.value),
        'financialYearEnd': Timestamp.fromDate(financialYearEnd.value),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Save to local storage
      await _saveToLocalStorage();
      
      // Clear notification preferences cache
      _prefsService.clearCache();
      
      Get.back();
      SnackbarService.to.showSuccess(
        'title_success'.tr, 
        'msg_settings_saved'.tr,
      );
    } catch (e) {
      SnackbarService.to.showError(
        'title_error'.tr,
        'msg_failed_save_settings'.tr,
      );
    }
  }
  
  Future<void> resetToDefaults() async {
    final user = _auth.currentUser;
    if (user == null) {
      SnackbarService.to.showError(
        'title_error'.tr,
        'msg_must_login_reset'.tr,
      );
      return;
    }
    
    // Reset reactive values
    vatRemindersEnabled.value = true;
    ctRemindersEnabled.value = true;
    ocrErrorsEnabled.value = true;
    duplicateInvoiceAlertsEnabled.value = true;
    monthlySummariesEnabled.value = false;
    selectedVatReminder.value = 7;
    selectedCtReminder.value = 30;
    isCtRegistered.value = true;
    financialYearStart.value = DateTime(DateTime.now().year, 1, 1);
    financialYearEnd.value = DateTime(DateTime.now().year, 12, 31);
    ctRegistrationDate.value = DateTime(DateTime.now().year, 1, 1);
    
    // Save defaults
    await saveSettings();
  }

  Future<void> selectDate(Rx<DateTime> target) async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: target.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != target.value) {
      target.value = picked;
    }
  }
}
