import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get userId => _auth.currentUser?.uid;

  // Fetch user's events
  Stream<List<Map<String, dynamic>>> getEvents() {
    if (userId == null) throw Exception("User not logged in");
    return _firestore.collection('users').doc(userId).collection('events').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
    );
  }

  // Add a gift to a specific event
  Future<void> addGift(String eventId, String name) async {
    if (userId == null) throw Exception("User not logged in");
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .doc(eventId)
        .collection('gifts')
        .add({
      'name': name,
      'status': 'Not Pledged',
      'isPledged': false,
    });
  }

  // Update a gift (only name)
  Future<void> updateGift(String eventId, String giftId, String newName) async {
    if (userId == null) throw Exception("User not logged in");
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .doc(eventId)
        .collection('gifts')
        .doc(giftId)
        .update({
      'name': newName,
    });
  }

  // Fetch gifts for a specific event
  Stream<List<Map<String, dynamic>>> getGifts(String eventId) {
    if (userId == null) throw Exception("User not logged in");
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .doc(eventId)
        .collection('gifts')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  // Delete a gift
  Future<void> deleteGift(String eventId, String giftId) async {
    if (userId == null) throw Exception("User not logged in");
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .doc(eventId)
        .collection('gifts')
        .doc(giftId)
        .delete();
  }
}

class GiftPage extends StatefulWidget {
  const GiftPage({Key? key}) : super(key: key);

  @override
  _GiftPageState createState() => _GiftPageState();
}

class _GiftPageState extends State<GiftPage> {
  final FirestoreService _firestoreService = FirestoreService();
  String? selectedEventId; // Holds the currently selected event ID

  void addGift() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController nameController = TextEditingController();

        return AlertDialog(
          title: const Text("Add Gift"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Gift Name"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && selectedEventId != null) {
                  _firestoreService.addGift(selectedEventId!, nameController.text);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select an event and enter a gift name")),
                  );
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void editGift(String eventId, String giftId, String currentName) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController nameController = TextEditingController(text: currentName);

        return AlertDialog(
          title: const Text("Edit Gift"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Gift Name"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  _firestoreService.updateGift(eventId, giftId, nameController.text);
                  Navigator.pop(context);
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void deleteGift(String eventId, String giftId) {
    _firestoreService.deleteGift(eventId, giftId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gift List'),
        backgroundColor: Colors.deepPurple[800],
      ),
      body: Column(
        children: [
          // Dropdown to select the event
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getEvents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text("No events found. Add events first.");
                }

                final events = snapshot.data!;
                return DropdownButton<String>(
                  value: selectedEventId,
                  hint: const Text("Select Event"),
                  isExpanded: true,
                  items: events.map<DropdownMenuItem<String>>((event) {
                    return DropdownMenuItem<String>(
                      value: event['id'] as String,
                      child: Text(event['name'] as String),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedEventId = value;
                    });
                  },
                );
              },
            ),
          ),

          // Display gifts for the selected event
          Expanded(
            child: selectedEventId == null
                ? const Center(child: Text("Select an event to view gifts."))
                : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getGifts(selectedEventId!),
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
                      leading: Icon(
                        Icons.card_giftcard,
                        color: gift['isPledged'] ? Colors.green : Colors.red,
                      ),
                      title: Text(gift['name']),
                      subtitle: Text(gift['status']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => editGift(
                              selectedEventId!,
                              gift['id'],
                              gift['name'],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteGift(selectedEventId!, gift['id']),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addGift,
        backgroundColor: Colors.deepPurple[700],
        child: const Icon(Icons.add),
      ),
      backgroundColor: Colors.deepPurple[900],
    );
  }
}
