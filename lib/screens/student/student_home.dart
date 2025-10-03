import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

  // Dark theme color scheme
  static const Color _primary = Color(0xFF2EC4B6); // teal
  static const Color _textPrimary = Colors.white;
  static const Color _textSecondary = Color(0xFFB0B0B0);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _background = Color(0xFF121212);
  static const Color _accentBlue = Color(0xFF3A7ADF);
  static const Color _accentPurple = Color(0xFF8E44AD);
  static const Color _accentGreen = Color(0xFF27AE60);

  @override
  void initState() {
    super.initState();
    saveDeviceToken(); // Save FCM token after login
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.school, color: _primary),
                          SizedBox(width: 8),
                          Text(
                            'Student Dashboard',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () async {
                        await _auth.signOut();
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: _textPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        backgroundColor: _surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Welcome card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back, ${name ?? ''}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              department != null && year != null
                                  ? '$year • $department'
                                  : '',
                              style: TextStyle(color: _textSecondary),
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: _primary.withOpacity(0.15),
                        child: const Icon(Icons.person, color: _primary),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
                Text('Your Subjects', style: TextStyle(color: _textSecondary)),

                const SizedBox(height: 16),

                StreamBuilder<QuerySnapshot>(
                  stream: subjectListStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            "No subjects found.",
                            style: TextStyle(color: _textSecondary),
                          ),
                        ),
                      );
                    }

                    final subjects = snapshot.data!.docs;

                    return Column(
                      children: subjects.asMap().entries.map((entry) {
                        final index = entry.key;
                        final doc = entry.value;
                        final data = doc.data() as Map<String, dynamic>;
                        final subjectName = data['name'] ?? 'Unknown';

                        return _cardTile(
                          title: subjectName,
                          subtitle: 'View assignments, notes, and queries',
                          icon: Icons.menu_book,
                          backgroundColor: index.isEven
                              ? _accentBlue.withOpacity(0.1)
                              : _accentPurple.withOpacity(0.1),
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
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 16),
                Text('Connect', style: TextStyle(color: _textSecondary)),

                const SizedBox(height: 16),
                _cardTile(
                  title: 'Communities',
                  subtitle: 'Connect with your class',
                  icon: Icons.groups,
                  backgroundColor: _accentGreen.withOpacity(0.1),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CommunitiesPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cardTile({
    required String title,
    String? subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Color? backgroundColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: backgroundColor ?? _surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: _primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: _textSecondary),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
