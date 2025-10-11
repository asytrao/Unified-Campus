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

  // Design constants matching other professor pages
  static const Color _primary = Color(0xFF2EC4B6);
  static const Color _textDark = Color(0xFF2C3E50);
  static const Color _surface = Colors.white;
  static const Color _background = Color(0xFFF0F2F5);
  static const Color _accentBlue = Color(0xFFD6EBFB);
  static const Color _accentGreen = Color(0xFFCFF3E6);

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('year', isEqualTo: year)
        .where('department', isEqualTo: department);

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _textDark,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subject != null ? '$year - $subject Students' : '$year Students',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _textDark,
              ),
            ),
            Text(
              department,
              style: TextStyle(
                fontSize: 12,
                color: _textDark.withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: _textDark.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No students found",
                    style: TextStyle(
                      fontSize: 16,
                      color: _textDark.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "No students enrolled in $year",
                    style: TextStyle(
                      fontSize: 14,
                      color: _textDark.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            );
          }

          final students = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = students[index].data() as Map<String, dynamic>;
              final name = data['name'] ?? 'Unnamed';
              final email = data['email'] ?? 'No email';
              final rollNumber = data['rollNumber'];

              return _StudentTile(
                name: name,
                email: email,
                studentId: students[index].id,
                rollNumber: rollNumber,
              );
            },
          );
        },
      ),
    );
  }
}

class _StudentTile extends StatelessWidget {
  final String name;
  final String email;
  final String studentId;
  final String? rollNumber;

  static const Color _textDark = Color(0xFF2C3E50);
  static const Color _surface = Colors.white;
  static const Color _accentBlue = Color(0xFFD6EBFB);

  const _StudentTile({
    required this.name,
    required this.email,
    required this.studentId,
    this.rollNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Container(
            width: 6,
            height: 80,
            decoration: BoxDecoration(
              color: _accentBlue,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _accentBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person, color: Color(0xFF2EC4B6)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    color: _textDark.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (rollNumber != null) ...[
                      Text(
                        'Roll: $rollNumber',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _textDark.withOpacity(0.8),
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(
                          fontSize: 12,
                          color: _textDark.withOpacity(0.5),
                        ),
                      ),
                    ],
                    Text(
                      'ID: ${studentId.substring(0, 8)}...',
                      style: TextStyle(
                        fontSize: 12,
                        color: _textDark.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.chevron_right, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
