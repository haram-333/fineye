import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/services/snackbar_service.dart';
import '../../controllers/security_controller.dart';
import 'widgets/security_widgets.dart';

class SecurityView extends GetView<SecurityController> {
  const SecurityView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<SecurityController>()) {
      Get.put(SecurityController());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Get.back(),
        ),
        toolbarHeight: 90,
        title: Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'security'.tr,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'security_subtitle'.tr,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedText,
                  fontWeight: FontWeight.w400,
                ),
        
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLoginAuthSection(),
            // Devices & sessions panel removed per design
            _buildDataProtectionSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(context),
    );
  }

  Widget _buildLoginAuthSection() {
    return SecuritySectionCard(
      title: 'login_auth_section'.tr,
      icon: Container(
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
        // Change Password Button only (2FA and Biometric options removed per design)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              Get.toNamed(AppRoutes.changePassword);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1967D2),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.lock_outline, size: 20),
            label: Text(
              'change_password'.tr,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataProtectionSection() {
    return SecuritySectionCard(
      title: 'data_protection_section'.tr,
      children: [
        // Screen Privacy
        Obx(() => SecurityOptionTile(
              title: 'screen_privacy'.tr,
              subtitle: 'screen_privacy_desc'.tr,
              value: controller.isScreenPrivacyEnabled.value,
              onChanged: controller.toggleScreenPrivacy,
            )),
        const SizedBox(height: 8),
        // Auto-lock After
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'auto_lock_after'.tr,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Obx(() => Switch(
                      value: controller.isAutoLockEnabled.value,
                      onChanged: controller.toggleAutoLockEnabled,
                      activeColor: AppColors.primaryBlue,
                    )),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'auto_lock_desc'.tr,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mutedText,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              final enabled = controller.isAutoLockEnabled.value;
              return Row(
                children: [
                  _buildAutoLockOption('3 min', '3m', enabled: enabled),
                  const SizedBox(width: 8),
                  _buildAutoLockOption('5 min', '5m', enabled: enabled),
                  const SizedBox(width: 8),
                  _buildAutoLockOption('15 min', '15m', enabled: enabled),
                ],
              );
            }),
          ],
        ),
        const SizedBox(height: 16),
        // Explanatory Note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9FC),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'security_data_note'.tr,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.mutedText,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAutoLockOption(String label, String value, {required bool enabled}) {
    final isSelected = enabled && controller.autoLockTime.value == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!enabled) return;
          controller.setAutoLockTime(value);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryBlue
                : (enabled ? Colors.white : Colors.grey.shade100),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryBlue
                  : (enabled ? Colors.grey.shade300 : Colors.grey.shade200),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (enabled ? AppColors.ink : Colors.grey),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  // Save security settings
                  await controller.saveSecuritySettings();
                  Get.back();
                  SnackbarService.to.showSuccess(
                    'title_success'.tr, 
                    'msg_security_saved'.tr,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'save_settings'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: controller.resetSettings,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'reset_security_default'.tr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
