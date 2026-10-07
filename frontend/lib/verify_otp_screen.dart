import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'reset_password_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({
    super.key,
    required this.email,
  });

  @override
  State<VerifyOtpScreen> createState() =>
      _VerifyOtpScreenState();
}

class _VerifyOtpScreenState
    extends State<VerifyOtpScreen> {
  final otpController =
      TextEditingController();

  final String baseUrl =
      "http://localhost:5000";

  bool isLoading = false;

  Future<void> verifyOtp() async {
    final otp =
        otpController.text.trim();

    if (otp.isEmpty) {
      showMessage(
        "Please enter the OTP",
      );
      return;
    }

    if (otp.length != 6) {
      showMessage(
        "OTP must be 6 digits",
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          "$baseUrl/auth/verify-otp",
        ),
        headers: {
          "Content-Type":
              "application/json",
        },
        body: jsonEncode({
          "email": widget.email,
          "otp": otp,
        }),
      );

      final data =
          jsonDecode(response.body);

      if (response.statusCode == 200) {
        showMessage(
          "OTP verified successfully",
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ResetPasswordScreen(
              email: widget.email,
            ),
          ),
        );
      } else {
        showMessage(
          data["message"] ??
              "Invalid OTP",
        );
      }
    } catch (error) {
      showMessage(
        "Unable to connect to server",
      );

      print(
        "Verify OTP error: $error",
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
            const Text("Verify OTP"),
      ),

      body: Padding(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          children: [
            const SizedBox(height: 30),

            const Text(
              "Enter OTP",
              style: TextStyle(
                fontSize: 24,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "We sent a 6-digit OTP to\n${widget.email}",
              textAlign:
                  TextAlign.center,
            ),

            const SizedBox(height: 30),

            TextField(
              controller:
                  otpController,

              keyboardType:
                  TextInputType.number,

              maxLength: 6,

              decoration:
                  const InputDecoration(
                labelText: "OTP",
                hintText:
                    "Enter 6-digit OTP",
                border:
                    OutlineInputBorder(),
                prefixIcon:
                    Icon(Icons.lock),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width:
                  double.infinity,

              child:
                  ElevatedButton(
                onPressed:
                    isLoading
                        ? null
                        : verifyOtp,

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
                        "Verify OTP",
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
    otpController.dispose();
    super.dispose();
  }
}