import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MainController extends GetxController {
  final currentIndex = 0.obs;

  final List<GlobalKey<NavigatorState>> navigatorKeys = [
    GlobalKey<NavigatorState>(), // Dashboard
    GlobalKey<NavigatorState>(), // Invoices
    GlobalKey<NavigatorState>(), // Upload
    GlobalKey<NavigatorState>(), // Alerts
    GlobalKey<NavigatorState>(), // Settings
  ];

  void changeTabIndex(int index) {
    if (currentIndex.value == index) {
      navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      currentIndex.value = index;
    }
  }

  Future<bool> onWillPop() async {
    final isFirstRouteInCurrentTab = !await navigatorKeys[currentIndex.value]
        .currentState!
        .maybePop();

    if (isFirstRouteInCurrentTab) {
      if (currentIndex.value != 0) {
        currentIndex.value = 0;
        return false;
      }
    }
    
    
    return isFirstRouteInCurrentTab;
  }
}
