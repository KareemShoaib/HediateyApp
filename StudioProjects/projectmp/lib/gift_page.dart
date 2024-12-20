import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'database_helper.dart';

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

  Future<void> addGift(String eventId, String name, String? imagePath) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .doc(eventId)
        .collection('gifts')
        .add({'name': name, 'image': imagePath, 'status': 'Not Pledged'});
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
  final ImagePicker _imagePicker = ImagePicker();

  String? selectedEventId;
  String? selectedEventSource;
  String? _selectedImagePath;
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
          leading: const Icon(Icons.card_giftcard, color: Colors.red),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gift['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      isPledged ? "Pledged" : "Not Pledged",
                      style: TextStyle(
                        color: isPledged ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (gift['image'] != null && File(gift['image']).existsSync())
                Container(
                  margin: const EdgeInsets.only(left: 10.0),
                  width: 50,
                  height: 50,
                  child: Image.file(
                    File(gift['image']),
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ),
          trailing: isPledged
              ? null // Do not show any buttons if the gift is pledged
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () =>
                    _editGift(gift['id'].toString(), gift['name']),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteGift(gift['id'].toString()),
              ),
            ],
          ),
        );
      },
    );
  }


  void _editGift(String giftId, String currentName) {
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
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (selectedEventSource == 'Firestore') {
                    await _firestoreService.updateGift(
                      selectedEventId!,
                      giftId,
                      nameController.text,
                    );
                  } else if (selectedEventSource == 'Local') {
                    await _dbHelper.update(
                      'Gifts',
                      {'name': nameController.text},
                      where: 'id = ?',
                      whereArgs: [giftId],
                    );
                  }
                  Navigator.pop(context);
                  setState(() {}); // Refresh UI
                } catch (e) {
                  print("Error editing gift: $e");
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _deleteGift(String giftId) async {
    try {
      if (selectedEventSource == 'Firestore') {
        await _firestoreService.deleteGift(selectedEventId!, giftId);
      } else if (selectedEventSource == 'Local') {
        await _dbHelper.delete('Gifts', where: 'id = ?', whereArgs: [giftId]);
      }
      setState(() {}); // Refresh UI
    } catch (e) {
      print("Error deleting gift: $e");
    }
  }

  void _addGift() {
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Gift Name"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.image),
                label: const Text("Select Image (Optional)"),
                onPressed: () async {
                  final pickedFile = await _imagePicker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (pickedFile != null) {
                    setState(() {
                      _selectedImagePath = pickedFile.path;
                    });
                  }
                },
              ),
              if (_selectedImagePath != null)
                Text(
                  "Image Selected: ${_selectedImagePath!.split('/').last}",
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
            ],
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
                      await _firestoreService.addGift(
                        selectedEventId!,
                        nameController.text,
                        _selectedImagePath,
                      );
                    } else if (selectedEventSource == 'Local') {
                      final newGift = {
                        'name': nameController.text,
                        'image': _selectedImagePath,
                        'event_id': int.tryParse(selectedEventId!) ?? -1,
                      };
                      int result = await _dbHelper.insert('Gifts', newGift);
                    }
                    Navigator.pop(context);
                    setState(() {
                      _selectedImagePath = null;
                    });
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gift List'),
        backgroundColor: Colors.deepPurple[800], // Match AppBar color
      ),
      backgroundColor: Colors.deepPurple[900], // Match the exact background color
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedEventId,
              hint: const Text("Select Event"),
              isExpanded: true,
              items: combinedEvents.map((event) {
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
                style: TextStyle(color: Colors.white, fontSize: 16), // Match text style
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
        onPressed: _addGift,
        backgroundColor: Colors.deepPurple[700], // Match FloatingActionButton color
        child: const Icon(Icons.add),
      ),
    );
  }

}
