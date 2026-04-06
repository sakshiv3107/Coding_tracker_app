import 'package:url_launcher/url_launcher.dart';

class EmailService {
  static const String _recipientEmail = 'vishnoisakshi124@gmail.com';

  static Future<bool> sendReviewEmail({
    required String name,
    required String email,
    required String reviewType,
    required String message,
  }) async {
    final String subject = 'App Review - $reviewType';
    final String body = '''
Name: ${name.isEmpty ? 'Not provided' : name}
Email: ${email.isEmpty ? 'Not provided' : email}
Review Type: $reviewType

Message:
$message
''';

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: _recipientEmail,
      queryParameters: {
        'subject': subject,
        'body': body,
      },
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        return await launchUrl(emailLaunchUri);
      } else {
        throw 'Could not launch $emailLaunchUri';
      }
    } catch (e) {
      print('Error launching email: $e');
      return false;
    }
  }
}
