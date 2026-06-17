import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Support"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            "Frequently Asked Questions",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          SizedBox(height: 20),
          ListTile(
            title: Text(
              "How do I delete a task?",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Simply swipe the task to the left on the 'My Tasks' screen.",
            ),
            contentPadding: EdgeInsets.zero,
          ),
          Divider(),
          ListTile(
            title: Text(
              "How do I change task status?",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Tap the circle icon next to the task to cycle between Pending, In Progress, and Completed.",
            ),
            contentPadding: EdgeInsets.zero,
          ),
          Divider(),
          ListTile(
            title: Text(
              "What are Rewards?",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Complete assignments before their deadline to build your responsibility streak and earn rewards!",
            ),
            contentPadding: EdgeInsets.zero,
          ),
          SizedBox(height: 40),
          Text(
            "Contact Us",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "If you encounter any bugs or need further assistance with your Student Task App, please contact the developer at:\n\nsupport@studentapp.edu.my",
          ),
        ],
      ),
    );
  }
}
