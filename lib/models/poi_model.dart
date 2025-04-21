class POI {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final String? phone;
  final String? openingHours;
  final int? connections;
  double distance = 0;
  double? rating;

  POI({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    this.phone,
    this.openingHours,
    this.connections,
    this.rating,
  });

  factory POI.fromJson(Map<String, dynamic> f) {
    var props = f['properties'];
    return POI(
      id: f['id']?.toString() ?? '',
      name: props['name'] ?? 'Unknown',
      lat: f['geometry']['coordinates'][1],
      lon: f['geometry']['coordinates'][0],
      phone: props['phone'] as String?,
      openingHours: props['opening_hours'] as String?,
      connections: props['charger:count'] != null
          ? int.tryParse(props['charger:count'].toString())
          : null,
      rating: props['rating'] != null
          ? double.tryParse(props['rating'].toString())
          : null,
    );
  }
}
