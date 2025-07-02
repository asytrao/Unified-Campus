import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'student_list_page.dart';
import 'subject_manager_page.dart';
import 'add_year_page.dart';

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
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading professor data: $e")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Widget buildCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Professor Dashboard'),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("👋 Welcome, $name", style: const TextStyle(fontSize: 20)),
            Text(
              "🏫 Department: $department",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            buildCard("📘 First Year", Icons.looks_one, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentListPage(
                    year: 'First Year',
                    department: department ?? '',
                  ),
                ),
              );
            }),
            buildCard("📗 Second Year", Icons.looks_two, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentListPage(
                    year: 'Second Year',
                    department: department ?? '',
                  ),
                ),
              );
            }),
            buildCard("📙 Third Year", Icons.looks_3, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StudentListPage(
                    year: 'Third Year',
                    department: department ?? '',
                  ),
                ),
              );
            }),
            const SizedBox(height: 10),
            buildCard("🗂️ Subject Manager", Icons.menu_book, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubjectManagerPage(year: 'First Year'),
                ),
              );
            }),
            buildCard("➕ Add Year Section", Icons.add_box, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddYearSectionPage()),
              );
            }),
          ],
        ),
      ),
    );
  }
}
