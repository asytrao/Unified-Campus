import 'package:flutter/material.dart';
import 'screens/auth/login_page.dart';

class UnifiedCampusApp extends StatelessWidget {
  const UnifiedCampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unified Campus',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
