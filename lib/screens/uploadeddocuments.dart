import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';
import '../models/document_model.dart';

class ViewDocumentsScreen extends StatefulWidget {
  final String userId;

  const ViewDocumentsScreen({super.key, required this.userId});

  @override
  State<ViewDocumentsScreen> createState() => _ViewDocumentsScreenState();
}

class _ViewDocumentsScreenState extends State<ViewDocumentsScreen> {
  late Future<List<Document>> _documentsFuture;
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _documentsFuture = _supabaseService.getUserDocuments(widget.userId);
  }

  Future<void> _openDocument(Document doc) async {
    try {
      if (await canLaunchUrl(Uri.parse(doc.fileUrl))) {
        await launchUrl(Uri.parse(doc.fileUrl));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Could not open document"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error opening document: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Documents"),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Document>>(
        future: _documentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }

          final documents = snapshot.data ?? [];
          if (documents.isEmpty) {
            return const Center(
              child: Text(
                "No documents found.",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 4,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(Icons.description, color: Colors.teal),
                  title: Text(
                    doc.category.replaceAll('_', ' ').toUpperCase(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          doc.description,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "Tap to view document",
                          style: TextStyle(
                            color: Colors.teal[300],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.teal),
                  onTap: () => _openDocument(doc),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/document_screen',
              arguments: widget.userId);
        },
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
