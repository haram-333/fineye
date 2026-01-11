import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/snackbar_service.dart';
import '../../core/services/settings_storage_service.dart';
import '../../../data/services/auth_service.dart';

class CompanyProfileController extends GetxController {
  final _storageService = SettingsStorageService();
  final _authService = AuthService();
  
  // Text Controllers for Company Info
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController countryCodeController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  
  // Text Controllers for Tax Info
  final TextEditingController trnController = TextEditingController();
  
  // Reactive Variables for VAT Registration
  final RxBool isVatRegistered = false.obs;
  
  // Reactive Variables for Dropdowns & Dates
  final RxString vatFilingFrequency = 'quarterly'.obs;
  final RxString taxPeriod = 'quarterly'.obs;
  final RxString natureOfBusiness = ''.obs;
  final RxString corporateTaxRegime = 'standard_uae_9'.obs;
  
  // Default financial year: 1 Jan – 31 Dec of the CURRENT year at first install.
  // Once saved, the values are loaded from Firestore / local storage.
  final Rx<DateTime> financialYearStart =
      DateTime(DateTime.now().year, 1, 1).obs;
  final Rx<DateTime> financialYearEnd =
      DateTime(DateTime.now().year, 12, 31).obs;
  
  // Logic Variables
  final RxDouble completeness = 0.5.obs;
  final RxBool isTrnValid = false.obs;

  @override
  void onInit() {
    super.onInit();
    _loadProfile();
    // Listeners to update completeness
    companyNameController.addListener(() => _calculateCompleteness());
    emailController.addListener(() => _calculateCompleteness());
    countryCodeController.addListener(() => _calculateCompleteness());
    phoneController.addListener(() => _calculateCompleteness());
    trnController.addListener(() => _calculateCompleteness());
    
    // Listen to VAT registration changes
    ever(isVatRegistered, (_) => _calculateCompleteness());
    ever(taxPeriod, (_) => _calculateCompleteness());
    ever(natureOfBusiness, (_) => _calculateCompleteness());
    
    // Initial calculation
    _calculateCompleteness();
  }

  Future<void> _loadProfile() async {
    try {
      // First try to load from Firestore (production)
      final firestoreProfile = await _authService.getUserProfile();
      
      if (firestoreProfile != null && firestoreProfile.isNotEmpty) {
        // Load from Firestore
        companyNameController.text = firestoreProfile['companyName']?.toString() ?? '';
        emailController.text = firestoreProfile['email']?.toString() ?? '';
        countryCodeController.text = firestoreProfile['countryCode']?.toString() ?? '+971';
        phoneController.text = firestoreProfile['phone']?.toString() ?? '';
        trnController.text = firestoreProfile['trn']?.toString() ?? '';
        isVatRegistered.value = firestoreProfile['isVatRegistered'] as bool? ?? false;
        vatFilingFrequency.value = firestoreProfile['vatFilingFrequency']?.toString() ?? 'quarterly';
        taxPeriod.value = firestoreProfile['taxPeriod']?.toString() ?? 'quarterly';
        natureOfBusiness.value = firestoreProfile['natureOfBusiness']?.toString() ?? '';
        corporateTaxRegime.value = firestoreProfile['corporateTaxRegime']?.toString() ?? 'standard_uae_9';

        // If financial year was never set in Firestore, default to current year.
        final currentYear = DateTime.now().year;
        financialYearStart.value =
            firestoreProfile['financialYearStart'] as DateTime? ??
                DateTime(currentYear, 1, 1);
        financialYearEnd.value =
            firestoreProfile['financialYearEnd'] as DateTime? ??
                DateTime(currentYear, 12, 31);
        
        // Profile loaded from Firestore
      } else {
        // Fallback to SharedPreferences (for backward compatibility)
        final profile = await _storageService.loadCompanyProfile();
        
        companyNameController.text = profile['companyName'] as String;
        emailController.text = profile['email'] as String;
        countryCodeController.text = profile['countryCode'] as String;
        phoneController.text = profile['phone'] as String;
        trnController.text = profile['trn'] as String;
        isVatRegistered.value = profile['isVatRegistered'] as bool;
        vatFilingFrequency.value = profile['vatFilingFrequency'] as String;
        taxPeriod.value = profile['taxPeriod'] as String;
        natureOfBusiness.value = profile['natureOfBusiness'] as String;
        corporateTaxRegime.value = profile['corporateTaxRegime'] as String;
        financialYearStart.value = profile['financialYearStart'] as DateTime;
        financialYearEnd.value = profile['financialYearEnd'] as DateTime;
      }
    } catch (e) {
      // Error loading profile
      // Load defaults from SharedPreferences as last resort
      final profile = await _storageService.loadCompanyProfile();
      companyNameController.text = profile['companyName'] as String;
      emailController.text = profile['email'] as String;
      countryCodeController.text = profile['countryCode'] as String;
      phoneController.text = profile['phone'] as String;
      trnController.text = profile['trn'] as String;
      isVatRegistered.value = profile['isVatRegistered'] as bool;
      vatFilingFrequency.value = profile['vatFilingFrequency'] as String;
      taxPeriod.value = profile['taxPeriod'] as String;
      natureOfBusiness.value = profile['natureOfBusiness'] as String;
      corporateTaxRegime.value = profile['corporateTaxRegime'] as String;
      financialYearStart.value = profile['financialYearStart'] as DateTime;
      financialYearEnd.value = profile['financialYearEnd'] as DateTime;
    }
  }
  
