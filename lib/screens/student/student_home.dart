import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_page.dart';
import 'student_subject_options_page.dart';
import 'communities_page.dart';

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

  // Colors - Lighter theme similar to professor
  static const Color _primary = Color(0xFF2EC4B6); // teal to match professor
  static const Color _textDark = Color(0xFF2C3E50);
  static const Color _surface = Colors.white;
  static const Color _background = Color(0xFFF0F2F5);

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

      await ensureClassCommunity();

      setState(() => loading = false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading profile: $e")));
      setState(() => loading = false);
    }
  }

  Future<void> ensureClassCommunity() async {
    try {
      final communityId = "${department!.trim()}_${year!.trim()}";
      final communityRef = _firestore
          .collection('communities')
          .doc(communityId);

      final communityDoc = await communityRef.get();

      if (!communityDoc.exists) {
        final professorsSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'professor')
            .where('department', isEqualTo: department)
            .get();

        final admins = {for (var doc in professorsSnapshot.docs) doc.id: true};

        final studentsSnapshot = await _firestore
            .collection('users')
            .where('role', isEqualTo: 'student')
            .where('department', isEqualTo: department)
            .where('year', isEqualTo: year)
            .get();

        final members = {for (var doc in studentsSnapshot.docs) doc.id: true};

        await communityRef.set({
          'name': "$department $year Class Group",
          'department': department,
          'year': year,
          'createdAt': FieldValue.serverTimestamp(),
          'admins': admins,
          'members': members,
          'isDefault': true,
        });
      }
    } catch (e) {
      print("Error ensuring class community: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading || department == null || year == null) {
      return Scaffold(
        backgroundColor: _background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final subjectDocId =
        "${department!.trim().replaceAll(' ', '')}_${year!.trim().replaceAll(' ', '')}";
    final subjectListStream = _firestore
        .collection('subjects')
        .doc(subjectDocId)
        .collection('subjectList')
        .snapshots();

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _textDark,
        title: Text("Student Dashboard", style: TextStyle(color: _textDark)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: subjectListStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No subjects found."));
          }

          final subjects = snapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                "👋 Hello, $name",
                style: const TextStyle(fontSize: 20, color: _textDark),
              ),
              Text(
                "🎓 $year - $department",
                style: TextStyle(
                  fontSize: 16,
                  color: _textDark.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                "📚 Your Subjects:",
                style: TextStyle(fontSize: 18, color: _textDark),
              ),
              const SizedBox(height: 12),
              ...subjects.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final subjectName = data['name'] ?? 'Unknown';
                return Card(
                  color: _surface,
                  child: ListTile(
                    title: Text(
                      subjectName,
                      style: const TextStyle(color: _textDark),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey,
                    ),
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
              }).toList(),

              const SizedBox(height: 24),

              const Text(
                "👥 Communities:",
                style: TextStyle(fontSize: 18, color: _textDark),
              ),
              const SizedBox(height: 12),
              Card(
                color: _surface,
                child: ListTile(
                  leading: const Icon(Icons.groups, color: _primary),
                  title: const Text(
                    "Communities",
                    style: TextStyle(color: _textDark),
                  ),
                  subtitle: Text(
                    "Connect with your class",
                    style: TextStyle(color: _textDark.withOpacity(0.7)),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CommunitiesPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
