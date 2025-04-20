import 'package:autovista/screens/document_list_screen.dart';
import 'package:autovista/screens/emergency_contacts_screen.dart';
import 'package:autovista/screens/faq_screen.dart'; // Added import
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
import 'screens/ocr_Scan.dart';
import 'screens/maintenance_log_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart'; // generated later
import 'services/firebase_background_handler.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await Supabase.initialize(
    url: 'https://qmxoticuvkdmeyteyvaa.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFteG90aWN1dmtkbWV5dGV5dmFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzU5MjM4MzQsImV4cCI6MjA1MTQ5OTgzNH0.pwmB8VjrNKdBMdG8mvB5D_Ke4u-ONCk9rMMbrs3mKfE',
  );

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
      home: Supabase.instance.client.auth.currentUser != null
          ? HomeScreen(userId: Supabase.instance.client.auth.currentUser!.id)
          : const LoginScreen(),
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/ocr_screen':
            return MaterialPageRoute(builder: (_) => const OcrScanScreen());
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
            final userId = settings.arguments as String;
            return MaterialPageRoute(
                builder: (_) => CalendarFuelScreen(userId: userId));
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
          case '/emergency_contacts':
            final userId = settings.arguments as String;
            return MaterialPageRoute(
                builder: (_) => EmergencyContactsScreen(userId: userId));
          case '/faq_screen':  // New route
            return MaterialPageRoute(builder: (_) => FAQScreen());

          case '/maintenance_logs':
            final userId = settings.arguments as String;
            return MaterialPageRoute(
                builder: (_) => MaintenanceLogsScreen(userId: userId)
            );



          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );
  }
}