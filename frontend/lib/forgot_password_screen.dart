import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'verify_otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();

  final String baseUrl = "http://localhost:5000";

  bool isLoading = false;

  Future<void> sendOtp() async {
  final email = emailController.text.trim();

  if (email.isEmpty) {
    showMessage("Please enter your email");
    return;
  }

  setState(() {
    isLoading = true;
  });

  try {
    final response = await http.post(
      Uri.parse("$baseUrl/auth/forgot-password"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "email": email,
      }),
    );

    // Debug information
    print("STATUS CODE: ${response.statusCode}");
    print("RESPONSE HEADERS: ${response.headers}");
    print("RESPONSE BODY: ${response.body}");

    // Only decode JSON if the server actually returned JSON
    if (response.headers["content-type"]?.contains("application/json") ??
        false) {
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        showMessage(
          "If an account exists, an OTP has been sent",
        );

        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VerifyOtpScreen(
              email: email,
            ),
          ),
        );
      } else {
        showMessage(
          data["message"] ?? "Failed to send OTP",
        );
      }
    } else {
      // Server returned HTML or something other than JSON
      print("Server returned non-JSON response");

      showMessage(
        "Server error: ${response.statusCode}",
      );
    }
  } catch (error) {
    print("Forgot password error: $error");

    showMessage(
      "Unable to connect to server",
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
        title: const Text(
          "Forgot Password",
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const SizedBox(height: 30),

            const Text(
              "Reset your password",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Enter your registered email address. "
              "We will send you a verification OTP.",
            ),

            const SizedBox(height: 30),

            TextField(
              controller: emailController,
              keyboardType:
                  TextInputType.emailAddress,

              decoration:
                  const InputDecoration(
                labelText: "Email",
                hintText:
                    "Enter your email",
                border:
                    OutlineInputBorder(),
                prefixIcon:
                    Icon(Icons.email),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                onPressed:
                    isLoading
                        ? null
                        : sendOtp,

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
                        "Send OTP",
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
    emailController.dispose();
    super.dispose();
  }
}