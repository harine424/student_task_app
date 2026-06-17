import 'package:flutter/material.dart';

class RewardsScreen extends StatelessWidget {
  final List<dynamic> tasks;

  const RewardsScreen({super.key, required this.tasks});

  int _calculateResponsibilityStreak() {
    return tasks.where((t) => t['status'] == 'Completed').length;
  }

  @override
  Widget build(BuildContext context) {
    int streak = _calculateResponsibilityStreak();
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 100, color: Colors.amber),
            const SizedBox(height: 20),
            Text(
              "Your Score: $streak",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Assignments completed on time!",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            if (streak >= 5)
              const Text(
                "🏆 You are a Pro Student!",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Text(
                "Complete ${5 - streak} more to reach Pro level!",
                style: const TextStyle(color: Colors.blueGrey),
              ),
          ],
        ),
      ),
    );
  }
}
