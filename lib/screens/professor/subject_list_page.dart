import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'subject_details_page.dart';

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
    final subjectListRef = FirebaseFirestore.instance
        .collection('subjects')
        .doc(docId)
        .collection('subjectList');

    return Scaffold(
      appBar: AppBar(title: Text("$year Subjects")),
      body: StreamBuilder<QuerySnapshot>(
        stream: subjectListRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No subjects found."));
          }

          final subjects = snapshot.data!.docs;

          return ListView.builder(
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subjectDoc = subjects[index];
              final subjectData = subjectDoc.data() as Map<String, dynamic>;
              final subjectName =
                  subjectData['name'] as String? ?? 'Unknown Subject';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(subjectName),
                  subtitle: Text(
                    "${subjectData['year'] ?? year} • ${subjectData['department'] ?? department}",
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubjectDetailPage(
                          subject: subjectName,
                          year: year,
                          department: department,
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
