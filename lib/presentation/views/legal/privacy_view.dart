import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({super.key});

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
                'privacy_title'.tr,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'privacy_last_updated_date'.tr,
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
            _buildOverviewSection(),
            const SizedBox(height: 16),
            _buildOcrDisclosureSection(),
            const SizedBox(height: 16),
            _buildCollectSection(),
            const SizedBox(height: 16),
            _buildUseDataSection(),
            const SizedBox(height: 16),
            _buildStorageSecuritySection(),
            const SizedBox(height: 16),
            _buildDataRetentionSection(),
            const SizedBox(height: 16),
            _buildExportDeletionSection(),
            const SizedBox(height: 16),
            _buildRightsControlsSection(),
            const SizedBox(height: 16),
            _buildContactDetailsSection(),
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

  Widget _buildOverviewSection() {
    return _buildSectionCard(
      title: 'privacy_overview_title'.tr,
      topRight: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'privacy_for_info'.tr,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryBlue,
          ),
        ),
      ),
      children: [
        Text(
          'privacy_last_updated'.tr,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.mutedText,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'privacy_overview_body'.tr,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.ink,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCollectSection() {
    return _buildSectionCard(
      title: 'privacy_collect_title'.tr,
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
        _buildBulletPoint('privacy_collect_1'.tr),
        _buildBulletPoint('privacy_collect_2'.tr),
        _buildBulletPoint('privacy_collect_3'.tr),
        const SizedBox(height: 8),
        _buildNoteBox('privacy_collect_note'.tr),
      ],
    );
  }

  Widget _buildUseDataSection() {
    return _buildSectionCard(
      title: 'privacy_use_title'.tr,
      topRight: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.shield_outlined,
          color: AppColors.primaryBlue,
          size: 20,
        ),
      ),
      children: [
        _buildBulletPoint('privacy_use_1'.tr),
        _buildBulletPoint('privacy_use_2'.tr),
        _buildBulletPoint('privacy_use_3'.tr),
        const SizedBox(height: 8),
        _buildNoteBox('privacy_use_note'.tr),
      ],
    );
  }

  Widget _buildStorageSecuritySection() {
    return _buildSectionCard(
      title: 'privacy_storage_title'.tr,
      topRight: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.lock_outline,
          color: AppColors.primaryBlue,
          size: 20,
        ),
      ),
      children: [
        _buildBulletPoint('privacy_storage_1'.tr),
        _buildBulletPoint('privacy_storage_2'.tr),
        _buildBulletPoint('privacy_storage_3'.tr),
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
                  'privacy_storage_warning'.tr,
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

  Widget _buildRightsControlsSection() {
    return _buildSectionCard(
      title: 'privacy_rights_title'.tr,
      topRight: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.tune_outlined,
          color: AppColors.primaryBlue,
          size: 20,
        ),
      ),
      children: [
        _buildBulletPoint('privacy_rights_1'.tr),
        _buildBulletPoint('privacy_rights_2'.tr),
        _buildBulletPoint('privacy_rights_3'.tr),
        const SizedBox(height: 8),
        _buildNoteBox('privacy_rights_note'.tr),
      ],
    );
  }

  Widget _buildContactDetailsSection() {
    return _buildSectionCard(
      title: 'privacy_contact_title'.tr,
      topRight: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.email_outlined,
          color: AppColors.primaryBlue,
          size: 20,
        ),
      ),
      children: [
        Text(
          'privacy_contact_body'.tr,
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
                'privacy_open_help'.tr,
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
          onTap: () => Get.toNamed(AppRoutes.dataPrivacy),
          child: Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'privacy_view_settings'.tr,
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
        _buildNoteBox('privacy_confirmation'.tr),
      ],
    );
  }

  Widget _buildOcrDisclosureSection() {
    return _buildSectionCard(
      title: 'ocr_disclosure_title'.tr,
      topRight: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.document_scanner_outlined,
          color: AppColors.primaryBlue,
          size: 20,
        ),
      ),
      children: [
        Text(
          'ocr_disclosure_desc'.tr,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.ink,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDataRetentionSection() {
    return _buildSectionCard(
      title: 'data_retention_title'.tr,
      topRight: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.schedule_outlined,
          color: AppColors.primaryBlue,
          size: 20,
        ),
      ),
      children: [
        Text(
          'data_retention_desc'.tr,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.ink,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        _buildNoteBox('data_retention_note'.tr),
      ],
    );
  }

  Widget _buildExportDeletionSection() {
    return _buildSectionCard(
      title: 'export_deletion_title'.tr,
      topRight: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.file_download_outlined,
          color: AppColors.primaryBlue,
          size: 20,
        ),
      ),
      children: [
        Text(
          'export_deletion_desc'.tr,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.ink,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => Get.toNamed(AppRoutes.dataPrivacy),
          child: Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                color: AppColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'privacy_view_settings'.tr,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
