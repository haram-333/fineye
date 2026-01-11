class AppInfoModel {
  final String appName;
  final String appTitle;
  final String appSubtitle;
  final String appIconPath;
  final String version;
  final String buildNumber;
  final String packageName;
  final String? buildSignature;

  AppInfoModel({
    required this.appName,
    required this.appTitle,
    required this.appSubtitle,
    required this.appIconPath,
    required this.version,
    required this.buildNumber,
    required this.packageName,
    this.buildSignature,
  });

  String get versionDisplay => 'Version $version';
  String get buildDisplay => 'Build $buildNumber';

  String copyrightText() {
    final year = DateTime.now().year.toString();
    return '© $year $appName. All rights reserved.';
  }
}

class DeveloperInfoModel {
  final String company;
  final String location;
  final String email;
  final String website;

  DeveloperInfoModel({
    required this.company,
    required this.location,
    required this.email,
    required this.website,
  });
}

