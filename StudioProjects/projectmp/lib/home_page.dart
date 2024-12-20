import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:io'; // Import this to use the File class


class Friend {
  final String id;
  final String firstName;
  final String lastName;
  final int numberOfEvents;

  Friend({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.numberOfEvents,
  });
}

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch friends of the logged-in user
  Stream<List<Friend>> getUserFriends() async* {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      yield [];
      return;
    }

    final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
    final friendsList = userDoc.data()?['friends'] as List<dynamic>? ?? [];

    List<Friend> friends = [];

    for (String friendId in friendsList) {
      final friendDoc = await _firestore.collection('users').doc(friendId).get();

      if (friendDoc.exists) {
        final friendData = friendDoc.data()!;
        final eventCount = await _firestore
            .collection('users')
            .doc(friendId)
            .collection('events')
            .get()
            .then((snapshot) => snapshot.size);

        friends.add(
          Friend(
            id: friendId,
            firstName: friendData['firstName'] ?? 'Unknown',
            lastName: friendData['lastName'] ?? 'Unknown',
            numberOfEvents: eventCount,
          ),
        );
      }
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
  Future<void> pledgeGift(String userId, String eventId, String giftId, String userName) async {
    final giftRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .doc(eventId)
        .collection('gifts')
        .doc(giftId);

    // Update gift's status and store who pledged it
    await giftRef.update({
      'status': 'Pledged',
      'pledgedBy': userName,
    });

    // Fetch gift details
    final giftSnapshot = await giftRef.get();
    final giftData = giftSnapshot.data();

    // Store the pledged gift in a "pledged_gifts" collection
    if (giftData != null) {
      await _firestore.collection('pledged_gifts').add({
        'giftId': giftId,
        'eventId': eventId,
        'eventOwnerId': userId,
        'name': giftData['name'],
        'pledgedBy': userName,
        'pledgedAt': Timestamp.now(),
      });
    }
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
      leading: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(friend.id).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircleAvatar(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const CircleAvatar(
              child: Icon(Icons.person),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final profileImagePath = data['profileImagePath'] as String?;

          if (profileImagePath != null && File(profileImagePath).existsSync()) {
            return CircleAvatar(
              backgroundImage: FileImage(File(profileImagePath)),
            );
          }

          return const CircleAvatar(
            child: Icon(Icons.person),
          );
        },
      ),
      title: Text(
        '${friend.firstName} ${friend.lastName}',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      subtitle: Text("Number of Events: ${friend.numberOfEvents}"),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Friends'),
        backgroundColor: Colors.deepPurple[800],
      ),
      body: StreamBuilder<List<Friend>>(
        stream: _firestoreService.getUserFriends(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("You have no friends added yet."));
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
                        userName: "${friends[index].firstName} ${friends[index].lastName}",
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


class UserEventListPage extends StatelessWidget {
  final String userId;
  final String userName;

  const UserEventListPage({Key? key, required this.userId, required this.userName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: Text("$userName's Events"),
        backgroundColor: Colors.deepPurple[800],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestoreService.getUserEvents(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No events found."));
          }

          final events = snapshot.data!;
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];

              // Handle date conversion
              DateTime eventDate;
              if (event['date'] is Timestamp) {
                eventDate = (event['date'] as Timestamp).toDate();
              } else if (event['date'] is String) {
                eventDate = DateTime.parse(event['date']);
              } else {
                eventDate = DateTime.now(); // Default to now if type is unexpected
              }

              // Format the date to show only the date part
              final formattedDate = DateFormat('yyyy-MM-dd').format(eventDate);

              return ListTile(
                leading: const Icon(Icons.event, color: Colors.green),
                title: Text(event['name']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Date: $formattedDate"),
                    Text(
                      "Location: ${event['location'] ?? 'Location not specified'}",
                    ),
                  ],
                ),
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

  const EventGiftListPage({
    Key? key,
    required this.userId,
    required this.eventId,
    required this.eventName,
  }) : super(key: key);

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
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No gifts found."));
          }

          final gifts = snapshot.data!;
          return ListView.builder(
            itemCount: gifts.length,
            itemBuilder: (context, index) {
              final gift = gifts[index];
              final String? imagePath = gift['image']; // Path to the image

              return ListTile(
                leading: imagePath != null && File(imagePath).existsSync()
                    ? Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(File(imagePath)),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                    : const Icon(Icons.card_giftcard, color: Colors.purple),
                title: Text(gift['name']),
                subtitle: Text(
                  gift['status'] ?? 'Not Pledged',
                  style: TextStyle(
                    color: gift['status'] == 'Pledged' ? Colors.green : Colors.grey,
                  ),
                ),
                trailing: gift['status'] == 'Pledged'
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : IconButton(
                  icon: const Icon(Icons.check_circle_outline, color: Colors.grey),
                  onPressed: () {
                    final currentUser = FirebaseAuth.instance.currentUser;

                    if (currentUser != null) {
                      final userName =
                          currentUser.displayName ?? currentUser.email ?? 'Unknown User';
                      firestoreService.pledgeGift(
                          userId, eventId, gift['id'], userName);
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
