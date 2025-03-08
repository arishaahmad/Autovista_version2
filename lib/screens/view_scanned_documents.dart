import 'package:flutter/material.dart';

class ViewScannedDocumentsScreen extends StatelessWidget {
  const ViewScannedDocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Scanned Documents"),
      ),
      body: Center(
        child: Text(
          "Your scanned documents will appear here.",
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
