import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FlutterSecureStorage storage =
      const FlutterSecureStorage();

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool isLoading = false;
  bool isPasswordVisible = false;

  Future<void> registerUser() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Prepare request body
      final Map<String, dynamic> body = {
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "password": passwordController.text,
      };

      final Map<String, String> headers = {
        "Content-Type": "application/json",
      };

      // Print request details
      debugPrint("========== REGISTRATION REQUEST ==========");
      debugPrint("Method: POST");
      debugPrint("URL: http://localhost:5000/auth/register");

      debugPrint("REQUEST HEADERS: ${headers.toString()}");
      debugPrint("REQUEST BODY: ${jsonEncode(body)}");

      // Call backend registration API
      final response = await http.post(
        Uri.parse("http://localhost:5000/auth/register"),
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint("========== REGISTRATION RESPONSE ==========");
      debugPrint("Status: ${response.statusCode}");
      debugPrint("Headers: ${response.headers}");
      debugPrint("Body: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Get JWT created by backend
        final String token = data["token"];

        // Save JWT securely
        await storage.write(
          key: "token",
          value: token,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful'),
          ),
        );

        // Navigate to HomeScreen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => HomeScreen(
            ),
          ),
          (route) => false,
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data["message"] ?? "Registration failed",
            ),
          ),
        );
      }
    } catch (error) {
      debugPrint("REGISTRATION ERROR: $error");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Server error: $error"),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 30),

              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: passwordController,
                obscureText: isPasswordVisible,
                decoration:  InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(onPressed: (){
                    setState(() {
                      isPasswordVisible = !isPasswordVisible;
                    });
                  }, icon: Icon(isPasswordVisible ? Icons.visibility:Icons.visibility_off)),
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      isLoading ? null : registerUser,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Register'),
                ),
              ),

              const SizedBox(height: 12),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Already have an account? Login',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}