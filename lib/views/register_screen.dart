import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/api_path.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  String get apiUrl => ApiPath.endpoint("register.php");

  Future<void> registerUser() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": nameController.text.trim(),
          "email": emailController.text.trim(),
          "password": passwordController.text,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("HTTP ${response.statusCode}");
      }

      final data = jsonDecode(response.body);

      if (data["status"] != "success") {
        throw Exception(data["message"] ?? "Registration failed");
      }

      setState(() => isLoading = false);
      if (!mounted) return;

      // Success!
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registration Successful! Please login."),
          backgroundColor: Colors.green,
        ),
      );

      // Send the user back to the Login Screen
      Navigator.pop(context);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Registration failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Create Account",
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Sign up to get started",
                  style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                ),
                const SizedBox(height: 25),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    prefixIcon: Icon(
                      Icons.person,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    prefixIcon: Icon(
                      Icons.email,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest,
                    prefixIcon: Icon(
                      Icons.lock,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: isLoading ? null : registerUser,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Register",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
