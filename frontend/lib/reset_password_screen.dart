import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.email,
  });

  @override
  State<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState
    extends State<ResetPasswordScreen> {
  final newPasswordController =
      TextEditingController();

  final confirmPasswordController =
      TextEditingController();

  final String baseUrl =
      "http://localhost:5000";

  bool isLoading = false;

  bool hidePassword = true;
  bool hideConfirmPassword = true;

  Future<void> resetPassword() async {
    final newPassword =
        newPasswordController.text;

    final confirmPassword =
        confirmPasswordController.text;

    if (newPassword.isEmpty) {
      showMessage(
        "Please enter a new password",
      );
      return;
    }

    if (newPassword.length < 6) {
      showMessage(
        "Password must be at least 6 characters",
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      showMessage(
        "Please confirm your password",
      );
      return;
    }

    if (newPassword != confirmPassword) {
      showMessage(
        "Passwords do not match",
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          "$baseUrl/auth/reset-password",
        ),
        headers: {
          "Content-Type":
              "application/json",
        },
        body: jsonEncode({
          "email": widget.email,
          "newPassword": newPassword,
        }),
      );

      final data =
          jsonDecode(response.body);

      if (response.statusCode == 200) {
        showMessage(
          "Password reset successfully",
        );

        await Future.delayed(
          const Duration(
            milliseconds: 800,
          ),
        );

        if (!mounted) return;

        // Remove reset screens and
        // return to LoginScreen.
        Navigator.popUntil(
          context,
          (route) => route.isFirst,
        );
      } else {
        showMessage(
          data["message"] ??
              "Failed to reset password",
        );
      }
    } catch (error) {
      showMessage(
        "Unable to connect to server",
      );

      print(
        "Reset password error: $error",
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Reset Password"),
      ),

      body: Padding(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          children: [
            const SizedBox(height: 30),

            const Text(
              "Create a new password",
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Enter your new password below.",
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(height: 30),

            TextField(
              controller:
                  newPasswordController,

              obscureText:
                  hidePassword,

              decoration:
                  InputDecoration(
                labelText:
                    "New Password",

                border:
                    const OutlineInputBorder(),

                prefixIcon:
                    const Icon(
                  Icons.lock,
                ),

                suffixIcon:
                    IconButton(
                  icon: Icon(
                    hidePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),

                  onPressed: () {
                    setState(() {
                      hidePassword =
                          !hidePassword;
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
                    "Confirm Password",

                border:
                    const OutlineInputBorder(),

                prefixIcon:
                    const Icon(
                  Icons.lock,
                ),

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
                    isLoading
                        ? null
                        : resetPassword,

                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Reset Password",
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
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }
}