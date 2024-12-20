import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'home_page.dart';
import 'event_list.dart';
import 'gift_page.dart';
import 'search_people.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String firstName = '';
  String profileImagePath = ''; // Store local path for the image
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            firstName = doc.data()?['firstName'] ?? 'User';
            profileImagePath = doc.data()?['profileImagePath'] ?? '';
          });
        }
      }
    } catch (e) {
      setState(() {
        firstName = 'User';
      });
    }
  }

  Future<void> _pickAndSaveImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });

        final user = _auth.currentUser;

        if (user != null) {
          // Save the local path to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'profileImagePath': pickedFile.path});

          // Update the state with the new path
          setState(() {
            profileImagePath = pickedFile.path;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated successfully!')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select image: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple[900],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
            );
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
            // Profile Picture
            GestureDetector(
              onTap: _pickAndSaveImage,
              child: CircleAvatar(
                key: ValueKey(profileImagePath), // Force rebuild when path changes
                radius: 60,
                backgroundImage: profileImagePath.isNotEmpty
                    ? FileImage(File(profileImagePath))
                    : const NetworkImage('https://cdn.pixabay.com/photo/2023/02/18/11/00/icon-7797704_960_720.png') as ImageProvider,
                child: profileImagePath.isEmpty
                    ? const Icon(Icons.camera_alt, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tap to change profile picture',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // Welcome Message
            Text(
              'Welcome $firstName',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Search for People Button
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchPeoplePage()),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.deepPurple[700],
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.search, color: Colors.white),
              label: const Text(
                'Search for People',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),

            // Friends List Button
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.deepPurple[700],
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.person, color: Colors.white),
              label: const Text(
                'Friends List',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),

            // Event List Button
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EventListPage()),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.deepPurple[700],
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.event, color: Colors.white),
              label: const Text(
                'Your Event List',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),

            // Gift List Button
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GiftPage()),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.deepPurple[700],
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.card_giftcard, color: Colors.white),
              label: const Text(
                'Your Gift List',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
