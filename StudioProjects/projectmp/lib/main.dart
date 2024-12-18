import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'login_page.dart';
import 'database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDatabase();
  await Firebase.initializeApp();
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
    // Request permissions (only necessary on iOS)
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();

    // Fetch and print the token
    String? token = await FirebaseMessaging.instance.getToken();
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
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark(),
      home: const LoginScreen(),
    );
  }
}
