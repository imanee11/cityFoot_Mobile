import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/supabase_constants.dart';

class NotificationService {
  static Future<void> sendWhatsApp({
    required String phone,
    required String title,
    required String body,
  }) async {
    if (phone.isEmpty) return;
    try {
      await http.post(
        Uri.parse(SupabaseConstants.whatsappFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${SupabaseConstants.anonKey}',
        },
        body: jsonEncode({'phone': phone, 'title': title, 'body': body}),
      );
    } catch (_) {}
  }

  // Legacy alias
  static Future<void> sendWhatsAppNotification(String phone, String title, String body) =>
      sendWhatsApp(phone: phone, title: title, body: body);
}
