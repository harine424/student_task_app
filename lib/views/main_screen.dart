import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_path.dart';
import 'profile_screen.dart';
import 'task_detail_screen.dart';

class MainScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  List<dynamic> _tasks = [];

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    try {
      final url = ApiPath.endpoint(
        "load_tasks.php?user_id=${widget.user['id']}",
      );
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['status'] == 'success') setState(() => _tasks = data['tasks']);
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _toggleTaskStatus(String id, String status) async {
    String newStatus = status == 'Completed' ? 'Pending' : 'Completed';
    await http.post(
      Uri.parse(ApiPath.endpoint("update_task.php")),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"task_id": id, "status": newStatus}),
    );
    _fetchTasks();
  }

  Future<void> _deleteTask(String id) async {
    await http.post(
      Uri.parse(ApiPath.endpoint("delete_task.php")),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"task_id": id}),
    );
    _fetchTasks();
  }

  void _showAddTaskDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController dateController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Add Task"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Title"),
            ),
            TextField(
              controller: dateController,
              readOnly: true,
              decoration: const InputDecoration(labelText: "Date"),
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                );
                if (picked != null)
                  dateController.text =
                      "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
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
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _submitNewTask(String title, String deadline) async {
    if (title.isEmpty) return;
    await http.post(
      Uri.parse(ApiPath.endpoint("add_task.php")),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": widget.user['id'],
        "title": title,
        "deadline": deadline,
        "status": "Pending",
      }),
    );
    _fetchTasks();
  }

  Widget _buildDashboard() {
    return _tasks.isEmpty
        ? const Center(child: Text("No tasks yet!"))
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _tasks.length,
            itemBuilder: (context, index) {
              final task = _tasks[index];
              return Dismissible(
                key: Key(task['id'].toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  final backup = task;
                  setState(() => _tasks.removeAt(index));
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                        SnackBar(
                          content: const Text("Task deleted"),
                          action: SnackBarAction(
                            label: "Undo",
                            onPressed: () =>
                                setState(() => _tasks.insert(index, backup)),
                          ),
                        ),
                      )
                      .closed
                      .then((reason) {
                        if (reason == SnackBarClosedReason.timeout)
                          _deleteTask(task['id'].toString());
                      });
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailScreen(
                          task: task,
                          onUpdate: () => _fetchTasks(),
                        ),
                      ),
                    ),
                    leading: IconButton(
                      icon: Icon(
                        task['status'] == 'Completed'
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: task['status'] == 'Completed'
                            ? Colors.green
                            : Colors.blueAccent,
                      ),
                      onPressed: () => _toggleTaskStatus(
                        task['id'].toString(),
                        task['status'],
                      ),
                    ),
                    title: Text(task['title']),
                    subtitle: Text("Due: ${task['deadline']}"),
                  ),
                ),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'My Tasks' : 'Profile'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: _currentIndex == 0
          ? _buildDashboard()
          : ProfileScreen(user: widget.user),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Tasks"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              backgroundColor: Colors.blueAccent,
              onPressed: _showAddTaskDialog,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
