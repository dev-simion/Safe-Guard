import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationTrackingService {
  static LocationTrackingService? _instance;
  static LocationTrackingService get instance => _instance ??= LocationTrackingService._();
  
  LocationTrackingService._();

  StreamSubscription<Position>? _locationSubscription;
  final StreamController<Position> _locationController = StreamController<Position>.broadcast();
  final StreamController<Set<Marker>> _markersController = StreamController<Set<Marker>>.broadcast();
  
  bool _isTracking = false;
  Position? _currentPosition;
  final Set<Marker> _markers = {};
  final List<LatLng> _trackingPath = [];

  // Getters
  bool get isTracking => _isTracking;
  Position? get currentPosition => _currentPosition;
  Set<Marker> get markers => _markers;
  List<LatLng> get trackingPath => _trackingPath;
  
  // Streams
  Stream<Position> get locationStream => _locationController.stream;
  Stream<Set<Marker>> get markersStream => _markersController.stream;

  /// Request location permissions
  static Future<bool> requestPermissions() async {
    final locationPermission = await Permission.location.request();
    
    // For background location tracking (optional)
    if (locationPermission.isGranted) {
      await Permission.locationAlways.request();
    }
    
    return locationPermission.isGranted;
  }

  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get current location once
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) return null;

      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _currentPosition = position;
      _updateCurrentLocationMarker(position);
      
      return position;
    } catch (e) {
      print('Error getting current location: $e');
      return null;
    }
  }

  /// Start live location tracking
  Future<bool> startTracking() async {
    if (_isTracking) return true;

    try {
      final hasPermission = await requestPermissions();
      if (!hasPermission) return false;

      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      _isTracking = true;
      _trackingPath.clear();

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
        timeLimit: Duration(seconds: 10),
      );

      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _currentPosition = position;
          _trackingPath.add(LatLng(position.latitude, position.longitude));
          _updateCurrentLocationMarker(position);
          _locationController.add(position);
        },
        onError: (error) {
          print('Location tracking error: $error');
          stopTracking();
        },
      );

      return true;
    } catch (e) {
      print('Error starting location tracking: $e');
      _isTracking = false;
      return false;
    }
  }

  /// Stop location tracking
  void stopTracking() {
    _isTracking = false;
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  /// Update the current location marker
  void _updateCurrentLocationMarker(Position position) {
    _markers.removeWhere((marker) => marker.markerId.value == 'current_location');
    
    _markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: LatLng(position.latitude, position.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: 'Your Current Location',
          snippet: 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}',
        ),
      ),
    );
    
    _markersController.add(_markers);
  }

  /// Add a custom marker to the map
  void addMarker({
    required String id,
    required LatLng position,
    String? title,
    String? snippet,
    BitmapDescriptor? icon,
  }) {
    _markers.add(
      Marker(
        markerId: MarkerId(id),
        position: position,
        icon: icon ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
          title: title,
          snippet: snippet,
        ),
      ),
    );
    
    _markersController.add(_markers);
  }

  /// Remove a marker by ID
  void removeMarker(String id) {
    _markers.removeWhere((marker) => marker.markerId.value == id);
    _markersController.add(_markers);
  }

  /// Clear all markers except current location
  void clearMarkers({bool keepCurrentLocation = true}) {
    if (keepCurrentLocation) {
      _markers.removeWhere((marker) => marker.markerId.value != 'current_location');
    } else {
      _markers.clear();
    }
    _markersController.add(_markers);
  }

  /// Get distance between two points in meters
  static double getDistanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Calculate total distance of tracking path
  double getTotalDistance() {
    if (_trackingPath.length < 2) return 0.0;
    
    double totalDistance = 0.0;
    for (int i = 1; i < _trackingPath.length; i++) {
      totalDistance += getDistanceBetween(
        _trackingPath[i - 1].latitude,
        _trackingPath[i - 1].longitude,
        _trackingPath[i].latitude,
        _trackingPath[i].longitude,
      );
    }
    
    return totalDistance;
  }

  /// Get formatted address from coordinates (placeholder - requires geocoding service)
  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      // This is a placeholder. For real address lookup, you'd use:
      // - Google Geocoding API
      // - Mapbox Geocoding API  
      // - Or a geocoding package like 'geocoding'
      return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    } catch (e) {
      return 'Unknown location';
    }
  }

  /// Dispose of resources
  void dispose() {
    stopTracking();
    _locationController.close();
    _markersController.close();
  }
}