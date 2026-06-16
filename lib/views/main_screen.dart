import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_path.dart';

class MainScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<dynamic> _tasks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final url = ApiPath.endpoint(
        "load_tasks.php?user_id=${widget.user['id']}",
      );

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          setState(() {
            _tasks = data['tasks'];
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleTaskStatus(String taskId, String currentStatus) async {
    String newStatus = currentStatus == 'Completed' ? 'Pending' : 'Completed';
    try {
      final url = ApiPath.endpoint("update_task.php");
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"task_id": taskId, "status": newStatus}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          _fetchTasks();
        }
      }
    } catch (e) {
      print("Error updating task: $e");
    }
  }

  void _showAddTaskDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController dateController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Add New Task"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Task Title",
                  prefixIcon: Icon(Icons.task),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: dateController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Select Deadline",
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                onTap: () async {
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );

                  if (pickedDate != null) {
                    String formattedDate =
                        "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
                    dateController.text = formattedDate;
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _submitNewTask(titleController.text, dateController.text);
              },
              child: const Text("Save Task"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitNewTask(String title, String deadline) async {
    if (title.isEmpty) return;

    try {
      final url = ApiPath.endpoint("add_task.php");
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.user['id'],
          "title": title,
          "description": "",
          "deadline": deadline.isEmpty ? "No Date" : deadline,
          "status": "Pending",
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          _fetchTasks();

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Task added successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed: ${data['message']}"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
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
          await _fetchTasks();
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
        onPressed: _showAddTaskDialog,
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
    int pendingCount = _tasks.where((t) => t['status'] == 'Pending').length;

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
          child: _buildSummaryCard(
            "Pending",
            pendingCount.toString(),
            Icons.hourglass_empty,
          ),
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
                leading: IconButton(
                  icon: Icon(
                    task['status'] == 'Completed'
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: task['status'] == 'Completed'
                        ? Colors.green
                        : Colors.blueAccent,
                  ),
                  onPressed: () {
                    _toggleTaskStatus(
                      task['id'].toString(),
                      task['status'] ?? 'Pending',
                    );
                  },
                ),
                title: Text(
                  task['title'] ?? 'No Title',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: task['status'] == 'Completed'
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                subtitle: Text("Due: ${task['deadline'] ?? 'No Date'}"),
                trailing: _buildStatusChip(task['status'] ?? 'Pending'),
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
