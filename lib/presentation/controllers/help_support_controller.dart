import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/snackbar_service.dart';

class HelpSupportController extends GetxController {
  static const String _supportEmail = 'support@fineye.ai';

  Future<void> sendEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: encodeQueryParameters(<String, String>{
        'subject': 'support_email_subject'.tr,
      }),
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        SnackbarService.to.showError(
          'title_error'.tr,
          'msg_email_client_error'.tr,
        );
      }
    } catch (e) {
      SnackbarService.to.showError(
        'title_error'.tr,
        'msg_email_client_error'.tr,
      );
    }
  }

  Future<void> reportBug() async {
    final Uri bugLaunchUri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      query: encodeQueryParameters(<String, String>{
        'subject': 'support_bug_subject'.tr,
        'body': 'support_bug_body'.tr,
      }),
    );

    try {
      if (await canLaunchUrl(bugLaunchUri)) {
        await launchUrl(bugLaunchUri);
      } else {
        SnackbarService.to.showError(
          'title_error'.tr,
          'msg_email_client_error'.tr,
        );
      }
    } catch (e) {
      SnackbarService.to.showError(
        'title_error'.tr,
        'msg_email_client_error'.tr,
      );
    }
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map(
          (MapEntry<String, String> e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
  }
}
