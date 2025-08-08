import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/auth/login_page.dart';
import 'package:unified_campus/screens/student/student_home.dart';
import 'screens/professor/professor_home.dart';

class UnifiedCampusApp extends StatelessWidget {
  const UnifiedCampusApp({super.key});

  Future<Widget> _getInitialScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const LoginPage();
    // Fetch user role from Firestore
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!doc.exists) return const LoginPage();
    final data = doc.data() as Map<String, dynamic>;
    final role = data['role'];
    if (role == 'student') return const StudentHomePage();
    if (role == 'professor') return const ProfessorHomePage();
    return const LoginPage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unified Campus',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: FutureBuilder<Widget>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data ?? const LoginPage();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
