import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_page.dart';
import 'package:unified_campus/screens/student/student_home.dart';
import 'screens/professor/professor_home.dart';
import 'package:unified_campus/screens/student/community_chat_page.dart';

class UnifiedCampusApp extends StatelessWidget {
  const UnifiedCampusApp({super.key});

  Future<Widget> _getInitialScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SplashScreen();
    // Fetch user role from Firestore
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!doc.exists) return const SplashScreen();
    final data = doc.data() as Map<String, dynamic>;
    final role = data['role'];
    if (role == 'student') return const StudentHomePage();
    if (role == 'professor') return const ProfessorHomePage();
    return const SplashScreen();
  }

  @override
  Widget build(BuildContext context) {
    setupFCMListeners(context);

    // Handle notification taps
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleMessageClick(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessageClick(message);
    });

    return MaterialApp(
      title: 'Unified Campus',
      navigatorKey: navigatorKey, // Add this line
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: FutureBuilder<Widget>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data ?? const SplashScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Add this function to app.dart (or a utils file and import it)
void setupFCMListeners(BuildContext context) {
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📩 Received foreground message: ${message.notification?.title}');

    if (message.notification != null) {
      final title = message.notification!.title ?? "Notification";
      final body = message.notification!.body ?? "";

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$title\n$body"),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  });
}

// Add this function to handle message clicks
void _handleMessageClick(RemoteMessage message) {
  final data = message.data;
  if (data['type'] == 'new_community_message') {
    final communityId = data['communityId'];
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => CommunityChatPage(
          communityId: communityId,
          communityName: data['communityName'] ?? '',
        ),
      ),
    );
  }
  // Add other navigation logic if needed
}
