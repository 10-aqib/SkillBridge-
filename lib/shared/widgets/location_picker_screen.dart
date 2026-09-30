import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import 'package:skill_bridge/core/services/location_service.dart';
import 'package:skill_bridge/core/services/places_service.dart';
import 'package:skill_bridge/core/services/geocoding_service.dart';
import 'package:skill_bridge/core/utils/geo_location_util.dart';
import 'package:skill_bridge/shared/widgets/location_accuracy_badge.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final String formattedAddress;
  final String city;
  final LocationAccuracyLevel accuracy;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.formattedAddress,
    required this.city,
    required this.accuracy,
  });
}

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  
  const LocationPickerScreen({super.key, this.initialLocation});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng _currentMapPosition = const LatLng(33.6844, 73.0479); // Default Islamabad
  bool _isLoadingAddress = false;
  
  GeocodingResult? _currentGeocoding;
  LocationAccuracyLevel _currentAccuracy = LocationAccuracyLevel.unknown;
  double? _accuracyInMeters;

  final TextEditingController _searchController = TextEditingController();
  List<PlacePrediction> _predictions = [];
  Timer? _debounce;
  String _sessionToken = const Uuid().v4();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _currentMapPosition = widget.initialLocation!;
      _fetchAddressForPosition(_currentMapPosition);
    } else {
      _locateUser();
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _locateUser() async {
    setState(() => _isLoadingAddress = true);
    try {
      final position = await LocationService.getCurrentLocation(accuracy: LocationAccuracy.high);
      _currentAccuracy = LocationService.evaluateAccuracy(position);
      _accuracyInMeters = position.accuracy;
      
      final latLng = LatLng(position.latitude, position.longitude);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
      await _fetchAddressForPosition(latLng);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      setState(() => _isLoadingAddress = false);
    }
  }

  Future<void> _fetchAddressForPosition(LatLng position) async {
    setState(() {
      _isLoadingAddress = true;
      _currentMapPosition = position;
    });

    final result = await GeocodingService.reverseGeocode(position.latitude, position.longitude);
    
    if (mounted) {
      setState(() {
        _currentGeocoding = result;
        _isLoadingAddress = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _predictions = [];
        _isSearching = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _isSearching = true);
      final results = await PlacesService.getAutocompletePredictions(query, _sessionToken);
      if (mounted) {
        setState(() {
          _predictions = results;
          _isSearching = false;
        });
      }
    });
  }

  Future<void> _onPlaceSelected(PlacePrediction prediction) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _predictions = [];
      _searchController.text = prediction.mainText;
      _isLoadingAddress = true;
    });

    final details = await PlacesService.getPlaceDetails(prediction.placeId, _sessionToken);
    
    // Reset session token for next query
    _sessionToken = const Uuid().v4();

    if (details != null && mounted) {
      final latLng = LatLng(details.latitude, details.longitude);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
      
      setState(() {
        _currentAccuracy = LocationAccuracyLevel.unknown; // Manual pick
        _accuracyInMeters = null;
        _currentGeocoding = GeocodingResult(
          latitude: details.latitude,
          longitude: details.longitude,
          formattedAddress: details.formattedAddress,
          city: details.city,
        );
        _isLoadingAddress = false;
      });
    } else {
      setState(() => _isLoadingAddress = false);
    }
  }

  void _confirmLocation() {
    if (_currentGeocoding != null) {
      Navigator.pop(context, LocationResult(
        latitude: _currentGeocoding!.latitude,
        longitude: _currentGeocoding!.longitude,
        formattedAddress: _currentGeocoding!.formattedAddress,
        city: _currentGeocoding!.city,
        accuracy: _currentAccuracy,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _currentMapPosition, zoom: 15),
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onCameraMove: (position) {
              _currentMapPosition = position.target;
            },
            onCameraIdle: () {
              _fetchAddressForPosition(_currentMapPosition);
              // As user drags map, accuracy is unknown
              setState(() {
                _currentAccuracy = LocationAccuracyLevel.unknown;
                _accuracyInMeters = null;
              });
            },
          ),
          
          // Center Pin Marker
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40.0), // Adjust for pin pointing at center
              child: Icon(Icons.location_on, size: 48, color: Colors.red),
            ),
          ),

          // Search Bar & Predictions
          Positioned(
            top: 16, left: 16, right: 16,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search for a place or address',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      ) : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                if (_isSearching)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ),
                if (_predictions.isNotEmpty)
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(12),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _predictions.length,
                      itemBuilder: (context, index) {
                        final p = _predictions[index];
                        return ListTile(
                          leading: const Icon(Icons.location_city),
                          title: Text(p.mainText),
                          subtitle: Text(p.secondaryText),
                          onTap: () => _onPlaceSelected(p),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Use Current Location FAB
          Positioned(
            bottom: 180, right: 16,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _locateUser,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),

          // Bottom Confirmation Card
          Positioned(
            bottom: 16, left: 16, right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_currentAccuracy != LocationAccuracyLevel.unknown)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: LocationAccuracyBadge(
                          accuracyLevel: _currentAccuracy,
                          accuracyInMeters: _accuracyInMeters,
                        ),
                      ),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _isLoadingAddress
                            ? const Text('Loading address...', style: TextStyle(color: Colors.grey))
                            : Text(
                                _currentGeocoding?.formattedAddress ?? 'Unknown Location',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoadingAddress || _currentGeocoding == null ? null : _confirmLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Confirm Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
