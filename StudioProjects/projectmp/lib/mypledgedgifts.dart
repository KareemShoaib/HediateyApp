import 'package:flutter/material.dart';

class PledgedGiftsPage extends StatelessWidget {
  const PledgedGiftsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sample data for pledged gifts
    final List<Map<String, String>> pledgedGifts = [
      {"name": "Smartwatch", "friend": "Alice", "dueDate": "2024-12-20", "status": "Pending"},
      {"name": "Book", "friend": "Bob", "dueDate": "2024-12-15", "status": "Completed"},
      {"name": "Headphones", "friend": "Charlie", "dueDate": "2024-12-25", "status": "Pending"},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Pledged Gifts'),
        backgroundColor: Colors.deepPurple[800],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            "Overview of Pledged Gifts",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pledgedGifts.length,
            itemBuilder: (context, index) {
              final gift = pledgedGifts[index];
              final isPending = gift['status'] == 'Pending';

              return Card(
                color: isPending ? Colors.deepPurple[700] : Colors.grey[600],
                child: ListTile(
                  title: Text(
                    gift['name']!,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Friend: ${gift['friend']} \nDue Date: ${gift['dueDate']}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                  trailing: isPending
                      ? IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () {
                      // Navigate to edit page or show edit dialog
                      print("Edit ${gift['name']} tapped");
                    },
                  )
                      : null,
                  onTap: () {
                    // Show details or additional options
                    print("${gift['name']} tapped");
                  },
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.deepPurple[900],
    );
  }
}
