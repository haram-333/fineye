import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'firebase_options.dart';
import 'core/services/fcm_service.dart' show FCMService, firebaseMessagingBackgroundHandler;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/screen_privacy_service.dart';
import 'core/services/auto_lock_service.dart';
import 'core/services/settings_storage_service.dart';
// TEMPORARY: Remove after seeding data
// import 'data/helpers/seed_invoice_data.dart';
import 'core/constants/app_routes.dart';
import 'presentation/views/about/about_view.dart';
import 'presentation/controllers/about_controller.dart';
import 'data/repositories/app_info_repository.dart';
import 'presentation/views/splash/splash_view.dart';
import 'presentation/controllers/splash_controller.dart';
import 'presentation/views/auth/auth_view.dart';
import 'presentation/views/main/main_view.dart';
import 'presentation/controllers/status_bar_controller.dart';
import 'core/services/snackbar_service.dart';
import 'presentation/views/invoices/invoice_details_view.dart';
import 'presentation/controllers/invoice_details_controller.dart';
import 'presentation/views/invoices/invoice_filters_view.dart';
import 'presentation/controllers/invoice_filters_controller.dart';
import 'presentation/views/security/security_view.dart';
import 'presentation/controllers/security_controller.dart';
import 'presentation/views/notification_settings/notification_settings_view.dart';
import 'presentation/controllers/change_password_controller.dart';
import 'presentation/views/change_password/change_password_view.dart';
import 'presentation/controllers/notification_settings_controller.dart';
import 'presentation/views/auth/forgot_password_view.dart';
import 'presentation/controllers/forgot_password_controller.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/views/auth/reset_password_view.dart';
import 'presentation/controllers/reset_password_controller.dart';

