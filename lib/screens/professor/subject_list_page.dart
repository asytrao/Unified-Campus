import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_list_page.dart';

class SubjectListPage extends StatelessWidget {
  final String year;
  final String department;

  const SubjectListPage({
    super.key,
    required this.year,
    required this.department,
  });

  @override
  Widget build(BuildContext context) {
    final docId =
        "${department.trim().replaceAll(' ', '')}_${year.trim().replaceAll(' ', '')}";
    final docRef = FirebaseFirestore.instance.collection('subjects').doc(docId);

    return Scaffold(
      appBar: AppBar(title: Text("$year Subjects")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: docRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No subjects found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final subjects = List<String>.from(data['subjects'] ?? []);

          if (subjects.isEmpty) {
            return const Center(child: Text("No subjects available."));
          }

          return ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(subject),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentListPage(
                          year: year,
                          department: department,
                          subject: subject,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
