import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the currently logged-in user's ID
  String? get userId => _auth.currentUser?.uid;

  // Add an event associated with the user
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

  // Fetch events associated with the user
  Stream<List<Map<String, dynamic>>> getEvents() {
    if (userId == null) throw Exception("User not logged in");
    return _firestore.collection('users').doc(userId).collection('events').snapshots().map(
          (snapshot) {
        return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      },
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
  String sortBy = "Name"; // Default sorting criterion

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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && selectedDate != null) {
                  _firestoreService.addEvent(nameController.text, selectedDate!);
                  Navigator.pop(context);
                }
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  void editEvent(String eventId, String currentName, DateTime currentDate) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController nameController =
        TextEditingController(text: currentName);
        DateTime? selectedDate = currentDate;

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
                    initialDate: currentDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    selectedDate = pickedDate;
                  }
                },
                child: const Text("Select New Date"),
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
                if (nameController.text.isNotEmpty && selectedDate != null) {
                  _firestoreService.updateEvent(
                      eventId, nameController.text, selectedDate!);
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

  void deleteEvent(String eventId) {
    _firestoreService.deleteEvent(eventId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event List'),
        backgroundColor: Colors.deepPurple[800],
      ),
      body: Column(
        children: [
          // Sorting Dropdown
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: sortBy,
              items: const [
                DropdownMenuItem(value: "Name", child: Text("Sort by Name")),
                DropdownMenuItem(value: "Date", child: Text("Sort by Date")),
              ],
              onChanged: (value) {
                setState(() {
                  sortBy = value!;
                });
              },
            ),
          ),

          // Event List
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getEvents(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No events found"));
                }

                // Sort events based on the selected criterion
                final events = snapshot.data!;
                if (sortBy == "Name") {
                  events.sort((a, b) => a['name'].compareTo(b['name']));
                } else if (sortBy == "Date") {
                  events.sort((a, b) => a['date'].compareTo(b['date']));
                }

                return ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return ListTile(
                      leading: const Icon(Icons.event, color: Colors.green),
                      title: Text(event['name']),
                      subtitle: Text(event['date'].toDate().toString()),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => editEvent(
                                event['id'], event['name'], event['date'].toDate()),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => deleteEvent(event['id']),
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
        onPressed: addEvent,
        backgroundColor: Colors.deepPurple[700],
        child: const Icon(Icons.add),
      ),
      backgroundColor: Colors.deepPurple[900],
    );
  }
}
