import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import '../services/supabase_service.dart';
import 'package:logger/logger.dart';

class ParkingScreen extends StatefulWidget {
  final String? userId;

  const ParkingScreen({super.key, this.userId});

  @override
  State<ParkingScreen> createState() => _ParkingScreenState();
}

class _ParkingScreenState extends State<ParkingScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final Location _location = Location();
  final logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );
  LatLng? _currentLocation;
  LatLng? _parkedLocation;
  bool _isLoading = true;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    try {
      logger.i('Checking location permission');

      // Check if location service is enabled
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          logger.w('Location services are disabled');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location services are disabled. Please enable them in your settings.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
      }

      // Check location permission
      PermissionStatus permission = await _location.hasPermission();
      if (permission == PermissionStatus.denied) {
        permission = await _location.requestPermission();
        if (permission == PermissionStatus.denied) {
          logger.w('Location permissions are denied');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location permissions are denied. Please enable them in your settings.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (permission == PermissionStatus.deniedForever) {
        logger.w('Location permissions are permanently denied');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Location permissions are permanently denied. Please enable them in your settings.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // If we have permission, proceed with getting location and loading data
      await _getCurrentLocation();
      await _loadParkedLocation();
    } catch (e) {
      logger.e('Error checking location permission: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking location permission: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final locationData = await _location.getLocation();
      setState(() {
        _currentLocation =
            LatLng(locationData.latitude!, locationData.longitude!);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting location: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadParkedLocation() async {
    if (widget.userId == null) return;

    try {
      final parking = await _supabaseService.getLatestParking(widget.userId!);
      if (parking != null) {
        setState(() {
          _parkedLocation = LatLng(parking.latitude, parking.longitude);
          _photoUrl = parking.photoUrl;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading parked location: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveParkedLocation() async {
    if (widget.userId == null || _currentLocation == null) return;

    try {
      await _supabaseService.saveParking(
        widget.userId!,
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );
      setState(() {
        _parkedLocation = _currentLocation;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parking location saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving parking location: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearParkedLocation() async {
    if (widget.userId == null) return;

    try {
      await _supabaseService.clearParking(widget.userId!);
      setState(() {
        _parkedLocation = null;
        _photoUrl = null;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parking location cleared successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing parking location: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Default to a location if current location is not available
    final LatLng mapCenter = _currentLocation ?? const LatLng(0, 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Location'),
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: mapCenter,
                zoom: 15.0,
                minZoom: 3.0,
                maxZoom: 18.0,
                keepAlive: true,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c'],
                  tileProvider: NetworkTileProvider(),
                ),
                MarkerLayer(
                  markers: [
                    if (_currentLocation != null)
                      Marker(
                        point: _currentLocation!,
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 40.0,
                        ),
                        width: 40.0,
                        height: 40.0,
                      ),
                    if (_parkedLocation != null)
                      Marker(
                        point: _parkedLocation!,
                        child: const Icon(
                          Icons.local_parking,
                          color: Colors.red,
                          size: 40.0,
                        ),
                        width: 40.0,
                        height: 40.0,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (_photoUrl != null)
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(_photoUrl!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _saveParkedLocation,
                  child: const Text('Save Location'),
                ),
                if (_parkedLocation != null)
                  ElevatedButton(
                    onPressed: _clearParkedLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Clear Location'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
