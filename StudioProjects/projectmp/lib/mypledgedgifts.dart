import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get userId => _auth.currentUser?.uid;

  // Fetch pledged gifts by the logged-in user
  Stream<List<Map<String, dynamic>>> getPledgedGiftsByUser() async* {
    if (userId == null) throw Exception("User not logged in");

    yield* _firestore.collection('users').doc(userId).collection('events').snapshots().asyncMap((eventSnapshots) async {
      List<Map<String, dynamic>> pledgedGifts = [];

      for (var eventDoc in eventSnapshots.docs) {
        final eventId = eventDoc.id;
        final eventName = eventDoc.data()['name'];

        final giftSnapshots = await _firestore
            .collection('users')
            .doc(userId)
            .collection('events')
            .doc(eventId)
            .collection('gifts')
            .where('pledgedBy', isEqualTo: userId) // Filter by logged-in user's ID
            .where('status', isEqualTo: 'Pledged') // Filter by pledged status
            .get();

        for (var giftDoc in giftSnapshots.docs) {
          pledgedGifts.add({
            'name': giftDoc.data()['name'],
            'event': eventName,
            'status': giftDoc.data()['status'],
          });
        }
      }

      return pledgedGifts;
    });
  }
}

class PledgedGiftsPage extends StatelessWidget {
  final FirestoreService firestoreService = FirestoreService();

  PledgedGiftsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pledged Gifts'),
        backgroundColor: Colors.deepPurple[800],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: firestoreService.getPledgedGiftsByUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No pledged gifts found."));
          }

          final pledgedGifts = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: pledgedGifts.length,
            itemBuilder: (context, index) {
              final gift = pledgedGifts[index];
              return Card(
                color: Colors.deepPurple[700],
                child: ListTile(
                  title: Text(
                    gift['name'],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Event: ${gift['event']}",
                    style: const TextStyle(color: Colors.white70),
                  ),
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
