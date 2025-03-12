import 'package:autovista/screens/document_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/view_vehicle_screen.dart';
import 'screens/event_manager_screen.dart';
import 'screens/document_screen.dart';
import 'screens/parking_screen.dart';
import 'screens/added_vehicle.dart';
import 'screens/notifications_screen.dart';
import 'services/notification_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url:
        'https://qmxoticuvkdmeyteyvaa.supabase.co', // Replace with your Supabase URL
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFteG90aWN1dmtkbWV5dGV5dmFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzU5MjM4MzQsImV4cCI6MjA1MTQ5OTgzNH0.pwmB8VjrNKdBMdG8mvB5D_Ke4u-ONCk9rMMbrs3mKfE', // Replace with your Supabase anon key
  );

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const AutoVistaApp());
}

class AutoVistaApp extends StatelessWidget {
  const AutoVistaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AutoVista',
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/signup':
            return MaterialPageRoute(builder: (_) => const SignupScreen());
          case '/home':
            final userId = settings.arguments as String;
            return MaterialPageRoute(
                builder: (_) => HomeScreen(userId: userId));
          case '/profile_screen':
            final userId = settings.arguments as String;
            return MaterialPageRoute(
                builder: (_) => ProfileScreen(userId: userId));
          case '/viewVehicle':
            final userId = settings.arguments as String;
            return MaterialPageRoute(
                builder: (_) => ViewVehicleScreen(userId: userId));
          case '/eventManager':
            return MaterialPageRoute(
                builder: (_) => const CalendarFuelScreen());
          case '/document_screen':
            final userId = settings.arguments as String;
            return MaterialPageRoute(
                builder: (_) => ScanDocumentScreen(userId: userId));
          case '/parking_screen':
            final userId = settings.arguments as String;
            return MaterialPageRoute(
                builder: (_) => ParkingScreen(userId: userId));
          case '/added_vehicle_screen':
            final vehicleData = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
                builder: (_) => AddedVehicleScreen(vehicleData: vehicleData));
          case '/uploaded_documents':
            final userId = settings.arguments as String;
            return MaterialPageRoute(
                builder: (_) => DocumentListScreen(userId: userId));
          case '/notifications':
            final userId = settings.arguments as String;
            return MaterialPageRoute(builder: (_) => NotificationsScreen(userId: userId));
          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );
  }
}
