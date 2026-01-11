import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/services/snackbar_service.dart';

class HelpSupportController extends GetxController {
  
  Future<void> sendEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@fineye.ai',
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

  Future<void> openWhatsApp() async {
    // Replace with actual support number
    const String phoneNumber = ''; 
    final String message = 'support_whatsapp_body'.tr;
    
    final Uri whatsappUri = Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else {
        SnackbarService.to.showError(
          'title_error'.tr, 
          'msg_whatsapp_error'.tr,
        );
      }
    } catch (e) {
        SnackbarService.to.showError(
          'title_error'.tr, 
          'msg_whatsapp_error'.tr,
        );
    }
  }
  
  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
