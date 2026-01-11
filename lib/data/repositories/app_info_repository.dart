import 'package:package_info_plus/package_info_plus.dart';

import '../models/app_info_model.dart';
import '../../core/constants/app_strings.dart';

class AppInfoRepository {
  Future<AppInfoModel> fetchAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return AppInfoModel(
      appName: AppStrings.appName,
      appTitle: AppStrings.appTitle,
      appSubtitle: AppStrings.appSubtitle,
      appIconPath: AppStrings.appIconPath,
      version: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      packageName: packageInfo.packageName,
      buildSignature: packageInfo.buildSignature,
    );
  }

  Future<DeveloperInfoModel> fetchDeveloperInfo() async {
    return DeveloperInfoModel(
      company: AppStrings.developerCompany,
      location: AppStrings.developerLocation,
      email: AppStrings.developerEmail,
      website: AppStrings.developerWebsite,
    );
  }
}

