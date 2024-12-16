import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'update_profile.dart';
import 'mypledgedgifts.dart';
import 'main.dart'; // Import MyApp for logout navigation

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get userId => _auth.currentUser?.uid;

  // Fetch user's events with gift count
  Stream<List<Map<String, dynamic>>> getUserEventsWithGiftCount() async* {
    if (userId == null) throw Exception("User not logged in");

    final eventSnapshots = await _firestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .get();

    List<Map<String, dynamic>> events = [];

    for (var doc in eventSnapshots.docs) {
      final eventId = doc.id;
      final eventData = doc.data();

      // Count the number of gifts for this event
      final giftCount = await _firestore
          .collection('users')
          .doc(userId)
          .collection('events')
          .doc(eventId)
          .collection('gifts')
          .get()
          .then((giftSnapshot) => giftSnapshot.size);

      events.add({
        'id': eventId,
        'name': eventData['name'] ?? 'Unnamed Event',
        'date': eventData['date'] ?? '',
        'giftCount': giftCount,
      });
    }

    yield events;
  }

  // Fetch user's first and last name
  Future<Map<String, String>> getUserName() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return {'firstName': 'Unknown', 'lastName': 'User'};

    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      final data = doc.data();
      return {
        'firstName': data?['firstName'] ?? 'Unknown',
        'lastName': data?['lastName'] ?? 'User',
      };
    }
    return {'firstName': 'Unknown', 'lastName': 'User'};
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirestoreService _firestoreService = FirestoreService();
    final User? user = FirebaseAuth.instance.currentUser;
    final String email = user?.email ?? "No email available";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.deepPurple[800],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Fetch and Display First and Last Name
          FutureBuilder<Map<String, String>>(
            future: _firestoreService.getUserName(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final firstName = snapshot.data?['firstName'] ?? 'Unknown';
              final lastName = snapshot.data?['lastName'] ?? 'User';

              return Column(
                children: [
                  Text(
                    "$firstName $lastName",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                ],
              );
            },
          ),

          const Divider(height: 32, color: Colors.white70),

          // Personal Information Section
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.white),
            title: const Text(
              "Update Personal Information",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UpdatePasswordPage()),
              );
            },
          ),

          // Notification Settings Section
          ListTile(
            leading: const Icon(Icons.notifications, color: Colors.white),
            title: const Text(
              "Notification Settings",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              print("Notification Settings tapped");
            },
          ),

          const Divider(height: 32, color: Colors.white70),

          // User Created Events Section
          const Text(
            "Your Created Events",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),

          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestoreService.getUserEventsWithGiftCount(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text("No events created."));
              }

              final events = snapshot.data!;

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Card(
                    color: Colors.deepPurple[700],
                    child: ListTile(
                      title: Text(
                        event['name'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        "Associated Gifts: ${event['giftCount']}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                      onTap: () {
                        print("${event['name']} tapped");
                      },
                    ),
                  );
                },
              );
            },
          ),

          const Divider(height: 32, color: Colors.white70),

          // Pledged Gifts Section
          ListTile(
            leading: const Icon(Icons.card_giftcard, color: Colors.white),
            title: const Text(
              "My Pledged Gifts",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PledgedGiftsPage()),
              );
            },
          ),

          const Divider(height: 32, color: Colors.white70),

          // Logout Button
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.white),
            title: const Text(
              "Logout",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MyApp()),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.deepPurple[900],
    );
  }
}
