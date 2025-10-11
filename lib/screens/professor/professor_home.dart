import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'subject_list_page.dart'; // NEW: added import
import 'subject_manager_page.dart';
import 'add_year_page.dart';
import '../auth/login_page.dart';
import '../common/security_settings_page.dart';

class ProfessorHomePage extends StatefulWidget {
  const ProfessorHomePage({super.key});

  @override
  State<ProfessorHomePage> createState() => _ProfessorHomePageState();
}

class _ProfessorHomePageState extends State<ProfessorHomePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  String? name, email, department;
  bool loading = true;

  final List<String> defaultYears = ["First Year", "Second Year", "Third Year"];
  List<String> years = [];

  @override
  void initState() {
    super.initState();
    loadProfessorData();
  }

  Future<void> loadProfessorData() async {
    try {
      String uid = _auth.currentUser!.uid;
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      final data = doc.data() as Map<String, dynamic>;

      name = data['name'];
      email = data['email'];
      department = data['department'];

      // Fetch years for this department
      List<String> customYears = [];
      if (department != null) {
        try {
          final deptDoc = await _firestore
              .collection('departments')
              .doc(department)
              .get();

          if (deptDoc.exists) {
            final deptData = deptDoc.data() as Map<String, dynamic>;
            customYears = List<String>.from(deptData['years'] ?? []);
          }
        } catch (deptError) {
          print("Warning: Could not fetch department data: $deptError");
          // Don't show error to user, just use default years
          customYears = [];
        }
      }

      // Merge default and custom years, avoiding duplicates
      years = [
        ...defaultYears,
        ...customYears.where((y) => !defaultYears.contains(y)),
      ];
    } catch (e) {
      print("Error loading professor data: $e");
      // Only show error if it's a critical error (not just department fetch failure)
      if (name == null || email == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading professor data: $e")),
        );
      }
    } finally {
      setState(() => loading = false);
    }
  }

  static const Color _primary = Color(0xFF2EC4B6); // teal to match app_name
  static const Color _textDark = Color(0xFF2C3E50);
  static const Color _surface = Colors.white;
  static const Color _background = Color(0xFFF0F2F5);
  static const Color _accentBlue = Color(0xFFD6EBFB);
  static const Color _accentGreen = Color(0xFFCFF3E6);
  static const Color _accentOrange = Color(0xFFFBE3C8);
  static const Color _accentBeige = Color(0xFFEEDFCC);

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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                backgroundColor != null ? 0.08 : 0.05,
              ),
              blurRadius: backgroundColor != null ? 12 : 10,
              offset: const Offset(0, 4),
            ),
          ],
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
                      color: _textDark,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: _textDark.withOpacity(0.6),
                      ),
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

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: _background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.school, color: _primary),
                          SizedBox(width: 8),
                          Text(
                            'Professor Dashboard',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SecuritySettingsPage(),
                          ),
                        );
                      },
                      style: IconButton.styleFrom(
                        foregroundColor: _textDark,
                        backgroundColor: _surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.security),
                    ),
                    const SizedBox(width: 8),
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
                        foregroundColor: _textDark,
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
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
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
                                color: _textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              department != null
                                  ? 'Department of $department'
                                  : '',
                              style: TextStyle(
                                color: _textDark.withOpacity(0.7),
                              ),
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
                Text(
                  'Academic Years',
                  style: TextStyle(color: _textDark.withOpacity(0.7)),
                ),

                const SizedBox(height: 8),

                ...years.asMap().entries.map((entry) {
                  final index = entry.key;
                  final year = entry.value;
                  final bool isCurrent = index == 0; // treat first as current
                  return _cardTile(
                    title: year,
                    subtitle: isCurrent ? 'Current academic year' : 'Archived',
                    icon: Icons.calendar_today,
                    backgroundColor: isCurrent
                        ? _accentGreen
                        : (index % 2 == 0 ? _accentBeige : _accentBlue),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubjectListPage(
                            year: year,
                            department: department ?? '',
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),

                const SizedBox(height: 8),
                Text(
                  'Management',
                  style: TextStyle(color: _textDark.withOpacity(0.7)),
                ),

                const SizedBox(height: 8),
                _cardTile(
                  title: 'Subject Manager',
                  subtitle: 'Create and organize subjects',
                  icon: Icons.menu_book,
                  backgroundColor: _accentOrange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SubjectManagerPage(),
                      ),
                    ).then((_) => loadProfessorData());
                  },
                ),



                const SizedBox(height: 16),
                // Add year CTA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddYearSectionPage(),
                        ),
                      ).then((_) => loadProfessorData());
                    },
                    icon: const Icon(Icons.add),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text('Add Year Section'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
