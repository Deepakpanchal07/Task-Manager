import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/profile_screen.dart';
import 'package:frontend/task_screen.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
 

  const HomeScreen({
    super.key,
    
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FlutterSecureStorage storage =
      const FlutterSecureStorage();

  String? profileName;
  String? profileEmail;
  String? profileUserId;

  bool isLoadingProfile = true;

  @override
  void initState() {
    super.initState();

    // Show the login response data initially
    // profileName = widget.name;
    // profileEmail = widget.email;
    // profileUserId = widget.userId;

    // Fetch the latest user data from backend
    fetchUserProfile();
  }

  Future<void> fetchUserProfile() async {
    try {
      // Read token from secure storage
      final String? savedToken =
          await storage.read(key: "token");

      if (savedToken == null) {
        debugPrint("No token found!");
        return;
      }

      // Prepare headers
      final Map<String, String> headers = {
        "Content-Type": "application/json",
        "Authorization": "Bearer $savedToken",
      };

      // Print request
      debugPrint("========== PROFILE REQUEST ==========");
      debugPrint("Method: GET");
      debugPrint("URL: http://localhost:5000/users/profile");

      debugPrint("========== REQUEST HEADERS ==========");

      headers.forEach((key, value) {
        debugPrint("$key: $value");
      });

      // Call profile API
      final response = await http.get(
        Uri.parse("http://localhost:5000/users/profile"),
        headers: headers,
      );

      // Print response status
      debugPrint("========== RESPONSE STATUS ==========");
      debugPrint(response.statusCode.toString());

      // Print response headers
      debugPrint("========== RESPONSE HEADERS ==========");

      response.headers.forEach((key, value) {
        debugPrint("$key: $value");
      });

      // Print response body
      debugPrint("========== RESPONSE BODY ==========");

      try {
        final decodedResponse = jsonDecode(response.body);

        debugPrint(
          const JsonEncoder.withIndent('  ')
              .convert(decodedResponse),
        );
      } catch (_) {
        debugPrint(response.body);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final user = data["user"];

        if (user == null) {
          throw Exception("User data missing in response");
        }

        if (!mounted) return;

        setState(() {
          profileName = user["name"];
          profileEmail = user["email"];
          profileUserId =
              (user["id"] ?? user["_id"]).toString();

          isLoadingProfile = false;
        });
      } else if (response.statusCode == 401) {
        // Backend rejected the token
        await storage.delete(key: "token");

        if (!mounted) return;

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
          (route) => false,
        );
      } else {
        if (!mounted) return;

        setState(() {
          isLoadingProfile = false;
        });

        debugPrint("Profile API failed");
      }
    } catch (error) {
      debugPrint("PROFILE API ERROR: $error");

      if (!mounted) return;

      setState(() {
        isLoadingProfile = false;
      });
    }
  }

  Future<void> logoutUser() async {
    // Delete saved JWT
    await storage.delete(key: "token");

    if (!mounted) return;

    // Clear navigation stack and go to login
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> checkLogin()async{
    final token = await storage.read(key: "token");
    if (token != null && token.isEmpty){
      Get.offAll(() => HomeScreen());
    }else{
      Get.offAll(()=> LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home Screen"),
        actions: [
          IconButton(
            onPressed: logoutUser,
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
          ),
        ],
      ),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: isLoadingProfile
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.account_circle,
                      size: 80,
                    ),

                    const SizedBox(height: 20),

                    Text(
                      "Welcome, $profileName!",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "Email: $profileEmail",
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "User ID: "
                      "$profileUserId",
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      "JWT Token received successfully",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                      // final updatedUser =
                      await Navigator.push(
                            context,
                            MaterialPageRoute(
                                  builder: (context) =>
                                        const ProfileScreen(),
                        ),
                    );

                      fetchUserProfile();
                    // if (updatedUser != null && mounted) {
                    //   setState(() {
                    //     profileName: updatedUser["name"];
                    //     profileEmail: updatedUser["email"];

                    //     profileUserId = (updatedUser["id" ?? updatedUser["_id"].toString()]);
                    //   });
                    // }},
                      },
                    icon: const Icon(Icons.person,),
                    label: const Text("Edit Profile",)),

                   

                    const SizedBox(height: 20),

                    ElevatedButton.icon(onPressed: () {
                      Navigator.push(context,MaterialPageRoute(builder: (context) => const TaskScreen()));
                    },
                    icon: const Icon(Icons.task_alt),
                     label: const Text("Open task Manager")),

                    SizedBox(height: 50,),


                    ElevatedButton.icon(
                      onPressed: logoutUser,
                      icon: const Icon(Icons.logout),
                      label: const Text("Logout"),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}