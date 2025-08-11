import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_page.dart';
import 'student_subject_options_page.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String? name, email, department, year;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadStudentData();
  }

  Future<void> loadStudentData() async {
    try {
      final uid = _auth.currentUser!.uid;
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data() as Map<String, dynamic>;

      name = data['name'];
      email = data['email'];
      department = data['department'];
      year = data['year'];

      setState(() => loading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading profile: $e")),
      );
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading || department == null || year == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final subjectDocId =
        "${department!.trim().replaceAll(' ', '')}_${year!.trim().replaceAll(' ', '')}";
    final subjectListStream = _firestore
        .collection('subjects')
        .doc(subjectDocId)
        .collection('subjectList')
        .snapshots();

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
        child: StreamBuilder<QuerySnapshot>(
          stream: subjectListStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text("No subjects found for your year."),
              );
            }

            final subjects = snapshot.data!.docs;

            return Column(
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
                  (doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final subjectName = data['name'] ?? 'Unknown';
                    return Card(
                      elevation: 2,
                      child: ListTile(
                        title: Text(subjectName),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StudentSubjectOptionsPage(
                                subject: subjectName,
                                department: department!,
                                year: year!,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
