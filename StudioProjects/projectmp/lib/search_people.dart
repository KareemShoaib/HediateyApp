import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchPeoplePage extends StatefulWidget {
  const SearchPeoplePage({super.key});

  @override
  State<SearchPeoplePage> createState() => _SearchPeoplePageState();
}

class _SearchPeoplePageState extends State<SearchPeoplePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = ''; // Holds the search query

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

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search People'),
        backgroundColor: Colors.deepPurple[800],
        centerTitle: true,
        actions: [
          // Search Bar Icon
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: UserSearchDelegate(
                  firestore: _firestore,
                  currentUserId: currentUserId,
                  onAddFriend: _addFriend,
                ),
              );
            },
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

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>?;
              final otherUserId = users[index].id;

              final firstName = user?['firstName'] ?? 'Unknown';
              final lastName = user?['lastName'] ?? 'Unknown';
              final List friends = user?['friends'] ?? [];

              final isAlreadyFriend = friends.contains(currentUserId);

              return Card(
                color: Colors.deepPurple[700],
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.white),
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

class UserSearchDelegate extends SearchDelegate {
  final FirebaseFirestore firestore;
  final String currentUserId;
  final Function(String, String) onAddFriend;

  UserSearchDelegate({
    required this.firestore,
    required this.currentUserId,
    required this.onAddFriend,
  });

  @override
  String get searchFieldLabel => "Search for people...";

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildUserList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildUserList();
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No users found.'),
          );
        }

        final filteredUsers = snapshot.data!.docs.where((doc) {
          final userId = doc.id;
          final data = doc.data() as Map<String, dynamic>?;
          final firstName = data?['firstName']?.toLowerCase() ?? '';
          final lastName = data?['lastName']?.toLowerCase() ?? '';
          return userId != currentUserId &&
              (firstName.contains(query.toLowerCase()) ||
                  lastName.contains(query.toLowerCase()));
        }).toList();

        return FutureBuilder<DocumentSnapshot>(
          future: firestore.collection('users').doc(currentUserId).get(),
          builder: (context, currentUserSnapshot) {
            if (currentUserSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final currentUserData =
            currentUserSnapshot.data?.data() as Map<String, dynamic>?;

            final List friends = currentUserData?['friends'] ?? [];

            return ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index].data() as Map<String, dynamic>?;
                final userId = filteredUsers[index].id;
                final firstName = user?['firstName'] ?? 'Unknown';
                final lastName = user?['lastName'] ?? 'Unknown';
                final isAlreadyFriend = friends.contains(userId);

                return ListTile(
                  leading: const Icon(Icons.person, color: Colors.white),
                  title: Text(
                    '$firstName $lastName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: isAlreadyFriend
                      ? const Text(
                    "Already Friends",
                    style: TextStyle(color: Colors.green),
                  )
                      : null,
                  trailing: isAlreadyFriend
                      ? const Icon(Icons.check, color: Colors.green)
                      : IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () => onAddFriend(currentUserId, userId),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

