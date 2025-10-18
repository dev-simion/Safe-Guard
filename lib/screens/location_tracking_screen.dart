import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardian_shield/services/location_tracking_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class LocationTrackingScreen extends StatefulWidget {
  const LocationTrackingScreen({super.key});

  @override
  State<LocationTrackingScreen> createState() => _LocationTrackingScreenState();
}

class _LocationTrackingScreenState extends State<LocationTrackingScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isTracking = false;
  Set<Marker> _markers = {};
  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<Set<Marker>>? _markersSubscription;
  double _totalDistance = 0.0;
  final LocationTrackingService _locationService = LocationTrackingService.instance;
  
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Check location service first
      final serviceEnabled = await LocationTrackingService.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled. Please enable them in settings.';
          _isLoading = false;
        });
        return;
      }

      // Request permissions
      final hasPermission = await LocationTrackingService.requestPermissions();
      if (!hasPermission) {
        setState(() {
          _errorMessage = 'Location permission denied. Please grant permission in app settings.';
          _isLoading = false;
        });
        return;
      }

      // Get current location
      await _getCurrentLocation();
      
      // Setup streams after getting initial location
      _setupStreams();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing location: $e';
        _isLoading = false;
      });
      print('Error in _initializeLocation: $e');
    }
  }

  void _setupStreams() {
    // Listen to location updates
    _locationSubscription = _locationService.locationStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _totalDistance = _locationService.getTotalDistance();
        });
        _animateToPosition(position);
      }
    });

    // Listen to marker updates
    _markersSubscription = _locationService.markersStream.listen((markers) {
      if (mounted) {
        setState(() {
          _markers = markers;
        });
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = position;
          _markers = _locationService.markers;
        });
        _animateToPosition(position);
      } else {
        throw Exception('Failed to get current location');
      }
    } catch (e) {
      print('Error getting current location: $e');
      setState(() {
        _errorMessage = 'Could not get your location. Please try again.';
      });
    }
  }

  void _animateToPosition(Position position) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(position.latitude, position.longitude),
      ),
    );
  }

  Future<void> _toggleTracking() async {
    if (_isTracking) {
      _locationService.stopTracking();
      setState(() => _isTracking = false);
    } else {
      final success = await _locationService.startTracking();
      if (success) {
        setState(() => _isTracking = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to start location tracking. Please check permissions and location services.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Location Tracking',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Initializing location...',
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _initializeLocation,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    if (_currentPosition != null)
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                          ),
                          zoom: 15,
                        ),
                        markers: _markers,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        mapType: MapType.normal,
                        zoomControlsEnabled: false,
                        compassEnabled: true,
                        onMapCreated: (controller) {
                          _mapController = controller;
                          print('Map created successfully');
                        },
                      )
                    else
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: theme.colorScheme.primary),
                            const SizedBox(height: 16),
                            Text(
                              'Getting your location...',
                              style: theme.textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      top: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isTracking ? Icons.location_searching : Icons.location_on,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isTracking ? 'Tracking Active' : 'Tracking Inactive',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (_currentPosition != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                                style: theme.textTheme.bodySmall,
                              ),
                              if (_isTracking && _totalDistance > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Distance: ${(_totalDistance / 1000).toStringAsFixed(2)} km',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 24,
                      right: 24,
                      child: FloatingActionButton.extended(
                        onPressed: _toggleTracking,
                        backgroundColor: theme.colorScheme.primary,
                        icon: Icon(
                          _isTracking ? Icons.stop : Icons.play_arrow,
                          color: theme.colorScheme.onPrimary,
                        ),
                        label: Text(
                          _isTracking ? 'Stop' : 'Start',
                          style: TextStyle(color: theme.colorScheme.onPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _markersSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
}