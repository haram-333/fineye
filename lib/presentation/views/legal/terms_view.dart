import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/snackbar_service.dart';

class TermsConditionsView extends StatelessWidget {
  const TermsConditionsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Get.back(),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'terms_title'.tr,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'terms_last_updated_date'.tr,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        toolbarHeight: 90,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroSection(),
            const SizedBox(height: 16),
            _buildDisclaimersSection(),
            const SizedBox(height: 16),
            _buildUseOfServiceSection(),
            const SizedBox(height: 16),
            _buildAccountsSecuritySection(),
            const SizedBox(height: 16),
            _buildBillingSection(),
            const SizedBox(height: 16),
            _buildDataComplianceSection(),
            const SizedBox(height: 16),
            _buildLiabilitySection(),
            const SizedBox(height: 16),
            _buildChangesContactSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    Widget? topRight,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
              ),
              if (topRight != null) topRight,
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 7, right: 12, left: 12),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primaryBlue,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.ink,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: AppColors.mutedText,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildIntroSection() {
    return _buildSectionCard(
      title: 'terms_intro_title'.tr,
      topRight: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'terms_read_carefully'.tr,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
      children: [
        Text(
          'terms_last_updated'.tr,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.mutedText,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'terms_intro_body'.tr,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.ink,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildUseOfServiceSection() {
    return _buildSectionCard(
      title: 'terms_use_title'.tr,
      topRight: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.description_outlined,
          color: AppColors.primaryBlue,
          size: 20,
        ),
      ),
      children: [
        _buildBulletPoint('terms_use_1'.tr),
        _buildBulletPoint('terms_use_2'.tr),
        _buildBulletPoint('terms_use_3'.tr),
        const SizedBox(height: 8),
        _buildNoteBox('terms_use_note'.tr),
      ],
    );
  }

  Widget _buildAccountsSecuritySection() {
    return _buildSectionCard(
      title: 'terms_accounts_title'.tr,
      topRight: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.person_outline,
          color: AppColors.primaryBlue,
          size: 20,
        ),
      ),
      children: [
        _buildBulletPoint('terms_accounts_1'.tr),
        _buildBulletPoint('terms_accounts_2'.tr),
        _buildBulletPoint('terms_accounts_3'.tr),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9E6),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFC107).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Color(0xFFF59E0B),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'terms_accounts_warning'.tr,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBillingSection() {
    return _buildSectionCard(
      title: 'terms_billing_title'.tr,
      topRight: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.credit_card_outlined,
          color: AppColors.primaryBlue,
          size: 20,
        ),
      ),
      children: [
        _buildBulletPoint('terms_billing_1'.tr),
        _buildBulletPoint('terms_billing_2'.tr),
        _buildBulletPoint('terms_billing_3'.tr),
        const SizedBox(height: 8),
        _buildNoteBox('terms_billing_note'.tr),
      ],
    );
  }

  Widget _buildDataComplianceSection() {
    return _buildSectionCard(
      title: 'terms_data_title'.tr,
      topRight: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.folder_outlined,
          color: AppColors.primaryBlue,
          size: 20,
        ),
      ),
      children: [
        _buildBulletPoint('terms_data_1'.tr),
        _buildBulletPoint('terms_data_2'.tr),
        _buildBulletPoint('terms_data_3'.tr),
        const SizedBox(height: 8),
        _buildNoteBox('terms_data_note'.tr),
      ],
    );
  }

  Widget _buildLiabilitySection() {
    return _buildSectionCard(
      title: 'terms_liability_title'.tr,
      topRight: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.info_outline,
          color: AppColors.primaryBlue,
          size: 20,
        ),
      ),
      children: [
        _buildBulletPoint('terms_liability_1'.tr),
        _buildBulletPoint('terms_liability_2'.tr),
        _buildBulletPoint('terms_liability_3'.tr),
        const SizedBox(height: 8),
        _buildNoteBox('terms_liability_note'.tr),
      ],
    );
  }

  Widget _buildChangesContactSection() {
    return _buildSectionCard(
      title: 'terms_changes_title'.tr,
      topRight: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.help_outline,
          color: AppColors.primaryBlue,
          size: 20,
        ),
      ),
      children: [
        Text(
          'terms_changes_body'.tr,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.ink,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => Get.toNamed(AppRoutes.helpSupport),
          child: Row(
            children: [
              const Icon(
                Icons.help_outline,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'terms_open_help'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: () {
            // Open contact support
            SnackbarService.to.showInfo(
              'title_contact_support'.tr, 
              'msg_contact_form_stub'.tr,
            );
          },
          child: Row(
            children: [
              const Icon(
                Icons.email_outlined,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'terms_contact_support'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildNoteBox('terms_confirmation'.tr),
      ],
    );
  }

  Widget _buildDisclaimersSection() {
    return _buildSectionCard(
      title: 'disclaimers_section_title'.tr,
      topRight: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF6E7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.warning_amber_rounded,
          color: Color(0xFFF59E0B),
          size: 20,
        ),
      ),
      children: [
        _buildDisclaimerBox(
          icon: Icons.info_outline,
          title: 'indicator_disclaimer_title'.tr,
          description: 'indicator_disclaimer_desc'.tr,
          color: AppColors.primaryBlue,
        ),
        const SizedBox(height: 12),
        _buildDisclaimerBox(
          icon: Icons.account_balance,
          title: 'fta_disclaimer_title'.tr,
          description: 'fta_disclaimer_desc'.tr,
          color: const Color(0xFFF59E0B),
        ),
        const SizedBox(height: 12),
        _buildDisclaimerBox(
          icon: Icons.check_circle_outline,
          title: 'user_responsibility_title'.tr,
          description: 'user_responsibility_desc'.tr,
          color: AppColors.successGreen,
        ),
      ],
    );
  }

  Widget _buildDisclaimerBox({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.ink,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
