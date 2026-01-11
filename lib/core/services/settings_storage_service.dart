import 'package:shared_preferences/shared_preferences.dart';

/// Service to handle persistent storage of all app settings
class SettingsStorageService {
  static const String _keyLanguage = 'settings_language';
  static const String _keyNotificationsEnabled = 'settings_notifications_enabled';
  
  // Notification settings keys
  static const String _keyVatReminders = 'notif_vat_reminders';
  static const String _keyCtReminders = 'notif_ct_reminders';
  static const String _keyOcrErrors = 'notif_ocr_errors';
  static const String _keyDuplicateAlerts = 'notif_duplicate_alerts';
  static const String _keyMonthlySummaries = 'notif_monthly_summaries';
  static const String _keyPushNotifications = 'notif_push';
  static const String _keyEmailUpdates = 'notif_email';
  static const String _keyInAppOnly = 'notif_in_app_only';
  static const String _keyQuietHoursEnabled = 'notif_quiet_hours_enabled';
  static const String _keyQuietHoursMode = 'notif_quiet_hours';
  
  // Security settings keys
  static const String _keyTwoFactorEnabled = 'security_two_factor';
  static const String _keyBiometricEnabled = 'security_biometric';
  static const String _keyScreenPrivacy = 'security_screen_privacy';
  static const String _keyAutoLockTime = 'security_auto_lock_time';
  static const String _keyAutoLockEnabled = 'security_auto_lock_enabled';
  
  // Tax settings keys
  static const String _keyDefaultVatRate = 'tax_default_vat_rate';
  static const String _keyDefaultCtRate = 'tax_default_ct_rate';
  static const String _keyFilingFrequency = 'tax_filing_frequency';
  static const String _keyFilingDate = 'tax_filing_date';
  
  // Company profile keys
  static const String _keyCompanyName = 'company_name';
  static const String _keyCompanyEmail = 'company_email';
  static const String _keyCompanyCountryCode = 'company_country_code';
  static const String _keyCompanyPhone = 'company_phone';
  static const String _keyCompanyTrn = 'company_trn';
  static const String _keyCompanyVatRegistered = 'company_vat_registered';
  static const String _keyCompanyVatFilingFrequency = 'company_vat_filing_frequency';
  static const String _keyCompanyTaxPeriod = 'company_tax_period';
  static const String _keyCompanyNatureOfBusiness = 'company_nature_of_business';
  static const String _keyCompanyCorporateTaxRegime = 'company_corporate_tax_regime';
  static const String _keyCompanyFinancialYearStart = 'company_financial_year_start';
  static const String _keyCompanyFinancialYearEnd = 'company_financial_year_end';

