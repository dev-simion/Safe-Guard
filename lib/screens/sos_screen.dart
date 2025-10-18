import 'package:flutter/material.dart';
import 'package:guardian_shield/models/emergency_alert.dart';
import 'package:guardian_shield/services/alert_service.dart';
import 'package:guardian_shield/services/location_service.dart';
import 'package:guardian_shield/services/sms_service.dart';
import 'package:guardian_shield/supabase/supabase_config.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  final _alertService = AlertService();
  bool _isProcessing = false;

  Future<void> _makeEmergencyCall(String number) async {
    try {
      await FlutterPhoneDirectCaller.callNumber(number);
    } catch (e) {
      _showError('Unable to make call: $e');
    }
  }

  Future<void> _triggerSOS({
    required AlertType type,
    bool isSilent = false,
    String? phoneNumber,
  }) async {
    if (_isProcessing) return;

    final userId = SupabaseConfig.auth.currentUser?.id;
    if (userId == null) {
      _showError('You must be signed in to send an alert.');
      return;
    }

    setState(() => _isProcessing = true);

    final position = await LocationService.getCurrentLocation();
    if (position == null) {
      _showError('Unable to get location. Please enable location services.');
      setState(() => _isProcessing = false);
      return;
    }

    // Make phone call if number is provided
    if (phoneNumber != null) {
      await _makeEmergencyCall(phoneNumber);
    }

    final alert = await _alertService.createAlert(
      userId: userId,
      type: type,
      latitude: position.latitude,
      longitude: position.longitude,
      isSilent: isSilent,
    );

    setState(() => _isProcessing = false);

    if (alert != null) {
      _showSuccess('Emergency alert sent! Help is on the way.');
    } else {
      _showError('Failed to send alert. Please try again.');
    }
  }

  Future<void> _notifyFamily() async {
    if (_isProcessing) return;

    final userId = SupabaseConfig.auth.currentUser?.id;
    if (userId == null) {
      _showError('You must be signed in to notify family.');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Fetch user's data including emergency contact and name
      final response = await SupabaseConfig.client
          .from('users')
          .select('emergency_contacts, full_name')
          .eq('id', userId)
          .single();

      final emergencyContacts = response['emergency_contacts'] as String?;
      final userName = response['full_name'] as String? ?? 'User';

      if (emergencyContacts == null || emergencyContacts.isEmpty) {
        _showError('No emergency contact set. Please add one in settings.');
        setState(() => _isProcessing = false);
        return;
      }

      // Get location
      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        _showError('Unable to get location. Please enable location services.');
        setState(() => _isProcessing = false);
        return;
      }

      // Create silent alert
      final alert = await _alertService.createAlert(
        userId: userId,
        type: AlertType.general,
        latitude: position.latitude,
        longitude: position.longitude,
        isSilent: true,
        notes: 'Family notification alert',
      );

      // Format and send SMS to emergency contact
      final message = SmsService.formatEmergencyMessage(
        userName: userName,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      final smsSent = await SmsService.sendEmergencySMS(
        emergencyContacts,
        message,
      );

      setState(() => _isProcessing = false);

      if (alert != null && smsSent) {
        _showSuccess('Family has been notified with your location via SMS.');
      } else if (alert != null && !smsSent) {
        _showSuccess('Alert created but SMS failed. Please check SMS permissions.');
      } else {
        _showError('Failed to notify family. Please try again.');
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Error notifying family: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Header with notification icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // Spacer for centering
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'SafeGuard',
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Emergency Alert System',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Stack(
                      children: [
                        Icon(
                          Icons.notifications_outlined,
                          color: theme.colorScheme.primary,
                          size: 28,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    onPressed: () {
                      // Navigate to notifications screen
                      // Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsScreen()));
                    },
                  ),
                ],
              ),
              const SizedBox(height: 40),
              
              // Main SOS Button
              GestureDetector(
                onTap: () => _triggerSOS(
                  type: AlertType.general,
                  phoneNumber: '911',
                ),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emergency,
                        size: 80,
                        color: theme.colorScheme.onPrimary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'SOS',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'TAP FOR HELP',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 60),
              
              // Quick Actions Title
              Text(
                'Quick Actions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Quick Action Buttons
              _QuickActionButton(
                icon: Icons.local_police,
                label: 'Need Police',
                emoji: '🚓',
                onTap: () => _triggerSOS(
                  type: AlertType.police,
                  phoneNumber: '911',
                ),
                theme: theme,
              ),
              const SizedBox(height: 16),
              _QuickActionButton(
                icon: Icons.local_hospital,
                label: 'Need Ambulance',
                emoji: '🚑',
                onTap: () => _triggerSOS(
                  type: AlertType.ambulance,
                  phoneNumber: '211',
                ),
                theme: theme,
              ),
              const SizedBox(height: 16),
              _QuickActionButton(
                icon: Icons.family_restroom,
                label: 'Notify Family',
                emoji: '👨‍👩‍👧‍👦',
                onTap: _notifyFamily,
                theme: theme,
              ),
              const SizedBox(height: 32),
              
              // Loading Indicator
              if (_isProcessing)
                CircularProgressIndicator(color: theme.colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String emoji;
  final VoidCallback onTap;
  final ThemeData theme;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.emoji,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: theme.colorScheme.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ],
          ),
        ),
      ),
    );
  }
}