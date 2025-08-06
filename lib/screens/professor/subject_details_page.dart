import 'package:flutter/material.dart';
import 'student_list_page.dart';
import 'manage_subject_content_page.dart';

class SubjectDetailPage extends StatelessWidget {
  final String subject;
  final String year;
  final String department;

  const SubjectDetailPage({
    super.key,
    required this.subject,
    required this.year,
    required this.department,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage $subject')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Choose an action:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.people),
              label: const Text("View Students"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StudentListPage(
                      year: year,
                      department: department,
                      subject: subject,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              icon: const Icon(Icons.library_books),
              label: const Text("Manage Assignments & Notes"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageSubjectContentPage(
                      subject: subject,
                      year: year,
                      department: department,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
