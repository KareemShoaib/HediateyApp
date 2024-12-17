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
  const PledgedGiftsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pledgedGiftsRef = FirebaseFirestore.instance.collection('pledged_gifts');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pledged Gifts'),
        backgroundColor: Colors.deepPurple[800],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: pledgedGiftsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No pledged gifts found.",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final gifts = snapshot.data!.docs;

          return ListView.builder(
            itemCount: gifts.length,
            itemBuilder: (context, index) {
              final gift = gifts[index];

              return ListTile(
                leading: const Icon(Icons.card_giftcard, color: Colors.green),
                title: Text(
                  gift['name'], // Display only the gift's name
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              );
            },
          );
        },
      ),
      backgroundColor: Colors.deepPurple[900], // Background color
    );
  }
}
