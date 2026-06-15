import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // await _loadTasks();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            _buildSummaryRow(),
            const SizedBox(height: 20),
            const Text(
              'Recent Tasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildTaskList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () {
          print("Add Task button pressed!");
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: const LinearGradient(
          colors: [Colors.blueAccent, Colors.lightBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${widget.user['name']}!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${widget.user['email']} | Role: ${widget.user['role']}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            "Total Tasks",
            _tasks.length.toString(),
            Icons.assignment,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSummaryCard("Pending", "0", Icons.hourglass_empty),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String count, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: Colors.blueAccent, size: 28),
            const SizedBox(height: 10),
            Text(
              count,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: const Text(
          "No tasks yet! Tap the + button to add one.",
          style: TextStyle(color: Colors.grey, fontSize: 15),
        ),
      );
    }
    return Column(
      children: _tasks
          .map(
            (task) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.radio_button_unchecked,
                  color: Colors.blueAccent,
                ),
                title: Text(
                  task['title'],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text("Due: ${task['deadline']}"),
                trailing: _buildStatusChip(task['status']),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bgColor = status == 'Completed'
        ? Colors.green.shade100
        : Colors.orange.shade100;
    Color textColor = status == 'Completed'
        ? Colors.green.shade900
        : Colors.orange.shade900;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
