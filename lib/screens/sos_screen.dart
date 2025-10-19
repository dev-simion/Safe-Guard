import 'package:flutter/material.dart';
import 'package:guardian_shield/models/emergency_alert.dart';
import 'package:guardian_shield/services/alert_service.dart';
import 'package:guardian_shield/services/location_service.dart';
import 'package:guardian_shield/services/supabase_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

// Main UI Screen. 

class SOSScreen extends StatefulWidget {
  const SOSScreen({super.key});

  @override
  State<SOSScreen> createState() => _SOSScreenState();
}

class _SOSScreenState extends State<SOSScreen> {
  final _alertService = AlertService();
  bool _isProcessing = false;
  bool _isSharingLocation = false;
  Position? _currentPosition;
  StreamSubscription<Position>? _locationSubscription;
  String _locationDetails = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final position = await LocationService.getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _currentPosition = position;
        _updateLocationDetails(position);
      });
    }
  }

  void _updateLocationDetails(Position position) {
    setState(() {
      _locationDetails = 'Lat: ${position.latitude.toStringAsFixed(6)}, '
          'Lng: ${position.longitude.toStringAsFixed(6)}\n'
          'Accuracy: ${position.accuracy.toStringAsFixed(1)}m\n'
          'Speed: ${position.speed.toStringAsFixed(1)} m/s\n'
          'Altitude: ${position.altitude.toStringAsFixed(1)}m';
    });
  }

  Future<void> _shareLocation() async {
    if (_currentPosition == null) {
      _showError('Unable to get location. Please enable location services.');
      return;
    }

    final latitude = _currentPosition!.latitude;
    final longitude = _currentPosition!.longitude;
    final googleMapsUrl = 'https://www.google.com/maps?q=$latitude,$longitude';
    final appleMapsUrl = 'https://maps.apple.com/?q=$latitude,$longitude';
    
    final message = '''
🚨 EMERGENCY - I NEED HELP! 🚨

📍 My Current Location:
$googleMapsUrl

Alternative (Apple Maps):
$appleMapsUrl

Coordinates:
Latitude: $latitude
Longitude: $longitude

Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(1)}m
Timestamp: ${DateTime.now().toString()}

$_locationDetails

This is an automated emergency alert from SafeGuard App.
''';

    try {
      await Share.share(
        message,
        subject: '🚨 EMERGENCY ALERT - Location Share',
      );
      _showSuccess('Location shared successfully!');
    } catch (e) {
      _showError('Failed to share location: $e');
    }
  }

  Future<void> _toggleLocationSharing() async {
    if (_isSharingLocation) {
      // Stop sharing
      _stopLocationSharing();
    } else {
      // Start sharing
      await _startLocationSharing();
    }
  }

  Future<void> _startLocationSharing() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Check and request permissions
      final hasPermission = await LocationService.requestPermissions();
      if (!hasPermission) {
        _showError('Location permission denied. Please grant permission.');
        setState(() => _isProcessing = false);
        return;
      }

      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled. Please enable them.');
        setState(() => _isProcessing = false);
        return;
      }

      // Get current location first
      await _getCurrentLocation();

      if (_currentPosition == null) {
        _showError('Unable to get your location. Please try again.');
        setState(() => _isProcessing = false);
        return;
      }

      // Share initial location
      await _shareLocation();

      // Start tracking and sharing updates
      _locationSubscription = LocationService.getLocationStream().listen(
        (position) {
          if (mounted) {
            setState(() {
              _currentPosition = position;
              _updateLocationDetails(position);
            });
          }
        },
        onError: (error) {
          print('Location tracking error: $error');
          _stopLocationSharing();
        },
      );

      // Create alert in database
      final userId = SupabaseService.auth.currentUser?.id;
      if (userId != null) {
        await _alertService.createAlert(
          userId: userId,
          type: AlertType.general,
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          isSilent: false,
          notes: 'Live location sharing started',
        );
      }

      setState(() {
        _isSharingLocation = true;
        _isProcessing = false;
      });

      _showSuccess('Live location sharing started!');
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Error starting location sharing: $e');
    }
  }

  void _stopLocationSharing() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    
    setState(() {
      _isSharingLocation = false;
    });

    _showSuccess('Location sharing stopped');
  }

  Future<void> _quickShare(AlertType type, String label) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final hasPermission = await LocationService.requestPermissions();
      if (!hasPermission) {
        _showError('Location permission denied.');
        setState(() => _isProcessing = false);
        return;
      }

      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        _showError('Unable to get location.');
        setState(() => _isProcessing = false);
        return;
      }

      setState(() {
        _currentPosition = position;
        _updateLocationDetails(position);
      });

      final googleMapsUrl = 'https://www.google.com/maps?q=${position.latitude},${position.longitude}';
      
      final message = '''
🚨 EMERGENCY: $label 🚨

📍 My Location: $googleMapsUrl

Coordinates: ${position.latitude}, ${position.longitude}

Sent from SafeGuard App at ${DateTime.now().toString()}
''';

      await Share.share(message, subject: '🚨 $label - Emergency Alert');

      // Create alert in database
      final userId = SupabaseService.auth.currentUser?.id;
      if (userId != null) {
        await _alertService.createAlert(
          userId: userId,
          type: type,
          latitude: position.latitude,
          longitude: position.longitude,
          isSilent: false,
          notes: label,
        );
      }

      setState(() => _isProcessing = false);
      _showSuccess('Emergency alert shared!');
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Failed to share: $e');
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
                  const SizedBox(width: 48),
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
                          'Emergency Location Sharing',
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
                        if (_isSharingLocation)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.green,
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
                      // Navigate to notifications
                    },
                  ),
                ],
              ),
              const SizedBox(height: 40),
              
              // Main SOS Button - Now for location sharing
              GestureDetector(
                onTap: _toggleLocationSharing,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isSharingLocation 
                        ? Colors.green 
                        : theme.colorScheme.primary,
                    boxShadow: [
                      BoxShadow(
                        color: (_isSharingLocation ? Colors.green : theme.colorScheme.primary)
                            .withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isSharingLocation 
                            ? Icons.stop_circle 
                            : Icons.share_location,
                        size: 80,
                        color: theme.colorScheme.onPrimary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isSharingLocation ? 'STOP' : 'SHARE',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _isSharingLocation 
                            ? 'SHARING LOCATION' 
                            : 'LIVE LOCATION',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Location info card
              if (_currentPosition != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isSharingLocation 
                                ? Icons.gps_fixed 
                                : Icons.gps_not_fixed,
                            color: _isSharingLocation 
                                ? Colors.green 
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isSharingLocation 
                                  ? 'Location tracking active' 
                                  : 'Location ready',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _locationDetails,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 40),
              
              // Quick Actions
              Text(
                'Quick Share',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              _QuickActionButton(
                icon: Icons.local_police,
                label: 'Share - Need Police',
                emoji: '🚓',
                onTap: () => _quickShare(AlertType.police, 'Need Police'),
                theme: theme,
              ),
              const SizedBox(height: 16),
              _QuickActionButton(
                icon: Icons.local_hospital,
                label: 'Share - Need Ambulance',
                emoji: '🚑',
                onTap: () => _quickShare(AlertType.ambulance, 'Need Ambulance'),
                theme: theme,
              ),
              const SizedBox(height: 16),
              _QuickActionButton(
                icon: Icons.family_restroom,
                label: 'Share with Family',
                emoji: '👨‍👩‍👧‍👦',
                onTap: () => _quickShare(AlertType.general, 'Emergency - Family Alert'),
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

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
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