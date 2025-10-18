import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsService {
  /// Send SMS using URL launcher (opens SMS app with pre-filled message)
  /// This is the most reliable method and works on all devices
  static Future<bool> sendEmergencySMS(String phoneNumber, String message) async {
    try {
      // Request SMS permission (optional, but good practice)
      final status = await Permission.sms.request();
      if (!status.isGranted) {
        print('SMS permission not granted, but will try to open SMS app anyway');
      }

      // Clean phone number (remove spaces and special characters except +)
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Create SMS URI with message
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: cleanNumber,
        queryParameters: {'body': message},
      );

      // Launch SMS app
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        print('SMS app opened successfully for $cleanNumber');
        return true;
      } else {
        print('Could not launch SMS app');
        return false;
      }
    } catch (e) {
      print('Error sending SMS: $e');
      return false;
    }
  }

  /// Send SMS directly without opening app (Android only - requires special setup)
  /// Note: This method opens the SMS app but is more reliable than direct send
  static Future<bool> sendEmergencySMSDirect(String phoneNumber, String message) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // For Android, use sms: scheme
      final Uri smsUri = Uri.parse('sms:$cleanNumber?body=${Uri.encodeComponent(message)}');

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(
          smsUri,
          mode: LaunchMode.externalApplication,
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Error sending SMS: $e');
      return false;
    }
  }

  /// Format emergency message with location
  static String formatEmergencyMessage({
    required String userName,
    required double latitude,
    required double longitude,
  }) {
    final locationUrl = 'https://maps.google.com/?q=$latitude,$longitude';
    
    // Keep message concise for SMS length limits
    return '🚨 EMERGENCY! $userName needs help!\n'
        '📍 Location: $locationUrl\n'
        'Sent from SafeGuard App';
  }

  /// Format short emergency message (for SMS length limits)
  static String formatShortEmergencyMessage({
    required String userName,
    required double latitude,
    required double longitude,
  }) {
    return '🚨 $userName needs help! '
        'Location: https://maps.google.com/?q=$latitude,$longitude';
  }

  /// Check if SMS can be sent on this device
  static Future<bool> canSendSMS() async {
    try {
      final Uri smsUri = Uri(scheme: 'sms', path: '');
      return await canLaunchUrl(smsUri);
    } catch (e) {
      return false;
    }
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