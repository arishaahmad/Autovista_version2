import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_contact_model.dart';
import '../services/supabase_service.dart';

class EmergencyContactsScreen extends StatefulWidget {
  final String userId;

  const EmergencyContactsScreen({super.key, required this.userId});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  late Future<List<EmergencyContact>> _contactsFuture;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshContacts();
  }

  void _refreshContacts() {
    setState(() {
      _contactsFuture = _supabaseService.getEmergencyContacts(widget.userId);
    });
  }

  Future<void> _showEditContactDialog(EmergencyContact contact) async {
    _nameController.text = contact.contactName;
    _phoneController.text = contact.contactNumber;

    await showDialog(
      context: context,
      builder: (context) => _buildContactDialog(
        isEdit: true,
        onSave: () async {
          if (_formKey.currentState!.validate()) {
            final updatedContact = EmergencyContact(
              id: contact.id,
              userId: contact.userId,
              contactName: _nameController.text,
              contactNumber: _phoneController.text,
              createdAt: contact.createdAt,
              updatedAt: DateTime.now(),
            );

            try {
              await _supabaseService.updateEmergencyContact(updatedContact);
              if (!mounted) return;
              Navigator.pop(context);
              _refreshContacts();
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error updating contact: $e')),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildContactDialog({
    required bool isEdit,
    required VoidCallback onSave,
  }) {
    return AlertDialog(
      title: Text(isEdit ? 'Edit Contact' : 'Add New Contact'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: onSave,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      await launchUrl(launchUri);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch phone: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshContacts,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
        onPressed: () async {
          _nameController.clear();
          _phoneController.clear();

          await showDialog(
            context: context,
            builder: (context) => _buildContactDialog(
              isEdit: false,
              onSave: () async {
                if (_formKey.currentState!.validate()) {
                  final newContact = EmergencyContact(
                    id: '',
                    userId: widget.userId,
                    contactName: _nameController.text,
                    contactNumber: _phoneController.text,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );

                  try {
                    await _supabaseService.addEmergencyContact(newContact);
                    if (!mounted) return;
                    Navigator.pop(context);
                    _refreshContacts();
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding contact: $e')),
                    );
                  }
                }
              },
            ),
          );
        },
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
        ),
        child: FutureBuilder<List<EmergencyContact>>(
          future: _contactsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.red));
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final contacts = snapshot.data!;

            if (contacts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.contact_phone, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text(
                      'No emergency contacts added',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap + to add your first contact',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            // Group contacts alphabetically
            contacts.sort((a, b) => a.contactName.compareTo(b.contactName));

            return ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                final firstLetter = contact.contactName[0].toUpperCase();
                final showDivider = index == 0 ||
                    contacts[index - 1].contactName[0].toUpperCase() != firstLetter;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDivider)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Text(
                          firstLetter,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade800,
                          ),
                        ),
                      ),
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      elevation: 2,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.shade100,
                          child: Text(
                            contact.contactName[0].toUpperCase(),
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          contact.contactName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(contact.contactNumber),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.call, color: Colors.green.shade700),
                              onPressed: () => _makePhoneCall(contact.contactNumber),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue.shade700),
                              onPressed: () => _showEditContactDialog(contact),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red.shade700),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Contact'),
                                    content: Text(
                                        'Are you sure you want to delete ${contact.contactName}?'
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  try {
                                    await _supabaseService.deleteEmergencyContact(contact.id);
                                    _refreshContacts();
                                  } catch (e) {
                                    if (!mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error deleting contact: $e')),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}