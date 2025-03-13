import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/document_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class DocumentListScreen extends StatefulWidget {
  final String? userId;

  const DocumentListScreen({super.key, this.userId});

  @override
  State<DocumentListScreen> createState() => _DocumentListScreenState();
}

class _DocumentListScreenState extends State<DocumentListScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<Document> _documents = [];
  bool _isLoading = true;
  String? _selectedFilter;
  String? _errorMessage;

  final List<String> _categoryFilters = [
    'All Documents',
    'Vehicle Registration',
    'Insurance Document',
    'Maintenance Record',
    'Other Document',
  ];

  @override
  void initState() {
    super.initState();
    _selectedFilter = _categoryFilters[0]; // Default to "All Documents"
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    if (widget.userId == null) {
      setState(() {
        _errorMessage = 'User ID is required';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final docs = await _supabaseService.getUserDocuments(widget.userId!);
      setState(() {
        _documents = docs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load documents: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  List<Document> _getFilteredDocuments() {
    if (_selectedFilter == 'All Documents' || _selectedFilter == null) {
      return _documents;
    }

    // Convert from display name to database category format
    String dbCategory = _selectedFilter!.toLowerCase().replaceAll(' ', '_');
    return _documents.where((doc) => doc.category == dbCategory).toList();
  }

  Future<void> _viewDocument(Document document) async {
    if (document.fileUrl != null) {
      final url = Uri.parse(document.fileUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open the document'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteDocument(Document document) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Are you sure you want to delete "${document.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true && mounted) {
      setState(() => _isLoading = true);

      try {
        await _supabaseService.deleteDocument(widget.userId!, document.id);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Document deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );

        _loadDocuments(); // Refresh the list
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to delete document: ${e.toString()}';
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete document: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return 'Unknown size';

    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();

    while (size > 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }

    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  Icon _getFileTypeIcon(String fileType) {
    fileType = fileType.toLowerCase();

    if (fileType.contains('pdf')) {
      return const Icon(Icons.picture_as_pdf, color: Colors.red);
    } else if (fileType.contains('doc')) {
      return const Icon(Icons.description, color: Colors.blue);
    } else if (fileType.contains(RegExp(r'jpg|jpeg|png|gif'))) {
      return const Icon(Icons.image, color: Colors.green);
    } else {
      return const Icon(Icons.insert_drive_file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredDocs = _getFilteredDocuments();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDocuments,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedFilter,
                    hint: const Text('Filter by category'),
                    items: _categoryFilters.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedFilter = newValue;
                      });
                    },
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadDocuments,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            )
                : filteredDocs.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    _selectedFilter == 'All Documents'
                        ? 'No documents found'
                        : 'No $_selectedFilter found',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // This will take them back to the main screen where they can upload
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Upload New Document'),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: filteredDocs.length,
              padding: const EdgeInsets.all(8.0),
              itemBuilder: (context, index) {
                final document = filteredDocs[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ExpansionTile(
                    leading: _getFileTypeIcon(document.fileType ?? ''),
                    title: Text(
                      document.description,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${document.category?.replaceAll('_', ' ').capitalize() ?? 'Unknown category'} • ${_formatDate(document.createdAt)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (document.fileName != null) ...[
                              const Text(
                                'File name:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(document.fileName!),
                              const SizedBox(height: 8),
                            ],
                            Row(
                              children: [
                                if (document.fileType != null) ...[
                                  Text(
                                    'Type: ${document.fileType!.toUpperCase()}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                if (document.fileSize != null)
                                  Text(
                                    'Size: ${_formatFileSize(document.fileSize)}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  onPressed: () => _deleteDocument(document),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.visibility),
                                  label: const Text('View'),
                                  onPressed: () => _viewDocument(document),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
          // This will take them back to the main screen where they can upload
        },
        child: const Icon(Icons.add),
        tooltip: 'Upload New Document',
      ),
    );
  }
}

// Extension to capitalize first letter of string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}