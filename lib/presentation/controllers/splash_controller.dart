import 'package:get/get.dart';
import 'package:flutter/material.dart'; // Needed for Locale
import 'package:shared_preferences/shared_preferences.dart';
import 'status_bar_controller.dart';
import '../../core/constants/app_routes.dart';
import '../../../data/services/auth_service.dart';

class SplashController extends GetxController {

  // State for Language Panel
  final RxBool showLanguagePanel = false.obs;
  final RxString tempLanguageSelection = ''.obs; // '' means none, 'en', 'ar'
  final RxBool isLoading = true.obs;

  final AuthService _authService = AuthService();

  @override
  void onInit() {
    super.onInit();
    // Set status bar to transparent
    Get.find<StatusBarController>().setTransparent();
    
    // Check storage for language preference
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSelected = prefs.getBool('hasSelectedLanguage') ?? false;
    final storedLang = prefs.getString('selectedLanguageCode');

    // Always show language selection on first run
    // If user has already selected, they can skip by selecting again
    if (hasSelected && storedLang != null) {
      // User has already selected a language.
      // Apply it just in case main.dart didn't (though main usually sets initial, updates here are safe)
      if (storedLang == 'ar') {
        Get.updateLocale(const Locale('ar', 'AE'));
      } else {
        Get.updateLocale(const Locale('en', 'US'));
      }
      
      // Proceed with normal splash timer
      _navigateToNext();
    } else {
      // First run (or data cleared)
      // Show language panel and DO NOT start timer
      isLoading.value = false;
      showLanguagePanel.value = true;
    }
  }

  void selectLanguage(String code) {
    tempLanguageSelection.value = code;
    
    // Update locale immediately for preview
    if (code == 'ar') {
      Get.updateLocale(const Locale('ar', 'AE'));
    } else {
      Get.updateLocale(const Locale('en', 'US'));
    }
  }

  Future<void> confirmLanguage() async {
    if (tempLanguageSelection.value.isEmpty) return;

    final code = tempLanguageSelection.value;
    
    // 1. Save to storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSelectedLanguage', true);
    await prefs.setString('selectedLanguageCode', code);

    // 2. Locale is already updated by selectLanguage, but we confirm here just in case
    // (Optimization: can be skipped if certain, but harmless to keep)

    // 3. Dismiss panel
    showLanguagePanel.value = false;

    // 4. Navigate
    await Future.delayed(const Duration(milliseconds: 300));
    Get.offNamed(AppRoutes.auth, arguments: true);
  }

  void _navigateToNext() async {
    // Professional wait time: 2.5 seconds (2500 ms)
    await Future.delayed(const Duration(milliseconds: 2500));

    // If a Firebase user is already signed in, skip auth and go straight
    // to the main application. Otherwise, show the auth screen.
    final user = _authService.currentUser;
    if (user != null) {
      Get.offNamed(AppRoutes.main);
    } else {
      Get.offNamed(AppRoutes.auth, arguments: true);
    }
  }
}
