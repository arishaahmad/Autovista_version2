import 'package:flutter/material.dart';

class ProfileCard extends StatelessWidget {
  final String name;
  final String email;
  final String phone;

  const ProfileCard({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(name,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(email),
            const SizedBox(height: 8),
            Text(phone),
          ],
        ),
      ),
    );
  }
}
