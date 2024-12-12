import 'package:flutter/material.dart';
import 'dart:convert';
import 'login_page.dart';
import 'profile_page.dart'; // Import profile.dart
import 'main.dart';
import 'home_page.dart';
import 'event_list.dart'; // Import the Event List Page
import 'gift_page.dart'; // Import the Gift Page

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hediatey',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark, // Use dark theme
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  // Base64 image string
  final String base64Image =
      'data:image/png;base64,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';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[900], // Dark purple background
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyApp()),
            ); // Go back to the previous screen (login)
          },
        ),
        title: const Text('Hediatey'),
        backgroundColor: Colors.deepPurple[800],
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            iconSize: 30.0,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.memory(
              base64Decode(base64Image.split(',')[1]), // Decode the base64 string
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              'Welcome User',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white, // White text
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.deepPurple[700], // Button background color
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(
                Icons.person,
                color: Colors.white,
              ),
              label: const Text(
                'Friends List',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EventListPage()),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.deepPurple[700], // Button background color
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(
                Icons.event,
                color: Colors.white,
              ),
              label: const Text(
                'Your Event List',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GiftPage()),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.deepPurple[700], // Button background color
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(
                Icons.card_giftcard,
                color: Colors.white,
              ),
              label: const Text(
                'Your Gift List',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