  @override
  void onClose() {
    companyNameController.dispose();
    emailController.dispose();
    countryCodeController.dispose();
    phoneController.dispose();
    trnController.dispose();
    super.onClose();
  }

  void _calculateCompleteness() {
    // Calculate based on required fields
    int totalFields = 6; // company name, email, phone, VAT registration, tax period, financial year
    int completedFields = 0;
    
    // Company name (required)
    if (companyNameController.text.isNotEmpty) completedFields++;
    
    // Email (required)
    if (emailController.text.isNotEmpty) completedFields++;
    
    // Phone (required - both country code and number)
    if (countryCodeController.text.isNotEmpty && phoneController.text.isNotEmpty) completedFields++;
    
    completedFields++;
    
    // TRN (required only if VAT registered)
    if (isVatRegistered.value) {
      totalFields++;
      if (trnController.text.isNotEmpty) completedFields++;
    }
    
    // Tax period (required)
    if (taxPeriod.value.isNotEmpty) completedFields++;
    
    completedFields++;
    
    // Calculate percentage
    completeness.value = totalFields > 0 ? (completedFields / totalFields) : 0.0;
  }

  /// Check if company setup is complete (all required fields filled)
  bool isCompanySetupComplete() {
    // Company name, email, phone must be filled
    if (companyNameController.text.isEmpty) return false;
    if (emailController.text.isEmpty) return false;
    if (countryCodeController.text.isEmpty || phoneController.text.isEmpty) return false;
    
    if (taxPeriod.value.isEmpty) return false;
    
    if (isVatRegistered.value && trnController.text.isEmpty) return false;
    
    // if (financialYearEnd.value == null) return false;
    
    return true;
  }

  Future<void> verifyTrnOnFta() async {
    final Uri url = Uri.parse('https://eservices.tax.gov.ae/en-us/trn-verification');
    if (!await launchUrl(url)) {
      SnackbarService.to.showError(
        'title_error'.tr, 
        'msg_fta_verification_error'.tr,
      );
    }
  }

  Future<void> saveProfile() async {
    // Validate required fields
    if (companyNameController.text.isEmpty) {
      SnackbarService.to.showError(
        'title_error'.tr, 
        'field_required'.tr,
      );
      return;
    }
    
    // If VAT registered, TRN is required
    if (isVatRegistered.value && trnController.text.isEmpty) {
      SnackbarService.to.showError(
        'title_error'.tr, 
        'missing_fields'.tr,
      );
      return;
    }

    // Validate email format
    if (emailController.text.isNotEmpty && !GetUtils.isEmail(emailController.text)) {
      SnackbarService.to.showError(
        'title_error'.tr,
        'email_error_invalid'.tr,
      );
      return;
    }

    try {
      // Save to Firestore (production database)
      final result = await _authService.updateUserProfile(
        companyName: companyNameController.text.trim(),
        email: emailController.text.trim(),
        countryCode: countryCodeController.text.trim(),
        phone: phoneController.text.trim(),
        trn: trnController.text.trim(),
        isVatRegistered: isVatRegistered.value,
        vatFilingFrequency: vatFilingFrequency.value,
        taxPeriod: taxPeriod.value,
        natureOfBusiness: natureOfBusiness.value,
        corporateTaxRegime: corporateTaxRegime.value,
        financialYearStart: financialYearStart.value,
        financialYearEnd: financialYearEnd.value,
      );

      if (result['success'] == true) {
        // Also save to SharedPreferences for offline access/backup
        await _storageService.saveCompanyProfile(
          companyName: companyNameController.text.trim(),
          email: emailController.text.trim(),
          countryCode: countryCodeController.text.trim(),
          phone: phoneController.text.trim(),
          trn: trnController.text.trim(),
          isVatRegistered: isVatRegistered.value,
          vatFilingFrequency: vatFilingFrequency.value,
          taxPeriod: taxPeriod.value,
          natureOfBusiness: natureOfBusiness.value,
          corporateTaxRegime: corporateTaxRegime.value,
          financialYearStart: financialYearStart.value,
          financialYearEnd: financialYearEnd.value,
        );

        Get.back();
        SnackbarService.to.showSuccess(
          'title_success'.tr, 
          result['message'] ?? 'msg_profile_saved'.tr,
        );
      } else {
        SnackbarService.to.showError(
          'title_error'.tr,
          result['error'] ?? 'Failed to save profile. Please try again.',
        );
      }
    } catch (e) {
      // Error saving profile
      SnackbarService.to.showError(
        'title_error'.tr,
        'An unexpected error occurred. Please try again.',
      );
    }
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
      _calculateCompleteness();
    }
  }
}
