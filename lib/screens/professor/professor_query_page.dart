import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfessorQueryPage extends StatelessWidget {
  final String subject;
  final String year;
  final String department;

  const ProfessorQueryPage({
    super.key,
    required this.subject,
    required this.year,
    required this.department,
  });

  @override
  Widget build(BuildContext context) {
    final docId = "${department.trim().replaceAll(' ', '')}_${year.trim().replaceAll(' ', '')}";
    final queryRef = FirebaseFirestore.instance
        .collection('queries')
        .doc(docId)
        .collection('subjectList')
        .doc(subject.trim().replaceAll(' ', ''))
        .collection('queries')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: Text('Student Queries - $subject'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: queryRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No queries found."));
          }

          final queries = snapshot.data!.docs;

          return ListView.builder(
            itemCount: queries.length,
            itemBuilder: (context, index) {
              final data = queries[index].data() as Map<String, dynamic>;
              final docRef = queries[index].reference;

              final studentName = data['studentName'] ?? 'Unknown';
              final question = data['question'] ?? '';
              final isResolved = data['isResolved'] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(studentName),
                  subtitle: Text(question),
                  trailing: IconButton(
                    icon: Icon(
                      isResolved ? Icons.check_circle : Icons.hourglass_bottom,
                      color: isResolved ? Colors.green : Colors.orange,
                    ),
                    tooltip: isResolved ? "Resolved" : "Mark as Resolved",
                    onPressed: isResolved
                        ? null
                        : () async {
                            await docRef.update({'isResolved': true});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("✅ Marked as resolved")),
                            );
                          },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
