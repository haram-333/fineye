import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../controllers/settings_controller.dart';

class CompanyProfile extends StatelessWidget {
  const CompanyProfile({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text('profile_info'.tr)));
}

class TaxSettings extends StatelessWidget {
  const TaxSettings({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text('tax_settings'.tr)));
}

class DataPrivacy extends StatelessWidget {
  const DataPrivacy({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text('privacy_title'.tr)));
}

class HelpSupport extends StatelessWidget {
  const HelpSupport({super.key});
  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: AppBar(title: Text('help_title'.tr)));
}

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SettingsController>()) {
      Get.put(SettingsController());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('account_section'.tr),
                  _buildSectionCard([
                    _buildSettingsItem(
                      icon: Icons.person_outline,
                      title: 'profile_info'.tr,
                      subtitle: 'profile_desc'.tr,
                      onTap: () => Get.toNamed(AppRoutes.companyProfile),
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.lock_outline,
                      title: 'security'.tr,
                      subtitle: 'security_desc'.tr,
                      onTap: () => Get.toNamed(AppRoutes.security),
                    ),
                  ]),

                  _buildSectionHeader('preferences_section'.tr),
                  _buildSectionCard([
                    _buildLanguageItem(),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.notifications_outlined,
                      title: 'notifications'.tr,
                      subtitle: 'notifications_desc'.tr,
                      trailing: Text(
                        'configured'.tr,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      onTap: () => Get.toNamed(AppRoutes.notificationSettings),
                    ),
                  ]),

                  _buildSectionHeader('tax_section'.tr),
                  _buildSectionCard([
                    _buildSettingsItem(
                      icon: Icons.receipt_long_outlined,
                      title: 'tax_settings'.tr,
                      subtitle: 'tax_settings_desc'.tr,
                      onTap: () => Get.toNamed(AppRoutes.taxSettings),
                    ),
                  ]),

                  _buildSectionHeader('privacy_section'.tr),
                  _buildSectionCard([
                    _buildSettingsItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'privacy_title'.tr,
                      subtitle: 'privacy_desc'.tr,
                      onTap: () => Get.toNamed(AppRoutes.dataPrivacy),
                    ),
                  ]),

                  _buildSectionHeader('help_section'.tr),
                  _buildSectionCard([
                    _buildSettingsItem(
                      icon: Icons.help_outline,
                      title: 'help_title'.tr,
                      subtitle: 'help_desc'.tr,
                      onTap: () => Get.toNamed(AppRoutes.helpSupport),
                    ),
                  ]),

                  _buildSectionHeader('about_section'.tr),
                  _buildSectionCard([
                    _buildSettingsItem(
                      icon: Icons.info_outline,
                      title: 'about_title'.tr,
                      subtitle: 'about_desc'.tr,
                      onTap: () => Get.toNamed(AppRoutes.about),
                    ),
                  ]),

                  const SizedBox(height: 32),

                  // Logout Button
                  _buildLogoutButton(),

                  const SizedBox(height: 100), // Bottom padding
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: false,
      backgroundColor: const Color(0xFFF7F9FC).withValues(alpha: 0.9),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
      titleSpacing: 20,
      automaticallyImplyLeading: false,
      toolbarHeight: 90,
      title: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Image.asset(
                'assets/logo/fineye_logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'settings_title'.tr,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    'settings_subtitle'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.mutedText,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.mutedText,
        ),
      ),
    );
  }

  Widget _buildSectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: Color(0xFFF0F2F5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primaryBlue, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      subtitle:
          subtitle != null
              ? Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              )
              : null,
      trailing: trailing,
    );
  }

  Widget _buildLanguageItem() {
    return Obx(() {
      final isArabic = controller.isArabic.value;
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFF0F2F5),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.language,
            color: AppColors.primaryBlue,
            size: 20,
          ),
        ),
        title: Text(
          'language'.tr,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        subtitle: Text(
          'language_subtitle'.tr,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        trailing: Container(
          height: 32,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: const Color(0xFFEAECF0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToggleOption(
                text: 'EN',
                isSelected: !isArabic,
                onTap: () => controller.toggleLanguage(false),
              ),
              _buildToggleOption(
                text: 'AR',
                isSelected: isArabic,
                onTap: () => controller.toggleLanguage(true),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildToggleOption({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.withValues(alpha: 0.1),
      indent: 60, // Indent to align with text, bypassing icon
      endIndent: 0,
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: () => controller.logout(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFFFEBEE),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.logout, color: Colors.red, size: 20),
        ),
        title: Text(
          'btn_logout'.tr,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        subtitle: Text(
          'logout_subtitle'.tr,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ),
    );
  }
}
