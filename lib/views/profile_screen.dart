import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/user_model.dart';
import '../services/api_path.dart';
import 'support_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String _currentName;
  late String _currentEmail;

  @override
  void initState() {
    super.initState();
    _currentName = widget.user.name ?? 'User';
    _currentEmail = widget.user.email ?? 'No email';
  }

  Future<void> _updateProfile(String name, String email) async {
    try {
      final response = await http.post(
        Uri.parse(ApiPath.endpoint("update_profile.php")),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": widget.user.id,
          "name": name,
          "email": email,
        }),
      );

      debugPrint("SERVER RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          // Update the screen instantly
          setState(() {
            _currentName = name;
            _currentEmail = email;
          });

          widget.user.name;
          widget.user.email;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Profile updated successfully!"),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          debugPrint("Server Error: ${data['message']}");
        }
      }
    } catch (e) {
      debugPrint("HTTP Error updating profile: $e");
    }
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _currentName);
    final emailController = TextEditingController(text: _currentEmail);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Edit Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Full Name",
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email Address",
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
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
              _updateProfile(nameController.text, emailController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text("Save Changes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 30),

            // Profile Header
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              child: const Icon(
                Icons.person,
                size: 70,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _currentName,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            Text(
              _currentEmail,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 40),

            // Menu Items
            _buildMenuItem(
              context,
              Icons.edit,
              "Edit Profile",
              _showEditProfileDialog,
            ),

            _buildMenuItem(context, Icons.help_outline, "Help & Support", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SupportScreen()),
              );
            }),

            const Divider(height: 40),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/', (route) => false),
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Student Task App v1.0",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
