import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';

class StatusBarController extends GetxController {
  
  void setTransparent() {
    if (!kIsWeb) {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ));
    }
  }

  void setWhite() {
    if (!kIsWeb) {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
      ));
    }
  }

  void setSolidBlue() {
    if (!kIsWeb) {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: AppColors.primaryBlue,
        statusBarIconBrightness: Brightness.light,
      ));
    }
  }
}
