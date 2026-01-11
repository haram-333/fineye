import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../controllers/help_support_controller.dart';

class HelpSupportView extends GetView<HelpSupportController> {
  const HelpSupportView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is loaded
    if (!Get.isRegistered<HelpSupportController>()) {
      Get.put(HelpSupportController());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        top: false,
        bottom: false,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'faq_section'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFAQSection(),
                    
                    const SizedBox(height: 8),
                    Text(
                      'help_footer'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'contact_section'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildContactSection(),

                    const SizedBox(height: 24),
                    Text(
                      'legal_section'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLegalSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      snap: true,
      pinned: false,
      backgroundColor: const Color(0xFFF5F7FA).withValues(alpha: 0.9),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: BackButton(color: AppColors.ink),
        ),
      ),
      toolbarHeight: 90,
      title: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'help_title'.tr,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
             const SizedBox(height: 4),
             Text(
              'help_subtitle'.tr,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildFAQSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Getting Started
          _buildFAQGroupHeader('faq_cat_getting_started'.tr),
          _buildFAQItem('faq_q_getting_started_1'.tr, 'faq_a_getting_started_1'.tr, showDivider: true),

          // 2. General
          _buildFAQGroupHeader('faq_cat_general'.tr),
          _buildFAQItem('faq_q_general_1'.tr, 'faq_a_general_1'.tr, showDivider: true),
          _buildFAQItem('faq_q_general_2'.tr, 'faq_a_general_2'.tr, showDivider: true),

          // 3. Invoices
          _buildFAQGroupHeader('faq_cat_invoices'.tr),
          _buildFAQItem('faq_q1'.tr, 'faq_a1'.tr, showDivider: true), // Existing: Upload
          _buildFAQItem('faq_q_invoices_2'.tr, 'faq_a_invoices_2'.tr, showDivider: true), // New: Edit

          // 4. Compliance Status
          _buildFAQGroupHeader('faq_cat_compliance'.tr),
          _buildFAQItem('faq_q_compliance_1'.tr, 'faq_a_compliance_1'.tr, showDivider: true),
          _buildFAQItem('faq_q_compliance_2'.tr, 'faq_a_compliance_2'.tr, showDivider: true),

          // 5. VAT
          _buildFAQGroupHeader('faq_cat_vat'.tr),
          _buildFAQItem('faq_q_vat_1'.tr, 'faq_a_vat_1'.tr, showDivider: true),
          _buildFAQItem('faq_q2'.tr, 'faq_a2'.tr, showDivider: true), // Existing: Deadlines

          // 6. Corporate Tax
          _buildFAQGroupHeader('faq_cat_ct'.tr),
          _buildFAQItem('faq_q_ct_1'.tr, 'faq_a_ct_1'.tr, showDivider: true),
          
          // 7. Security
          _buildFAQGroupHeader('faq_cat_security'.tr),
          _buildFAQItem('faq_q_security_1'.tr, 'faq_a_security_1'.tr, showDivider: false),
        ],
      ),
    );
  }

  Widget _buildFAQGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryBlue,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer, {bool showDivider = false}) {
    return Column(
      children: [
        ExpansionTile(
          title: Text(
            question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedAlignment: Get.locale?.languageCode == 'ar' ? Alignment.topRight : Alignment.topLeft,
          shape: const Border(),
          collapsedShape: const Border(),
          iconColor: AppColors.primaryBlue,
          collapsedIconColor: Colors.grey,
          children: [
            Text(
              answer,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
        if (showDivider)
          Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
      ],
    );
  }

  Widget _buildContactSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFF0F2F5),
              child: Icon(Icons.email_outlined, color: AppColors.primaryBlue, size: 20),
            ),
            title: Text(
              'email_support'.tr,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
            subtitle: Text(
              'email_desc'.tr,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            trailing: Text(
              'support@fineye.ai', // Or 'Link' icon
              style: const TextStyle(fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
            ),
            onTap: controller.sendEmail,
          ),
          const Divider(height: 1, indent: 70, endIndent: 0),
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFF0F2F5),
              child: Icon(Icons.chat_bubble_outline, color: AppColors.primaryBlue, size: 20),
            ),
            title: Text(
              'whatsapp_support'.tr,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
            subtitle: Text(
              'whatsapp_desc'.tr,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            trailing: Text(
              'open_chat'.tr,
              style: const TextStyle(fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
            ),
            onTap: controller.openWhatsApp,
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              'privacy_policy'.tr,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () => Get.toNamed(AppRoutes.privacyPolicy),
          ),
          const Divider(height: 1, indent: 16, endIndent: 0),
          ListTile(
            title: Text(
              'terms_conditions'.tr,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () => Get.toNamed(AppRoutes.termsConditions),
          ),
        ],
      ),
    );
  }
}
