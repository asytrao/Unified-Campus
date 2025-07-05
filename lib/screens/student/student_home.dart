import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_page.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String? name, email, department, year;
  List<String> subjects = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadStudentData();
  }

  Future<void> loadStudentData() async {
    try {
      String uid = _auth.currentUser!.uid;

      // Get student profile
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data() as Map<String, dynamic>;

      name = data['name'];
      email = data['email'];
      department = data['department'];
      year = data['year'];

      // Get subject list from Firestore
      String subjectDocId = "${department}_$year";
      DocumentSnapshot subjectDoc = await _firestore
          .collection('subjects')
          .doc(subjectDocId)
          .get();

      if (subjectDoc.exists) {
        subjects = List<String>.from(subjectDoc['subjects'] ?? []);
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading student data: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await _auth.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: subjects.isEmpty
            ? const Center(child: Text("No subjects found for your year."))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("👋 Hello, $name", style: const TextStyle(fontSize: 20)),
                  Text(
                    "🎓 $year - $department",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "📚 Your Subjects:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...subjects.map(
                    (subject) => Card(
                      elevation: 2,
                      child: ListTile(
                        title: Text(subject),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // TODO: Navigate to subject detail page
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Tapped on $subject')),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
