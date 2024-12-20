import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io'; // Import this to use the File class

class SearchPeoplePage extends StatefulWidget {
  const SearchPeoplePage({super.key});

  @override
  State<SearchPeoplePage> createState() => _SearchPeoplePageState();
}

class _SearchPeoplePageState extends State<SearchPeoplePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = ''; // Holds the search query
  String sortOption = 'Alphabetically'; // Default sorting option

  // Function to add friends to each other
  Future<void> _addFriend(String currentUserId, String otherUserId) async {
    final currentUserRef = _firestore.collection('users').doc(currentUserId);
    final otherUserRef = _firestore.collection('users').doc(otherUserId);

    try {
      await currentUserRef.update({
        'friends': FieldValue.arrayUnion([otherUserId]),
      });

      await otherUserRef.update({
        'friends': FieldValue.arrayUnion([currentUserId]),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Friend added successfully!')),
      );
    } catch (e) {
      print('Error adding friends: $e');
    }
  }

  void _changeSortOption(String newOption) {
    setState(() {
      sortOption = newOption;
    });
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search People'),
        backgroundColor: Colors.deepPurple[800],
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            onSelected: _changeSortOption,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'Alphabetically',
                child: Text('Sort Alphabetically'),
              ),
              const PopupMenuItem(
                value: 'Friends First',
                child: Text('Sort Friends First'),
              ),
            ],
            icon: const Icon(Icons.sort),
          ),
        ],
      ),
      backgroundColor: Colors.deepPurple[900],
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No users found.',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          final users = snapshot.data!.docs.where((doc) {
            final userId = doc.id;
            return userId != currentUserId;
          }).toList();

          // Sort users based on the selected sort option
          if (sortOption == 'Alphabetically') {
            users.sort((a, b) {
              final nameA = ((a.data() as Map<String, dynamic>)['firstName'] ?? '')
                  .toString()
                  .toLowerCase();
              final nameB = ((b.data() as Map<String, dynamic>)['firstName'] ?? '')
                  .toString()
                  .toLowerCase();
              return nameA.compareTo(nameB);
            });
          } else if (sortOption == 'Friends First') {
            users.sort((a, b) {
              final friendsA = (a.data() as Map<String, dynamic>)['friends'] ?? [];
              final friendsB = (b.data() as Map<String, dynamic>)['friends'] ?? [];
              final isFriendA = friendsA.contains(currentUserId) ? 0 : 1;
              final isFriendB = friendsB.contains(currentUserId) ? 0 : 1;
              if (isFriendA == isFriendB) {
                final nameA = ((a.data() as Map<String, dynamic>)['firstName'] ?? '')
                    .toString()
                    .toLowerCase();
                final nameB = ((b.data() as Map<String, dynamic>)['firstName'] ?? '')
                    .toString()
                    .toLowerCase();
                return nameA.compareTo(nameB);
              }
              return isFriendA.compareTo(isFriendB);
            });
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>?;
              final otherUserId = users[index].id;

              final firstName = user?['firstName'] ?? 'Unknown';
              final lastName = user?['lastName'] ?? 'Unknown';
              final List friends = user?['friends'] ?? [];
              final profileImagePath = user?['profileImagePath']; // Path to the user's profile image

              final isAlreadyFriend = friends.contains(currentUserId);

              return Card(
                color: Colors.deepPurple[700],
                child: ListTile(
                  leading: profileImagePath != null && File(profileImagePath).existsSync()
                      ? CircleAvatar(
                    backgroundImage: FileImage(File(profileImagePath)),
                  )
                      : const CircleAvatar(
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    '$firstName $lastName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    isAlreadyFriend ? 'Already Friends' : 'Registered User',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: isAlreadyFriend
                      ? const Icon(Icons.check, color: Colors.green)
                      : IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () => _addFriend(currentUserId, otherUserId),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
