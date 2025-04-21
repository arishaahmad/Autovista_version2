import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/car_model.dart';
import '../services/supabase_service.dart';
import '../services/recommendation_service.dart';

class RecommendationsScreen extends StatefulWidget {
  final String userId;
  const RecommendationsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  final _supabase = SupabaseService();
  final _recService = RecommendationService();

  List<Car> _cars = [];
  Car? _selectedCar;
  List<Place> _places = [];
  LatLng? _currentLocation;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCars();
    _getCurrentLocation();
  }

  Future<void> _loadCars() async {
    final cars = await _supabase.getUserCars(widget.userId);
    setState(() => _cars = cars);
    print('Loaded ${cars.length} cars for user ${widget.userId}');
  }

  Future<void> _getCurrentLocation() async {
    print('Checking location services…');
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      if (!await Geolocator.isLocationServiceEnabled()) return;
    }

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) return;

    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _search() async {
    if (_selectedCar == null) return;
    setState(() => _loading = true);

    // TEMP LOCATION
    final loc = LatLng(37.7749,-122.4194);

    const gasStationId = 471;
    const electricalId = 458;
    const carPartsId = 439;

    final isElectric = _selectedCar!.engineType.toLowerCase() == 'electric';
    final categories = <int>{isElectric ? electricalId : gasStationId, carPartsId}.toList();

    try {
      final results = await _recService.fetchPlaces(
        location: loc,
        categoryIds: categories,
        radius: 2000,
      );

      results.sort((a, b) => a.distance.compareTo(b.distance));

      setState(() {
        _places = results;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      print('Search error: $e');
    }
  }

  Icon _getIcon(String category) {
    switch (category.toLowerCase()) {
      case 'gas station':
        return const Icon(Icons.local_gas_station, color: Colors.red);
      case 'electrical parts':
        return const Icon(Icons.electrical_services, color: Colors.blue);
      case 'mechanics':
      case 'car parts':
        return const Icon(Icons.build, color: Colors.green);
      default:
        return const Icon(Icons.location_on);
    }
  }

  Widget _buildCategorySection(String title, List<Place> places) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const Divider(),
        ...places.map((p) => ListTile(
          leading: _getIcon(p.category),
          title: Text(p.name),
          subtitle: Text(
            '${(p.distance / 1000).toStringAsFixed(2)}km • Phone: ${p.phone}',
          ),
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final gasStations = _places.where((p) => p.category.toLowerCase().contains('gas')).toList();
    final electricParts = _places.where((p) => p.category.toLowerCase().contains('electric')).toList();
    final mechanics = _places.where((p) =>
    p.category.toLowerCase().contains('car') ||
        p.category.toLowerCase().contains('parts') ||
        p.category.toLowerCase().contains('mechanic')).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Recommendations')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          DropdownButton<Car>(
            hint: const Text('Select a car'),
            value: _selectedCar,
            items: _cars.map((c) => DropdownMenuItem(value: c, child: Text('${c.brand} ${c.model}'))).toList(),
            onChanged: (c) => setState(() => _selectedCar = c),
          ),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _search, child: const Text('Search')),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _places.isEmpty
                ? const Center(child: Text('No recommendations found.'))
                : ListView(
              children: [
                if (gasStations.isNotEmpty) _buildCategorySection('Gas Stations', gasStations),
                if (electricParts.isNotEmpty) _buildCategorySection('Electrical Parts', electricParts),
                if (mechanics.isNotEmpty) _buildCategorySection('Mechanics', mechanics),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
