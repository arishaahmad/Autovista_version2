// 5-4-2025

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdfx/pdfx.dart';
import 'package:printing/printing.dart';
import '../services/supabase_service.dart';
import '../models/maintenance_log_model.dart';
import 'dart:io';
import 'event_manager_screen.dart';

class MaintenanceLogsScreen extends StatefulWidget {
  final String userId;
  const MaintenanceLogsScreen({super.key, required this.userId});
  @override
  State<MaintenanceLogsScreen> createState() => _MaintenanceLogsScreenState();
}

class _MaintenanceLogsScreenState extends State<MaintenanceLogsScreen> {
  final svc = SupabaseService();
  late Future<List<MaintenanceLog>> logsFuture;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  void _loadLogs() {
    logsFuture = svc.fetchMaintenanceLogs(widget.userId)
        .then((list) => list.map((e) => MaintenanceLog.fromJson(e)).toList());
  }

  // Inside _MaintenanceLogsScreenState
  Future<void> _upload() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (res != null) {
      final file = res.files.single;
      final bytes = file.bytes ?? await File(file.path!).readAsBytes();
      final name = file.name;
      await svc.uploadMaintenanceLog(widget.userId, name, bytes);
      setState(() => _loadLogs());
      // Show prompt to add event
      _showAddEventPrompt(name);
    }
  }

  // Add this new method
  void _showAddEventPrompt(String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Related Event?'),
        content: const Text('Would you like to create a maintenance event tied to this log?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No Thanks'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CalendarFuelScreen(
                    userId: widget.userId,
                    initialEventTitle: 'Maintenance: $fileName',
                    initialEventDescription: 'Related to maintenance log: $fileName',
                    initialEventType: 'Maintenance',
                  ),
                ),
              );
            },
            child: const Text('Yes, Add Event'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Maintenance Logs'),
      actions: [
        IconButton(
          icon: const Icon(Icons.upload_file),
          onPressed: _upload,
        )
      ],
    ),
    body: FutureBuilder<List<MaintenanceLog>>(
      future: logsFuture,
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }
        final logs = snap.data!;
        if (logs.isEmpty) {
          return const Center(child: Text('No logs found'));
        }
        return ListView.builder(
          itemCount: logs.length,
          itemBuilder: (_, i) {
            final log = logs[i];
            return ListTile(
              title: Text(log.fileName),
              subtitle: Text(log.createdAt.toLocal().toString()),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'view') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PdfViewScreen(path: log.filePath),
                      ),
                    );
                  } else if (v == 'print') {
                    final data = await svc.supabase.storage
                        .from('maintenance-logs')
                        .download(log.filePath);
                    // ensure Uint8List
                    final pdfData = Uint8List.fromList(data);
                    await Printing.layoutPdf(
                        onLayout: (_) => pdfData);
                  } else if (v == 'delete') {
                    // **Fix #1**: pass all three arguments
                    await svc.deleteMaintenanceLog(
                      widget.userId,
                      log.id,
                      log.filePath,
                    );
                    setState(_loadLogs);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'view', child: Text('View')),
                  PopupMenuItem(value: 'print', child: Text('Print')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            );
          },
        );
      },
    ),
  );
}

class PdfViewScreen extends StatefulWidget {
  final String path;
  const PdfViewScreen({super.key, required this.path});
  @override
  State<PdfViewScreen> createState() => _PdfViewScreenState();
}

class _PdfViewScreenState extends State<PdfViewScreen> {
  PdfControllerPinch? controller;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final svc = SupabaseService();
    final data = await svc.supabase.storage
        .from('maintenance-logs')
        .download(widget.path);

    controller = PdfControllerPinch(
      document: PdfDocument.openData(Uint8List.fromList(data)),
    );
    setState(() => loading = false);
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('View PDF')),
    body: loading
        ? const Center(child: CircularProgressIndicator())

        : PdfViewPinch(controller: controller!),
  );
}


