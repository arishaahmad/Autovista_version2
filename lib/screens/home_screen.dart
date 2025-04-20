import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';
import '../models/car_model.dart';
import 'package:logger/logger.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart' as awesome;

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

  // Dashboard state
  final Map<String, dynamic> _carStats = {
    'engineRpm': 1250,
    'oilPressure': 45,
    'fuelPressure': 40,
    'coolantPressure': 15,
    'oilTemp': 95,
    'coolantTemp': 87,
    'engineCondition': 'Good',
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshCars();
    _initializeNotifications();
    _fetchCarStats();
  }

  Future<void> _fetchCarStats() async {
    // TODO: Replace with actual database fetch
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _initializeNotifications() async {
    try {
      final hasPermission =
      await _notificationService.requestUserPermission(context);
      if (hasPermission) {
        await _notificationService.subscribeToUserNotifications(widget.userId);
        await _refreshUnreadCount();

        // 🔥 FCM Setup for testing (foreground)
        final messaging = FirebaseMessaging.instance;

        await messaging.requestPermission();
        final token = await messaging.getToken();
        logger.i('🔑 FCM Token: $token');

        FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
          final title = message.notification?.title ?? 'Alert';
          final body = message.notification?.body ?? 'You received a message';

          logger.i('📥 Foreground message: $title');

          await awesome.AwesomeNotifications().createNotification(
            content: awesome.NotificationContent(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              channelKey: 'autovista_notifications',
              title: '🚨 $title',
              body: body,
              backgroundColor: Colors.red.shade900,
              color: Colors.white,
              notificationLayout: awesome.NotificationLayout.BigText,
              criticalAlert: true,
              wakeUpScreen: true,
              fullScreenIntent: true,
              autoDismissible: false,
              displayOnBackground: true,
              displayOnForeground: true,
              locked: true
            ),
            actionButtons: [
              awesome.NotificationActionButton(
                key: 'EMERGENCY_ACKNOWLEDGE',
                label: 'Acknowledge',
                color: Colors.red,
                autoDismissible: true,
              ),
            ],
          );
        });

      } else {
        logger.w('User denied notification permissions');
      }
    } catch (e) {
      logger.e('Error initializing notifications: $e');
    }
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final notifications =
          await _notificationService.getNotifications(widget.userId);
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
        logger.i(
            'Displaying info for car: ${cars.first.brand} ${cars.first.model}');
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

  Widget _buildVehicleHealthDashboard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.teal.shade600, Colors.teal.shade800],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.dashboard_rounded, color: Colors.white),
                const SizedBox(width: 8),
                const Text(
                  "Vehicle Health Monitor",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    _fetchCarStats();
                    setState(() => _isLoading = true);
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15)),
                    child: const Icon(Icons.refresh,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              height: 200,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(color: Colors.teal),
            )
          else
            Column(
              children: [
                _buildStatusRow(
                  icon: Icons.speed,
                  title: "Engine Status",
                  children: [
                    _buildStatusItem(
                      "RPM",
                      "${_carStats['engineRpm']}",
                      Icons.speed_rounded,
                      _getHealthColor(_carStats['engineRpm'], 800, 2000),
                    ),
                    _buildStatusItem(
                        "Health",
                        _carStats['engineCondition'],
                        Icons.health_and_safety,
                        _carStats['engineCondition'] == 'Good'
                            ? Colors.green
                            : Colors.orange),
                  ],
                ),
                _buildStatusRow(
                  icon: Icons.thermostat,
                  title: "Temperature",
                  children: [
                    _buildStatusItem(
                        "Oil Temp",
                        "${_carStats['oilTemp']}°C",
                        Icons.oil_barrel,
                        _getHealthColor(_carStats['oilTemp'], 80, 110)),
                    _buildStatusItem(
                        "Coolant",
                        "${_carStats['coolantTemp']}°C",
                        Icons.water_drop,
                        _getHealthColor(_carStats['coolantTemp'], 70, 100)),
                  ],
                ),
                _buildStatusRow(
                  icon: Icons.compress,
                  title: "System Pressure",
                  children: [
                    _buildStatusItem(
                        "Oil",
                        "${_carStats['oilPressure']} PSI",
                        Icons.oil_barrel,
                        _getHealthColor(_carStats['oilPressure'], 30, 60)),
                    _buildStatusItem(
                        "Fuel",
                        "${_carStats['fuelPressure']} PSI",
                        Icons.local_gas_station,
                        _getHealthColor(_carStats['fuelPressure'], 35, 45)),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(
      {required IconData icon,
      required String title,
      required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.teal.shade800, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                    color: Colors.teal.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
            ],
          ),
          const Divider(),
          Row(children: children),
        ],
      ),
    );
  }

  Widget _buildStatusItem(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                Text(value,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getHealthColor(dynamic value, double min, double max) {
    if (value is num) {
      if (value < min) return Colors.red;
      if (value > max) return Colors.orange;
      return Colors.green;
    }
    return Colors.grey;
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Custom App Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
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
                                icon: const Icon(
                                    Icons.notifications_active_outlined,
                                    color: Colors.white),
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
                            icon: const Icon(Icons.refresh_rounded,
                                color: Colors.white),
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
                            icon: const Icon(Icons.logout_rounded,
                                color: Colors.white),
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
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF004D40),
                                ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.teal.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                // Vehicle Health Dashboard
                _buildVehicleHealthDashboard(),

                // Main Menu Grid
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  child: GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.0,
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

                      //5-4-2025
                      _buildFeatureButton(
                        icon: Icons.file_present_outlined,
                        label: "Maintenance",
                        tooltip: "Maintenance Logs",
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/maintenance_logs',
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
                      _buildFeatureButton(
                        icon: Icons.help_outline_rounded,
                        label: "Car Help",
                        tooltip: "Vehicle Help & FAQs",
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/faq_screen',
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
      ),
    );
  }
}
