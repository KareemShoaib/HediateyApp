import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Friend {
  final String id;
  final String email;
  final String profilePicture;
  final int numberOfEvents;

  Friend({
    required this.id,
    required this.email,
    required this.profilePicture,
    required this.numberOfEvents,
  });
}

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch all users except the logged-in user
  Stream<List<Friend>> getAllUsersWithEvents() async* {
    final currentUser = _auth.currentUser;
    final userSnapshots = await _firestore.collection('users').get();

    List<Friend> friends = [];

    for (var userDoc in userSnapshots.docs) {
      final userId = userDoc.id;
      final userData = userDoc.data();

      // Skip the logged-in user's email and users without a valid email
      final email = userData['email'];
      if (email == null || email.isEmpty || email == currentUser?.email) {
        continue;
      }

      // Fetch the number of events for the user
      final eventCount = await _firestore
          .collection('users')
          .doc(userId)
          .collection('events')
          .get()
          .then((eventSnapshot) => eventSnapshot.size);

      friends.add(
        Friend(
          id: userId,
          email: email,
          profilePicture: userData['profilePicture'] ?? 'https://via.placeholder.com/150',
          numberOfEvents: eventCount,
        ),
      );
    }

    yield friends;
  }

  // Fetch events for a specific user
  Stream<List<Map<String, dynamic>>> getUserEvents(String userId) {
    return _firestore.collection('users').doc(userId).collection('events').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
    );
  }

  // Fetch gifts for a specific event
  Stream<List<Map<String, dynamic>>> getEventGifts(String userId, String eventId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .doc(eventId)
        .collection('gifts')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // Update the gift's status to "Pledged"
  Future<void> pledgeGift(String userId, String eventId, String giftId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .doc(eventId)
        .collection('gifts')
        .doc(giftId)
        .update({'status': 'Pledged'});
  }
}

class FriendWidget extends StatelessWidget {
  final Friend friend;
  final VoidCallback onTap;

  const FriendWidget({Key? key, required this.friend, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundImage: NetworkImage(friend.profilePicture),
        radius: 25,
      ),
      title: Text(
        friend.email,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Number of Events: ${friend.numberOfEvents}",
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
      trailing: friend.numberOfEvents > 0
          ? Container(
        padding: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        child: Text(
          friend.numberOfEvents.toString(),
          style: const TextStyle(color: Colors.white, fontSize: 12),
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
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Friend>>(
              stream: _firestoreService.getAllUsersWithEvents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No friends found."));
                }

                final friends = snapshot.data!;

                return ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    return FriendWidget(
                      friend: friends[index],
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserEventListPage(
                              userId: friends[index].id,
                              userEmail: friends[index].email,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      backgroundColor: Colors.deepPurple[900],
    );
  }
}

class UserEventListPage extends StatelessWidget {
  final String userId;
  final String userEmail;

  const UserEventListPage({Key? key, required this.userId, required this.userEmail}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Text("$userEmail's Events"),
        backgroundColor: Colors.deepPurple[800],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestoreService.getUserEvents(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No events found."));
          }

          final events = snapshot.data!;
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return ListTile(
                leading: const Icon(Icons.event, color: Colors.green),
                title: Text(event['name']),
                subtitle: Text(event['date'].toDate().toString()),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventGiftListPage(
                        userId: userId,
                        eventId: event['id'],
                        eventName: event['name'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      backgroundColor: Colors.deepPurple[900],
    );
  }
}

class EventGiftListPage extends StatelessWidget {
  final String userId;
  final String eventId;
  final String eventName;

  const EventGiftListPage({Key? key, required this.userId, required this.eventId, required this.eventName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Text("Gifts for $eventName"),
        backgroundColor: Colors.deepPurple[800],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestoreService.getEventGifts(userId, eventId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No gifts found."));
          }

          final gifts = snapshot.data!;
          return ListView.builder(
            itemCount: gifts.length,
            itemBuilder: (context, index) {
              final gift = gifts[index];
              return ListTile(
                leading: const Icon(Icons.card_giftcard, color: Colors.purple),
                title: Text(gift['name']),
                subtitle: Text(gift['status'] ?? 'Not Pledged'),
                trailing: IconButton(
                  icon: Icon(
                    Icons.check_circle,
                    color: gift['status'] == 'Pledged' ? Colors.green : Colors.grey,
                  ),
                  onPressed: () {
                    if (gift['status'] != 'Pledged') {
                      firestoreService.pledgeGift(userId, eventId, gift['id']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gift pledged successfully!')),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      backgroundColor: Colors.deepPurple[900],
    );
  }
}