  // Language Settings
  Future<void> saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, languageCode);
  }

  Future<String?> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage);
  }

  // Notification Settings
  Future<void> saveNotificationSettings({
    bool? vatReminders,
    bool? ctReminders,
    bool? ocrErrors,
    bool? duplicateAlerts,
    bool? monthlySummaries,
    bool? pushNotifications,
    bool? emailUpdates,
    bool? inAppOnly,
    bool? quietHoursEnabled,
    String? quietHoursMode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (vatReminders != null) await prefs.setBool(_keyVatReminders, vatReminders);
    if (ctReminders != null) await prefs.setBool(_keyCtReminders, ctReminders);
    if (ocrErrors != null) await prefs.setBool(_keyOcrErrors, ocrErrors);
    if (duplicateAlerts != null) await prefs.setBool(_keyDuplicateAlerts, duplicateAlerts);
    if (monthlySummaries != null) await prefs.setBool(_keyMonthlySummaries, monthlySummaries);
    if (pushNotifications != null) await prefs.setBool(_keyPushNotifications, pushNotifications);
    if (emailUpdates != null) await prefs.setBool(_keyEmailUpdates, emailUpdates);
    if (inAppOnly != null) await prefs.setBool(_keyInAppOnly, inAppOnly);
    if (quietHoursEnabled != null) await prefs.setBool(_keyQuietHoursEnabled, quietHoursEnabled);
    if (quietHoursMode != null) await prefs.setString(_keyQuietHoursMode, quietHoursMode);
  }

  Future<Map<String, dynamic>> loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'vatReminders': prefs.getBool(_keyVatReminders) ?? true,
      'ctReminders': prefs.getBool(_keyCtReminders) ?? true,
      'ocrErrors': prefs.getBool(_keyOcrErrors) ?? true,
      'duplicateAlerts': prefs.getBool(_keyDuplicateAlerts) ?? true,
      'monthlySummaries': prefs.getBool(_keyMonthlySummaries) ?? false,
      'pushNotifications': prefs.getBool(_keyPushNotifications) ?? true,
      'emailUpdates': prefs.getBool(_keyEmailUpdates) ?? true,
      'inAppOnly': prefs.getBool(_keyInAppOnly) ?? false,
      'quietHoursEnabled': prefs.getBool(_keyQuietHoursEnabled) ?? false,
      'quietHoursMode': prefs.getString(_keyQuietHoursMode) ?? 'night',
    };
  }

  // Security Settings
  Future<void> saveSecuritySettings({
    bool? twoFactorEnabled,
    bool? biometricEnabled,
    bool? screenPrivacy,
    String? autoLockTime,
    bool? autoLockEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (twoFactorEnabled != null) await prefs.setBool(_keyTwoFactorEnabled, twoFactorEnabled);
    if (biometricEnabled != null) await prefs.setBool(_keyBiometricEnabled, biometricEnabled);
    if (screenPrivacy != null) await prefs.setBool(_keyScreenPrivacy, screenPrivacy);
    if (autoLockTime != null) await prefs.setString(_keyAutoLockTime, autoLockTime);
    if (autoLockEnabled != null) await prefs.setBool(_keyAutoLockEnabled, autoLockEnabled);
  }

  Future<Map<String, dynamic>> loadSecuritySettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'twoFactorEnabled': prefs.getBool(_keyTwoFactorEnabled) ?? true,
      'biometricEnabled': prefs.getBool(_keyBiometricEnabled) ?? false,
      'screenPrivacy': prefs.getBool(_keyScreenPrivacy) ?? true,
      'autoLockTime': prefs.getString(_keyAutoLockTime) ?? '3m',
      'autoLockEnabled': prefs.getBool(_keyAutoLockEnabled) ?? true,
    };
  }

  // Tax Settings
  Future<void> saveTaxSettings({
    double? defaultVatRate,
    double? defaultCtRate,
    String? filingFrequency,
    int? filingDate,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (defaultVatRate != null) await prefs.setDouble(_keyDefaultVatRate, defaultVatRate);
    if (defaultCtRate != null) await prefs.setDouble(_keyDefaultCtRate, defaultCtRate);
    if (filingFrequency != null) await prefs.setString(_keyFilingFrequency, filingFrequency);
    if (filingDate != null) await prefs.setInt(_keyFilingDate, filingDate);
  }

  Future<Map<String, dynamic>> loadTaxSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'defaultVatRate': prefs.getDouble(_keyDefaultVatRate) ?? 5.0,
      'defaultCtRate': prefs.getDouble(_keyDefaultCtRate) ?? 9.0,
      'filingFrequency': prefs.getString(_keyFilingFrequency) ?? 'monthly',
      'filingDate': prefs.getInt(_keyFilingDate) ?? 28,
    };
  }

  // Company Profile Settings
  Future<void> saveCompanyProfile({
    String? companyName,
    String? email,
    String? countryCode,
    String? phone,
    String? trn,
    bool? isVatRegistered,
    String? vatFilingFrequency,
    String? taxPeriod,
    String? natureOfBusiness,
    String? corporateTaxRegime,
    DateTime? financialYearStart,
    DateTime? financialYearEnd,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (companyName != null) await prefs.setString(_keyCompanyName, companyName);
    if (email != null) await prefs.setString(_keyCompanyEmail, email);
    if (countryCode != null) await prefs.setString(_keyCompanyCountryCode, countryCode);
    if (phone != null) await prefs.setString(_keyCompanyPhone, phone);
    if (trn != null) await prefs.setString(_keyCompanyTrn, trn);
    if (isVatRegistered != null) await prefs.setBool(_keyCompanyVatRegistered, isVatRegistered);
    if (vatFilingFrequency != null) await prefs.setString(_keyCompanyVatFilingFrequency, vatFilingFrequency);
    if (taxPeriod != null) await prefs.setString(_keyCompanyTaxPeriod, taxPeriod);
    if (natureOfBusiness != null) await prefs.setString(_keyCompanyNatureOfBusiness, natureOfBusiness);
    if (corporateTaxRegime != null) await prefs.setString(_keyCompanyCorporateTaxRegime, corporateTaxRegime);
    if (financialYearStart != null) await prefs.setInt(_keyCompanyFinancialYearStart, financialYearStart.millisecondsSinceEpoch);
    if (financialYearEnd != null) await prefs.setInt(_keyCompanyFinancialYearEnd, financialYearEnd.millisecondsSinceEpoch);
  }

  Future<Map<String, dynamic>> loadCompanyProfile() async {
    final prefs = await SharedPreferences.getInstance();
    
    final startMs = prefs.getInt(_keyCompanyFinancialYearStart);
    final endMs = prefs.getInt(_keyCompanyFinancialYearEnd);
    final currentYear = DateTime.now().year;
    
    return {
      'companyName': prefs.getString(_keyCompanyName) ?? 'FinEye Technologies LLC',
      'email': prefs.getString(_keyCompanyEmail) ?? 'finance@fineye.ae',
      'countryCode': prefs.getString(_keyCompanyCountryCode) ?? '+971',
      'phone': prefs.getString(_keyCompanyPhone) ?? '50 000 0000',
      'trn': prefs.getString(_keyCompanyTrn) ?? '',
      'isVatRegistered': prefs.getBool(_keyCompanyVatRegistered) ?? false,
      'vatFilingFrequency': prefs.getString(_keyCompanyVatFilingFrequency) ?? 'quarterly',
      'taxPeriod': prefs.getString(_keyCompanyTaxPeriod) ?? 'quarterly',
      'natureOfBusiness': prefs.getString(_keyCompanyNatureOfBusiness) ?? '',
      'corporateTaxRegime': prefs.getString(_keyCompanyCorporateTaxRegime) ?? 'standard_uae_9',
      // Default to 1 Jan – 31 Dec of the current year on first install
      'financialYearStart': startMs != null
          ? DateTime.fromMillisecondsSinceEpoch(startMs)
          : DateTime(currentYear, 1, 1),
      'financialYearEnd': endMs != null
          ? DateTime.fromMillisecondsSinceEpoch(endMs)
          : DateTime(currentYear, 12, 31),
    };
  }

  // Clear all settings (for logout)
  Future<void> clearAllSettings() async {
    final prefs = await SharedPreferences.getInstance();
    // Don't clear language preference on logout
    await prefs.remove(_keyNotificationsEnabled);
    await prefs.remove(_keyVatReminders);
    await prefs.remove(_keyCtReminders);
    await prefs.remove(_keyOcrErrors);
    await prefs.remove(_keyDuplicateAlerts);
    await prefs.remove(_keyMonthlySummaries);
    await prefs.remove(_keyPushNotifications);
    await prefs.remove(_keyEmailUpdates);
    await prefs.remove(_keyInAppOnly);
    await prefs.remove(_keyQuietHoursMode);
    await prefs.remove(_keyTwoFactorEnabled);
    await prefs.remove(_keyBiometricEnabled);
    await prefs.remove(_keyScreenPrivacy);
    await prefs.remove(_keyAutoLockTime);
    await prefs.remove(_keyDefaultVatRate);
    await prefs.remove(_keyDefaultCtRate);
    await prefs.remove(_keyFilingFrequency);
    await prefs.remove(_keyFilingDate);
    // Don't clear company profile on logout (it's business data)
  }
}



