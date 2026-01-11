import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../controllers/data_privacy_controller.dart';

class DataPrivacyView extends GetView<DataPrivacyController> {
  const DataPrivacyView({super.key});

  @override
  Widget build(BuildContext context) {
      if (!Get.isRegistered<DataPrivacyController>()) {
      Get.put(DataPrivacyController());
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
                      'data_tools_section'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDataToolsCard(),

                    const SizedBox(height: 32),
                    Text(
                      'danger_zone'.tr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDangerZoneCard(),

                    const SizedBox(height: 24),
                    Text(
                      'privacy_footer_text'.tr,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        height: 1.5,
                      ),
                    ),
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
              'privacy_title'.tr,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
             const SizedBox(height: 4),
             Text(
              'privacy_desc'.tr,
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

  Widget _buildDataToolsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(
            'data_tools_desc'.tr,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _buildActionButton(
            label: 'btn_export_data'.tr,
            description: 'btn_export_desc'.tr,
            color: AppColors.primaryBlue,
            onTap: controller.exportUserData,
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            label: 'btn_clear_cache'.tr,
            description: 'btn_clear_cache_desc'.tr,
            color: Colors.grey.shade200,
            textColor: AppColors.ink,
             descColor: Colors.grey.shade600,
            onTap: controller.clearCache,
          ),
        ],
      ),
    );
  }

  Widget _buildDangerZoneCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2).withValues(alpha: 0.3), // Light red background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF87171).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'delete_account_title'.tr,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDC2626), // Red 600
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: controller.deleteAccount,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444), // Red 500
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'btn_delete_account'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'delete_warning'.tr,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFEF4444), // Red 500
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required String description,
    required Color color,
    required VoidCallback onTap,
    Color textColor = Colors.white,
    Color descColor = Colors.white70,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: descColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
