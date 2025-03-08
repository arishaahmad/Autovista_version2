import 'package:flutter/material.dart';

class AddedVehicleScreen extends StatelessWidget {
  final Map<String, dynamic> vehicleData;

  const AddedVehicleScreen({super.key, required this.vehicleData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vehicle Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "Your Vehicle Information",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildInfoRow("Brand", vehicleData['brand']),
                const Divider(),
                _buildInfoRow("Model", vehicleData['model']),
                const Divider(),
                _buildInfoRow("Engine Type", vehicleData['engine_type']),
                const Divider(),
                _buildInfoRow(
                    "Mileage (km)", vehicleData['mileage']?.toString()),
                const Divider(),
                _buildInfoRow("Region", vehicleData['region']),
                const Divider(),
                _buildInfoRow(
                    "Make Year", vehicleData['make_year']?.toString()),
                const Divider(),
                if (vehicleData['engine_capacity'] != null)
                  _buildInfoRow("Engine Capacity (L)",
                      vehicleData['engine_capacity']?.toString()),
                if (vehicleData['license_start_date'] != null)
                  _buildInfoRow(
                      "License Start Date", vehicleData['license_start_date']),
                if (vehicleData['license_validity_months'] != null)
                  _buildInfoRow("License Validity (Months)",
                      vehicleData['license_validity_months']?.toString()),
                if (vehicleData['insurance_start_date'] != null)
                  _buildInfoRow("Insurance Start Date",
                      vehicleData['insurance_start_date']),
                if (vehicleData['insurance_validity_months'] != null)
                  _buildInfoRow("Insurance Validity (Months)",
                      vehicleData['insurance_validity_months']?.toString()),
                if (vehicleData['last_oil_change_date'] != null)
                  _buildInfoRow("Last Oil Change Date",
                      vehicleData['last_oil_change_date']),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(200, 50),
                      backgroundColor: Colors.teal,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Back", style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            value ?? "N/A",
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
