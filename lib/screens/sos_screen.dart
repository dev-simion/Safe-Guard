import 'package:flutter/material.dart';
import 'package:guardian_shield/models/emergency_alert.dart';
import 'package:guardian_shield/services/alert_service.dart';
import 'package:guardian_shield/services/location_service.dart';
import 'package:guardian_shield/supabase/supabase_config.dart';

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  final _alertService = AlertService();
  bool _isProcessing = false;

  Future<void> _triggerSOS({
    required AlertType type,
    bool isSilent = false,
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
              const SizedBox(height: 40),
              Text(
                'SafeGuard',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Emergency Alert System',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 60),
              GestureDetector(
                onTap: () => _triggerSOS(type: AlertType.general),
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.4),
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
              Text(
                'Quick Actions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _QuickActionButton(
                icon: Icons.local_police,
                label: 'Need Police',
                emoji: '🚓',
                onTap: () => _triggerSOS(type: AlertType.police),
                theme: theme,
              ),
              const SizedBox(height: 16),
              _QuickActionButton(
                icon: Icons.local_hospital,
                label: 'Need Ambulance',
                emoji: '🚑',
                onTap: () => _triggerSOS(type: AlertType.ambulance),
                theme: theme,
              ),
              const SizedBox(height: 16),
              _QuickActionButton(
                icon: Icons.notifications_off,
                label: 'Silent Alert',
                emoji: '🔕',
                onTap: () => _triggerSOS(type: AlertType.general, isSilent: true),
                theme: theme,
              ),
              const SizedBox(height: 32),
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
      color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
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
