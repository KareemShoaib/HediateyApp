import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'update_profile.dart'; // Import UpdateProfilePage

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get the currently logged-in user's email
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
          // Email Section
          const SizedBox(height: 16),
          Center(
            child: Text(
              email, // Display the dynamic email
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
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
              // Navigate to UpdateProfilePage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UpdateProfilePage()),
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
              // Navigate to notification settings screen
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
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3, // Replace with the actual number of events
            itemBuilder: (context, index) {
              return Card(
                color: Colors.deepPurple[700],
                child: ListTile(
                  title: Text(
                    "Event ${index + 1}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    "Associated Gifts: 2",
                    style: TextStyle(color: Colors.white70),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                  onTap: () {
                    // Navigate to the event details page
                    print("Event ${index + 1} tapped");
                  },
                ),
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
              // Navigate to My Pledged Gifts Page
              print("My Pledged Gifts tapped");
            },
          ),
        ],
      ),
      backgroundColor: Colors.deepPurple[900],
    );
  }
}
