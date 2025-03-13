import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../models/car_model.dart';
import 'package:logger/logger.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final NotificationService _notificationService = NotificationService();
  final logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );
  late Future<List<Car>> _carsFuture;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _refreshCars();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      final hasPermission = await _notificationService.requestUserPermission(context);
      if (hasPermission) {
        await _notificationService.subscribeToUserNotifications(widget.userId);
        await _refreshUnreadCount();
      } else {
        logger.w('User denied notification permissions');
      }
    } catch (e) {
      logger.e('Error initializing notifications: $e');
    }
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final notifications = await _notificationService.getNotifications(widget.userId);
      if (mounted) {
        setState(() {
          _unreadNotifications = notifications.where((n) => !n.isRead).length;
        });
      }
    } catch (e) {
      logger.e('Error refreshing unread count: $e');
    }
  }

  Future<void> _refreshCars() async {
    logger.i('Refreshing cars for user: ${widget.userId}');
    setState(() {
      _carsFuture = _supabaseService.getUserCars(widget.userId);
    });
  }

  Future<void> _signOut() async {
    try {
      await _supabaseService.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleVehicleInfo() async {
    try {
      logger.i('Fetching cars for vehicle info display');
      final cars = await _carsFuture;
      logger.d('Found ${cars.length} cars');

      if (!mounted) return;

      if (cars.isNotEmpty) {
        logger.i('Displaying info for car: ${cars.first.brand} ${cars.first.model}');
        Navigator.pushNamed(
          context,
          '/added_vehicle_screen',
          arguments: cars.first.toJson(),
        );
      } else {
        logger.w('No vehicles found for user');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No vehicles found. Please add a vehicle first."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      logger.e('Error displaying vehicle info: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading vehicle info: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFeatureButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.28,
        height: 90,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF009688),
              const Color(0xFF00796B),
              Colors.teal.shade900,
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onPressed,
            splashColor: Colors.tealAccent.withOpacity(0.3),
            highlightColor: Colors.tealAccent.withOpacity(0.1),
            child: Tooltip(
              message: tooltip,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 28, color: Colors.white),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.teal.shade50],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.teal.shade700, Colors.teal.shade900],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x29000000),
                      blurRadius: 6.0,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.teal,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "AutoVista",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Stack(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.notifications_active_outlined, color: Colors.white),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  '/notifications',
                                  arguments: widget.userId,
                                ).then((_) => _refreshUnreadCount());
                              },
                              tooltip: "Notifications",
                              iconSize: 24,
                            ),
                            if (_unreadNotifications > 0)
                              Positioned(
                                right: 6,
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    _unreadNotifications.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          onPressed: () {
                            _refreshCars();
                            _refreshUnreadCount();
                          },
                          tooltip: "Refresh data",
                          iconSize: 24,
                        ),
                        Container(
                          height: 32,
                          width: 1,
                          color: Colors.white.withOpacity(0.3),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: Colors.white),
                          onPressed: _signOut,
                          tooltip: "Log Out",
                          iconSize: 24,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Welcome Section
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      "Welcome to AutoVista!",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF004D40),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.teal.withOpacity(0.1),
                            blurRadius: 4.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        "Your one-stop solution for managing your vehicles.",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.teal.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Menu Grid
              Expanded(
                child: GridView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0, // Make buttons square
                  ),
                  children: [
                    _buildFeatureButton(
                      icon: Icons.directions_car_filled_outlined,
                      label: "Vehicle",
                      tooltip: "Edit Vehicle Information",
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/viewVehicle',
                          arguments: widget.userId,
                        );
                      },
                    ),
                    _buildFeatureButton(
                      icon: Icons.event_available_outlined,
                      label: "Events",
                      tooltip: "Event Manager",
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/eventManager',
                          arguments: widget.userId,
                        );
                      },
                    ),
                    _buildFeatureButton(
                      icon: Icons.local_parking_outlined,
                      label: "Parking",
                      tooltip: "Parking",
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/parking_screen',
                          arguments: widget.userId,
                        );
                      },
                    ),
                    _buildFeatureButton(
                      icon: Icons.document_scanner_outlined,
                      label: "Scanner",
                      tooltip: "Document Scanner",
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/document_screen',
                          arguments: widget.userId,
                        );
                      },
                    ),
                    _buildFeatureButton(
                      icon: Icons.info_outline_rounded,
                      label: "Info",
                      tooltip: "View Vehicle Info",
                      onPressed: _handleVehicleInfo,
                    ),
                    _buildFeatureButton(
                      icon: Icons.person_outline_rounded,
                      label: "Profile",
                      tooltip: "Profile",
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/profile_screen',
                          arguments: widget.userId,
                        );
                      },
                    ),
                    _buildFeatureButton(
                      icon: Icons.emergency_outlined,
                      label: "Emergency",
                      tooltip: "Emergency Contacts",
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/emergency_contacts',
                          arguments: widget.userId,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}