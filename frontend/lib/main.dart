import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';
import 'home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  final FlutterSecureStorage storage =
      const FlutterSecureStorage();

  bool isLoading = true;
  bool hasServerError = false;

  String? token;
  String? name;
  String? email;
  String? userId;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    try {
      // Step 1: Read saved token
      final String? savedToken =
          await storage.read(key: "token");

      if (savedToken == null) {
        if (!mounted) return;

        setState(() {
          isLoading = false;
        });

        return;
      }

      // Step 2: Prepare profile request headers
      final Map<String, String> headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $savedToken",
      };

      // Print complete request details
      debugPrint("========== AUTH CHECK REQUEST ==========");
      debugPrint("Method: GET");
      debugPrint("URL: http://localhost:5000/users/profile");

      debugPrint("========== REQUEST HEADERS ==========");

      headers.forEach((key, value) {
        debugPrint("$key: $value");
      });

      // Step 3: Validate token using profile API
      final response = await http.get(
        Uri.parse("http://localhost:5000/users/profile"),
        headers: headers,
      );

      // Print response details
      debugPrint("========== RESPONSE STATUS ==========");
      debugPrint(response.statusCode.toString());

      debugPrint("========== RESPONSE HEADERS ==========");

      response.headers.forEach((key, value) {
        debugPrint("$key: $value");
      });

      debugPrint("========== RESPONSE BODY ==========");
      debugPrint(response.body);

      if (response.statusCode == 200) {
        // Step 4: Read user details
        final data = jsonDecode(response.body);
        final user = data["user"];

        if (user == null ||
            user["name"] == null ||
            user["email"] == null ||
            (user["id"] == null && user["_id"] == null)) {
          throw Exception("Invalid profile response");
        }

        if (!mounted) return;

        setState(() {
          token = savedToken;
          name = user["name"];
          email = user["email"];
          userId = (user["id"] ?? user["_id"]).toString();

          isLoading = false;
          hasServerError = false;
        });
      } else if (response.statusCode == 401) {
        // Invalid or expired token
        await storage.delete(key: "token");

        if (!mounted) return;

        setState(() {
          token = null;
          isLoading = false;
          hasServerError = false;
        });
      } else {
        // Server error: preserve saved token
        if (!mounted) return;

        setState(() {
          isLoading = false;
          hasServerError = true;
        });
      }
    } catch (error) {
      debugPrint("AUTH CHECK ERROR: $error");

      if (!mounted) return;

      setState(() {
        isLoading = false;
        hasServerError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking session
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // No token or token rejected
    if (token == null && !hasServerError) {
      return const LoginScreen();
    }

    // Server unavailable: preserve session and allow retry
    if (hasServerError) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Unable to verify your session. "
                  "Please check your connection.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isLoading = true;
                      hasServerError = false;
                    });

                    checkLoginStatus();
                  },
                  child: const Text("Retry"),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () async {
                    await storage.delete(key: "token");

                    if (!mounted) return;

                    setState(() {
                      token = null;
                      hasServerError = false;
                    });
                  },
                  child: const Text("Go to Login"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Valid token: open HomeScreen
    return HomeScreen();
  }
}