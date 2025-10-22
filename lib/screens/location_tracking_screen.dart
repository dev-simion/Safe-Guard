import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:guardian_shield/services/location_tracking_service.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

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
  List<NearbyPlace> _nearbyPlaces = [];
  String? _selectedCategory;

  // Your Google Maps API Key
  static const String _googleApiKey = 'GOOGLE_MAPS_API_KEY';

  // Categories with their Google Places types
  final List<PlaceCategory> _categories = [
    PlaceCategory('Police Station', 'police', Icons.local_police, Colors.blue),
    PlaceCategory('Hospital', 'hospital', Icons.local_hospital, Colors.red),
    PlaceCategory('Pharmacy', 'pharmacy', Icons.medication, Colors.green),
    PlaceCategory('Fire Station', 'fire_station', Icons.fire_truck, Colors.orange),
    PlaceCategory('ATM', 'atm', Icons.atm, Colors.purple),
    PlaceCategory('Gas Station', 'gas_station', Icons.local_gas_station, Colors.yellow),
  ];

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

      if (!kIsWeb) {
        final serviceEnabled = await LocationTrackingService.isLocationServiceEnabled();
        if (!serviceEnabled) {
          setState(() {
            _errorMessage = 'Location services are disabled. Please enable them in settings.';
            _isLoading = false;
          });
          return;
        }

        final hasPermission = await LocationTrackingService.requestPermissions();
        if (!hasPermission) {
          setState(() {
            _errorMessage = 'Location permission denied. Please grant permission in app settings.';
            _isLoading = false;
          });
          return;
        }
      }

      await _getCurrentLocation();
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
    _locationSubscription = _locationService.locationStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _totalDistance = _locationService.getTotalDistance();
        });
        _animateToPosition(position);
      }
    });

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

  Future<void> _searchNearbyPlaces(String type, String categoryName) async {
    if (_currentPosition == null) return;

    setState(() {
      _selectedCategory = categoryName;
      _nearbyPlaces = [];
    });

    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
        'location=${_currentPosition!.latitude},${_currentPosition!.longitude}'
        '&radius=5000'
        '&type=$type'
        '&key=$_googleApiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          
          setState(() {
            _nearbyPlaces = results.map((place) {
              return NearbyPlace(
                name: place['name'] ?? 'Unknown',
                address: place['vicinity'] ?? 'No address',
                latitude: place['geometry']['location']['lat'],
                longitude: place['geometry']['location']['lng'],
                placeId: place['place_id'] ?? '',
                rating: place['rating']?.toDouble(),
                isOpen: place['opening_hours']?['open_now'],
              );
            }).toList();
          });

          // Add markers for nearby places
          _addNearbyPlaceMarkers();

          // Show bottom sheet with results
          _showNearbyPlacesSheet();
        } else {
          _showError('No places found nearby');
        }
      } else {
        _showError('Failed to fetch places');
      }
    } catch (e) {
      print('Error searching nearby places: $e');
      _showError('Error searching places: $e');
    }
  }

  void _addNearbyPlaceMarkers() {
    final newMarkers = <Marker>{};
    
    // Keep current location marker
    final currentMarker = _markers.firstWhere(
      (m) => m.markerId.value == 'current_location',
      orElse: () => Marker(markerId: const MarkerId('none')),
    );
    
    if (currentMarker.markerId.value != 'none') {
      newMarkers.add(currentMarker);
    }

    // Add nearby place markers
    for (var i = 0; i < _nearbyPlaces.length; i++) {
      final place = _nearbyPlaces[i];
      newMarkers.add(
        Marker(
          markerId: MarkerId('place_$i'),
          position: LatLng(place.latitude, place.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: place.name,
            snippet: place.address,
          ),
          onTap: () => _showPlaceDetails(place),
        ),
      );
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  void _showNearbyPlacesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_selectedCategory Nearby',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_nearbyPlaces.length} found',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                // Places list
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: _nearbyPlaces.length,
                    itemBuilder: (context, index) {
                      final place = _nearbyPlaces[index];
                      final distance = _calculateDistance(
                        _currentPosition!.latitude,
                        _currentPosition!.longitude,
                        place.latitude,
                        place.longitude,
                      );

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          place.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(place.address),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.directions_walk, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  '${distance.toStringAsFixed(2)} km away',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                                if (place.rating != null) ...[
                                  const SizedBox(width: 12),
                                  const Icon(Icons.star, size: 14, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  Text(
                                    place.rating!.toStringAsFixed(1),
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                                if (place.isOpen != null) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: place.isOpen! ? Colors.green : Colors.red,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      place.isOpen! ? 'Open' : 'Closed',
                                      style: const TextStyle(color: Colors.white, fontSize: 10),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.directions),
                          onPressed: () => _openDirections(place),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _showPlaceDetails(place);
                          _animateToPlace(place);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPlaceDetails(NearbyPlace place) {
    final distance = _calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      place.latitude,
      place.longitude,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(place.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📍 ${place.address}'),
            const SizedBox(height: 8),
            Text('📏 Distance: ${distance.toStringAsFixed(2)} km'),
            if (place.rating != null) ...[
              const SizedBox(height: 8),
              Text('⭐ Rating: ${place.rating!.toStringAsFixed(1)}'),
            ],
            if (place.isOpen != null) ...[
              const SizedBox(height: 8),
              Text(place.isOpen! ? '🟢 Currently Open' : '🔴 Currently Closed'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openDirections(place);
            },
            icon: const Icon(Icons.directions),
            label: const Text('Get Directions'),
          ),
        ],
      ),
    );
  }

  void _animateToPlace(NearbyPlace place) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(place.latitude, place.longitude),
        15,
      ),
    );
  }

  void _openDirections(NearbyPlace place) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${place.latitude},${place.longitude}';
    // You can use url_launcher package here
    print('Open directions: $url');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening directions to ${place.name}')),
    );
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    final distanceInMeters = Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
    return distanceInMeters / 1000; // Convert to kilometers
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
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
                  Text('Initializing location...', style: theme.textTheme.bodyLarge),
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
                        Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                        const SizedBox(height: 16),
                        Text(_errorMessage, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center),
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
                          target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
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
                      ),
                    
                    // Category buttons
                    Positioned(
                      top: 16,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: 50,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final isSelected = _selectedCategory == category.name;
                            
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Material(
                                color: isSelected ? category.color : theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(25),
                                elevation: 2,
                                child: InkWell(
                                  onTap: () => _searchNearbyPlaces(category.type, category.name),
                                  borderRadius: BorderRadius.circular(25),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          category.icon,
                                          color: isSelected ? Colors.white : category.color,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          category.name,
                                          style: TextStyle(
                                            color: isSelected ? Colors.white : Colors.black87,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    // Status card
                    Positioned(
                      top: 80,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(_isTracking ? Icons.location_searching : Icons.location_on,
                                    color: theme.colorScheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  _isTracking ? 'Tracking Active' : 'Tracking Inactive',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            if (_currentPosition != null) ...[
                              const SizedBox(height: 8),
                              Text('Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                                  style: theme.textTheme.bodySmall),
                              Text('Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                                  style: theme.textTheme.bodySmall),
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
                    
                    // Tracking button
                    Positioned(
                      bottom: 24,
                      right: 24,
                      child: FloatingActionButton.extended(
                        onPressed: _toggleTracking,
                        backgroundColor: theme.colorScheme.primary,
                        icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow,
                            color: theme.colorScheme.onPrimary),
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

// Models
class PlaceCategory {
  final String name;
  final String type;
  final IconData icon;
  final Color color;

  PlaceCategory(this.name, this.type, this.icon, this.color);
}

class NearbyPlace {
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String placeId;
  final double? rating;
  final bool? isOpen;

  NearbyPlace({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.placeId,
    this.rating,
    this.isOpen,
  });
}
