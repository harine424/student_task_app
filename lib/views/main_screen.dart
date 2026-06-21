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
  // --- UI Colors ---
  final Color primaryMaroon = const Color(0xFF7B1113); // Deep, rich maroon
  final Color backgroundWhite = const Color(0xFFF8F9FA);
  final Color textDark = const Color(0xFF333333);

  // --- Logic State ---
  int _currentIndex = 0;
  List<dynamic> _tasks = [];
  String _currentFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  // --- Backend Logic (Unchanged) ---
  int _calculateResponsibilityStreak() {
    return _tasks.where((t) => t['status'] == 'Completed').length;
  }

  String _calculateTimeRemaining(String deadlineStr) {
    try {
      DateTime deadline = DateTime.parse(deadlineStr);
      DateTime now = DateTime.now();
      Duration diff = deadline.difference(now);

      if (diff.isNegative) {
        return "Overdue: ${diff.abs().inHours}h ${diff.abs().inMinutes.remainder(60)}m";
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
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Task successfully deleted."),
          backgroundColor: Colors.black87,
        ),
      );
    }
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

  // --- UI Helpers ---
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

  // Find the closest pending deadline to highlight in the top card
  Map<String, dynamic>? _getClosestDeadline() {
    final pendingTasks = _tasks
        .where((t) => t['status'] != 'Completed')
        .toList();
    if (pendingTasks.isEmpty) return null;

    pendingTasks.sort((a, b) {
      try {
        return DateTime.parse(
          a['deadline'],
        ).compareTo(DateTime.parse(b['deadline']));
      } catch (e) {
        return 0;
      }
    });
    return pendingTasks.first;
  }

  void _showAddTaskDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController dateController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Add New Task",
          style: TextStyle(color: primaryMaroon, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Task Title",
                prefixIcon: Icon(Icons.edit_note, color: primaryMaroon),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: dateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Deadline Date",
                prefixIcon: Icon(Icons.calendar_month, color: primaryMaroon),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2030),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: primaryMaroon,
                          onPrimary: Colors.white,
                          onSurface: textDark,
                        ),
                      ),
                      child: child!,
                    );
                  },
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
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryMaroon,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              _submitNewTask(titleController.text, dateController.text);
            },
            child: const Text(
              "Save Task",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // --- Main Dashboard UI ---
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

    Map<String, dynamic>? upcomingTask = _getClosestDeadline();

    return Column(
      children: [
        // 1. Curved Maroon Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 30, left: 20, right: 20),
          decoration: BoxDecoration(
            color: primaryMaroon,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(40),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Highlight Card (Shows closest upcoming deadline dynamically!)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            upcomingTask != null
                                ? "Next Deadline"
                                : "All Caught Up!",
                            style: TextStyle(
                              color: primaryMaroon,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            upcomingTask != null
                                ? upcomingTask['title']
                                : "Take a break, you've earned it.",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (upcomingTask != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: primaryMaroon.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _calculateTimeRemaining(
                            upcomingTask['deadline'],
                          ).split(":")[0], // Just shows "Time left"
                          style: TextStyle(
                            color: primaryMaroon,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // 2. Task List
        Expanded(
          child: filteredTasks.isEmpty
              ? Center(
                  child: Text(
                    "No tasks in '$_currentFilter'",
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    bool isCompleted = task['status'] == 'Completed';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.grey.shade200, width: 1),
                      ),
                      color: Colors.white,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 8,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TaskDetailScreen(
                              task: task,
                              onUpdate: () => _fetchTasks(),
                            ),
                          ),
                        ),
                        // Status Circle Button
                        leading: IconButton(
                          icon: Icon(
                            _getStatusIcon(task['status']),
                            color: _getStatusColor(task['status']),
                            size: 30,
                          ),
                          onPressed: () => _cycleTaskStatus(
                            task['id'].toString(),
                            task['status'],
                          ),
                        ),
                        // Title
                        title: Text(
                          task['title'],
                          style: TextStyle(
                            color: isCompleted ? Colors.grey : textDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        // Subtitle
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 5.0),
                          child: Text(
                            isCompleted
                                ? "Due: ${task['deadline']} • Done! 🎉"
                                : "Due: ${task['deadline']}\n${_calculateTimeRemaining(task['deadline'])}",
                            style: TextStyle(
                              color: isCompleted
                                  ? Colors.grey
                                  : Colors.blueGrey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        // Delete Button
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _deleteTask(task['id'].toString()),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundWhite,
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'My Tasks'
              : (_currentIndex == 1 ? 'Rewards' : 'Profile'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor:
            primaryMaroon, // App bar perfectly blends into the header
        elevation: 0,
        centerTitle: false,
        actions: [
          // The Streak Counter!
          if (_calculateResponsibilityStreak() > 0) ...[
            const Icon(Icons.local_fire_department, color: Colors.orangeAccent),
            const SizedBox(width: 4),
            Text(
              "${_calculateResponsibilityStreak()}",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 15),
          ],
          // Filter Menu
          if (_currentIndex == 0)
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list, color: Colors.white),
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
        selectedItemColor: primaryMaroon,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: "Tasks"),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: "Rewards",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),

      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              backgroundColor: primaryMaroon,
              onPressed: _showAddTaskDialog,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            )
          : null,
    );
  }
}
