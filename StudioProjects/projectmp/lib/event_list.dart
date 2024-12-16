import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_helper.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the currently logged-in user's ID
  String? get userId => _auth.currentUser?.uid;

  // Add an event associated with the user to Firestore
  Future<void> addEvent(String name, DateTime date) async {
    if (userId == null) throw Exception("User not logged in");
    await _firestore.collection('users').doc(userId).collection('events').add({
      'name': name,
      'date': date,
    });
  }

  // Update an event's name or date
  Future<void> updateEvent(String eventId, String newName, DateTime newDate) async {
    if (userId == null) throw Exception("User not logged in");
    await _firestore.collection('users').doc(userId).collection('events').doc(eventId).update({
      'name': newName,
      'date': newDate,
    });
  }

  // Delete an event associated with the user
  Future<void> deleteEvent(String eventId) async {
    if (userId == null) throw Exception("User not logged in");
    await _firestore.collection('users').doc(userId).collection('events').doc(eventId).delete();
  }

  // Fetch events from Firestore
  Stream<List<Map<String, dynamic>>> getEvents() {
    if (userId == null) throw Exception("User not logged in");
    return _firestore.collection('users').doc(userId).collection('events').snapshots().map(
          (snapshot) => snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
    );
  }
}

class EventListPage extends StatefulWidget {
  const EventListPage({Key? key}) : super(key: key);

  @override
  _EventListPageState createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final DatabaseHelper _localDB = DatabaseHelper.instance;

  String sortBy = "Name";

  Future<List<Map<String, dynamic>>> _fetchLocalEvents() async {
    return await _localDB.query('Events',
        where: 'user_id = ?',
        whereArgs: [FirebaseAuth.instance.currentUser?.uid]);
  }

  void addEvent() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController nameController = TextEditingController();
        DateTime? selectedDate;

        return AlertDialog(
          title: const Text("Add Event"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Event Name"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) selectedDate = pickedDate;
                },
                child: const Text("Select Date"),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty && selectedDate != null) {
                  await _showSaveOptionDialog(
                      nameController.text, selectedDate!);
                  Navigator.pop(context);
                }
              },
              child: const Text("Next"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSaveOptionDialog(String name, DateTime date) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Save Event"),
          content: const Text("Where do you want to save this event?"),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await _firestoreService.addEvent(name, date);
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text("Publish to Friends"),
            ),
            ElevatedButton(
              onPressed: () async {
                await _localDB.insert("Events", {
                  'name': name,
                  'date': date.toIso8601String(),
                  'user_id': FirebaseAuth.instance.currentUser?.uid,
                });
                Navigator.pop(context);
                setState(() {});
              },
              child: const Text("Only Me"),
            ),
          ],
        );
      },
    );
  }

  void editEvent(String id, String source, String currentName,
      DateTime currentDate) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController nameController = TextEditingController(
            text: currentName);
        DateTime selectedDate = currentDate;

        return AlertDialog(
          title: const Text("Edit Event"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Event Name"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) selectedDate = pickedDate;
                },
                child: const Text("Select New Date"),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                if (source == "Firestore") {
                  await _firestoreService.updateEvent(
                      id, nameController.text, selectedDate);
                } else {
                  await _localDB.update('Events', {
                    'name': nameController.text,
                    'date': selectedDate.toIso8601String()
                  },
                      where: 'id = ?', whereArgs: [id]);
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

  void deleteEvent(String id, String source) {
    if (source == "Firestore") {
      _firestoreService.deleteEvent(id);
    } else {
      _localDB.delete('Events', where: 'id = ?', whereArgs: [id]);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event List'),
          backgroundColor: Colors.deepPurple[800]),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchLocalEvents(),
              builder: (context, localSnapshot) {
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _firestoreService.getEvents(),
                  builder: (context, firestoreSnapshot) {
                    final localEvents = localSnapshot.data ?? [];
                    final firestoreEvents = firestoreSnapshot.data ?? [];

                    return ListView(
                      children: [
                        const ListTile(
                          title: Text("Published to Friends",
                              style: TextStyle(fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        ...firestoreEvents.map((event) =>
                            _buildEventItem(event, "Firestore")),

                        const ListTile(
                          title: Text("Only Me",
                              style: TextStyle(fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        ...localEvents.map((event) =>
                            _buildEventItem(event, "Local")),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addEvent,
        backgroundColor: Colors.deepPurple[700],
        child: const Icon(Icons.add),
      ),
      backgroundColor: Colors.deepPurple[900],
    );
  }


  Widget _buildEventItem(Map<String, dynamic> event, String source) {
    // Convert Firestore Timestamp to DateTime
    DateTime eventDate;

    if (event['date'] is Timestamp) {
      eventDate = (event['date'] as Timestamp).toDate();
    } else {
      // Handle local database where date is a string
      eventDate = DateTime.parse(event['date']);
    }

    // Format date
    String formattedDate = DateFormat('yyyy-MM-dd').format(eventDate);

    return ListTile(
      leading: const Icon(Icons.event, color: Colors.green),
      title: Text(event['name']),
      subtitle: Text('Date: $formattedDate'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () =>
                editEvent(
                    event['id'].toString(), source, event['name'], eventDate),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => deleteEvent(event['id'].toString(), source),
          ),
        ],
      ),
    );
  }
}
