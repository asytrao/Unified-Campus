import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentListPage extends StatelessWidget {
  final String year;
  final String department;
  final String? subject;

  const StudentListPage({
    super.key,
    required this.year,
    required this.department,
    this.subject,
  });

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('year', isEqualTo: year)
        .where('department', isEqualTo: department);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          subject != null ? '$year - $subject Students' : '$year Students',
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No students found."));
          }

          final students = snapshot.data!.docs;

          return ListView.builder(
            itemCount: students.length,
            itemBuilder: (context, index) {
              final data = students[index].data() as Map<String, dynamic>;

              final name = data['name'] ?? 'Unnamed';
              final email = data['email'] ?? 'No email';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(name),
                  subtitle: Text(email),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
