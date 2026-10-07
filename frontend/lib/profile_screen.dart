import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/changePasswordScreen.dart';
import 'package:http/http.dart' as http;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FlutterSecureStorage storage =
      const FlutterSecureStorage();

  final String baseUrl =
      "http://localhost:5000";

  final nameController =
      TextEditingController();

  final emailController =
      TextEditingController();

  bool isLoading = true;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();

    fetchProfile();
  }

  // -----------------------------------------
  // GET HEADERS
  // -----------------------------------------

  Future<Map<String, String>> getHeaders() async {
    final token =
        await storage.read(key: "token");

    if (token == null || token.isEmpty) {
      throw Exception(
        "Please login again",
      );
    }

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  // -----------------------------------------
  // GET PROFILE
  // -----------------------------------------

  Future<void> fetchProfile() async {
    try {
      final headers =
          await getHeaders();

      final response = await http.get(
        Uri.parse(
          "$baseUrl/users/profile",
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data =
            jsonDecode(response.body);

        final user = data["user"];

        setState(() {
          nameController.text =
              user["name"] ?? "";

          emailController.text =
              user["email"] ?? "";

          isLoading = false;
        });
      } else {
        showMessage(
          "Failed to load profile",
        );

        setState(() {
          isLoading = false;
        });
      }
    } catch (error) {
      showMessage(
        "Error: $error",
      );

      setState(() {
        isLoading = false;
      });
    }
  }

  // -----------------------------------------
  // UPDATE PROFILE
  // -----------------------------------------

  Future<void> updateProfile() async {
  final name = nameController.text.trim();
  final email = emailController.text.trim();

  if (name.isEmpty) {
    showMessage("Name cannot be empty");
    return;
  }

  if (email.isEmpty) {
    showMessage("Email cannot be empty");
    return;
  }

  setState(() {
    isUpdating = true;
  });

  try {
    final headers = await getHeaders();

    final response = await http.put(
      Uri.parse("$baseUrl/users/profile"),
      headers: headers,
      body: jsonEncode({
        "name": name,
        "email": email,
      }),
    );

    debugPrint("========== UPDATE PROFILE RESPONSE ==========");
    debugPrint("Status: ${response.statusCode}");
    debugPrint("Body: ${response.body}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      debugPrint("========== UPDATED USER ==========");
      debugPrint(data["user"].toString());

      showMessage("Profile updated successfully");

      if (!mounted) return;

      Navigator.pop(
        context,
        data["user"],
      );
    } else {
      showMessage(
        data["message"] ?? "Failed to update profile",
      );
    }
  } catch (error) {
    debugPrint("UPDATE PROFILE ERROR: $error");

    if (mounted) {
      showMessage("Error: $error");
    }
  } finally {
    if (mounted) {
      setState(() {
        isUpdating = false;
      });
    }
  }
}


  // -----------------------------------------
  // MESSAGE
  // -----------------------------------------

  void showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("My Profile"),
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Padding(
              padding:
                  const EdgeInsets.all(
                20,
              ),

              child: Column(
                children: [
                  TextField(
                    controller:
                        nameController,
                    decoration:
                        const InputDecoration(
                      labelText: "Name",
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(
                    height: 20,
                  ),

                  TextField(
                    controller:
                        emailController,
                    keyboardType:
                        TextInputType
                            .emailAddress,
                    decoration:
                        const InputDecoration(
                      labelText: "Email",
                      border:
                          OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(
                    height: 30,
                  ),

                  SizedBox(
                    width:
                        double.infinity,

                    child:
                        ElevatedButton(
                      onPressed:
                          isUpdating
                              ? null
                              : updateProfile,

                      child: isUpdating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                              ),
                            )
                          : const Text(
                              "Update Profile",
                            ),
                    ),
                    
                  ),
                  const SizedBox(height: 15),

SizedBox(
  width: double.infinity,
  child: OutlinedButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const ChangePasswordScreen(),
        ),
      );
    },
    child: const Text(
      "Change Password",
    ),
  ),
),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();

    super.dispose();
  }
}