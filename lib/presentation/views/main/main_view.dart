import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import '../../controllers/main_controller.dart';
import '../dashboard/dashboard_view.dart';
import '../../widgets/bottom_nav.dart';
import '../alerts/alerts_view.dart';
import '../upload/upload_view.dart';
import '../settings/settings_view.dart';
import '../invoices/invoice_list_view.dart';

class MainView extends GetView<MainController> {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<MainController>()) {
      Get.put(MainController());
    }



    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await controller.onWillPop();
        if (shouldPop) {
          final exit = await Get.dialog<bool>(
            AlertDialog(
              title: Text('exit_app_confirmation_title'.tr),
              content: Text('exit_app_confirmation_message'.tr),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: Text('exit_app_cancel'.tr),
                ),
                TextButton(
                  onPressed: () => Get.back(result: true),
                  child: Text('exit_app_confirm'.tr),
                ),
              ],
            ),
          );
          
          if (exit == true) {
            if (kIsWeb) {
              // On web, we can't close the window programmatically for security reasons
              // User must close the tab/window manually
            } else {
              SystemNavigator.pop();
            }
          }
        }
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            Positioned.fill(
              child: Obx(() => IndexedStack(
                index: controller.currentIndex.value,
                children: [
                  _buildNavigator(0, const DashboardView()),
                  _buildNavigator(1, const InvoiceListView()),
                  _buildNavigator(2, const UploadView()),
                  _buildNavigator(3, const AlertsView()),
                  _buildNavigator(4, const SettingsView()),
                ],
              )),
            ),
            Positioned(
              left: 0, 
              right: 0, 
              bottom: 0,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Obx(() => BottomNav(
                  currentIndex: controller.currentIndex.value,
                  onTap: controller.changeTabIndex,
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigator(int index, Widget child) {
    return Navigator(
      key: controller.navigatorKeys[index],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => child,
        );
      },
    );
  }
}
