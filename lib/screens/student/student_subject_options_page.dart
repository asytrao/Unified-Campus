import 'package:flutter/material.dart';
import 'package:unified_campus/screens/student/student_queries_page.dart';
import 'package:unified_campus/screens/student/student_submissions_page.dart';

class StudentSubjectOptionsPage extends StatelessWidget {
  final String subject;
  final String department;
  final String year;

  const StudentSubjectOptionsPage({
    super.key,
    required this.subject,
    required this.department,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(subject)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Select an Option:",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // 📂 View Submissions
            Card(
              child: ListTile(
                leading: const Icon(Icons.assignment),
                title: const Text("View / Submit Assignments & Practicals"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentSubmissionsPage(
                        subject: subject,
                        department: department,
                        year: year,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // ❓ Ask/View Queries
            Card(
              child: ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text("Ask / View Queries"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentQueriesPage(
                        subject: subject,
                        department: department,
                        year: year,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
