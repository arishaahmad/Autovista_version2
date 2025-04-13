import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../models/notification_model.dart';
import '../services/supabase_service.dart';

//13-4-2024
//updated to support redirection from maintenance_log_screen
class CalendarFuelScreen extends StatefulWidget {
  final String? userId;
  final NotificationModel? notification;
  final String? initialEventTitle;
  final String? initialEventDescription;
  final String? initialEventType;

  const CalendarFuelScreen({
    super.key,
    this.userId,
    this.notification,
    this.initialEventTitle,
    this.initialEventDescription,
    this.initialEventType,
  });

  @override
  State<CalendarFuelScreen> createState() => _CalendarFuelScreenState();
}

class _CalendarFuelScreenState extends State<CalendarFuelScreen> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late Map<DateTime, List<Event>> _events;
  List<Event> _upcomingEvents = [];
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
    _focusedDay = widget.notification?.createdAt ?? DateTime.now();
    _selectedDay = _focusedDay;
    _events = {};

    // Handle initial data from maintenance log
    if (widget.initialEventTitle != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _prefillAndShowDialog();
      });
    }
    // Existing notification handling
    else if (widget.notification != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddEventDialog(prefillData: true);
      });
    }
  }

  void _prefillAndShowDialog() {
    _titleController.text = widget.initialEventTitle!;
    _descriptionController.text = widget.initialEventDescription ?? '';
    _selectedEventType = widget.initialEventType ?? 'Maintenance';
    _showAddEventDialog(prefillData: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload events when the screen is revisited
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    if (widget.userId == null) return;
    try {
      final events = await _supabaseService.getUserEvents(widget.userId!);
      setState(() {
        _events = {};
        for (var event in events) {
          final date =
          DateTime(event.date.year, event.date.month, event.date.day);
          _events[date] = [..._events[date] ?? [], event];
        }

        // Update upcoming events list
        _updateUpcomingEvents(events);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error loading events: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _updateUpcomingEvents(List<Event> allEvents) {
    final now = DateTime.now();
    // Filter events that are today or in the future
    final futureEvents = allEvents
        .where((event) =>
        event.date.isAfter(DateTime(now.year, now.month, now.day - 1)))
        .toList();

    // Sort events by date
    futureEvents.sort((a, b) => a.date.compareTo(b.date));

    // Take only the next 4 events
    _upcomingEvents = futureEvents.take(4).toList();
  }

  List<Event> _getEventsForDay(DateTime day) => _events[day] ?? [];

  Future<void> _showAddEventDialog({bool prefillData = false}) async {
    DateTime selectedEventDate = _selectedDay;
    TimeOfDay? selectedReminderTime;

    if (prefillData) {
      if (widget.initialEventTitle != null) {
        // Prefill from maintenance log flow
        _titleController.text = widget.initialEventTitle!;
        _descriptionController.text = widget.initialEventDescription ?? '';
        _selectedEventType = widget.initialEventType ?? 'Maintenance';
      } else if (widget.notification != null) {
        // Existing notification prefill
        _titleController.text = widget.notification!.title;
        _descriptionController.text = widget.notification!.body;
        _selectedEventType = _mapNotificationType(widget.notification!.type);
      }
    } else {
      // Clear all fields for new event
      _titleController.clear();
      _descriptionController.clear();
      _fuelNeededController.clear();
      _locationController.clear();
      _reminderTimeController.clear();
      _notesController.clear();
      _selectedEventType = 'Maintenance';
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Event Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedEventType,
                decoration: const InputDecoration(
                  labelText: 'Event Type',
                  border: OutlineInputBorder(),
                ),
                items: _eventTypes
                    .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedEventType = value!),
              ),
              const SizedBox(height: 20),

              // Event Date Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Event Date'),
                subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedEventDate)),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedEventDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (pickedDate != null) {
                    setState(() => selectedEventDate = pickedDate);
                  }
                },
              ),
              const SizedBox(height: 15),

              // Title Field
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // Description Field
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 15),

              // Fuel Needed Field (conditional)
              if (_selectedEventType == 'Fuel')
                Column(
                  children: [
                    TextField(
                      controller: _fuelNeededController,
                      decoration: const InputDecoration(
                        labelText: 'Fuel Amount (L)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 15),
                  ],
                ),

              // Location Field
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 15),

              // Reminder Time Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: const Text('Reminder Time (Optional)'),
                subtitle: Text(selectedReminderTime?.format(context) ?? 'Not set'),
                onTap: () async {
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() => selectedReminderTime = pickedTime);
                  }
                },
              ),
              const SizedBox(height: 15),

              // Notes Field
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                ),
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
              // Update event creation with selected date
              final newEvent = Event(
                userId: widget.userId!,
                title: _titleController.text,
                description: _descriptionController.text,
                date: selectedEventDate, // Use selected date
                eventType: _selectedEventType,
                fuelNeeded: _selectedEventType == 'Fuel'
                    ? double.tryParse(_fuelNeededController.text)
                    : null,
                location: _locationController.text.isNotEmpty
                    ? _locationController.text
                    : null,
                reminderTime: selectedReminderTime?.format(context),
                notes: _notesController.text.isNotEmpty
                    ? _notesController.text
                    : null,
              );

              try {
                await _supabaseService.createEvent(newEvent);
                if (!mounted) return;
                Navigator.pop(context);
                _loadEvents();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }


  String _mapNotificationType(String notificationType) {
    switch (notificationType) {
      case 'document_expiry':
        return 'License';
      case 'maintenance':
        return 'Maintenance';
      case 'system':
        return 'Other';
      default:
        return 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Manager')),
      body: Column(
        children: [
          // Calendar widget
          TableCalendar<Event>(
            firstDay: DateTime.utc(2020),
            lastDay: DateTime.utc(2030),
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
            onPageChanged: (focusedDay) => _focusedDay = focusedDay,
          ),
          const SizedBox(height: 16),

          // Upcoming events section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Upcoming Events',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Upcoming events list - vertical list with swipe to delete
          Expanded(
            child: _upcomingEvents.isEmpty
                ? const Center(
              child: Text('No upcoming events'),
            )
                : ListView.builder(
              itemCount: _upcomingEvents.length,
              itemBuilder: (context, index) {
                final event = _upcomingEvents[index];
                return Dismissible(
                  key: Key(event.id?.toString() ?? 'temp-$index'),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  direction:
                  DismissDirection.endToStart, // Right to left swipe
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Event'),
                        content: const Text(
                            'Are you sure you want to delete this event?'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(context).pop(true),
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) async {
                    try {
                      await _supabaseService.deleteEvent(event.id!);
                      setState(() {
                        _upcomingEvents.removeAt(index);
                      });
                      _loadEvents(); // Refresh all events
                      if (!mounted) return;
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
                          content: Text('Error deleting event: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _getEventTypeColor(event.eventType),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            _getEventTypeIcon(event.eventType),
                            color: Colors.white,
                          ),
                        ),
                      ),
                      title: Text(
                        event.title,
                        style:
                        const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM d, yyyy').format(event.date),
                            style: TextStyle(
                              color: _getDateColor(event.date),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () => _showEventDetails(event),
                    ),
                  ),
                );
              },
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

  Color _getEventTypeColor(String eventType) {
    switch (eventType) {
      case 'Maintenance':
        return Colors.blue;
      case 'Fuel':
        return Colors.green;
      case 'Service':
        return Colors.orange;
      case 'Insurance':
        return Colors.purple;
      case 'License':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventTypeIcon(String eventType) {
    switch (eventType) {
      case 'Maintenance':
        return Icons.build;
      case 'Fuel':
        return Icons.local_gas_station;
      case 'Service':
        return Icons.handyman;
      case 'Insurance':
        return Icons.policy;
      case 'License':
        return Icons.card_membership;
      default:
        return Icons.event;
    }
  }

  Color _getDateColor(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final eventDate = DateTime(date.year, date.month, date.day);

    if (eventDate.isBefore(today)) {
      return Colors.red; // Past events
    } else if (eventDate.isAtSameMomentAs(today)) {
      return Colors.orange; // Today's events
    } else if (eventDate.isAtSameMomentAs(tomorrow)) {
      return Colors.amber.shade700; // Tomorrow's events
    } else if (eventDate.difference(today).inDays <= 7) {
      return Colors.blue; // This week's events
    } else {
      return Colors.grey; // Events further in the future
    }
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
              if (event.location != null && event.location!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Location: ${event.location}'),
              ],
              if (event.reminderTime != null &&
                  event.reminderTime!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Reminder: ${event.reminderTime}'),
              ],
              if (event.notes != null && event.notes!.isNotEmpty) ...[
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
                    content: Text('Error deleting event: $e'),
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
