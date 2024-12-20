import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the currently logged-in user's ID
  String? get userId => _auth.currentUser?.uid;

  // Fetch pledged gifts for the logged-in user's events
  Stream<List<Map<String, dynamic>>> getGiftsPledgedToCurrentUser() async* {
    if (userId == null) throw Exception("User not logged in");

    yield* _firestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .snapshots()
        .asyncMap((eventSnapshots) async {
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
            .where('status', isEqualTo: 'Pledged') // Fetch only pledged gifts
            .get();

        for (var giftDoc in giftSnapshots.docs) {
          pledgedGifts.add({
            'name': giftDoc.data()['name'], // Gift name
            'event': eventName, // Associated event name
          });
        }
      }

      return pledgedGifts;
    });
  }
}

class GiftsPledgedToMePage extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();

  GiftsPledgedToMePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gifts Pledged to Me'),
        backgroundColor: Colors.deepPurple[800],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getGiftsPledgedToCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error: ${snapshot.error}",
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No gifts pledged to you yet.",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          final pledgedGifts = snapshot.data!;

          return ListView.builder(
            itemCount: pledgedGifts.length,
            itemBuilder: (context, index) {
              final gift = pledgedGifts[index];
              return ListTile(
                leading: const Icon(Icons.card_giftcard, color: Colors.green),
                title: Text(
                  gift['name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  "Event: ${gift['event']}",
                  style: const TextStyle(color: Colors.grey),
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
