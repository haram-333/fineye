import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../controllers/auth_controller.dart';

import 'login_view.dart';
import 'register_view.dart';

class AuthView extends GetView<AuthController> {
  const AuthView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is registered (fallback in case binding doesn't work)
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController(), permanent: false);
    }
    // Don't auto-clear fields - let user keep their input
    
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    // Create a ScrollController for the NestedScrollView
    final scrollController = ScrollController();
    
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.white,
          body: DefaultTabController(
            length: 2,
            child: PrimaryScrollController(
              controller: scrollController,
            child: NestedScrollView(
                controller: scrollController,
              headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  // Pinned AppBar (Logo + App Name)
                  SliverAppBar(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    pinned: false,
                    floating: true,
                    toolbarHeight: 64,
                    titleSpacing: 16,
                    title: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: AppColors.lightWhite,
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            AppStrings.appIconPath,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          AppStrings.appName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Scrollable Header Content (Welcome Text)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            '${'welcome_to'.tr} ${AppStrings.appName}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'auth_subtitle'.tr,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.mutedText,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
    
                  // Pinned Tab Bar
                  SliverPersistentHeader(
                    pinned: false,
                    floating: true,
                    delegate: _SliverAppBarDelegate(
                      Container(
                        color: Colors.white, // Ensure background is white behind the tabs
                        padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 2.0), // Add padding here
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.lightWhite,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: TabBar(
                            indicator: BoxDecoration(
                              color: AppColors.primaryBlue,
                              borderRadius: BorderRadius.circular(28),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            splashFactory: NoSplash.splashFactory,
                            overlayColor: WidgetStateProperty.all(Colors.transparent),
                            labelColor: Colors.white,
                            unselectedLabelColor: AppColors.mutedText,
                            labelStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            unselectedLabelStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            dividerColor: Colors.transparent,
                            tabs: [
                              Tab(text: 'login_tab'.tr),
                              Tab(text: 'register_tab'.tr),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: const TabBarView(
                  children: [
                    LoginView(),
                    RegisterView(),
                  ],
                ),
                ),
            ),
          ),
        ),
        
        // Splash Screen Overlay (For Slide Transition) - Responsive Version
        Obx(() {
          if (!controller.showSplashOverlay.value) return const SizedBox.shrink();
          
          // Responsive sizing with clamp constraints (matching splash_view.dart)
          final logoContainerWidth = isLandscape 
              ? (screenWidth * 0.25).clamp(120.0, 180.0)
              : (screenWidth * 0.42).clamp(120.0, 200.0);
          final logoImageWidth = logoContainerWidth * 0.95;
          final logoImageHeight = logoContainerWidth * 1.07;
          final logoBorderRadius = (screenWidth * 0.04).clamp(12.0, 20.0);
          
          // Font sizes with clamp constraints
          final headlineFontSize = (screenWidth * 0.048).clamp(16.0, 24.0);
          final subheadlineFontSize = (screenWidth * 0.038).clamp(12.0, 18.0);
          final copyrightFontSize = (screenWidth * 0.035).clamp(10.0, 14.0);
          
          // Responsive spacing
          final spacingSmall = (screenHeight * 0.01).clamp(6.0, 10.0);
          
          // Responsive shadows
          final shadowOffsetY = (screenHeight * 0.003).clamp(1.0, 4.0);
          final shadowBlurRadius = (screenWidth * 0.03).clamp(8.0, 20.0);
          final shadowBlurRadiusLarge = (screenWidth * 0.05).clamp(12.0, 24.0);
          
          return AnimatedSlide(
            offset: Offset(controller.splashOffset.value, 0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0xFF1a1a2e), // Match SplashView scaffold background
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/logo/bg_sp_sc.jpg'),
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      onError: (exception, stackTrace) {
                        debugPrint('Error loading splash background: $exception');
                      },
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF0A1929).withValues(alpha: 0.91),
                          const Color(0xFF1E3A8A).withValues(alpha: 0.89),
                          const Color(0xFF1E40AF).withValues(alpha: 0.88),
                          const Color(0xFF2563EB).withValues(alpha: 0.89),
                          const Color(0xFF1E3A8A).withValues(alpha: 0.90),
                        ],
                        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        children: [
                          // Top spacing - responsive to orientation
                          SizedBox(height: isLandscape ? screenHeight * 0.05 : screenHeight * 0.10),
                          
                          // Logo
                          Container(
                            width: logoContainerWidth,
                            padding: EdgeInsets.symmetric(
                              horizontal: logoContainerWidth * 0.043,
                              vertical: screenHeight * 0.019,
                            ),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 252, 251, 251),
                              borderRadius: BorderRadius.circular(logoBorderRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: shadowBlurRadiusLarge,
                                  spreadRadius: (screenWidth * 0.02).clamp(2.0, 6.0),
                                  offset: Offset(-(screenWidth * 0.03).clamp(-8.0, -4.0), 0),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: shadowBlurRadiusLarge,
                                  spreadRadius: (screenWidth * 0.02).clamp(2.0, 6.0),
                                  offset: Offset((screenWidth * 0.03).clamp(4.0, 8.0), 0),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: shadowBlurRadiusLarge,
                                  offset: Offset(0, shadowOffsetY * 3),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: logoImageWidth,
                                  height: logoImageHeight,
                                  child: Image.asset(
                                    'assets/logo/fineye_logo.png',
                                    fit: BoxFit.contain,
                                    alignment: Alignment.center,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.image,
                                        color: Colors.grey,
                                        size: logoImageWidth * 0.3,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.04),
                          
                          // Tagline Text
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                            child: Column(
                              children: [
                                // Headline - responsive with clamp
                                Text(
                                  'splash_headline'.tr,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: headlineFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    height: 1.3,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, shadowOffsetY),
                                        blurRadius: shadowBlurRadius,
                                        color: Colors.black.withValues(alpha: 0.5),
                                      ),
                                      Shadow(
                                        offset: Offset(0, shadowOffsetY * 2),
                                        blurRadius: shadowBlurRadiusLarge,
                                        color: Colors.black.withValues(alpha: 0.3),
                                      ),
                                      Shadow(
                                        offset: Offset(0, shadowOffsetY * 0.5),
                                        blurRadius: shadowBlurRadius * 0.33,
                                        color: Colors.black.withValues(alpha: 0.6),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: spacingSmall),
                                
                                // Subheadline - responsive with clamp
                                Text(
                                  'splash_subheadline'.tr,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: subheadlineFontSize,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.95),
                                    height: 1.5,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, shadowOffsetY * 0.5),
                                        blurRadius: shadowBlurRadius * 0.67,
                                        color: Colors.black.withValues(alpha: 0.4),
                                      ),
                                      Shadow(
                                        offset: Offset(0, shadowOffsetY),
                                        blurRadius: shadowBlurRadius,
                                        color: Colors.black.withValues(alpha: 0.25),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const Spacer(),
                          
                          // Copyright Text at bottom
                          Padding(
                            padding: EdgeInsets.only(bottom: screenHeight * 0.037),
                            child: Text(
                              '© 2025 FinEye Technologies',
                              style: TextStyle(
                                fontSize: copyrightFontSize,
                                color: Colors.white.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget _child;

  _SliverAppBarDelegate(this._child);

  @override
  double get minExtent => 42.0 + 10.0; // Height (42) + vertical padding (8 top + 2 bottom)
  @override
  double get maxExtent => 42.0 + 10.0;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return _child; // The child already contains the Container and Padding
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
