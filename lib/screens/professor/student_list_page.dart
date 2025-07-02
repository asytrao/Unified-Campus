import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentListPage extends StatelessWidget {
  final String year;
  final String department;

  const StudentListPage({
    super.key,
    required this.year,
    required this.department,
  });

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('year', isEqualTo: year)
        .where('department', isEqualTo: department);

    return Scaffold(
      appBar: AppBar(title: Text('$year Students')),
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
              return Card(
                child: ListTile(
                  title: Text(data['name'] ?? ''),
                  subtitle: Text(data['email'] ?? ''),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
