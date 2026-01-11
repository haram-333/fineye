import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';

class OCRTipsView extends StatelessWidget {
  const OCRTipsView({super.key});

  @override
  Widget build(BuildContext context) {
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
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderCard(),
                        const SizedBox(height: 24),
                        _buildTipSection(
                          icon: Icons.light_mode_outlined,
                          title: 'tip_lighting_title'.tr,
                          tips: [
                            'tip_lighting_1'.tr,
                            'tip_lighting_2'.tr,
                            'tip_lighting_3'.tr,
                          ],
                        ),
                        _buildTipSection(
                          icon: Icons.filter_center_focus_outlined,
                          title: 'tip_camera_title'.tr,
                          tips: [
                            'tip_camera_1'.tr,
                            'tip_camera_2'.tr,
                            'tip_camera_3'.tr,
                          ],
                        ),
                        _buildTipSection(
                          icon: Icons.photo_size_select_actual_outlined,
                          title: 'tip_quality_title'.tr,
                          tips: [
                            'tip_quality_1'.tr,
                            'tip_quality_2'.tr,
                            'tip_quality_3'.tr,
                          ],
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
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
              'ocr_tips_title'.tr,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
      centerTitle: false,
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.tips_and_updates_outlined,
              color: AppColors.primaryBlue,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ocr_tips_header'.tr,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'ocr_tips_desc'.tr,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTipSection({
    required IconData icon,
    required String title,
    required List<String> tips,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00CED1).withValues(alpha: 0.1), // Accent Teal light
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF00CED1), // Accent Teal
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                ...tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: CircleAvatar(
                          radius: 3,
                          backgroundColor: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tip,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
