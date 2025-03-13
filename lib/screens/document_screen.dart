import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../services/supabase_service.dart';
import 'package:path/path.dart' as path;
import 'document_list_screen.dart';

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
  bool _isUploadMode = false;

  final List<String> _categories = [
    'Vehicle Registration',
    'Insurance Document',
    'Maintenance Record',
    'Other Document',
  ];

  @override
  void initState() {
    super.initState();
    _isUploadMode = false;
  }

  void _showInitialOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            width: MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.teal.shade700, Colors.teal.shade900],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Document Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildOptionTile(
                  icon: Icons.visibility,
                  color: Colors.white,
                  title: 'View Scanned Documents',
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToDocumentList();
                  },
                ),
                const Divider(height: 1, color: Colors.white54),
                _buildOptionTile(
                  icon: Icons.document_scanner,
                  color: Colors.white,
                  title: 'Scan New Document',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _isUploadMode = true);
                    _showScanOptions();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToDocumentList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentListScreen(userId: widget.userId),
      ),
    );
  }

  void _showScanOptions() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            width: MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.teal.shade700, Colors.teal.shade900],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Document',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                _buildOptionTile(
                  icon: Icons.photo_library,
                  color: Colors.white,
                  title: 'Upload from Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickImageFile(FileType.image);
                  },
                ),
                const Divider(height: 1, color: Colors.white54),
                _buildOptionTile(
                  icon: Icons.camera_alt,
                  color: Colors.white,
                  title: 'Take a Picture',
                  subtitle: 'Use camera app and return here',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Open your camera app, take a picture, and then select it here'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                    Future.delayed(const Duration(seconds: 3), () {
                      _pickImageFile(FileType.image);
                    });
                  },
                ),
                const Divider(height: 1, color: Colors.white54),
                _buildOptionTile(
                  icon: Icons.file_copy,
                  color: Colors.white,
                  title: 'Select Document File',
                  onTap: () {
                    Navigator.pop(context);
                    _pickFile();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color color,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(fontSize: 16, color: Colors.white)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.white70)) : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minLeadingWidth: 24,
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'txt'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => _selectedFile = File(result.files.first.path!));
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

  Future<void> _pickImageFile(FileType fileType) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: fileType,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => _selectedFile = File(result.files.first.path!));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _sanitizeFileName(String fileName) {
    final sanitized = fileName
        .replaceAll('ı', 'i').replaceAll('İ', 'I')
        .replaceAll('ğ', 'g').replaceAll('Ğ', 'G')
        .replaceAll('ü', 'u').replaceAll('Ü', 'U')
        .replaceAll('ş', 's').replaceAll('Ş', 'S')
        .replaceAll('ö', 'o').replaceAll('Ö', 'O')
        .replaceAll('ç', 'c').replaceAll('Ç', 'C')
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

    setState(() => _isUploading = true);

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

      setState(() {
        _isUploadMode = false;
        _selectedFile = null;
        _selectedCategory = null;
        _descriptionController.clear();
      });

    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Error uploading document';
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isUploadMode) _showInitialOptions();
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isUploadMode ? 'Upload Document' : 'Document Scanner',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal.shade700,
        elevation: 1,
        actions: [
          if (_isUploadMode)
            IconButton(
              icon: Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isUploadMode = false;
                  _showInitialOptions();
                });
              },
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.teal.shade50],
          ),
        ),
        child: _isUploadMode ? _buildUploadForm() : _buildEmptyState(),
      ),
      floatingActionButton: !_isUploadMode ? FloatingActionButton(
        onPressed: _showInitialOptions,
        backgroundColor: Colors.teal.shade700,
        child: const Icon(Icons.add, color: Colors.white),
      ) : null,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 64, color: Colors.teal.shade700),
          const SizedBox(height: 16),
          Text(
            'No document selected',
            style: TextStyle(
                fontSize: 18,
                color: Colors.teal.shade700,
                fontWeight: FontWeight.w500
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to get started',
            style: TextStyle(color: Colors.teal.shade700),
          )
        ],
      ),
    );
  }

  Widget _buildUploadForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            if (_selectedFile != null) _buildFilePreviewCard(),
            _buildSectionHeader('Document Details'),
            _buildCategoryDropdown(),
            const SizedBox(height: 20),
            _buildSectionHeader('Document Description'),
            _buildDescriptionField(),
            const SizedBox(height: 20),
            _buildSectionHeader('File Selection'),
            _buildFileSelectionButton(),
            const SizedBox(height: 24),
            _buildUploadButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.teal.shade700,
        ),
      ),
    );
  }

  Widget _buildFilePreviewCard() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.teal.shade300!, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insert_drive_file, color: Colors.teal.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    path.basename(_selectedFile!.path),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.teal.shade700,
                    ),
                  ),
                ),
              ],
            ),
            if (_isImageFile())
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.file(
                    _selectedFile!,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isImageFile() {
    final ext = path.extension(_selectedFile!.path).toLowerCase();
    return ext.contains(RegExp(r'(jpg|jpeg|png)$'));
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Select Category',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.teal.shade400!),
        ),
        filled: true,
        fillColor: Colors.teal.shade50,
        prefixIcon: Icon(Icons.category, color: Colors.teal.shade700),
      ),
      items: _categories.map((category) => DropdownMenuItem(
        value: category,
        child: Text(category, style: TextStyle(color: Colors.teal.shade700)),
      )).toList(),
      validator: (value) => value == null ? 'Please select a category' : null,
      onChanged: (value) => setState(() => _selectedCategory = value),
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Add Description',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.teal.shade400!),
        ),
        filled: true,
        fillColor: Colors.teal.shade50,
        alignLabelWithHint: true,
      ),
      validator: (value) => value?.isEmpty ?? true
          ? 'Please enter a description'
          : null,
      maxLines: 3,
    );
  }

  Widget _buildFileSelectionButton() {
    return OutlinedButton.icon(
      onPressed: _selectedFile == null ? _showScanOptions : null,
      icon: Icon(Icons.upload_file, color: Colors.teal.shade700),
      label: Text(
        _selectedFile == null ? 'Select Document' : 'Replace Document',
        style: TextStyle(color: Colors.teal.shade700),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        side: BorderSide(color: Colors.teal.shade700!),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.teal.shade50,
      ),
    );
  }

  Widget _buildUploadButton() {
    return ElevatedButton(
      onPressed: _isUploading ? null : _uploadDocument,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        backgroundColor: Colors.teal.shade700,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
        elevation: 2,
      ),
      child: _isUploading
          ? const CircularProgressIndicator(color: Colors.white)
          : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_upload, color: Colors.white),
          const SizedBox(width: 12),
          const Text(
            'Upload Document',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}