import 'package:flutter/services.dart';
import 'presentation/views/ocr_tips/ocr_tips_view.dart';
import 'presentation/views/invoices/ocr_preview_view.dart';
import 'presentation/controllers/ocr_preview_controller.dart';
import 'presentation/views/help_support/help_support_view.dart';
import 'presentation/views/legal/privacy_view.dart';
import 'presentation/views/legal/terms_view.dart';
import 'presentation/views/data_privacy/data_privacy_view.dart';
import 'presentation/views/tax_settings/tax_settings_view.dart';
import 'presentation/views/company_profile/company_profile_view.dart';
import 'presentation/controllers/tax_settings_controller.dart';
import 'core/constants/app_colors.dart';
import 'core/translations/messages.dart';
import 'domain/services/compliance_status_service.dart';
import 'presentation/controllers/main_controller.dart';
import 'presentation/controllers/dashboard_controller.dart';
import 'presentation/controllers/invoice_list_controller.dart';
import 'presentation/controllers/upload_invoice_controller.dart';
import 'presentation/controllers/notifications_controller.dart';
import 'presentation/controllers/settings_controller.dart';
import 'presentation/controllers/company_profile_controller.dart';
import 'presentation/views/upload/image_preprocessing_view.dart';
import 'presentation/controllers/image_preprocessing_controller.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Register background message handler (must be called before runApp)
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    }
    
    // Initialize Firebase Cloud Messaging (only on mobile, not web)
    if (!kIsWeb) {
      try {
        await FCMService.instance.initialize();
        debugPrint('✅ FCM Service initialized');
      } catch (e) {
        debugPrint('⚠️ FCM initialization failed: $e');
      }
      
      // Initialize screen privacy
      try {
        final settingsService = SettingsStorageService();
        final securitySettings = await settingsService.loadSecuritySettings();
        final screenPrivacyEnabled = securitySettings['screenPrivacy'] as bool? ?? true;
        
        if (screenPrivacyEnabled) {
          await ScreenPrivacyService.enable();
          debugPrint('✅ Screen privacy enabled');
        }
      } catch (e) {
        debugPrint('⚠️ Screen privacy initialization failed: $e');
      }
      
      // Initialize auto-lock service
      try {
        await AutoLockService.instance.initialize();
        debugPrint('✅ Auto-lock service initialized');
      } catch (e) {
        debugPrint('⚠️ Auto-lock initialization failed: $e');
      }
    }
    
    // TEMPORARY: Seed sample invoice data (run once, then comment again)
    // debugPrint('Starting to seed sample invoices...');
    // final success = await seedSampleInvoices();
    // if (success) {
    //   debugPrint('✅ Sample invoices seeded successfully!');
    // } else {
    //   debugPrint('❌ Failed to seed sample invoices');
    // }
  } catch (e, stackTrace) {
    debugPrint('Firebase initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
  }
  
  try {
    await initializeDateFormatting('ar', null);
  } catch (e) {
    debugPrint('Date formatting initialization error: $e');
  }
  
  // SystemChrome is not needed on web
  if (!kIsWeb) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: AppColors.primaryBlue,
      statusBarIconBrightness: Brightness.light,
    ));
  }
  
  // Set up error handlers
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
    // Also log to console for web debugging
    if (kIsWeb) {
      print('FlutterError: ${details.exception}');
      print('Stack: ${details.stack}');
    }
  };
  
  // Set up error widget builder to show errors instead of white screen
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('ErrorWidget.builder called: ${details.exception}');
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              const Text(
                'An error occurred',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                details.exception.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  };
  
  // Wrap in zone to catch all errors
  runZonedGuarded(() {
    runApp(const MyApp());
  }, (error, stack) {
    debugPrint('Zone error: $error');
    debugPrint('Stack: $stack');
    if (kIsWeb) {
      print('Zone error: $error');
      print('Stack: $stack');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      translations: Messages(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      debugShowCheckedModeBanner: false,
      title: 'FinEye',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child ?? const SizedBox(),
        );
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF002060)), // Primary Blue from AppColors
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: AppColors.primaryBlue,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark, // For iOS
          ),
        ),
        useMaterial3: true,
      ),
      initialRoute: AppRoutes.splash,
      initialBinding: BindingsBuilder(() {
        Get.put(StatusBarController());
        Get.put(ComplianceStatusService()); // Register compliance service globally
        Get.put(SnackbarService()); // Register snackbar service globally
      }),
      getPages: [
        GetPage(
          name: AppRoutes.about,
          page: () => const AboutView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<AppInfoRepository>(() => AppInfoRepository());
            Get.lazyPut<AboutController>(
              () => AboutController(Get.find<AppInfoRepository>()),
            );
          }),
        ),
        GetPage(
          name: AppRoutes.ocrTips,
          page: () => const OCRTipsView(),
        ),
        GetPage(
          name: AppRoutes.helpSupport,
          page: () => const HelpSupportView(),
        ),
        GetPage(
          name: AppRoutes.privacyPolicy,
          page: () => const PrivacyPolicyView(),
        ),
        GetPage(
          name: AppRoutes.termsConditions,
          page: () => const TermsConditionsView(),
        ),
        GetPage(
          name: AppRoutes.dataPrivacy,
          page: () => const DataPrivacyView(),
        ),
        GetPage(
          name: AppRoutes.taxSettings,
          page: () => const TaxSettingsView(),
          binding: BindingsBuilder(() {
            Get.put(TaxSettingsController());
          }),
        ),
        GetPage(
          name: AppRoutes.companyProfile,
          page: () => const CompanyProfileView(),
        ),
        GetPage(
          name: AppRoutes.splash,
          page: () => const SplashView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<SplashController>(() => SplashController());
          }),
        ),
        GetPage(
          name: AppRoutes.auth,
          page: () => const AuthView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
          }),
        ),
      GetPage(
          name: AppRoutes.main,
          page: () => const MainView(),
          binding: BindingsBuilder(() {
            // Register all controllers needed for the main view and its tabs
            Get.lazyPut(() => MainController());
            Get.lazyPut(() => DashboardController());
            Get.lazyPut(() => InvoiceListController());
            Get.lazyPut(() => UploadInvoiceController());
            Get.lazyPut(() => NotificationsController());
            Get.lazyPut(() => SettingsController());
            Get.lazyPut(() => CompanyProfileController());
          }),
        ),
        GetPage(
          name: AppRoutes.invoiceDetails,
          page: () => const InvoiceDetailsView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<InvoiceDetailsController>(() => InvoiceDetailsController());
          }),
        ),
        GetPage(
          name: AppRoutes.invoiceFilters,
          page: () => const InvoiceFiltersView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<InvoiceFiltersController>(() => InvoiceFiltersController());
          }),
        ),
        GetPage(
          name: AppRoutes.security,
          page: () => const SecurityView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<SecurityController>(() => SecurityController());
          }),
        ),
        GetPage(
          name: AppRoutes.notificationSettings,
          page: () => const NotificationSettingsView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<NotificationSettingsController>(() => NotificationSettingsController());
          }),
        ),
        GetPage(
          name: AppRoutes.changePassword,
          page: () => const ChangePasswordView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<ChangePasswordController>(() => ChangePasswordController());
          }),
        ),
        GetPage(
          name: AppRoutes.forgotPassword,
          page: () => const ForgotPasswordView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<ForgotPasswordController>(() => ForgotPasswordController());
          }),
        ),
        GetPage(
          name: AppRoutes.resetPassword,
          page: () => const ResetPasswordView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<ResetPasswordController>(() => ResetPasswordController());
          }),
        ),
        GetPage(
          name: AppRoutes.imagePreprocessing,
          page: () => const ImagePreprocessingView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<ImagePreprocessingController>(() => ImagePreprocessingController());
          }),
        ),
        GetPage(
          name: AppRoutes.ocrPreview,
          page: () => const OCRPreviewView(),
          binding: BindingsBuilder(() {
            Get.lazyPut<OCRPreviewController>(() => OCRPreviewController());
          }),
        ),
      ],
    );
  }
}
