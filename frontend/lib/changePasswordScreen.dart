import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({
    super.key,
  });

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {

  final FlutterSecureStorage storage =
      const FlutterSecureStorage();

  final String baseUrl =
      "http://localhost:5000";

  final currentPasswordController =
      TextEditingController();

  final newPasswordController =
      TextEditingController();

  final confirmPasswordController =
      TextEditingController();

  bool isUpdating = false;

  bool hideCurrentPassword = true;
  bool hideNewPassword = true;
  bool hideConfirmPassword = true;

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
  // CHANGE PASSWORD
  // -----------------------------------------

  Future<void> changePassword() async {
    final currentPassword =
        currentPasswordController.text;

    final newPassword =
        newPasswordController.text;

    final confirmPassword =
        confirmPasswordController.text;

    if (currentPassword.isEmpty) {
      showMessage(
        "Enter your current password",
      );
      return;
    }

    if (newPassword.isEmpty) {
      showMessage(
        "Enter your new password",
      );
      return;
    }

    if (newPassword.length < 6) {
      showMessage(
        "New password must be at least 6 characters",
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      showMessage(
        "Confirm your new password",
      );
      return;
    }

    if (newPassword != confirmPassword) {
      showMessage(
        "New passwords do not match",
      );
      return;
    }

    setState(() {
      isUpdating = true;
    });

    try {
      final headers =
          await getHeaders();

      final response = await http.put(
        Uri.parse(
          "$baseUrl/users/change-password",
        ),
        headers: headers,
        body: jsonEncode({
          "currentPassword":
              currentPassword,
          "newPassword":
              newPassword,
        }),
      );

      final data =
          jsonDecode(response.body);

      if (response.statusCode == 200) {
        showMessage(
          "Password changed successfully",
        );

        currentPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();

      } else {
        showMessage(
          data["message"] ??
              "Failed to change password",
        );
      }

    } catch (error) {
      showMessage(
        "Error: $error",
      );
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

  // -----------------------------------------
  // UI
  // -----------------------------------------

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Change Password"),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          children: [

            TextField(
              controller:
                  currentPasswordController,

              obscureText:
                  hideCurrentPassword,

              decoration:
                  InputDecoration(
                labelText:
                    "Current Password",

                border:
                    const OutlineInputBorder(),

                suffixIcon:
                    IconButton(
                  icon: Icon(
                    hideCurrentPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),

                  onPressed: () {
                    setState(() {
                      hideCurrentPassword =
                          !hideCurrentPassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller:
                  newPasswordController,

              obscureText:
                  hideNewPassword,

              decoration:
                  InputDecoration(
                labelText:
                    "New Password",

                border:
                    const OutlineInputBorder(),

                suffixIcon:
                    IconButton(
                  icon: Icon(
                    hideNewPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),

                  onPressed: () {
                    setState(() {
                      hideNewPassword =
                          !hideNewPassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller:
                  confirmPasswordController,

              obscureText:
                  hideConfirmPassword,

              decoration:
                  InputDecoration(
                labelText:
                    "Confirm New Password",

                border:
                    const OutlineInputBorder(),

                suffixIcon:
                    IconButton(
                  icon: Icon(
                    hideConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),

                  onPressed: () {
                    setState(() {
                      hideConfirmPassword =
                          !hideConfirmPassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width:
                  double.infinity,

              child:
                  ElevatedButton(
                onPressed:
                    isUpdating
                        ? null
                        : changePassword,

                child:
                    isUpdating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Change Password",
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------
  // DISPOSE
  // -----------------------------------------

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }
}