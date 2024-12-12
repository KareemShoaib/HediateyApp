import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Friend {
  final String id;
  final String email;
  final String profilePicture;
  final int upcomingEvents;

  Friend({
    required this.id,
    required this.email,
    required this.profilePicture,
    required this.upcomingEvents,
  });
}

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch all users with events
  Stream<List<Friend>> getFriendsWithEvents() async* {
    final userSnapshots = await _firestore.collection('users').get();

    List<Friend> friends = [];

    for (var userDoc in userSnapshots.docs) {
      final userId = userDoc.id;
      final userData = userDoc.data();

      // Count the events for the user
      final eventCount = await _firestore
          .collection('users')
          .doc(userId)
          .collection('events')
          .get()
          .then((eventSnapshot) => eventSnapshot.size);

      if (eventCount > 0) {
        friends.add(
          Friend(
            id: userId,
            email: userData['email'] ?? 'No Email', // Fetch the email field
            profilePicture: userData['profilePicture'] ?? 'https://via.placeholder.com/150',
            upcomingEvents: eventCount,
          ),
        );
      }
    }

    yield friends;
  }
}

class FriendWidget extends StatelessWidget {
  final Friend friend;

  const FriendWidget({Key? key, required this.friend}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(friend.profilePicture),
        radius: 25,
      ),
      title: Text(
        friend.email, // Display the email as the main title
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        friend.upcomingEvents > 0
            ? "Upcoming Events: ${friend.upcomingEvents}"
            : "No Upcoming Events",
        style: const TextStyle(color: Colors.white54),
      ),
      trailing: friend.upcomingEvents > 0
          ? CircleAvatar(
        radius: 15,
        backgroundColor: Colors.red,
        child: Text(
          friend.upcomingEvents.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
      )
          : null,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService _firestoreService = FirestoreService();
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends List'),
        backgroundColor: Colors.deepPurple[800],
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: FriendSearchDelegate(firestoreService: _firestoreService),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Friend>>(
        stream: _firestoreService.getFriendsWithEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No friends with events found."));
          }

          final friends = snapshot.data!
              .where((friend) => friend.email.toLowerCase().contains(searchQuery.toLowerCase()))
              .toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to Create Event/List page
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple[700],
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
                  ),
                  child: const Text(
                    "Create Your Own Event/List",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    return FriendWidget(friend: friends[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
      backgroundColor: Colors.deepPurple[900],
    );
  }
}

class FriendSearchDelegate extends SearchDelegate {
  final FirestoreService firestoreService;

  FriendSearchDelegate({required this.firestoreService});

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = "";
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
    return StreamBuilder<List<Friend>>(
      stream: firestoreService.getFriendsWithEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final results = snapshot.data!
            .where((friend) => friend.email.toLowerCase().contains(query.toLowerCase()))
            .toList();

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            return FriendWidget(friend: results[index]);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return StreamBuilder<List<Friend>>(
      stream: firestoreService.getFriendsWithEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final suggestions = snapshot.data!
            .where((friend) => friend.email.toLowerCase().contains(query.toLowerCase()))
            .toList();

        return ListView.builder(
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            return FriendWidget(friend: suggestions[index]);
          },
        );
      },
    );
  }
}
