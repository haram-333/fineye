import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../controllers/notifications_controller.dart';

class AlertsView extends GetView<NotificationsController> {
  const AlertsView({super.key});

  // Strings prepared for future i18n


  @override
  Widget build(BuildContext context) {
    Get.put(NotificationsController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      body: Column(
        children: [
          _buildTopNavBar(),
          const SizedBox(height: 12),
          _buildFilterTabs(),
          const SizedBox(height: 16),
          _buildNotificationList(),
        ],
      ),
    );
  }

  Widget _buildTopNavBar() {
    final topPadding = Get.context != null ? MediaQuery.of(Get.context!).padding.top : 0.0;
    
    return Container(
      padding: EdgeInsets.only(top: topPadding + 12, bottom: 12, left: 20, right: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FA), // Match scaffold background
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'alerts_title'.tr,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'alerts_subtitle'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: controller.markAllAsRead,
            child: Text(
              'mark_all_read'.tr,
              style: const TextStyle(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Obx(() => _buildFilterChip(
              label: '${'filter_all'.tr} ${controller.allCount}',
              isSelected: controller.filterType.value == 'All',
              onTap: () => controller.setFilter('All'),
            )),
            const SizedBox(width: 12),
            Obx(() => _buildFilterChip(
              label: '${'filter_unread'.tr} ${controller.unreadCount}',
              isSelected: controller.filterType.value == 'Unread',
              onTap: () => controller.setFilter('Unread'),
            )),
            const SizedBox(width: 12),
            Obx(() => _buildFilterChip(
              label: 'filter_system'.tr,
              isSelected: controller.filterType.value == 'System',
              onTap: () => controller.setFilter('System'),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE0F7FA) : Colors.transparent, // Light cyan for selected
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF006064) : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList() {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: () async {
          // Reload notifications
          controller.loadNotifications();
          // Add a small delay for visual feedback
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: AppColors.primaryBlue,
        child: Obx(() {
          final notifications = controller.filteredNotifications;
          
          if (notifications.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(Get.context!).size.height * 0.5,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'no_notifications'.tr,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 110), // Bottom padding for nav bar
          itemCount: notifications.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return Dismissible(
              key: Key(notification.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => controller.deleteNotification(notification.id),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.white),
              ),
              child: _buildNotificationCard(notification),
            );
          },
        );
        }),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategoryIcon(notification.type),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildCategoryBadge(notification.type),
                    Row(
                      children: [
                        Text(
                          notification.time,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500
                          ),
                        ),
                        if (!notification.isRead) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.accentTeal,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  notification.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(NotificationType type) {
    IconData icon;
    Color color;
    Color bg;

    switch (type) {
      case NotificationType.vat:
        icon = Icons.dashboard_customize_outlined; // Placeholder for grid icon
        color = AppColors.primaryBlue;
        bg = AppColors.primaryBlue.withValues(alpha: 0.1);
        break;
      case NotificationType.corporate:
        icon = Icons.business_center_outlined;
        color = const Color(0xFF2ECC71);
        bg = const Color(0xFF2ECC71).withValues(alpha: 0.1);
        break;
      case NotificationType.system:
        icon = Icons.info_outline;
        color = Colors.grey.shade700;
        bg = Colors.grey.shade200;
        break;
      case NotificationType.warning:
        icon = Icons.warning_amber_rounded;
        color = const Color(0xFFF1C40F);
        bg = const Color(0xFFF1C40F).withValues(alpha: 0.1);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildCategoryBadge(NotificationType type) {
    String text;
    Color color;

    switch (type) {
      case NotificationType.vat:
        text = 'VAT';
        color = AppColors.primaryBlue;
        break;
      case NotificationType.corporate:
        text = 'Corporate';
        color = const Color(0xFF2ECC71);
        break;
      case NotificationType.system:
        text = 'badge_system'.tr;
        color = Colors.grey.shade400; // Muted as per requirements (though image might show different)
        break;
      case NotificationType.warning:
        text = 'badge_warning'.tr;
        color = const Color(0xFFF1C40F);
        break;
    }

    // System badge style in image is actually lighter/different, but requirements say "Muted Text". 
    // Image shows "System" as a grey pill.
    if (type == NotificationType.system) {
       return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
