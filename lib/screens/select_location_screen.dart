import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class SelectLocationScreen extends StatefulWidget {
  const SelectLocationScreen({super.key});

  @override
  _SelectLocationScreenState createState() => _SelectLocationScreenState();
}

class _SelectLocationScreenState extends State<SelectLocationScreen> {
  LatLng? start;
  LatLng? end;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Locations"),
        backgroundColor: Colors.teal,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(33.6844, 73.0479),
          initialZoom: 10,
          onTap: (_, point) {
            setState(() {
              if (start == null) {
                start = point;
              } else if (end == null) {
                end = point;
                Navigator.pop(context, [start, end]);
              }
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          ),
          MarkerLayer(
            markers: [
              if (start != null)
                Marker(
                  point: start!,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on, color: Colors.green),
                ),
              if (end != null)
                Marker(
                  point: end!,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on, color: Colors.red),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
