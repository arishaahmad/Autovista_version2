import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../services/supabase_service.dart';

class CalendarFuelScreen extends StatefulWidget {
  final String? userId;

  const CalendarFuelScreen({super.key, this.userId});

  @override
  State<CalendarFuelScreen> createState() => _CalendarFuelScreenState();
}

class _CalendarFuelScreenState extends State<CalendarFuelScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late Map<DateTime, List<Event>> _events;
  final SupabaseService _supabaseService = SupabaseService();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _fuelNeededController = TextEditingController();
  final _locationController = TextEditingController();
  final _reminderTimeController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedEventType = 'Maintenance';

  final List<String> _eventTypes = [
    'Maintenance',
    'Fuel',
    'Service',
    'Insurance',
    'License',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _events = {};
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (widget.userId == null) return;

    try {
      final events = await _supabaseService.getUserEvents(widget.userId!);
      setState(() {
        _events = {};
        for (var event in events) {
          final date = DateTime(
            event.date.year,
            event.date.month,
            event.date.day,
          );
          if (_events[date] == null) _events[date] = [];
          _events[date]!.add(event);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading events: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    return _events[day] ?? [];
  }

  Future<void> _showAddEventDialog() async {
    _titleController.clear();
    _descriptionController.clear();
    _fuelNeededController.clear();
    _locationController.clear();
    _reminderTimeController.clear();
    _notesController.clear();
    _selectedEventType = 'Maintenance';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedEventType,
                decoration: const InputDecoration(labelText: 'Event Type'),
                items: _eventTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEventType = value!;
                  });
                },
              ),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              if (_selectedEventType == 'Fuel')
                TextField(
                  controller: _fuelNeededController,
                  decoration:
                      const InputDecoration(labelText: 'Fuel Amount (L)'),
                  keyboardType: TextInputType.number,
                ),
              TextField(
                controller: _locationController,
                decoration:
                    const InputDecoration(labelText: 'Location (Optional)'),
              ),
              TextField(
                controller: _reminderTimeController,
                decoration: const InputDecoration(
                    labelText: 'Reminder Time (Optional)'),
              ),
              TextField(
                controller: _notesController,
                decoration:
                    const InputDecoration(labelText: 'Notes (Optional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_titleController.text.isEmpty ||
                  _descriptionController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill in all required fields'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final newEvent = Event(
                userId: widget.userId!,
                title: _titleController.text,
                description: _descriptionController.text,
                date: _selectedDay,
                eventType: _selectedEventType,
                fuelNeeded: _fuelNeededController.text.isNotEmpty
                    ? double.parse(_fuelNeededController.text)
                    : null,
                location: _locationController.text.isNotEmpty
                    ? _locationController.text
                    : null,
                reminderTime: _reminderTimeController.text.isNotEmpty
                    ? _reminderTimeController.text
                    : null,
                notes: _notesController.text.isNotEmpty
                    ? _notesController.text
                    : null,
              );

              try {
                await _supabaseService.createEvent(newEvent);
                if (!mounted) return;
                Navigator.pop(context);
                _loadEvents();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Event added successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error adding event: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEventDetails(Event event) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type: ${event.eventType}'),
              const SizedBox(height: 8),
              Text('Description: ${event.description}'),
              const SizedBox(height: 8),
              Text('Date: ${DateFormat('yyyy-MM-dd').format(event.date)}'),
              if (event.fuelNeeded != null) ...[
                const SizedBox(height: 8),
                Text('Fuel Amount: ${event.fuelNeeded!.toStringAsFixed(2)} L'),
              ],
              if (event.location != null) ...[
                const SizedBox(height: 8),
                Text('Location: ${event.location}'),
              ],
              if (event.reminderTime != null) ...[
                const SizedBox(height: 8),
                Text('Reminder: ${event.reminderTime}'),
              ],
              if (event.notes != null) ...[
                const SizedBox(height: 8),
                Text('Notes: ${event.notes}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _supabaseService.deleteEvent(event.id!);
                if (!mounted) return;
                Navigator.pop(context);
                _loadEvents();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Event deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting event: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Manager'),
      ),
      body: Column(
        children: [
          TableCalendar<Event>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.monday,
            calendarStyle: const CalendarStyle(
              markersMaxCount: 3,
              markersAlignment: Alignment.bottomCenter,
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: _getEventsForDay(_selectedDay).map((event) {
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 4.0),
                  child: ListTile(
                    title: Text(event.title),
                    subtitle: Text(event.description),
                    trailing: Text(event.eventType),
                    onTap: () => _showEventDetails(event),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _fuelNeededController.dispose();
    _locationController.dispose();
    _reminderTimeController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
