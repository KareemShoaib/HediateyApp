import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_helper.dart'; // Import local database helper

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  Future<List<Map<String, dynamic>>> getFirestoreEvents() async {
    if (userId == null) throw Exception("User not logged in");
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .get();

    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data(), 'source': 'Firestore'})
        .toList();
  }

  Stream<List<Map<String, dynamic>>> getGifts(String eventId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .doc(eventId)
        .collection('gifts')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
  }

  Future<void> addGift(String eventId, String name) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .doc(eventId)
        .collection('gifts')
        .add({'name': name, 'status': 'Not Pledged'});
  }

  Future<void> updateGift(String eventId, String giftId, String newName) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .doc(eventId)
        .collection('gifts')
        .doc(giftId)
        .update({'name': newName});
  }

  Future<void> deleteGift(String eventId, String giftId) async {
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
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  String? selectedEventId;
  String? selectedEventSource;
  List<Map<String, dynamic>> combinedEvents = [];

  @override
  void initState() {
    super.initState();
    _fetchCombinedEvents();
  }

  Future<void> _fetchCombinedEvents() async {
    final localEvents = await _dbHelper.query(
      'Events',
      where: 'user_id = ?',
      whereArgs: [FirestoreService().userId],
    );

    final firestoreEvents = await _firestoreService.getFirestoreEvents();

    setState(() {
      combinedEvents = [
        ...localEvents.map((e) => {
          'id': e['id'].toString(),
          'name': e['name'],
          'source': 'Local'
        }),
        ...firestoreEvents,
      ];
    });
  }

  void addGift() {
    if (selectedEventId == null || selectedEventSource == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select an event first."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController nameController = TextEditingController();

        return AlertDialog(
          title: const Text("Add Gift"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Gift Name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  try {
                    if (selectedEventSource == 'Firestore') {
                      // Firestore insertion
                      await _firestoreService.addGift(
                        selectedEventId!,
                        nameController.text,
                      );
                      print("Gift added to Firestore");
                    } else if (selectedEventSource == 'Local') {
                      // Local database insertion
                      int localEventId = int.tryParse(selectedEventId!) ?? -1;

                      if (localEventId > 0) {
                        final newGift = {
                          'name': nameController.text,
                          'event_id': localEventId,
                        };

                        int result = await _dbHelper.insert('Gifts', newGift);

                        if (result > 0) {
                          print("Gift successfully added to local database.");
                        } else {
                          print("Failed to add gift to local database.");
                        }
                      } else {
                        print("Invalid event ID for local database.");
                      }
                    }

                    Navigator.pop(context);
                    setState(() {}); // Refresh UI
                  } catch (e) {
                    print("Error adding gift: $e");
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Gift name cannot be empty."),
                      backgroundColor: Colors.red,
                    ),
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


  void editGift(String giftId, String currentName) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController nameController =
        TextEditingController(text: currentName);

        return AlertDialog(
          title: const Text("Edit Gift"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: "Gift Name"),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (selectedEventSource == 'Firestore') {
                  await _firestoreService.updateGift(
                      selectedEventId!, giftId, nameController.text);
                } else {
                  await _dbHelper.update('Gifts', {'name': nameController.text},
                      where: 'id = ?', whereArgs: [giftId]);
                }
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void deleteGift(String giftId) async {
    if (selectedEventSource == 'Firestore') {
      await _firestoreService.deleteGift(selectedEventId!, giftId);
    } else {
      await _dbHelper.delete('Gifts', where: 'id = ?', whereArgs: [giftId]);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gift List'),
        backgroundColor: Colors.deepPurple,
      ),
      backgroundColor: Colors.deepPurple[900], // Set the background color here
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 12.0),
            child: DropdownButton<String>(
              value: selectedEventId,
              hint: const Padding(
                padding: EdgeInsets.only(left: 8.0),
                child: Text("Select Event"),
              ),
              isExpanded: true,
              items: combinedEvents.map<DropdownMenuItem<String>>((event) {
                return DropdownMenuItem<String>(
                  value: event['id'],
                  child: Text(
                    '${event['name']} (${event['source'] == "Local" ? "Only Me" : "Published to Friends"})',
                  ),
                  onTap: () => selectedEventSource = event['source'],
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedEventId = value;
                });
              },
            ),
          ),
          Expanded(
            child: selectedEventId == null
                ? const Center(
              child: Text(
                "Select an event to view gifts.",
                style: TextStyle(color: Colors.white), // Ensure text visibility
              ),
            )
                : StreamBuilder<List<Map<String, dynamic>>>(
              stream: selectedEventSource == 'Firestore'
                  ? _firestoreService.getGifts(selectedEventId!)
                  : null,
              builder: (context, snapshot) {
                return selectedEventSource == 'Local'
                    ? FutureBuilder<List<Map<String, dynamic>>>(
                  future: _dbHelper.query('Gifts',
                      where: 'event_id = ?',
                      whereArgs: [selectedEventId]),
                  builder: (context, localSnapshot) {
                    return _buildGiftList(localSnapshot.data ?? []);
                  },
                )
                    : _buildGiftList(snapshot.data ?? []);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addGift,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add),
      ),
    );
  }


  Widget _buildGiftList(List<Map<String, dynamic>> gifts) {
    if (gifts.isEmpty) {
      return const Center(
        child: Text("No gifts available."),
      );
    }

    return ListView.builder(
      itemCount: gifts.length,
      itemBuilder: (context, index) {
        final gift = gifts[index];
        final bool isPledged = gift['status'] == 'Pledged';

        return ListTile(
          leading: Icon(Icons.card_giftcard,
              color: isPledged ? Colors.green : Colors.red),
          title: Text(gift['name']),
          subtitle: Text(
            isPledged ? "Pledged" : "Not Pledged",
            style: TextStyle(
                color: isPledged ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold),
          ),
          trailing: isPledged
              ? null
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () =>
                    editGift(gift['id'].toString(), gift['name']),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteGift(gift['id'].toString()),
              ),
            ],
          ),
        );
      },
    );
  }
}
