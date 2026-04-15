import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  static const String _apiUrl = 'https://api.emailjs.com/api/v1.0/email/send';

  static Future<bool> sendReviewEmail({
    required String name,
    required String email,
    required String reviewType,
    required String message,
  }) async {
    try {
      final serviceId = dotenv.env['EMAILJS_SERVICE_ID'] ?? '';
      final templateId = dotenv.env['EMAILJS_TEMPLATE_ID'] ?? '';
      final publicKey = dotenv.env['EMAILJS_PUBLIC_KEY'] ?? '';

      if (serviceId.isEmpty || templateId.isEmpty || publicKey.isEmpty) {
        // print('EmailJS credentials not configured');
        return false;
      }

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: json.encode({
          'service_id': serviceId,
          'template_id': templateId,
          'user_id': publicKey,
          'template_params': {
            'from_name': name.isEmpty ? 'Anonymous' : name,
            'from_email': email.isEmpty ? 'Not provided' : email,
            'review_type': reviewType,
            'message': message,
          },
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      // print('Error sending email: $e');
      return false;
    }
  }
}



