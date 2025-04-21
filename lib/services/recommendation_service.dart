import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RecommendationService {
  static const String _apiKey = '5b3ce3597851110001cf62489a5cb6f27c5349ecb67b93e3e81af80e';
  final Distance _distance = Distance();

  Future<List<Place>> fetchPlaces({
    required LatLng location,
    required List<int> categoryIds,
    int radius = 10000,
  }) async {
    const url = 'https://api.openrouteservice.org/pois';
    final buffer = radius.clamp(1, 2000);

    final body = {
      'request': 'pois',
      'geometry': {
        'geojson': {
          'type': 'Point',
          'coordinates': [location.longitude, location.latitude],
        },
        'buffer': buffer,
      },
      'filters': {
        'category_ids': categoryIds,
      },
      'limit': 200,
      'sortby': 'distance',
    };

    print('===== ORS POIs REQUEST =====');
    print(jsonEncode(body));
    print('============================');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': _apiKey,
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    print('Status: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch POIs: ${response.body}');
    }

    final data = jsonDecode(response.body.replaceAll('NaN', 'null'));
    final features = (data['features'] as List?) ?? [];
    print('Features count: ${features.length}');

    return features.map((f) {
      final Map<String, dynamic> props = f['properties'] as Map<String, dynamic>;
      final Map<String, dynamic> tags = (props['osm_tags'] as Map?)?.cast<String, dynamic>() ?? {};

      // 1) id
      final id = props['osm_id'].toString();

      // 2) name & phone
      final name = tags['name'] as String? ?? 'Unknown';
      final phone = tags['phone'] as String? ?? 'N/A';

      // 3) category
      String category = '';
      if (props['category_ids'] is Map) {
        final catMap = (props['category_ids'] as Map).cast<String, dynamic>();
        if (catMap.isNotEmpty) {
          final firstKey = catMap.keys.first;
          category = (catMap[firstKey]['category_name'] as String?) ?? '';
        }
      }

      // 4) rating (always 0 here)
      final rating = 0.0;

      // 5) geometry → LatLng + our own distance
      final coords = (f['geometry']['coordinates'] as List).cast<double>();
      final placeLoc = LatLng(coords[1], coords[0]);
      final distance = _distance(location, placeLoc);

      print('Parsed: $name (cat=$category) • ${distance.toStringAsFixed(0)}m • $phone');

      return Place(
        id: id,
        name: name,
        category: category,
        rating: rating,
        phone: phone,
        location: placeLoc,
        distance: distance,
      );
    }).toList();
  }
}

class Place {
  final String id;
  final String name;
  final String category;
  final double rating;
  final String phone;
  final LatLng location;
  final double distance;

  Place({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.phone,
    required this.location,
    required this.distance,
  });
}