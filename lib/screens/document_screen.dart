import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/supabase_service.dart';
import '../models/document_model.dart';
import 'package:path/path.dart' as path;

class ScanDocumentScreen extends StatefulWidget {
  final String? userId;

  const ScanDocumentScreen({super.key, this.userId});

  @override
  State<ScanDocumentScreen> createState() => _ScanDocumentScreenState();
}

class _ScanDocumentScreenState extends State<ScanDocumentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _selectedCategory;
  File? _selectedFile;
  bool _isUploading = false;
  final SupabaseService _supabaseService = SupabaseService();

  final List<String> _categories = [
    'Vehicle Registration',
    'Insurance Document',
    'Maintenance Record',
    'Other Document',
  ];

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = File(result.files.first.path!);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _sanitizeFileName(String fileName) {
    // Replace special characters with their ASCII equivalents
    final sanitized = fileName
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'I')
      .replaceAll('ğ', 'g')
      .replaceAll('Ğ', 'G')
      .replaceAll('ü', 'u')
      .replaceAll('Ü', 'U')
      .replaceAll('ş', 's')
      .replaceAll('Ş', 'S')
      .replaceAll('ö', 'o')
      .replaceAll('Ö', 'O')
      .replaceAll('ç', 'c')
      .replaceAll('Ç', 'C')
      // Replace any remaining non-alphanumeric characters (except dots and underscores) with underscores
      .replaceAll(RegExp(r'[^a-zA-Z0-9._]'), '_');

    return sanitized;
  }

  Future<void> _uploadDocument() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file and fill in all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final bytes = await _selectedFile!.readAsBytes();
      final originalFileName = path.basename(_selectedFile!.path);
      final sanitizedFileName = _sanitizeFileName(originalFileName);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_$sanitizedFileName';
      final fileType = path.extension(_selectedFile!.path).toLowerCase();

      await _supabaseService.uploadDocument(
        widget.userId!,
        _selectedCategory!.toLowerCase().replaceAll(' ', '_'),
        _descriptionController.text,
        fileName,
        bytes,
        fileType,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document uploaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Error uploading document';

      if (e.toString().contains('Storage error: new row violates row-level security policy')) {
        errorMessage = 'You don\'t have permission to upload documents. Please check your account settings.';
      } else if (e.toString().contains('Bucket not found')) {
        errorMessage = 'Storage system is not properly configured. Please contact support.';
      } else if (e.toString().contains('storage error')) {
        errorMessage = 'Unable to store the document. Please try again or contact support if the issue persists.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Document'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Document Category',
                  border: OutlineInputBorder(),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.attach_file),
                label: const Text('Select Document'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              if (_selectedFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Selected file: ${path.basename(_selectedFile!.path)}',
                    style: const TextStyle(color: Colors.green),
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isUploading ? null : _uploadDocument,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.teal,
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Upload Document'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}
