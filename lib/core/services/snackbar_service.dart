import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';

class SnackbarService extends GetxService {
  static SnackbarService get to => Get.find();

  /// Show success snackbar with green background and white text
  void showSuccess(String title, String message, {Duration? duration}) {
    Get.snackbar(
      '',
      '',
      backgroundColor: Colors.transparent,
      duration: duration ?? const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 0,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      overlayBlur: 0, // Remove blur
      animationDuration: const Duration(milliseconds: 200), // Faster animation
      messageText: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.successGreen,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
      titleText: const SizedBox.shrink(),
    );
  }

  /// Show error snackbar with red background and white text
  void showError(String title, String message, {Duration? duration}) {
    Get.snackbar(
      '',
      '',
      backgroundColor: Colors.transparent,
      duration: duration ?? const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 0,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      overlayBlur: 0, // Remove blur
      animationDuration: const Duration(milliseconds: 200), // Faster animation
      messageText: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.destructiveRed,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
      titleText: const SizedBox.shrink(),
    );
  }

  /// Show info snackbar with blue background and white text
  void showInfo(String title, String message, {Duration? duration}) {
    Get.snackbar(
      '',
      '',
      backgroundColor: Colors.transparent,
      duration: duration ?? const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 0,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      overlayBlur: 0, // Remove blur
      animationDuration: const Duration(milliseconds: 200), // Faster animation
      messageText: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primaryBlue,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (message.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
      titleText: const SizedBox.shrink(),
    );
  }
}

