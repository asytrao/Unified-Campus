import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../student/student_home.dart';
import '../professor/professor_home.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  static const Color kPrimary = Color(0xFF2EC4B6); // Teal to match app logo
  static const Color kTextDark = Color(0xFF2C3E50);

  Future<void> login() async {
    setState(() => loading = true);

    try {
      // Sign in user
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;

      // Fetch user document from Firestore
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        throw Exception("User data not found in Firestore.");
      }

      final data = userDoc.data() as Map<String, dynamic>;
      final role = data['role'];

      if (role == 'student') {
        await saveDeviceToken();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentHomePage()),
        );
      } else if (role == 'professor') {
        await saveDeviceToken();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ProfessorHomePage()),
        );
      } else {
        throw Exception("Invalid user role.");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Login failed: ${e.toString()}")));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> saveDeviceToken() async {
    String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': fcmToken,
      });
      print('✅ FCM Token saved: $fcmToken');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: constraints.maxHeight * 0.06),

                      // App name image
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Image.asset(
                          'assets/images/app_name.png',
                          height: 68,
                          width: 260,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Login title
                      const Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: kTextDark, // Dark gray
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Illustration section
                      Container(
                        height: 220,
                        width: 260, // Slightly larger for prominence
                        child: Image.asset(
                          'assets/images/login_clipart.png',
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Email input field
                      Container(
                        width: 300, // Fixed width for better centering
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: const Color(0xFFBDC3C7),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            hintText: 'Email',
                            hintStyle: TextStyle(
                              color: kPrimary, // Teal
                              fontSize: 16,
                            ),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: Color(0xFF7F8C8D), // Dark gray
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Password input field
                      Container(
                        width: 300, // Fixed width for better centering
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: const Color(0xFFBDC3C7),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: 'Password',
                            hintStyle: TextStyle(
                              color: kPrimary, // Teal
                              fontSize: 16,
                            ),
                            prefixIcon: Icon(
                              Icons.lock_outline,
                              color: Color(0xFF7F8C8D), // Dark gray
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Login button
                      SizedBox(
                        width: 300, // Fixed width for better centering
                        height: 50,
                        child: ElevatedButton(
                          onPressed: loading ? null : login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary, // Teal
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 0,
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward, size: 18),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
