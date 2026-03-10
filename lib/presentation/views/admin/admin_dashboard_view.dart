import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/admin_dashboard_controller.dart';

class AdminDashboardView extends GetView<AdminDashboardController> {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AdminDashboardController>()) {
      Get.put(AdminDashboardController());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: controller.loadDashboard,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!controller.isAuthorized.value) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                controller.errorMessage.value.isEmpty
                    ? 'Access denied.'
                    : controller.errorMessage.value,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadDashboard,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricCard(
                    title: 'Registered Users',
                    value: controller.registeredUsers.value.toString(),
                    icon: Icons.group_outlined,
                  ),
                  _MetricCard(
                    title: 'Active Today',
                    value: controller.activeUsersToday.value.toString(),
                    icon: Icons.bolt_outlined,
                  ),
                  _MetricCard(
                    title: 'Active (7 Days)',
                    value: controller.activeUsers7Days.value.toString(),
                    icon: Icons.calendar_view_week_outlined,
                  ),
                  _MetricCard(
                    title: 'Total Invoices',
                    value: controller.totalInvoices.value.toString(),
                    icon: Icons.receipt_long_outlined,
                  ),
                  _MetricCard(
                    title: 'Total App Opens',
                    value: controller.totalAppOpens.value.toString(),
                    icon: Icons.open_in_new_outlined,
                  ),
                  _MetricCard(
                    title: 'Total Screen Views',
                    value: controller.totalScreenViews.value.toString(),
                    icon: Icons.insights_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Users Activity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Company')),
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Invoices')),
                    DataColumn(label: Text('Last Active')),
                    DataColumn(label: Text('App Opens')),
                    DataColumn(label: Text('Views')),
                  ],
                  rows:
                      controller.userMetrics
                          .map(
                            (item) => DataRow(
                              cells: [
                                DataCell(
                                  SizedBox(
                                    width: 180,
                                    child: Text(
                                      item.companyName,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 220,
                                    child: Text(
                                      item.email.isEmpty ? '-' : item.email,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(Text(item.invoiceCount.toString())),
                                DataCell(
                                  Text(
                                    item.lastActiveAt == null
                                        ? '-'
                                        : _formatDate(item.lastActiveAt!),
                                  ),
                                ),
                                DataCell(Text(item.appOpenCount.toString())),
                                DataCell(Text(item.screenViewCount.toString())),
                              ],
                            ),
                          )
                          .toList(),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  String _formatDate(DateTime dateTime) {
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueGrey.shade700),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
