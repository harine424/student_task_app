import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/user_model.dart';
import '../services/api_path.dart';
import 'profile_screen.dart';
import 'rewards_screen.dart';
import 'task_detail_screen.dart';

class MainScreen extends StatefulWidget {
  final UserModel user;
  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final Color primaryMaroon = const Color(0xFF7B1113);
  final Color backgroundWhite = const Color(0xFFF8F9FA);
  final Color textDark = const Color(0xFF333333);

  int _currentIndex = 0;
  List<dynamic> _tasks = [];
  String _currentFilter = 'All';

  bool _isLoading = true;

  String get _loadTasksApiUrl => ApiPath.endpoint("load_tasks.php");

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
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
        return "Overdue: ${diff.abs().inHours}h ${diff.abs().inMinutes.remainder(60)}m";
      } else {
        return "Time left: ${diff.inHours}h ${diff.inMinutes.remainder(60)}m";
      }
    } catch (e) {
      return "No deadline";
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final tasksUri = Uri.parse(
        _loadTasksApiUrl,
      ).replace(queryParameters: {'user_id': widget.user.id.toString()});

      final response = await http.get(tasksUri);

      if (response.statusCode != 200) {
        throw Exception('Failed to load dashboard data');
      }

      final data = jsonDecode(response.body);

      if (data['status'] != 'success') {
        throw Exception(data['message'] ?? 'Failed to load data');
      }

      final loadedTasks = List<dynamic>.from(data['tasks'] ?? []);

      if (!mounted) return;
      setState(() {
        _tasks
          ..clear()
          ..addAll(loadedTasks);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Dashboard load error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    _loadDashboardData();
  }

  Future<void> _deleteTask(String id) async {
    await http.post(
      Uri.parse(ApiPath.endpoint("delete_task.php")),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"task_id": id}),
    );
    _loadDashboardData();
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
      Uri.parse(ApiPath.endpoint("insert_task.php")),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": widget.user.id,
        "title": title,
        "deadline": deadline,
        "status": "Pending",
      }),
    );
    _loadDashboardData();
  }

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
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              "Add New Task",
              style: TextStyle(
                color: primaryMaroon,
                fontWeight: FontWeight.bold,
              ),
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
                    prefixIcon: Icon(
                      Icons.calendar_month,
                      color: primaryMaroon,
                    ),
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
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
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
          );
        },
      ),
    );
  }

  Widget _buildResponsiveBody(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth >= 1500
            ? 1280.0
            : constraints.maxWidth >= 1100
            ? 1120.0
            : constraints.maxWidth;

        return Align(
          alignment: Alignment.topCenter,
          child: SizedBox(width: maxWidth, child: child),
        );
      },
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [primaryMaroon, const Color(0xFF5D0C0E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome, ${widget.user.name}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Student | ${widget.user.email}',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.78)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color backgroundColor,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: backgroundColor,
            child: Icon(icon, color: primaryMaroon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardStatusChip(String status) {
    Color backgroundColor;
    Color foregroundColor;

    switch (status) {
      case 'Completed':
        backgroundColor = Colors.green.shade100;
        foregroundColor = Colors.green.shade900;
        break;
      case 'In Progress':
        backgroundColor = Colors.blue.shade100;
        foregroundColor = Colors.blue.shade900;
        break;
      case 'Pending':
      default:
        backgroundColor = Colors.orange.shade100;
        foregroundColor = Colors.orange.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: foregroundColor,
        ),
      ),
    );
  }

  Widget _buildUrgencyBanner() {
    Map<String, dynamic>? urgentTask = _getClosestDeadline();
    if (urgentTask == null) return const SizedBox.shrink();

    try {
      DateTime deadline = DateTime.parse(urgentTask['deadline']);
      DateTime now = DateTime.now();
      Duration diff = deadline.difference(now);

      if (diff.isNegative) {
        return Card(
          color: Colors.red.shade50,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "⚠️ Reminder: '${urgentTask['title']}' is OVERDUE!",
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (diff.inHours <= 24) {
        return Card(
          color: Colors.orange.shade50,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(Icons.timer, color: Colors.orange.shade700),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "⏳ Reminder: '${urgentTask['title']}' is due in ${diff.inHours} hours!",
                    style: TextStyle(
                      color: Colors.orange.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      return const SizedBox.shrink();
    }
    return const SizedBox.shrink();
  }

  Widget _buildDashboard() {
    final pendingTasks = _tasks.where((t) => t['status'] == 'Pending').length;
    final totalTasks = _tasks.length;
    final streak = _calculateResponsibilityStreak();

    final filteredTasks = _tasks.where((task) {
      if (_currentFilter == 'All') return true;
      if (_currentFilter == 'Overdue') {
        try {
          return DateTime.parse(task['deadline']).isBefore(DateTime.now()) &&
              task['status'] != 'Completed';
        } catch (e) {
          return false;
        }
      }
      return task['status'] == _currentFilter;
    }).toList();

    return _buildResponsiveBody(
      _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildWelcomeCard(),
                  const SizedBox(height: 16),

                  _buildUrgencyBanner(),

                  Text(
                    'App Summary',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cards = [
                        _buildSummaryCard(
                          'Total Tasks',
                          totalTasks.toString(),
                          Icons.assignment_outlined,
                          const Color(0xFFDBEAFE),
                        ),
                        _buildSummaryCard(
                          'Pending',
                          pendingTasks.toString(),
                          Icons.hourglass_top_outlined,
                          const Color(0xFFFEF3C7),
                        ),
                        _buildSummaryCard(
                          'Completed Streak',
                          streak.toString(),
                          Icons.local_fire_department,
                          const Color(0xFFDCFCE7),
                        ),
                      ];

                      if (constraints.maxWidth >= 900) {
                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cards.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 2.8,
                              ),
                          itemBuilder: (context, index) => cards[index],
                        );
                      }
                      return Column(
                        children: [
                          for (int i = 0; i < cards.length; i++) ...[
                            cards[i],
                            if (i != cards.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Tasks',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.filter_list),
                        onSelected: (String newValue) =>
                            setState(() => _currentFilter = newValue),
                        itemBuilder: (BuildContext context) =>
                            <PopupMenuEntry<String>>[
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
                  const SizedBox(height: 10),

                  if (filteredTasks.isEmpty)
                    Card(
                      color: Theme.of(context).colorScheme.surface,
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No tasks available'),
                      ),
                    )
                  else
                    ...filteredTasks.map(
                      (task) => Card(
                        color: Theme.of(context).colorScheme.surface,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskDetailScreen(
                                task: task,
                                onUpdate: () => _loadDashboardData(),
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
                                  : Colors.grey,
                            ),
                            onPressed: () => _cycleTaskStatus(
                              task['id'].toString(),
                              task['status'],
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
                                  : textDark,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            task['status'] == 'Completed'
                                ? "Due: ${task['deadline']} • Done! 🎉"
                                : "Due: ${task['deadline']}\n${_calculateTimeRemaining(task['deadline'])}",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildDashboardStatusChip(task['status']),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    _deleteTask(task['id'].toString()),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
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
        backgroundColor: primaryMaroon,
        elevation: 0,
        actions: [
          if (_currentIndex == 0)
            IconButton(
              onPressed: _loadDashboardData,
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh, color: Colors.white),
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
