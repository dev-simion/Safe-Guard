import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsService {
  static final Telephony telephony = Telephony.instance;

  /// Send emergency SMS using telephony package (more reliable)
  static Future<bool> sendEmergencySMS(String phoneNumber, String message) async {
    try {
      // Request SMS permission
      final status = await Permission.sms.request();
      if (!status.isGranted) {
        print('SMS permission not granted');
        return false;
      }

      // Send SMS directly without opening SMS app
      await telephony.sendSms(
        to: phoneNumber,
        message: message,
      );

      print('SMS sent successfully to $phoneNumber');
      return true;
    } catch (e) {
      print('Error sending SMS: $e');
      return false;
    }
  }

  /// Send SMS via default SMS app (opens SMS app with pre-filled message)
  static Future<bool> sendEmergencySMSViaApp(String phoneNumber, String message) async {
    try {
      // This will open the default SMS app with pre-filled content
      await telephony.sendSmsByDefaultApp(
        to: phoneNumber,
        message: message,
      );

      print('SMS app opened successfully');
      return true;
    } catch (e) {
      print('Error opening SMS app: $e');
      return false;
    }
  }

  /// Format emergency message with location
  static String formatEmergencyMessage({
    required String userName,
    required double latitude,
    required double longitude,
  }) {
    final locationUrl = 'https://www.google.com/maps?q=$latitude,$longitude';
    return '''
🚨 EMERGENCY ALERT 🚨

$userName needs help!

📍 Location: $locationUrl

Latitude: $latitude
Longitude: $longitude

This is an automated message from SafeGuard Emergency App.
''';
  }

  /// Request SMS permissions
  static Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  /// Check if SMS permission is granted
  static Future<bool> hasSmsPermission() async {
    final status = await Permission.sms.status;
    return status.isGranted;
  }
}