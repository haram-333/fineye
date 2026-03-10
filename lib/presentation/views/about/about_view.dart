import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../controllers/about_controller.dart';

class AboutView extends GetView<AboutController> {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    // --- Custom card/section + bullet widgets for about ---
    // SectionCard
    Widget sectionWrap({required Widget child}) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );

    // Section card widget
    Widget sectionCard({required String title, required List<Widget> children}) {
      return sectionWrap(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      );
    }

    // Bullet text widget
    Widget bulletText({required String text, Color? color, TextStyle? style}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• ', style: TextStyle(color: color ?? AppColors.primaryBlue, fontSize: style?.fontSize ?? 15)),
            Expanded(child: Text(text, style: style ?? TextStyle(fontSize: 15, color: AppColors.ink))),
          ],
        ),
      );
    }

    // Section divider
    Widget sectionDivider() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Divider(
        color: AppColors.borderGrey,
        thickness: 1,
        height: 2,
      ),
    );
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        toolbarHeight: 90,
        title: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: Obx(() {
            final info = controller.appInfo.value;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'about_page_title'.tr,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  'about_page_subtitle'.tr,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedText,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            );
          }),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  controller.error.value!,
                  style: const TextStyle(color: AppColors.destructiveRed),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.loadData,
                  child: Text('retry'.tr),
                ),
              ],
            ),
          );
        }

        final appInfo = controller.appInfo.value;
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // App icon
                      Center(
                        child: Container(
                          width: 120,
                          height: 120,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primaryBlue,
                              width: 2,
                            ),
                          ),
                          child: Image.asset(
                            appInfo?.appIconPath ?? AppStrings.appIconPath,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.apps,
                                color: AppColors.primaryBlue,
                                size: 60,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // App name
                      Center(
                        child: Text(
                          appInfo?.appName ?? AppStrings.appName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Version information
                      Center(
                        child: Column(
                          children: [
                            Text(
                              appInfo?.versionDisplay ?? 'Version N/A',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              appInfo?.buildDisplay ?? 'Build N/A',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Section: App Information
                      sectionCard(
                        title: 'about_app_info_title'.tr,
                        children: [
                          Text('about_app_info_what'.tr, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: AppColors.ink)),
                          const SizedBox(height: 8),
                          Text('about_app_info_desc'.tr, style: TextStyle(fontSize: 14, color: AppColors.ink)),
                        ],
                      ),

                      sectionDivider(),

                      // Section: What does FinEye do?
                      sectionCard(
                        title: 'about_what_does_title'.tr,
                        children: [
                          ...['about_what_does_bullet_1','about_what_does_bullet_2','about_what_does_bullet_3','about_what_does_bullet_4','about_what_does_bullet_5'].map((key) => bulletText(text: key.tr)),
                          const SizedBox(height: 12),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: "${'about_what_does_question_pre'.tr}\n", style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.ink)),
                                TextSpan(text: 'about_what_does_question'.tr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryBlue)),
                              ],
                            ),
                          ),
                        ],
                      ),

                      sectionDivider(),

                      // Section: What FinEye does NOT do
                      sectionCard(
                        title: 'about_what_not_title'.tr,
                        children: [
                          ...['about_what_not_bullet_1','about_what_not_bullet_2','about_what_not_bullet_3','about_what_not_bullet_4'].map((key) => bulletText(text: key.tr, color: AppColors.mutedText, style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic))),
                        ],
                      ),

                      sectionDivider(),

                      // Section: Legal Disclaimer
                      sectionCard(
                        title: 'about_legal_disclaimer_title'.tr,
                        children: [
                          ...['about_legal_bullet_1','about_legal_bullet_2','about_legal_bullet_3'].map((key) => bulletText(text: key.tr)),
                          const SizedBox(height: 10),
                          Text('about_legal_desc'.tr, style: TextStyle(fontSize: 13, color: AppColors.mutedText, fontStyle: FontStyle.italic)),
                        ],
                      ),

                      sectionDivider(),

                      // Section: Geographic Scope
                      sectionCard(
                        title: 'about_geo_scope_title'.tr,
                        children: [
                          Text('about_geo_scope_desc'.tr, style: TextStyle(fontSize: 14, color: AppColors.ink)),
                        ],
                      ),

                      sectionDivider(),

                      // Section: Our Vision
                      sectionCard(
                        title: 'about_vision_title'.tr,
                        children: [
                          Text('about_vision_desc'.tr, style: TextStyle(fontSize: 15, color: AppColors.ink)),
                        ],
                      ),

                      sectionDivider(),

                      // Section: Developer Information
                      sectionCard(
                        title: 'about_dev_title'.tr,
                        children: [
                          Text('about_dev_company'.tr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.ink)),
                          const SizedBox(height: 5),
                          Text('about_dev_location'.tr, style: TextStyle(fontSize: 13, color: AppColors.mutedText)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _launchEmail('about_dev_email'.tr),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.email, color: AppColors.primaryBlue, size: 18),
                                const SizedBox(width: 5),
                                Text('about_dev_email'.tr, style: TextStyle(color: AppColors.primaryBlue, fontSize: 14, decoration: TextDecoration.underline)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _launchWebsite('about_dev_website_link'.tr),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.language, color: AppColors.primaryBlue, size: 18),
                                const SizedBox(width: 5),
                                Text('about_dev_website'.tr, style: TextStyle(color: AppColors.primaryBlue, fontSize: 14, decoration: TextDecoration.underline)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text('about_version'.tr, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                          Text('about_copyright'.tr, style: const TextStyle(fontSize: 12, color: AppColors.mutedText)),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  appInfo?.copyrightText() ??
                      '© 2025 ${AppStrings.appName}. All rights reserved.',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedText,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _launchWebsite(String url) async {
    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

