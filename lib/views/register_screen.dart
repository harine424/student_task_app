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
  final _formKey = GlobalKey<FormState>(); // Added FormKey for validation

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  String? selectedRole;
  final List<String> roles = ["Student", "Lecturer", "Public"];

  final Color primaryMaroon = const Color(0xFF7B1113);
  final Color fieldBackground = const Color(0xFFF5F6FA);

  String get apiUrl => ApiPath.endpoint("register.php");

  double getResponsiveWidth(double width) {
    if (width > 900) return 400;
    if (width > 600) return 500;
    return width * 0.9;
  }

  Future<void> registerUser() async {
    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": nameController.text.trim(),
          "email": emailController.text.trim(),
          "password": passwordController.text,
          "role": selectedRole,
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Registration Successful! You can now log in.",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.green,
        ),
      );

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

  void confirmRegister() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Registration"),
        content: const Text("Are you sure you want to register?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryMaroon,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              registerUser();
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final availableHeight =
        mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom -
        mediaQuery.viewInsets.bottom;
    final formWidth = getResponsiveWidth(screenWidth);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryMaroon),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            mediaQuery.viewInsets.bottom + 24,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: availableHeight > 0 ? availableHeight : 0,
            ),
            child: Center(
              child: Container(
                width: formWidth,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: screenWidth > 600
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.10),
                            blurRadius: 10,
                          ),
                        ]
                      : [],
                ),
                // Wrapped the Column in a Form widget
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          height: 140,
                          width: 180,
                          decoration: BoxDecoration(
                            color: fieldBackground,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.person_add_alt_1,
                            size: 70,
                            color: primaryMaroon.withOpacity(0.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      Text(
                        "Register",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: primaryMaroon,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        "Create an account to get started.",
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 25),

                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: fieldBackground,
                          labelText: "Full Name",
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: fieldBackground,
                          labelText: "Email",
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: fieldBackground,
                          labelText: "Role",
                          prefixIcon: const Icon(
                            Icons.badge_outlined,
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        hint: const Text("Choose your role"),
                        items: roles
                            .map(
                              (role) => DropdownMenuItem(
                                value: role,
                                child: Text(role),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedRole = value),
                      ),
                      const SizedBox(height: 12),

                      // Changed to TextFormField for Validation
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: fieldBackground,
                          labelText: "Password",
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Colors.grey,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed: () => setState(
                              () => obscurePassword = !obscurePassword,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 8) {
                            return 'Must be at least 8 characters';
                          }
                          if (!RegExp(r'[a-zA-Z]').hasMatch(value)) {
                            return 'Must contain at least one alphabet character';
                          }
                          if (!RegExp(r'[0-9]').hasMatch(value)) {
                            return 'Must contain at least one number';
                          }
                          if (!RegExp(
                            r'[!@#\$%^&*(),.?":{}|<>]',
                          ).hasMatch(value)) {
                            return 'Must contain at least one symbol';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Changed to TextFormField for Validation
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: fieldBackground,
                          labelText: "Confirm Password",
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryMaroon,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: isLoading
                              ? null
                              : () {
                                  if (selectedRole == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Please select a role"),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }

                                  // Triggers the Form Validations
                                  if (_formKey.currentState!.validate()) {
                                    confirmRegister();
                                  }
                                },
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Register",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 15),

                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: RichText(
                            text: TextSpan(
                              text: "Already have an account? ",
                              style: const TextStyle(color: Colors.grey),
                              children: [
                                TextSpan(
                                  text: "Sign In",
                                  style: TextStyle(
                                    color: primaryMaroon,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
