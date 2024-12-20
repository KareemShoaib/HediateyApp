import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:overlay_support/overlay_support.dart';
import 'login_page.dart';
import 'database_helper.dart';

// Handles background messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Background Message received: ${message.notification?.title}, ${message.notification?.body}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDatabase();
  await Firebase.initializeApp();

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Print the FCM token
  await printFCMToken();

  runApp(const MyApp());
}

Future<void> initializeDatabase() async {
  final dbHelper = DatabaseHelper.instance;
  await dbHelper.database;
  print('Database initialized successfully.');
}

Future<void> printFCMToken() async {
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request notification permissions
    NotificationSettings settings = await messaging.requestPermission();

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permission.');
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('User denied notification permission.');
    }

    // Fetch and print the FCM token
    String? token = await messaging.getToken();
    if (token != null) {
      print('FCM Token: $token');
    } else {
      print('Failed to retrieve FCM Token.');
    }
  } catch (e) {
    print('Error retrieving FCM Token: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData.dark(),
        home: const NotificationHandler(child: LoginScreen()),
      ),
    );
  }
}

// Widget to handle FCM notifications
class NotificationHandler extends StatefulWidget {
  final Widget child;

  const NotificationHandler({super.key, required this.child});

  @override
  _NotificationHandlerState createState() => _NotificationHandlerState();
}

class _NotificationHandlerState extends State<NotificationHandler> {
  @override
  void initState() {
    super.initState();

    // Handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showSimpleNotification(
        Text(
          message.notification?.title ?? "No Title",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: Text(
          message.notification?.body ?? "No Body",
          style: const TextStyle(color: Colors.white70),
        ),
        background: Colors.blue,
        duration: const Duration(seconds: 4),
      );

      print("Foreground Message received: ${message.notification?.title}, ${message.notification?.body}");
    });

    // Handle notification tap while app is in the background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification tapped: ${message.notification?.title}, ${message.notification?.body}");
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
