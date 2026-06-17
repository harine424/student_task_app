import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_path.dart';
import 'profile_screen.dart';
import 'rewards_screen.dart';
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
  String _currentFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  int _calculateResponsibilityStreak() {
    return _tasks.where((t) => t['status'] == 'Completed').length;
  }

  String _calculateTimeRemaining(String deadlineStr) {
    try {
      DateTime deadline = DateTime.parse(deadlineStr);
      DateTime now = DateTime.now();
      Duration diff = deadline.difference(now);

      if (diff.isNegative) {
        return "Overdue by: ${diff.abs().inHours}h ${diff.abs().inMinutes.remainder(60)}m";
      } else {
        return "Time left: ${diff.inHours}h ${diff.inMinutes.remainder(60)}m";
      }
    } catch (e) {
      return "No deadline";
    }
  }

  Future<void> _fetchTasks() async {
    try {
      final url = ApiPath.endpoint(
        "load_tasks.php?user_id=${widget.user['id']}",
      );
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          setState(() {
            _tasks = data['tasks'] ?? [];
          });
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _cycleTaskStatus(String id, String currentStatus) async {
    String newStatus;
    if (currentStatus == 'Pending') {
      newStatus = 'In Progress';
    } else if (currentStatus == 'In Progress') {
      newStatus = 'Completed';
    } else {
      newStatus = 'Pending';
    }

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

  IconData _getStatusIcon(String status) {
    if (status == 'Completed') return Icons.check_circle;
    if (status == 'In Progress') return Icons.run_circle;
    return Icons.radio_button_unchecked;
  }

  Color _getStatusColor(String status) {
    if (status == 'Completed') return Colors.green;
    if (status == 'In Progress') return Colors.orange;
    return Colors.grey;
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
                if (picked != null) {
                  dateController.text =
                      "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
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
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final filteredTasks = _tasks.where((task) {
      if (_currentFilter == 'All') return true;

      if (_currentFilter == 'Overdue') {
        try {
          DateTime deadline = DateTime.parse(task['deadline']);
          return deadline.isBefore(DateTime.now()) &&
              task['status'] != 'Completed';
        } catch (e) {
          return false;
        }
      }

      return task['status'] == _currentFilter;
    }).toList();

    return filteredTasks.isEmpty
        ? Center(child: Text("No tasks in '$_currentFilter'"))
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filteredTasks.length,
            itemBuilder: (context, index) {
              final task = filteredTasks[index];
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
                        if (reason == SnackBarClosedReason.timeout) {
                          _deleteTask(task['id'].toString());
                        }
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
                    title: Text(
                      task['title'],
                      style: TextStyle(
                        decoration: task['status'] == 'Completed'
                            ? TextDecoration.lineThrough
                            : null,
                        color: task['status'] == 'Completed'
                            ? Colors.grey
                            : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      task['status'] == 'Completed'
                          ? "Due: ${task['deadline']}\nStatus: Completed - Great job! 🎉"
                          : "Due: ${task['deadline']}\nStatus: ${task['status']} - ${_calculateTimeRemaining(task['deadline'])}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.blueGrey,
                      ),
                    ),
                    leading: IconButton(
                      icon: Icon(
                        _getStatusIcon(task['status']),
                        color: _getStatusColor(task['status']),
                        size: 28,
                      ),
                      onPressed: () => _cycleTaskStatus(
                        task['id'].toString(),
                        task['status'],
                      ),
                    ),
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
        title: Row(
          children: [
            Text(
              _currentIndex == 0
                  ? 'My Tasks'
                  : (_currentIndex == 1 ? 'Rewards' : 'Profile'),
            ),
            const Spacer(),
            if (_calculateResponsibilityStreak() > 0) ...[
              const Icon(Icons.local_fire_department, color: Colors.orange),
              const SizedBox(width: 4),
              Text(
                "${_calculateResponsibilityStreak()}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
            ],
          ],
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          if (_currentIndex == 0)
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              onSelected: (String newValue) {
                setState(() {
                  _currentFilter = newValue;
                });
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'All',
                  child: Text('All Tasks'),
                ),
                const PopupMenuItem<String>(
                  value: 'Pending',
                  child: Text('Pending'),
                ),
                const PopupMenuItem<String>(
                  value: 'In Progress',
                  child: Text('In Progress'),
                ),
                const PopupMenuItem<String>(
                  value: 'Completed',
                  child: Text('Completed'),
                ),
                const PopupMenuItem<String>(
                  value: 'Overdue',
                  child: Text(
                    'Overdue Deadlines',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _currentIndex == 0
          ? _buildDashboard()
          : (_currentIndex == 1
                ? RewardsScreen(tasks: _tasks)
                : ProfileScreen(user: widget.user)),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Tasks"),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: "Rewards",
          ),
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
